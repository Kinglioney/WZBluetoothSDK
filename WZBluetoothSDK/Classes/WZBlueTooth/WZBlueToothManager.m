//
//  WZBlueToothManager.m
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/12.
//  Copyright © 2017年 make. All rights reserved.
//  处理蓝牙逻辑的类

#import "WZBlueToothManager.h"
#import "WZConstantClass.h"
#import "WZBlueToothDataManager.h"
//#import "NSTimer+MKTimer.h"


@interface WZBlueToothManager()

/**特征*/
@property (nonatomic,strong) CBCharacteristic *OTACharacteristic;
@property (nonatomic,strong) CBCharacteristic *notifyCharacteristic;
@property (nonatomic,strong) CBCharacteristic *commandCharacteristic;
@property (nonatomic,strong) CBCharacteristic *pairCharacteristic;
@property (nonatomic,strong) CBCharacteristic *fireWareCharacteristic;
/**username */
//@property (nonatomic,copy) NSString *userName;
@property (nonatomic, copy) NSString *meshName;
/**pwd */
@property (nonatomic,copy) NSString *password;
/**登陆成功标识 */
@property (nonatomic,assign) BOOL isLogin;

/**扫描到的设备列表*/
@property (nonatomic,strong) NSMutableArray *scanListArray;
/**连接成功的list*/
@property (nonatomic,strong) NSMutableArray *connectSucArray;
/**连接失败的list*/
@property (nonatomic,strong) NSMutableArray *connectFailArray;
/**连接超时的list*/
@property (nonatomic,strong) NSMutableArray *connectOutTimeArray;
/**用于标示 直连设备的连接状态 */
@property (nonatomic,assign) BOOL isConnecting;
@property (nonatomic,strong) BabyBluetooth *baby;
/**连接的定时器 检查有没有超时*/
@property (nonatomic,strong) NSTimer *connectOverTimer;
@property (nonatomic,strong) NSTimer *foundOverTimer;
/**当前运行的状态 */
@property (nonatomic,assign) WZBlueToothCurrentStatus currentStatus;

/**meshID */
@property (nonatomic,assign) int meshId;

/**记录扫描到设备的数量 */
@property (nonatomic,assign) NSInteger deviceNumber;
/**没有扫描到设备的次数 */
@property (nonatomic,assign) NSInteger scanEmptyNumber;
@end


@implementation WZBlueToothManager


#pragma mark - 单例模式
+ (WZBlueToothManager *)shareInstance{
    static WZBlueToothManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WZBlueToothManager alloc]init];
//
    });
    return manager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.baby = [BabyBluetooth shareBabyBluetooth];
        self.currentStatus = WZBlueToothScan; //默认模式
        [self initDelegate];
    }
    return self;
}

- (void)initDelegate{
    [self cancelScanDelegate];
    [self didDisConnectDevice];
    [self didConnectDeviceSuccessful];
    [self didConnectDeviceFailure];
    [self didDisConnectDevice];
    [self didDiscoverServices];
    [self didDiscoverCharacteristics];
    [self readValueForCharacteristic];
    [self centralManagerDidUpdateState];
    
}

#pragma mark - 蓝牙的操作
- (void)setWillConnectMeshId:(int)address{
    self.meshId = address;
    self.currentStatus = WZBlueToothScanAndConnectPer;
}

- (void)startScanWithLocalName:(NSString *)name andStatus:(WZBlueToothCurrentStatus)status{
    
    [self stopScan];
    [self.scanListArray removeAllObjects];
    [self.connectSucArray removeAllObjects];
    [self.connectFailArray removeAllObjects];
    [self.connectOutTimeArray removeAllObjects];
    [self.deviceList removeAllObjects];
    
    self.scanEmptyNumber = 0;
    self.deviceNumber = 0;
    
    self.currentDevice = nil;
    self.meshName = name;
    self.currentStatus = status;
    self.userName = name;
    
    if (status == WZBlueToothScanAndConnectAll) {
        [self scanForSeconds:1];
    }else if (status == WZBlueToothScanAndConnectOne) {
        [self scanForSeconds:1];
    }else{
        [self scanForSeconds:30];
    }
    
    [self discoverPeripheralsWithName:name andStatus:status];
}

