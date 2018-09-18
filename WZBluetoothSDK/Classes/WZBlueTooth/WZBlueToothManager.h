//
//  WZBlueToothManager.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/12.
//  Copyright © 2017年 make. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BabyBluetooth.h"
#import "WZDeviceModel.h"

typedef enum {
    WZBlueToothScan = 0, //普通扫描模式
    WZBlueToothScanAndConnectAll, //加灯模式
    WZBlueToothScanAndConnectOne, //搜索所有设备并连接一个直连设备
    WZBlueToothScanAndConnectPer, //直连外设 OTA用
}WZBlueToothCurrentStatus;

@interface WZBlueToothManager : NSObject
/**当前连接的设备*/
@property (nonatomic,strong) WZDeviceModel *currentDevice;
/**当前扫描到的设备列表*/
@property (nonatomic,strong) NSMutableArray <WZDeviceModel *> *deviceList;
/**当前运行的状态 */
@property (nonatomic,assign,readonly) WZBlueToothCurrentStatus currentStatus;
/**OTA特征*/
@property (nonatomic,strong,readonly) CBCharacteristic *OTACharacteristic;
@property (nonatomic,strong,readonly) CBCharacteristic *notifyCharacteristic;
@property (nonatomic,strong,readonly) CBCharacteristic *commandCharacteristic;
@property (nonatomic,strong,readonly) CBCharacteristic *pairCharacteristic;
@property (nonatomic,strong,readonly) CBCharacteristic *fireWareCharacteristic;
/**username = localName*/
@property (nonatomic,copy) NSString *userName;

+ (WZBlueToothManager *)shareInstance;

/**
 扫描

 @param name 过滤的localName
 @param status 枚举注释
 */
- (void)startScanWithLocalName:(NSString *)name andStatus:(WZBlueToothCurrentStatus)status;
- (void)stopScan;
- (void)cancelAllPeripheralsConnection;
- (void)stopScanAndCancelAllPeripheralsConnection;
- (void)connectPeripheral:(CBPeripheral *)device;
- (void)cancelConnectPeriphral:(CBPeripheral *)device;


/**
 OTA模式下使用，连接指定的meshId设备

 @param address meshId
 */
- (void)setWillConnectMeshId:(int)address;


#pragma mark --- 配网
/**
 入网超时的处理
 */
- (void)addNewNetWorkOverTimeAction;


@end
