//
//  SendMesg.m
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2018/6/2.
//  Copyright © 2018年 make. All rights reserved.
//

#import "WSSendMesg.h"
#import "WSTOpCode.h"
#import "WZBlueToothDataManager.h"

@implementation WSSendMesg
//设置群组的RGB的值
+ (void)setGroupRGB:(uint32_t)meshId Red:(uint8_t)red Green:(uint8_t)green Blue:(uint8_t)blue Brightness:(uint8_t)brightness Delay:(NSInteger)delay {
    //0x04调节RGB的标识位，RGB表示当前的色彩，0 表示亮度，如果亮度为 0 表示设备保持当前亮度。delay 颜色变化消耗的时间，如果为 0 那么就是表示跳变，如果只是实现渐变的效果发送 0x01 即可
    Byte cmd[] = {0x04, red, green, blue, brightness, delay};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SET_COLOR params: data ];
}

//设置群组的WC
+ (void)setGroupWC:(uint32_t)meshId Warm:(uint8_t)warm Cold:(uint8_t)cold Brightness:(uint8_t)brightness Delay:(NSInteger)delay  {
    //0x08 表示设置 WC 的一个标识。
    Byte cmd[] = {0x08, warm, cold, brightness, delay};
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SET_COLOR params: data];
}

+ (void)ctrlDeviceByRGBWC:(uint32_t)meshId Red:(uint8_t)red Green:(uint8_t)green Blue:(uint8_t)blue Warm:(uint8_t)warm Cold:(uint8_t)cold Brightness:(uint8_t)brightness Delay:(NSInteger)delay Valid:(uint8_t)valid {
    Byte cmd[] = {0x09, red, green, blue, warm, cold, brightness, delay,valid};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SET_COLOR params: data ];
}

+ (void)ctrlDeviceByHSBWC:(uint32_t)meshId H:(CGFloat)h S:(CGFloat)s B:(CGFloat)b Warm:(uint8_t)warm Cold:(uint8_t)cold Brightness:(uint8_t)brightness Delay:(NSInteger)delay Valid:(uint8_t)valid {
    CGFloat red, green, blue;
    UIColor *color = [UIColor colorWithHue:h saturation:s brightness:b alpha:1.0];
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    int redInt = red * 255;
    int greenInt = green * 255;
    int blueInt = blue * 255;
    [self ctrlDeviceByRGBWC:meshId Red:redInt Green:greenInt Blue:blueInt Warm:warm Cold:cold Brightness:brightness Delay:0x01 Valid:valid];
}

+ (void)setBrightness:(uint32_t)meshId Brightness:(uint8_t)brightness {
    if(brightness <= 5) brightness =5;
    Byte cmd[] = {brightness};
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SET_BRIGHTNESS params:data];
}

+ (void)playMusic:(uint32_t)meshID MusicData:(NSData *)musicData{
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshID opCode:SET_BRIGHTNESS params:musicData];
}

+ (void)kickOutDevic:(uint32_t)meshId {
    if(meshId > 0x8000){
        NSLog(@"MeshId is Error,Kick out only work at device,%d",meshId);
        return;
    }
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:KICKOUT_DEVICE params:nil];
}

//获取设备的状态
+ (void)getDeviceStatus:(uint32_t)meshId {
    Byte cmd[] = {0x10};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:DEVICE_STATUS_QUERY params:data];
}

//获取设备所在群组
+ (void)getDevInstanceofGroup:(uint32_t)meshId {
    Byte cmd[] = {0x08,0x01};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:GROUP_INFO_QUERY params:data];
}

//获取固件版本
+ (void)getDevFirmware:(uint32_t)meshId {
    Byte cmd [] = { 0x10 };
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:GET_FIRMWARE params:data];
}

//获取设备类型
+ (void)getDevType:(uint32_t)meshId {
    Byte cmd[] = {0x10};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:GET_CUSTOM_DATA params:data];
}

//支持呼吸效果
+(void)loadDevBreath:(uint32_t)meshId breathId:(int)breathId{
    Byte byte [] = { 0x0A ,(breathId & 0xFF)};
    NSData *data = [[NSData alloc]initWithBytes:byte length:sizeof(byte)];
    [[WZBlueToothDataManager shareInstance] sendCommonMesg:meshId opCode:SET_COLOR params:data];
}

//设备定位
+ (void)locationDevice:(uint32_t)meshId {
    Byte cmd[] = {0x03,0x00,0x00};
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:DEVICE_SWITCH params: data];
}

//开关设备
+ (void)switchDevice:(uint32_t)meshId isOpen:(Boolean)status {
    Byte cmd [] = { (status ?0x01 :0x00), 0x00, 0x00};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:DEVICE_SWITCH params:data];
}

//分配群组状态
+ (void)allocationGroup:(uint32_t)meshId GroupMeshAddress:(uint32_t)groupAddress{
    Byte cmd[] = {0x01, groupAddress & 0xFF, (groupAddress >> 8) & 0xFF};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:GROUP_DEVICE_MANAGE params:data];
}

//取消单个设备群组分配
+ (void)cancelAllocationGroup:(uint32_t)meshId GroupMeshAddress:(uint32_t)groupAddress {
    Byte cmd[] = {0x00, groupAddress & 0xFF, (groupAddress >> 8) & 0xFF};
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:GROUP_DEVICE_MANAGE params: data];
}

