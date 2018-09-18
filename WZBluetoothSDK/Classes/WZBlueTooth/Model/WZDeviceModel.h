//
//  WZDeviceModel.h
//  MKBabyBlueDemo
//
//  Created by 微智电子 on 2017/9/8.
//  Copyright © 2017年 微智电子. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FFDataBaseModel.h"
#import "WZConstantClass.h"




@interface WZDeviceModel : NSObject

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSString *name;               // 设备名称
@property (nonatomic, strong) NSString *devId;              // 设备 ID
@property (nonatomic, strong) NSString  *devModel;          // Mesh UUID, 设备类型标识， 用来判断设备类型 
@property (nonatomic, assign) NSUInteger mac;              // 设备 Mac 地址
@property (nonatomic, assign) int rssi;                     // 信号值
@property (nonatomic, assign) int brightness;             // 亮度: 0-100
@property (nonatomic, assign) int address;            // meshId
@property (nonatomic, assign) DeviceStatus status;             // 状态
@property (nonatomic, assign) uint16_t  manufactureID;      // 厂商辨识 ID
@property (nonatomic, assign) uint16_t  productId;          // 产品 ID
@property (nonatomic, strong) NSMutableArray    *devGroupArray;         // 群组信息




- (instancetype)initWithAdvertisementData:(NSDictionary *)advertisementData
                               peripheral:(CBPeripheral *)peripheral
                                     RSSI:(NSNumber *)RSSI;

+ (int)getMeshIdForAdvertisement:(NSDictionary *)dic;
@end