- (void)scanForSeconds:(int)sec{
    self.baby.scanForPeripherals().begin().stop(sec);
}

- (void)cancelAllPeripheralsConnection{
    [self.baby cancelAllPeripheralsConnection];
}

- (void)stopScan{
    
    //    self.currentStatus = WZBlueToothScan;
    [self.baby cancelScan];
    [self.connectOverTimer invalidate];
    self.connectOverTimer = nil;
    
    [self.foundOverTimer invalidate];
    self.foundOverTimer = nil;
}

- (void)stopScanAndCancelAllPeripheralsConnection{
    self.currentStatus = WZBlueToothScan;
    [self stopScan];
    //    if (self.currentDevice) {
    //        [self cancelConnectPeriphral:self.currentDevice.peripheral];
    //    }
    [self cancelAllPeripheralsConnection];
}

- (void)connectPeripheral:(CBPeripheral *)per{
    //开个定时器检查超时
    self.connectOverTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(overTimeAction:) userInfo:per repeats:NO];
    self.baby.having(per).then.connectToPeripherals().discoverServices().begin();
}

- (void)cancelConnectPeriphral:(CBPeripheral *)per{
    [self.baby cancelPeripheralConnection:per];
}

#pragma mark - 蓝牙的代理

/**
 过滤设备的规则
 
 @param userName 根据localName过滤设备
 */
-(void)discoverPeripheralsWithName:(NSString *)userName andStatus:(WZBlueToothCurrentStatus)status{
    
    //设置查找设备的过滤器
    [self.baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationAddDeviceStatus object:kNotificationBeginScanStatus]; //扫描通知
        NSString *localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        if ([localName isEqualToString:userName]) {
            return YES;
        }
        return NO;
    }];
    
    __weak typeof (self)weakSelf = self;
    //设置扫描到设备的委托
    [self.baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheral.state == CBPeripheralStateDisconnected) {
            NSInteger count = weakSelf.scanListArray.count; //当前个数
            [weakSelf.scanListArray addObject:peripheral];
            weakSelf.scanListArray = [weakSelf removeDuplicationScanList];
            NSInteger addCount = weakSelf.scanListArray.count;
            if (count<addCount) { //将没收完广播的设备丢出去，重新扫描
                WZDeviceModel *device = [[WZDeviceModel alloc]initWithAdvertisementData:advertisementData
                                                                             peripheral:peripheral
                                                                                   RSSI:RSSI];
                if (device.peripheral) {
                    [weakSelf.deviceList addObject:device];
                    [weakSelf updateFirmware:device];
//                    [weakSelf checkCurrentHomeMeshId:device];

                }else{
                    [weakSelf.scanListArray removeObject:peripheral];
                }
            }
        }
        if (weakSelf.deviceNumber == weakSelf.scanListArray.count) {
            if (weakSelf.scanEmptyNumber == 3) {
              [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationAddDeviceStatus object:kNotificationNoDeviceStatus]; //扫描通知
            }
            weakSelf.scanEmptyNumber ++;
        }
        weakSelf.deviceNumber = weakSelf.scanListArray.count;
        NSLog(@"scanListArray.count === %ld",(unsigned long)weakSelf.scanListArray.count);
        
    }];
    
    [self.baby setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSString *localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        if ([localName isEqualToString:userName] && weakSelf.isConnecting == NO) {
            weakSelf.isConnecting = YES;
            return YES;
        }
        return NO;
    }];
}

- (void)centralManagerDidUpdateState{
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"蓝牙打开............");
            if (weakSelf.currentStatus == WZBlueToothScanAndConnectOne) {
                if (weakSelf.meshName) {
                    [weakSelf startScanWithLocalName:weakSelf.meshName andStatus:WZBlueToothScanAndConnectOne];
                }
            }
        }else if (central.state ==CBCentralManagerStatePoweredOff){
            NSLog(@"蓝牙关闭............");
            [[WZBlueToothDataManager shareInstance]setAllDeviceOffline];
        }
    }];
}
/**
 停止扫描的回调
 */