//删除群组的信息
+ (void)deleteGroup:(uint32_t)groupAddress {
    Byte cmd[] = {0x01, groupAddress & 0xFF, (groupAddress >> 8) & 0xFF};
    NSData *data = [[NSData alloc] initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:groupAddress opCode:GROUP_DEVICE_MANAGE params: data];
};

//同步全部时间
+ (void)sysnAllDeviceTime {
    NSDate *currDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componts = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:currDate];
    NSInteger year = [componts year];
    NSInteger month = [componts  month];
    NSInteger day = [componts day];
    NSInteger hours = [componts hour];
    NSInteger minutes = [componts minute];
    NSInteger seconds = [componts second];
    Byte cmd [] = { year & 0xFF,(year >> 8) & 0xFF, month & 0xFF, day & 0xFF, hours & 0xFF, minutes & 0xFF,seconds & 0xFF };
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:0xFFFF opCode:UPDATE_DEVICE_TIME params: data ];
};

//通过 meshId 支持更新设备的时间
+ (void)sysnDevTimeByMeshId:(uint32_t)meshId {
    NSDate *currDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componts = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:currDate];
    NSInteger year = [componts year];
    NSInteger month = [componts  month];
    NSInteger day = [componts day];
    NSInteger hours = [componts hour];
    NSInteger minutes = [componts minute];
    NSInteger seconds = [componts second];
    Byte cmd[] = {year & 0xFF, (year >> 8) & 0xFF, month & 0xFF, day & 0xFF, hours & 0xFF, minutes & 0xFF, seconds & 0xFF};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:UPDATE_DEVICE_TIME params:data];
}

//删除设备(群组)的定时
+ (void)deleteDevAlarm:(uint32_t)meshId AlarmId:(uint32_t)alarmId {
    Byte cmd [] = { 0x01,alarmId & 0xFF, 0x00, 0x00};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[ WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:ALARM_MANAGE params:data];
}

//设备(群组)添加或者修改定时
+ (void)addOrChangeAlarmn:(uint32_t)meshId AlarmModel:(AlarmModel *)alarmmode {
    if(alarmmode == nil) return;
    //默认使能开所以组合位的最高位 bit7 为 1
    //判断是否为年月日模式Or周期模式
     int alarmModeInt = 0x80 + (alarmmode.alarmWeek == 0 ?0 : 0x10) + alarmmode.alarmEvents;
    Byte cmd[] = {
                0x02,
                alarmmode.alarmId & 0xFF,
                alarmModeInt & 0xFF,
                alarmmode.alarmWeek == 0 ?alarmmode.alarmMonths :0x00,
                alarmmode.alarmWeek == 0 ? alarmmode.alarmDays :alarmmode.alarmWeek,
                alarmmode.alarmHours & 0xFF,
                alarmmode.alarmMins & 0xFF,
                0x00,
                alarmmode.alarmEvents==2 ? alarmmode.alarmSceneId :0x00
        
    };
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:ALARM_MANAGE params:data];
}
//添加或删除昼夜节律
+ (void)addOrChangeCircadian:(uint32_t)meshId CircadianModel:(MLCircadianModel *)circadianModel isDayOrNight:(BOOL)isDayOrNight{
    int alarmModeInt = 0x92;//昼节律开灯,夜节律关灯
    Byte cmd[] = {
                0x02,
                isDayOrNight ?15 :16,//昼节律的id是15,夜节律的id是16
                alarmModeInt & 0xff,
                0x00,//昼夜节律是周期模式
                0x7f,//默认就是Everyday
                isDayOrNight ?circadianModel.dayStartHours :circadianModel.nightStartHours,
                isDayOrNight ?circadianModel.dayStartMinutes :circadianModel.nightStartMinutes,
                0x00,
                isDayOrNight ?0x0f :0x10,
                isDayOrNight ?circadianModel.dayDurTime :circadianModel.nightDurTime,
    };
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SUNRISE_SUNSET_MANAGE params:data];
}
//加载场景
+ (void)loadScene:(uint32_t)meshId SceneId:(int) sceneId {
    Byte cmd[] = {sceneId & 0xFF};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:LOAD_SCENE params:data];
}

//删除场景
+ (void)deleteScene:(uint32_t)meshId SceneId:(int) sceneId {
    Byte cmd[] = {0x00,sceneId & 0xFF, 0x00, 0x00};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[ WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SCENE_MANAGE params:data];
}

//添加或者修改场景
+ (void)addOrchangeScene:(uint32_t)meshId SceneModel:(SceneModel *)sceneModel {
    //场景的 ID 参数不会大于 13
    if( sceneModel.sceneId > 13 ) return;
    Byte cmd[] = {0x01, sceneModel.sceneId, sceneModel.sceneBrightness, sceneModel.sceneRed, sceneModel.sceneGreen, sceneModel.sceneBlue, sceneModel.sceneWarm, sceneModel.sceneCold};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:SCENE_MANAGE params: data];
}

//读取定时
+ (void)readAlarm:(uint32_t)meshId ReadMode:(int)readmode {
    Byte cmd[] = {0x10, readmode & 0xFF};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:READ_ALARM params:data];
}

//读出场景
+ (void)readScene:(uint32_t)meshId ReadSceneMode:(int)sceneMode {
    Byte cmd[] = {0x10, sceneMode & 0xFF};
    NSData *data = [[NSData alloc]initWithBytes:cmd length:sizeof(cmd)];
    [[WZBlueToothDataManager shareInstance]sendCommonMesg:meshId opCode:READ_SCENE params: data ];
}



@end
