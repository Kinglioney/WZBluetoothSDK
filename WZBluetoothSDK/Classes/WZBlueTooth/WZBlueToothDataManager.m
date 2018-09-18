//
//  MKBlueToothDataManager.m
//  MKBabyBlueDemo
//
//  Created by 微智电子 on 2017/9/7.
//  Copyright © 2017年 微智电子. All rights reserved.
//

#import "WZBlueToothDataManager.h"

#import "CryptoAction.h"
#import "WZConstantClass.h"
#import "NSTimer+MKTimer.h"
#import "WZDeviceModel.h"
#import "FFDB.h"
#import "WZBLEDataAnalysisTool.h"
#import "WZScanDeviceModel.h"

#define random(x) (rand() % x)
#define MaxSnValue 0xffffff
#define kCMDInterval 0.32

#define ISGroupAddress(address) address > 0x8000 && address < 0xffff
static NSUInteger addIndex; // 指令递增数字

typedef enum {
    BTCommandCaiYang,
    BTCommandInterval
} BTCommand;



@interface WZBlueToothDataManager ()
{
    // 加密界面用到
    uint8_t loginRand[8];
    uint8_t sectionKey[16];
    uint8_t tempbuffer[20];
    
    NSUInteger otaPackIndex;
    // 发送指令中用到
    //    NSTimer *clickTimer;
    int duration;
    NSTimeInterval clickDate;
    int snNo;
    NSInteger addressNumber;
}

@property (nonatomic, strong) dispatch_source_t clickTimer;
@property (nonatomic, assign) BTCommand btCMDType;
@property (nonatomic, assign) NSTimeInterval containCYDelay;
@property (nonatomic, assign) NSTimeInterval exeCMDDate;
@property (nonatomic, assign) NSTimeInterval clickDate;
/**定时器*/
@property (nonatomic,strong) NSTimer *setHomeTimer;
/**userName */
@property (nonatomic,copy) NSString *userName;
/**password */
@property (nonatomic,copy) NSString *password;
/**登陆成功标识 */
@property (nonatomic,assign) BOOL isLogin;
/**Description*/
@property (nonatomic,strong) NSTimer *addrTime;
/**超时次数 */
@property (nonatomic,assign) NSInteger outNumber;
/**旧网络名 */
@property (nonatomic,copy) NSString *oldName;
@end
@implementation WZBlueToothDataManager
@synthesize clickDate=_clickDate;
#pragma mark - 单例模式
+ (WZBlueToothDataManager *)shareInstance{
    static WZBlueToothDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WZBlueToothDataManager alloc]init];
        
    });
    return manager;
}

#pragma mark - 初始化数据
- (instancetype)init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}
- (void)initData{
    memset(loginRand, 0, 8);
    memset(sectionKey, 0, 16);
    srand((int) time(0));
    memset(tempbuffer, 0, 20);
    self.isLogin = NO;
    snNo = random(MaxSnValue);
    duration = 300;
    _outNumber = 0;
    otaPackIndex=0;
}

