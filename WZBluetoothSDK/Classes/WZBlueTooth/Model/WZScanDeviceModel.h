//
//  WZScanDeviceModel.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/14.
//  Copyright © 2017年 make. All rights reserved.
//

#import "WZDeviceModel.h"
#import "FFDataBaseModel.h"
@class CBPeripheral;


@interface WZScanDeviceModel : FFDataBaseModel
@property (nonatomic,strong) CBPeripheral *per;
@property (nonatomic,copy) NSString *compound;//"网络名称-meshId" 如:Filife-1
@property (nonatomic, strong) NSString *home; // 设备所属网络的名称
@property (nonatomic, assign) int address; // meshId
@property (nonatomic, strong) NSString  *devModel;//设备类型
@end
