//
//  MKBlueToothDataManager.h
//  MKBabyBlueDemo
//
//  Created by 微智电子 on 2017/9/7.
//  Copyright © 2017年 微智电子. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WZBlueToothManager.h"
#import "WZBLEDataModel.h"
#import "WZScanDeviceModel.h"
@protocol WZBlueToothDataSource<NSObject>
@optional
/**
 设备状态更新
 */
- (void)updateDeviceStatus;
- (void)updateDeviceStatus:(WZBLEDataModel *)model;
/**
 所有设备断开连接了
 */
- (void)disconnectAllDevice;
/**
 设备状态更新 需两个方法一起调用
 */
- (void)responseOfUserCustomData;

- (void)responseOfUserCustomData:(CustInfo *)info;

- (void)responseOfDeviceHasGroupsArray:(GroupInfo*)info;

/**
 设备灯珠状态的通知信息

 @param status [tempArr addObject:@(status)];
 */
- (void)responseOfDeviceStatus:(NSArray *)status;
/**
 获取场景信息的回调
 */
- (void)responseOfSceneInfo:(SceneInfo *)info;
/**
  接收到设备的firewareVersion

 @param data data
 */
- (void)deviceFirmWareData:(NSData *)data;

@end

@interface WZBlueToothDataManager : NSObject
/**登陆状态 */
@property (nonatomic,assign,readonly) BOOL isLogin;
/**新网络的名称 */
@property (nonatomic,   copy) NSString *netWorkNameNew;
/**新密码 */
@property (nonatomic,   copy) NSString *netWorkPwdNew;

/**WZBlueToothDataSource */
@property (nonatomic,   weak) id<WZBlueToothDataSource>delegate;

+ (WZBlueToothDataManager *)shareInstance;

/**
 处理UpdateValueForCharacteristicDataf返回的数据
 */
- (void)handleUpdateValueForCharacteristicData:(CBCharacteristic *)characteristic perpheral:(CBPeripheral *)perpheral;

/**
 Mesh登陆
 @param peripheral 当前外设
 @param userName userName
 @param pwd pwd
 */
-(void)loginPeripheral:(CBPeripheral *)peripheral withUserName:(NSString *)userName pwd:(NSString *)pwd;

/**
 设置新网络
 @param name 新网络名字
 @param pwd pwd
 */
- (void)setNewNetworkName:(NSString *)name andPwd:(NSString *)pwd;

/**
 获取当前mesh网络内的设备
 @param on 是否按照在带线状态过滤
 @return YES- 只获取在线设备 NO-获取所有设备
 */
- (NSArray <WZBLEDataModel *> *)getCurrentDevicesWithOnlie:(BOOL)on;

/**
 获取设备状态
 @param peripheral 当前外设
 */
- (void)openMeshLightStatus:(CBPeripheral *)peripheral;

/**
 将所有设备置为离线状态
 */
- (void)setAllDeviceOffline;

//发送指令的封装接口:所有的指令都通过该方法发送
- (void)sendCommonMesg:(uint32_t)destAddress opCode:(uint8_t)opcode params:(NSData *)cmd;
@end
