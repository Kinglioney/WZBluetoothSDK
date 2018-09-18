//
//  WZBLEDataAnalysisTool.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/14.
//  Copyright © 2017年 make. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WZBLEDataModel.h"
@class WZDeviceModel;
@class WZBLEDataModel;
@class CustInfo;

@interface WZBLEDataAnalysisTool : NSObject

+(WZBLEDataAnalysisTool*)shareInstance;
/**
 解析获取设备标准时间数据的通知信息
 @param bytes bytes description
 @return return value description
 */
- (NSMutableDictionary *)notifyDataOfDeviceTimerData:(uint8_t *)bytes;
/**
 解析获取设备用户自定义数据的通知信息
 @param bytes bytes description
 @return return value description
 */
- (CustInfo *)notifyDataOfUserCustomData:(uint8_t *)bytes;

/**
  解析获取群组时候的通知信
 @return return value description
 */
- (GroupInfo *)notifyDataOfAddToGroup:(uint8_t *)bytes;
/**
 解析获取群组时候的通知信息
 @param bytes bytes description
 @return return value description
 */
- (NSArray *)notifyDataOfDeviceStatus:(uint8_t *)bytes;
/**
 解析获取设备闹钟信息的通知解析
 @param bytes bytes description
 @return return value description
 */
- (AlarmInfo *)notifyDataOfAlarmInfo:(uint8_t *)bytes;
/**
 解析获取设备场景信息的通知解析
 @return return value description
 */
- (SceneInfo *)notifyDataOfSceneInfo:(uint8_t *)bytes;
/**
 将状态回复的两条指令合并处理
 @param bytes bytes description
 @param isFirst isFirst description
 @return return value description
 */
- (WZBLEDataModel *)getDeviceModelWithBytes:(uint8_t *)bytes isFirst:(BOOL)isFirst;
/**
 地址更改解析
 @param bytes bytes description
 @return return value description
 */
- (uint32_t)analysisedAddressAfterSettingWithBytes:(uint8_t *)bytes;

- (void)updateDeviceInfoWithBleUploadModel:(CustInfo *)model;

//根据设备类型来获取设备的名称
+ (NSString *)iconAndNameWithModel:(NSString *)model;
+ (NSString *)NameWithModel:(NSString *)model;

+ (void)saveDevicesToUserDefault:(NSArray<WZBLEDataModel*>*)array;
+ (NSArray<WZBLEDataModel *> *)getDevicesFromUserDefault;
@end