#pragma mark - 新网络的名称和密码
//登陆
-(void)loginPeripheral:(CBPeripheral *)peripheral withUserName:(NSString *)userName pwd:(NSString *)pwd {
    uint8_t buffer[17];
    [CryptoAction getRandPro:loginRand Len:8];
    for (int i = 0; i < 8; i++) {
        loginRand[i] = i;
    }
    buffer[0] = 12;
    [CryptoAction encryptPair:userName Pas:pwd Prand:loginRand PResult:buffer + 1];
    self.userName = userName;
    self.password = pwd;
    CBCharacteristic *characteristic = [WZBlueToothManager shareInstance].pairCharacteristic;
    [self writeValueWith:peripheral characteristic:characteristic Buffer:buffer Len:17];
}
//上层传入新网络的名称和密码
- (void)setNewNetworkName:(NSString *)name andPwd:(NSString *)pwd{
    if (![name isEqualToString:_netWorkNameNew]) {
        addIndex=0;
    }
    _netWorkPwdNew = pwd;
    _netWorkNameNew = name;
}
//将网络名称和密码设置到添加的设备中去
- (void)configNetworkWithNewName:(NSString *)name pwd:(NSString *)pwd{
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    [CryptoAction getNetworkInfo:buffer Opcode:4 Str:name Psk:sectionKey];
    [self writeValueWith:[WZBlueToothManager shareInstance].currentDevice.peripheral characteristic:[WZBlueToothManager shareInstance].pairCharacteristic Buffer:buffer Len:20];
    memset(buffer, 0, 20);
    [CryptoAction getNetworkInfo:buffer Opcode:5 Str:pwd Psk:sectionKey];
    [self writeValueWith:[WZBlueToothManager shareInstance].currentDevice.peripheral characteristic:[WZBlueToothManager shareInstance].pairCharacteristic Buffer:buffer Len:20];
    
    uint8_t ltkBuffer[20]={0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,0xd8,0xd9,0xda,0xdb,0xdc,0xdd,0xde,0xdf,0x0,0x0,0x0,0x0};
    [CryptoAction getNetworkInfoByte:buffer Opcode:6 Str:ltkBuffer Psk:sectionKey];
    [self writeValueWith:[WZBlueToothManager shareInstance].currentDevice.peripheral characteristic:[WZBlueToothManager shareInstance].pairCharacteristic Buffer:buffer Len:20];
    if (!self.setHomeTimer) {
        self.setHomeTimer = [NSTimer mk_scheduledTimerWithTimeInterval:2.f repeats:NO block:^{
            if ([WZBlueToothManager shareInstance].currentDevice) {
                [[WZBlueToothManager shareInstance]cancelConnectPeriphral:[WZBlueToothManager shareInstance].currentDevice.peripheral];
            }
        }];
    }
}
//修改设备的meshId并加入新网络
- (void)addDeviceToNewNetwork:(NSInteger)newAddress{
    if (self.isLogin == YES && [WZBlueToothManager shareInstance].currentDevice) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self modifyDeviceAddress:[WZBlueToothManager shareInstance].currentDevice.address WithNewAddress:newAddress per:[WZBlueToothManager shareInstance].currentDevice.peripheral]; //修改地址
            if (!_addrTime) {
                NSLog(@"-=================定时器创建 ===================");
                _addrTime = [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(addAddrOutTime) userInfo:nil repeats:NO];
            }
        });
    }else{ // 连接下一个
        [[WZBlueToothManager shareInstance]addNewNetWorkOverTimeAction];
    }
}

- (void)addAddrOutTime{
    NSLog(@"-====================================");
    NSLog(@"-================超时了===============");
    NSLog(@"-=====================================");
    
    [_addrTime invalidate];
    _addrTime = nil;
    if ([WZBlueToothManager shareInstance].currentDevice) {
        [[WZBlueToothManager shareInstance]cancelConnectPeriphral:[WZBlueToothManager shareInstance].currentDevice.peripheral];
    }
}

- (void)outTime:(NSTimer *)noti{
    [[WZBlueToothManager shareInstance]addNewNetWorkOverTimeAction];
}
//发送修改设备meshId的蓝牙指令
- (void)modifyDeviceAddress:(uint32_t)u_Address WithNewAddress:(NSUInteger)newAddress per:(CBPeripheral*)per {
    uint8_t cmd[12] = {0x11, 0x11, 0x70, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x11, 0x02, 0x00, 0x00};
    // 序列号
    cmd[2] = cmd[2] + addIndex;
    if (cmd[2] == 254) {
        cmd[2] = 1;
    }
    // 设备新地址
    cmd[10] = newAddress;
    addIndex++;
    [self sendCommand:cmd Len:12 per:per];
}

- (NSArray *)changeCommandToArray:(uint8_t *)cmd len:(int)len {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0; i < len; i++) {
        [arr addObject:[NSString stringWithFormat:@"%02X", cmd[i]]];
    }
    return arr;
}

//打开上报状态
- (void)openMeshLightStatus:(CBPeripheral *)peripheral {
    uint8_t buffer[1] = {1};
    [self writeValueWith:peripheral characteristic:[WZBlueToothManager shareInstance].notifyCharacteristic Buffer:buffer Len:1];
}

#pragma mark - 数据库操作
- (void)saveNewDevice{
    WZScanDeviceModel *item = [[WZScanDeviceModel alloc]init];
    item.home = self.netWorkNameNew;
    item.compound = [NSString stringWithFormat:@"%@-%ld", self.netWorkNameNew, (long)(addressNumber << 8)];
    item.address = (int)addressNumber;
    item.devModel = [WZBlueToothManager shareInstance].currentDevice.devModel;
    item.per = [WZBlueToothManager shareInstance].currentDevice.peripheral;
    [item insertObject];
    [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationAtNewDevice object:item];
}