- (void)cancelScanDelegate{
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        if (weakSelf.currentStatus == WZBlueToothScanAndConnectAll) { //加灯状态
            NSMutableArray *willConnectArray  = [[weakSelf removeDidconnectPeripheral] mutableCopy];
            if (willConnectArray.count > 0) {
                [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationAddDeviceStatus object:kNotificationStarConnectStatus];
            }
            [weakSelf checkAndConnectNextDevice];
        }else if (weakSelf.currentStatus == WZBlueToothScanAndConnectOne) { //connect one
            [weakSelf checkAndConnectDirectPeriphral];
        }
    }];
}


/**
 连接成功的回调
 */
- (void)didConnectDeviceSuccessful{
    
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"%@连接成功",peripheral);
        
        
        //销毁定时器
        [weakSelf.connectOverTimer invalidate];
        weakSelf.connectOverTimer = nil;
      
            if (!weakSelf.foundOverTimer) {
                weakSelf.foundOverTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:weakSelf selector:@selector(overTimeAction:) userInfo:peripheral repeats:NO];
            }
        

        
        [weakSelf.connectSucArray addObject:peripheral];
        for (WZDeviceModel *device in weakSelf.deviceList) {
            if ([peripheral isEqual:device.peripheral]) {
                weakSelf.currentDevice = device;
                NSLog(@"直连设备的meshID========%d",weakSelf.currentDevice.address);
                [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationOTAConnectSuc object:nil];
                break;
            }
        }
//        if (self.currentStatus == WZBlueToothScanAndConnectPer) {
//            weakSelf.currentStatus = WZBlueToothScanAndConnectOne;
//        }

        //直连。。连接成功
        if (weakSelf.currentStatus == WZBlueToothScanAndConnectOne || weakSelf.currentStatus == WZBlueToothScanAndConnectPer) {
            [weakSelf.scanListArray removeAllObjects];
            [weakSelf.connectSucArray removeAllObjects];
            [weakSelf.connectFailArray removeAllObjects];
            [weakSelf.connectOutTimeArray removeAllObjects];
        }
    }];
    
}


/**
 连接失败的回调
 */
- (void)didConnectDeviceFailure{
    
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"连接失败%@",error);
        //销毁定时器
        [weakSelf.connectOverTimer invalidate];
        weakSelf.connectOverTimer = nil;
        [weakSelf.connectFailArray addObject:peripheral];
    }];
}


/**
 连接超时的回调
 
 @param timer timer.userInfo
 */
- (void)overTimeAction:(NSTimer *)timer{
    NSLog(@"设备连接超时，准备连接下一个");
    CBPeripheral *device = timer.userInfo;
    if (self.currentStatus == WZBlueToothScanAndConnectPer) {
        for (WZDeviceModel *device in self.deviceList) {
            if (device.address == self.meshId) {
                [self connectPeripheral:device.peripheral];
                break;
            }
        }
    }else{
        [self.connectOutTimeArray addObject:device];
        [self cancelConnectPeriphral:device];
    }

    
    //    [self checkAndConnectNextDevice];
}


/**
 断开连接的回调
 */
- (void)didDisConnectDevice{
    
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"断开链接：%@ 还剩%ld",peripheral,(unsigned long)[weakSelf removeDidconnectPeripheral].count);
        weakSelf.currentDevice = nil;
        weakSelf.isConnecting = NO;
        if (self.currentStatus == WZBlueToothScanAndConnectAll) {
            [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationAddDeviceStatus object:kNotificationDisConnectDeviceStatus]; //断开连接
            [weakSelf checkAndConnectNextDevice];
        }else if (self.currentStatus ==WZBlueToothScanAndConnectOne){
            //全部设备重置成离线
            [[WZBlueToothDataManager shareInstance]setAllDeviceOffline];
//            if ([[WZBlueToothDataManager shareInstance].delegate respondsToSelector:@selector(updateDeviceStatus)]) {
//                [[WZBlueToothDataManager shareInstance].delegate updateDeviceStatus];
//            }
            if ([[WZBlueToothDataManager shareInstance].delegate respondsToSelector:@selector(disconnectAllDevice)]) {
                [[WZBlueToothDataManager shareInstance].delegate disconnectAllDevice];
            }
            [weakSelf scanForSeconds:1];
        }else if (self.currentStatus == WZBlueToothScanAndConnectPer){
            [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationOTAConnectFail object:nil];
            [weakSelf stopScan];
        }else{
            [weakSelf stopScan];
        }
    }];
}



