//
//  SendMesg.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2018/6/2.
//  Copyright © 2018年 make. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AlarmModel.h"
#import "SceneModel.h"

@interface WSSendMesg : NSObject

//设置群组的RGB的值
+ (void)setGroupRGB:(uint32_t)meshId  Red:(uint8_t)red Green:(uint8_t)green Blue:(uint8_t)blue Brightness:(uint8_t)brightness Delay:(NSInteger)delay;

//设置群组的WC
+ (void)setGroupWC:(uint32_t)meshId  Warm:(uint8_t)warm Cold:(uint8_t)cold  Brightness:(uint8_t)brightness Delay:(NSInteger)delay;

//设置设备的五路输出值
+ (void)ctrlDeviceByRGBWC:(uint32_t)meshId Red:(uint8_t)red Green:(uint8_t)green Blue:(uint8_t)blue Warm:(uint8_t)warm Cold:(uint8_t)cold Brightness:(uint8_t)brightness Delay:(NSInteger)delay Valid:(uint8_t)valid;

+ (void)ctrlDeviceByHSBWC:(uint32_t)meshId H:(CGFloat)h S:(CGFloat)s B:(CGFloat)b Warm:(uint8_t)warm Cold:(uint8_t)cold Brightness:(uint8_t)brightness Delay:(NSInteger)delay Valid:(uint8_t)valid;

//设置设备的亮度
+ (void)setBrightness:(uint32_t)meshId Brightness:(uint8_t)brightness;

//删除设备
+ (void)kickOutDevic:(uint32_t)meshId;

//播放音乐的指令
+ (void)playMusic:(uint32_t)meshID MusicData:(NSData *)musicData;

//获取设备的状态
+ (void)getDeviceStatus:(uint32_t)meshId;

//获取到设备所属的群组设备
+ (void)getDevInstanceofGroup:(uint32_t)meshId;

//获取固件版本
+ (void)getDevFirmware:(uint32_t)meshId;

//获取设备类型 -(设备类型/固件编码)
+ (void)getDevType:(uint32_t)meshId;

//支持呼吸效果
+(void)loadDevBreath:(uint32_t)meshId breathId:(int)breathId;

//设备定位
+ (void)locationDevice:(uint32_t)meshId;

//开关设备
+ (void)switchDevice:(uint32_t)meshId isOpen:(Boolean)status;

//分配群组状态
+ (void)allocationGroup:(uint32_t)meshId GroupMeshAddress:(uint32_t)groupAddress;

//取消群组分配
+ (void)cancelAllocationGroup:(uint32_t)meshId GroupMeshAddress:(uint32_t)groupAddress;

//设置群组的信息
+ (void)deleteGroup:(uint32_t)groupAddress;

//同步全部时间
+ (void)sysnAllDeviceTime;

//通过 meshId 支持更新设备的时间
+ (void)sysnDevTimeByMeshId:(uint32_t)meshId;

//删除设备(群组)的定时
+ (void)deleteDevAlarm:(uint32_t)meshId AlarmId:(uint32_t)alarmId;

//设备(群组)添加或者修改定时
+ (void)addOrChangeAlarmn:(uint32_t)meshId AlarmModel:(AlarmModel *) alarmmode;

//添加或删除昼夜节律
+ (void)addOrChangeCircadian:(uint32_t)meshId CircadianModel:(MLCircadianModel *)circadianModel isDayOrNight:(BOOL)isDayOrNight;

//加载场景
+ (void)loadScene:(uint32_t)meshId SceneId:(int) sceneId;

//删除场景
+ (void)deleteScene:(uint32_t)meshId SceneId:(int) sceneId;

//添加或者修改场景
+ (void)addOrchangeScene:(uint32_t)meshId SceneModel:(SceneModel *) sceneModel;

//读取场景
+ (void)readScene:(uint32_t)meshId ReadSceneMode:(int)sceneMode;

//读取定时
+ (void)readAlarm:(uint32_t)meshId ReadMode:(int)readmode;


@end