- (NSArray *)getCurrentDevicesWithOnlie:(BOOL)on{
    NSString *str;
    if (on) { //在线
        NSLog(@"当前网络名称: %@", [WZBlueToothManager shareInstance].userName);
        str = [NSString stringWithFormat:@"where home = '%@' And state != '0'",[WZBlueToothManager shareInstance].userName];
    }else{
        str = [NSString stringWithFormat:@"where home = '%@'",[WZBlueToothManager shareInstance].userName];
    }
   NSArray *array  = [FFDBTransaction selectObjectWithFFDBClass:[WZBLEDataModel class] format:str];
    array = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        WZBLEDataModel *device1 =  obj1;
        WZBLEDataModel *device2 =  obj2;
        return  [@(device1.address)compare:@(device2.address)];
    }];
    return array;
}

- (void)setAllDeviceOffline{
//    NSArray *array = [WZBLEDataModel selectFromClassPredicateWithFormat:[NSString stringWithFormat:@"where home = '%@'",[WZBlueToothManager shareInstance].userName]];
    NSArray *array = [WZBLEDataModel selectFromClassPredicateWithFormat:@"where state != 0"];
    for (WZBLEDataModel *model in array) {
        model.state = DeviceStatusOffLine;
        [model updateObject];
    }
}

#pragma mark - 读写数据
- (void)writeValueWith:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer Len:(int)len  {
    if (peripheral.state == CBPeripheralStateConnected && characteristic) {
        NSData *tempData = [NSData dataWithBytes:buffer length:len];
        [peripheral writeValue:tempData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

- (void)readValueWith:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic {
    if (peripheral.state == CBPeripheralStateConnected && characteristic) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}

#pragma mark - 打印指令
- (void)logByte:(uint8_t *)bytes Len:(int)len Str:(NSString *)str {
    NSMutableString *byteStr = [[NSMutableString alloc] init];
    for (int i = 0; i < len; i++) {
        [byteStr appendFormat:@"%0x ", bytes[i]];
    }
    NSLog(@"指令：%@: %@", str, byteStr);
}

/**********************************************************************/
#pragma mark - 所有的蓝牙指令发送接口
- (void)sendCommonMesg:(uint32_t)destAddress opCode:(uint8_t)opcode params:(NSData *)cmd {
    uint8_t bytes [20] = { 0x11,0x11,0x59,0x00,0x00,0x00,0x00,0xf1,0x11,0x02,0x00,0x00,0x00,0x00 };
    addIndex += 2 ;
    if(addIndex >= 254) addIndex = 1;
    bytes [2] = addIndex + 20;
    NSLog(@"destAddress = %d",destAddress);
    bytes[5] = destAddress  & 0xff;
    bytes[6] = (destAddress >> 8) & 0xff;
    bytes[7] = opcode & 0xff;
    if(nil != cmd ){
        Byte *paramsbyte = (Byte *)[cmd bytes];
        for(int x = 0 ; x < [cmd length] ; x++) {
            bytes[ 10 + x ] = paramsbyte[ x ];
        }
        [self logByte:paramsbyte Len:sizeof(cmd) Str:@"cmdSendCommonMsg"];
    }
    [self logByte:bytes Len:sizeof(bytes) Str:@"bytesSendCommonMsg"];
    [self sendCommand:bytes Len:20 per:[WZBlueToothManager shareInstance].currentDevice.peripheral];
}
- (void)sendCommand:(uint8_t *)cmd Len:(int)len per:(CBPeripheral *)per{
    NSArray *cmdArr = [self changeCommandToArray:cmd len:len];
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    if (clickDate > current) _clickDate = 0; //修复手机修改时间错误造成的命令延时执行错误的问题；
    //if cmd is nil , return;
    if (!cmdArr) return;
    //if _clickDate is equal 0,it means the first time to executor command
    NSTimeInterval count = 0;
    if (cmd[7] == 0xd0 || cmd[7] == 0xd2 || cmd[7] == 0xe2) {
        self.containCYDelay = YES;
        self.btCMDType = BTCommandCaiYang;
        if ((current - _clickDate) < kCMDInterval) {
            if (_clickTimer) {
                dispatch_cancel(_clickTimer);
                //                [_clickTimer invalidate];
                _clickTimer = nil;
                addIndex--;
            }
            count = (uint64_t)((kCMDInterval + self.clickDate - current) * NSEC_PER_SEC);
            dispatch_queue_t quen = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _clickTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quen);
            dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(count));
            uint64_t interv = (int64_t)(kCMDInterval * NSEC_PER_SEC);
            dispatch_source_set_timer(_clickTimer, start, interv, 0);
            dispatch_source_set_event_handler(_clickTimer, ^{
                [self cmdTimer:cmdArr];
            });
            dispatch_resume(_clickTimer);
        } else {
            [self cmdTimer:cmdArr];
        }
    } else {
        self.btCMDType = BTCommandInterval;
        double temp = current - self.exeCMDDate;
        if (((temp < kCMDInterval) && (temp > 0)) || temp < 0) {
            if (self.exeCMDDate == 0) {
                self.exeCMDDate = current;
            }
            self.exeCMDDate = self.exeCMDDate + kCMDInterval;
            count = self.exeCMDDate + kCMDInterval - current;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(cmdTimer:) withObject:cmdArr afterDelay:count];
            });
        } else {
            [self cmdTimer:cmdArr];
        }
    }
}
- (void)cmdTimer:(id)temp {
    @synchronized(self) {
        if (_clickTimer) {
            dispatch_cancel(_clickTimer);
            //        [_clickTimer invalidate];
            _clickTimer = nil;
            addIndex--;
        }
        int len = (int) [temp count];
        uint8_t cmd[len];
        for (int i = 0; i < len; i++) {
            cmd[i] = strtoul([temp[i] UTF8String], 0, 16);
        }
        NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
        _clickDate = current;
        [self cmd:cmd Len:len];
    }
}