/**
 发现服务的回调
 */
- (void)didDiscoverServices{
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        if (error) {
            //错误处理
            [weakSelf checkAndConnectNextDevice];
            return ;
        }
        
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:[CBUUID UUIDWithString:kDeviceInfoServerceUUID]] ) {
                
                [peripheral discoverCharacteristics:nil forService:service];
            }
            if ([service.UUID isEqual:[CBUUID UUIDWithString:kDeviceInfoDevInfoServerceUUID]]) {
                
                [peripheral discoverCharacteristics:nil forService:service];
            }
        }
        
        
    }];
}


/**
 发现设service的Characteristics的回调
 */
- (void)didDiscoverCharacteristics{
    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        if (error) {
            [weakSelf checkAndConnectNextDevice];
            return ;
        }
        NSLog(@"============================发现特征===============================");
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kDeviceInfoServerceUUID]] || [service.UUID isEqual:[CBUUID UUIDWithString:kDeviceInfoDevInfoServerceUUID]]){
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kDeviceCharacteristicNotifyUUID]]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    _notifyCharacteristic = characteristic;
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kDeviceCharacteristicCommandUUID]]) {
                    _commandCharacteristic = characteristic;
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kDeviceCharacteristicPairUUID]]) {
                    if (weakSelf.foundOverTimer) {
                        [weakSelf.foundOverTimer invalidate];
                        weakSelf.foundOverTimer = nil;
                    }
                    _pairCharacteristic = characteristic;
                    if (_currentStatus == WZBlueToothScanAndConnectAll) {
                        [[WZBlueToothDataManager shareInstance]loginPeripheral:peripheral withUserName:weakSelf.meshName pwd:@"2846"];
                    }else {
                        [[WZBlueToothDataManager shareInstance]loginPeripheral:peripheral withUserName:weakSelf.meshName pwd:USERDEFAULT_object(kUserDefaultLoginMeshPwd)];
                    }
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kDeviceCharacteristicOTAUUID]]) {
                    _OTACharacteristic = characteristic;
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kDeviceCharacteristicFireWare]]) {
                    _fireWareCharacteristic = characteristic;
                }
            }
        }
    }];
    
    [self.baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        
        CBCharacteristic *charra =  weakSelf.pairCharacteristic;
        if ([characteristic isEqual: charra]) {
            [weakSelf.currentDevice.peripheral readValueForCharacteristic:characteristic];
        }
    }];
}


/**
 读取特征值
 */
- (void)readValueForCharacteristic{
    //设置读取characteristics的委托
    //    __weak typeof (self)weakSelf = self;
    [self.baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        if (error) {
            return ;
        }
        [[WZBlueToothDataManager shareInstance]handleUpdateValueForCharacteristicData:characteristics perpheral:peripheral];
    }];
}



#pragma mark - 设备数据处理

- (void)checkAndConnectDirectPeriphral{
    NSMutableArray *willConnectArray  = [[self removeDidconnectPeripheral] mutableCopy];
    if (self.currentDevice) {
        [self cancelConnectPeriphral:self.currentDevice.peripheral];
        return;
    }
    if (willConnectArray.count > 0) {
        if (self.currentStatus == WZBlueToothScanAndConnectOne) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self connectPeripheral:willConnectArray.firstObject];
            });
        }else if (self.currentStatus == WZBlueToothScanAndConnectPer){
            for (WZDeviceModel *device in self.deviceList) {
                if (device.address == self.meshId) {
                    [self connectPeripheral:device.peripheral];
                    break;
                }
            }
        }

    }else{ //继续扫描
        //扫描之前清空 异常设备
        [self removeAnomalyDevice];
        [self scanForSeconds:1];
    }
    
}
- (void)checkAndConnectNextDevice{
    NSMutableArray *willConnectArray  = [[self removeDidconnectPeripheral] mutableCopy];
    if (willConnectArray.count > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self connectNextDevice];
        });
        
    }else{ //继续扫描
        //扫描之前清空 异常设备
        [self removeAnomalyDevice];
        if (self.currentStatus == WZBlueToothScanAndConnectOne) {
            [self scanForSeconds:1];
        }else if(self.currentStatus == WZBlueToothScanAndConnectAll) {

            [self scanForSeconds:1.5];
        }
        
    }
}

- (void)connectNextDevice{
    
    NSMutableArray *willConnectArray = [[self removeDidconnectPeripheral] mutableCopy];
    for (CBPeripheral *per in willConnectArray) {
        if (per.state == CBPeripheralStateDisconnected) {
            [self connectPeripheral:per];
            break;
        }
    }
}

//入网超时
- (void)addNewNetWorkOverTimeAction{
    if (self.currentDevice) {
        [self.connectOutTimeArray addObject:self.currentDevice.peripheral];
        [self cancelConnectPeriphral:self.currentDevice.peripheral];
    }
}

//固件升级的直连设备
- (void)updateFirmware:(WZDeviceModel *)device{
    if (self.currentStatus == WZBlueToothScanAndConnectPer && device.address == self.meshId) {
        [self stopScan];
        [self connectPeripheral:device.peripheral];
    }
}



/**
 删除重复扫描到的外设
 
 @return 不含重复设备的list
 */
- (NSMutableArray *)removeDuplicationScanList{
    NSMutableSet *scanSet = [NSMutableSet setWithArray:self.scanListArray];
    return [[scanSet allObjects] mutableCopy];
}


/**
 可以连接的设备(删除已连接的设备)
 
 @return 还未连接过的设备array
 */
- (NSArray *)removeDidconnectPeripheral{
    
    NSMutableSet *scanSet = [NSMutableSet setWithArray:self.scanListArray];
    NSMutableSet *sucSet = [NSMutableSet setWithArray:self.connectSucArray];
    NSMutableSet *failSet = [NSMutableSet setWithArray:self.connectFailArray];
    NSMutableSet *outTimeSet = [NSMutableSet setWithArray:self.connectOutTimeArray];
    
    [scanSet minusSet:sucSet];
    [scanSet minusSet:failSet];
    [scanSet minusSet:outTimeSet];
    
    NSArray * array = [scanSet allObjects];
    NSArray *newArray = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CBPeripheral *per1 = obj1;
        CBPeripheral *per2 = obj2;
        return  [per1.identifier.UUIDString compare:per2.identifier.UUIDString];
    }];
    return newArray;
}

//清空异常设备
- (void)removeAnomalyDevice{
    
    NSMutableSet *scanSet = [NSMutableSet setWithArray:self.scanListArray];
    NSMutableSet *failSet = [NSMutableSet setWithArray:self.connectFailArray];
    NSMutableSet *outTimeSet = [NSMutableSet setWithArray:self.connectOutTimeArray];
    [scanSet minusSet:failSet];
    [scanSet minusSet:outTimeSet];
    NSArray * array = [scanSet allObjects];
    NSArray *newArray = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CBPeripheral *per1 = obj1;
        CBPeripheral *per2 = obj2;
        return  [per1.identifier.UUIDString compare:per2.identifier.UUIDString];
    }];
    [self.connectFailArray removeAllObjects];
    [self.connectOutTimeArray removeAllObjects];
    self.scanListArray = [newArray mutableCopy];
}

#pragma mark - 懒加载
- (NSMutableArray *)scanListArray{
    if (!_scanListArray) {
        _scanListArray = [NSMutableArray array];
    }
    return _scanListArray;
}
- (NSMutableArray *)connectSucArray{
    if (!_connectSucArray) {
        _connectSucArray = [NSMutableArray array];
    }
    return _connectSucArray;
}
- (NSMutableArray *)connectFailArray{
    if (!_connectFailArray) {
        _connectFailArray = [NSMutableArray array];
    }
    return _connectFailArray;
}
- (NSMutableArray *)connectOutTimeArray{
    if (!_connectOutTimeArray) {
        _connectOutTimeArray = [NSMutableArray array];
    }
    return _connectOutTimeArray;
}
- (NSMutableArray<WZDeviceModel *> *)deviceList{
    if (!_deviceList) {
        _deviceList = [NSMutableArray array];
    }
    return _deviceList;
}

@end