- (void)cmd:(Byte *)cmd Len:(int)len{
    WZDeviceModel *model = [WZBlueToothManager shareInstance].currentDevice;
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    if (self.exeCMDDate < current) {
        self.exeCMDDate = current;
    }
    if (!self.isLogin|| model.peripheral.state != CBPeripheralStateConnected) {
        return;
    }
    uint8_t buffer[20];
    uint8_t sec_ivm[8];
    memset(buffer, 0, 20);
    memcpy(buffer, cmd, len);
    memset(sec_ivm, 0, 8);
    [self getNextSnNo];
    buffer[0] = snNo & 0xff;
    buffer[1] = (snNo >> 8) & 0xff;
    buffer[2] = (snNo >> 16) & 0xff;
    uint32_t tempMac = (uint32_t) model.mac;
    sec_ivm[0] = (tempMac >> 24) & 0xff;
    sec_ivm[1] = (tempMac >> 16) & 0xff;
    sec_ivm[2] = (tempMac >> 8) & 0xff;
    sec_ivm[3] = tempMac & 0xff;
    sec_ivm[4] = 1;
    sec_ivm[5] = buffer[0];
    sec_ivm[6] = buffer[1];
    sec_ivm[7] = buffer[2];
    
    [CryptoAction encryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer + 3 MicLen:2 Ps:buffer + 5 Len:15];
    [self writeValueWith:model.peripheral characteristic:[WZBlueToothManager shareInstance].commandCharacteristic Buffer:buffer Len:20];
}
- (int)getNextSnNo {
    snNo++;
    if (snNo > MaxSnValue) {
        snNo = 1;
    }
    return snNo;
}
#pragma mark - 数据解析部分
//解析设备上报的数据
- (void)handleUpdateValueForCharacteristicData:(CBCharacteristic *)characteristic perpheral:(CBPeripheral *)perpheral {
    CBCharacteristic *charaPair = [WZBlueToothManager shareInstance].pairCharacteristic;
    CBCharacteristic *charaOTA = [WZBlueToothManager shareInstance].OTACharacteristic;
    CBCharacteristic *charaNotify = [WZBlueToothManager shareInstance].notifyCharacteristic;
    CBCharacteristic *charaCommand = [WZBlueToothManager shareInstance].commandCharacteristic;
    CBCharacteristic *fireWear = [WZBlueToothManager shareInstance].fireWareCharacteristic;
    if ([characteristic isEqual:charaPair]) {
        uint8_t *tempData = (uint8_t *) [characteristic.value bytes];
        if (tempData[0] == 13) {
            uint8_t buffer[16];
            // 解密广播数据
            if ([CryptoAction encryptPair:self.userName Pas:self.password Prand:tempData + 1 PResult:buffer]) {
                [self logByte:buffer Len:16 Str:@"CheckBuffer"];
                memset(buffer, 0, 16);
                [CryptoAction getSectionKey:self.userName Pas:self.password Prandm:loginRand Prands:tempData + 1 PResult:buffer];
                memcpy(sectionKey, buffer, 16);
                [self logByte:buffer Len:16 Str:@"SectionKey"];
                // 解密完成，登陆成功
                self.isLogin = YES;
                NSLog(@"=======================登陆成功====================");
                [WSSendMesg sysnAllDeviceTime];
                if ([WZBlueToothManager shareInstance].currentStatus == WZBlueToothScanAndConnectAll){ //加灯状态
                    [self openMeshLightStatus:perpheral];
                    dispatch_queue_t _concurrentQueue = dispatch_queue_create("com.read-write.queue", DISPATCH_QUEUE_SERIAL);
                    dispatch_barrier_sync(_concurrentQueue,^{
                        addressNumber = [WZBlueToothManager shareInstance].currentDevice.address;
                    });
                    dispatch_async(_concurrentQueue, ^{
                        [self addDeviceToNewNetwork:addressNumber];
                    });
                }else if ([WZBlueToothManager shareInstance].currentStatus == WZBlueToothScanAndConnectOne){
                    //打开状态上传
                    [self openMeshLightStatus:perpheral];
                }
            }else{
                NSLog(@"=======================登陆失败====================");
                [[WZBlueToothManager shareInstance]addNewNetWorkOverTimeAction];
                self.isLogin = NO;
            }
        }else if (tempData[0] == 7) {
            if (self.setHomeTimer) {
                [self.setHomeTimer invalidate];
                self.setHomeTimer = nil;
            }
            //完成配网
            [self saveNewDevice];
            if ([WZBlueToothManager shareInstance].currentStatus == WZBlueToothScanAndConnectAll) {
                [[WZBlueToothManager shareInstance]cancelConnectPeriphral:[WZBlueToothManager shareInstance].currentDevice.peripheral];//连接下一个
                [self initData];
            }
        }
        
    }else if ([characteristic isEqual:charaCommand]) {
        if (self.isLogin == YES) {
            uint8_t *tempData = (uint8_t *) [characteristic.value bytes];
            [self pasterData:tempData IsNotify:NO peripheral:perpheral];
        }
    }else if ([characteristic isEqual:charaNotify]) {
        if (self.isLogin == YES) {
            uint8_t *tempData = (uint8_t *) [characteristic.value bytes];
            [self pasterData:tempData IsNotify:YES peripheral:perpheral];
            
        }
    }else if ([characteristic isEqual:charaOTA]) {
        
        
    }else if([characteristic isEqual:fireWear]){
        NSData *tempData = [characteristic value];
        if ([_delegate respondsToSelector:@selector(deviceFirmWareData:)] && tempData) {
            [_delegate deviceFirmWareData:tempData];
        }
    }
}
// 解密所有上报的数据
- (void)pasterData:(uint8_t *)buffer IsNotify:(BOOL)isNotify peripheral:(CBPeripheral *)peripheral {
    uint8_t sec_ivm[8];
    uint32_t tempMac = (uint32_t) [WZBlueToothManager shareInstance].currentDevice.mac;
    
    sec_ivm[0] = (tempMac >> 24) & 0xff;
    sec_ivm[1] = (tempMac >> 16) & 0xff;
    sec_ivm[2] = (tempMac >> 8) & 0xff;
    
    memcpy(sec_ivm + 3, buffer, 5);
    if (!(buffer[0] == 0 && buffer[1] == 0 && buffer[2] == 0)) {
        if ([CryptoAction decryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer + 5 MicLen:2 Ps:buffer + 7 Len:13]) {
            NSLog(@"Manager, 解密返回成功, Buffer: %@", [NSData dataWithBytes:buffer length:20]);
            
        } else {
            NSLog(@"Manager, 解密返回失败, Buffer");
        }
    }
    if (isNotify) {
        // 通知返回
        [self parsingTheBroadcastPackets:buffer peripheral:peripheral];
    } else {
        // 请求返回
        //        [self sendDevCommandReport:buffer];
    }
    
}
// 解析广播包
- (void)parsingTheBroadcastPackets:(uint8_t *)bytes peripheral:(CBPeripheral *)peripheral {
    [self logByte:bytes Len:20 Str:@"【Notify】parsingTheBroadcastPackets"];
    
    // MeshLightStatus 指令
    WZBLEDataModel *firstItem = [[WZBLEDataAnalysisTool shareInstance] getDeviceModelWithBytes:bytes isFirst:YES];
    WZBLEDataModel *secondItem = [[WZBLEDataAnalysisTool shareInstance] getDeviceModelWithBytes:bytes isFirst:NO];
    if ([self.delegate respondsToSelector:@selector(updateDeviceStatus:)]) {
        if (firstItem) {
            [self.delegate updateDeviceStatus:firstItem];
        }
        if (secondItem) {
            [self.delegate updateDeviceStatus:secondItem];
        }
    }
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xe0) {
        NSLog(@"......................");
    }
    // 解析设备修改地址通知
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xe1) {
        //        uint32_t address = [self analysisedAddressAfterSettingWithBytes:bytes];
        NSLog(@"-=================销毁定时器 ===================");
        [_addrTime invalidate];
        _addrTime = nil;
        _outNumber = 0;
        NSLog(@"-==============================================");
        NSLog(@"地址也修改成功了...");
        //地址修改成功后 修改网络
        [self configNetworkWithNewName:_netWorkNameNew pwd:_netWorkPwdNew]; //修改网络
    }
    // 解析设备群组状态通知
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xd4) {
        GroupInfo *info = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfAddToGroup:bytes];
        if ([self.delegate respondsToSelector:@selector(responseOfDeviceHasGroupsArray:)]) {
            [self.delegate responseOfDeviceHasGroupsArray:info];
        }
    }
    
    // 解析设备状态通知
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xdb) {
        NSArray *status = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfDeviceStatus:bytes];
        if ([_delegate respondsToSelector:@selector(responseOfDeviceStatus:)]) {
            [_delegate responseOfDeviceStatus:status];
        }
    }
    // 解析设备用户自定义数据通知
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xeb) {
        CustInfo *status = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfUserCustomData:bytes];
        [[WZBLEDataAnalysisTool shareInstance]updateDeviceInfoWithBleUploadModel:status]; //更新数据库模型
        if ([self.delegate respondsToSelector:@selector(responseOfUserCustomData)]) {
            [self.delegate responseOfUserCustomData]; //通知外面数据已更新
        }
        if ([self.delegate respondsToSelector:@selector(responseOfUserCustomData:)]) {
            [self.delegate responseOfUserCustomData:status]; //通知外面数据已更新
        }
    }
    // 解析设备标准时间通知
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xe9) {
        NSMutableDictionary *status = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfDeviceTimerData:bytes];
        //        if ([delegate respondsToSelector:@selector(responseOfDeviceTimeData:)]) {
        //            [delegate responseOfDeviceTimeData:status];
        //        }
    }
    // 解析设备的闹钟信息
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xe7) {
        AlarmInfo *info = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfAlarmInfo:bytes];
        //        if ([delegate respondsToSelector:@selector(responseOfAlarmInfo:)]) {
        //            [delegate responseOfAlarmInfo:info];
        //        }
        NSLog(@"%@",info);
    }
    // 解析设备的场景获取信息
    if (bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[7] == 0xc1) {
        SceneInfo *info = [[WZBLEDataAnalysisTool shareInstance] notifyDataOfSceneInfo:bytes];
        if ([_delegate respondsToSelector:@selector(responseOfSceneInfo:)]) {
            [_delegate responseOfSceneInfo:info];
        }
    }
    // 解析指定设备的固件版本信息
    if (bytes[7] == 0xc8 && bytes[8] == 0x11 && bytes[9] == 0x02 && bytes[10] == 0x00) {
        NSData *data = [NSData dataWithBytes:bytes length:20];
        if ([self.delegate respondsToSelector:@selector(deviceFirmWareData:)]) {
            [_delegate deviceFirmWareData:[data subdataWithRange:NSMakeRange(11, 9)]];
        }
    }
}
@end
