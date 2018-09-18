//
//  WZConstantClass.h
//  MKBabyBlueDemo
//
//  Created by 微智电子 on 2017/9/5.
//  Copyright © 2017年 微智电子. All rights reserved.
//

#import <Foundation/Foundation.h>


#define BTDevInfo_UID               0x0211            // 新的厂商标识
#define BTDevInfo_UID_0             0x1102            // 旧的厂商标识、兼容老版本的模块
#define DEV_TYPE_LIGHT_RGBWC            @"a0" // RGBWC
#define DEV_TYPE_LIGHT_RGBW             @"a1" // RGBW
#define DEV_TYPE_LIGHT_RGBC             @"a2" // RGBC
#define DEV_TYPE_LIGHT_RGB              @"a3" // RGB
#define DEV_TYPE_LIGHT_WC               @"a4" // WC
#define DEV_TYPE_LIGHT_W                @"a5" // W
#define DEV_TYPE_LIGHT_C                @"a6" // C
#define DEV_TYPE_SENSOR                 @"b0" // 传感器
#define DEV_TYPE_REMOTE                 @"c0" // 开关、遥控
#define DEV_TYPE_GATEWAY                @"c1" // 网关
// Device Model
// 灯带
#define DevModel_DD                     @"a000" // RGBWC
// 吊灯
#define DevModel_DL                     @"a001" // RGBWC
// 轨道灯
#define DevModel_GDD                    @"a002" // RGBWC
// 落地灯
#define DevModel_LDD                    @"a003" // RGBWC
// 面板灯
#define DevModel_MBD                    @"a004" // RGBWC
// 台灯
#define DevModel_TD                     @"a005" // RGBWC
// 天花嵌灯
#define DevModel_THQD                   @"a006" // RGBWC
// 吸顶灯
#define DevModel_XDD                    @"a007" // RGBWC
// A 型球泡灯
#define DevModel_AQPD                   @"a008" // RGBWC
// B 型蜡烛灯
#define DevModel_BLZD                   @"a009" // RGBWC
// BR 灯
#define DevModel_BRD                    @"a00a" // RGBWC
// G 型球泡灯
#define DevModel_GQPD                   @"a00b" // RGBWC
// GU10射灯
#define DevModel_GU10SD                 @"a00c" // RGBWC
#define DevModel_CSD                    @"a50c" // W
// MR16射灯
#define DevModel_MR16SD                 @"a00d" // RGBWC
// PAR 灯
#define DevModel_PARD                   @"a00e" // RGBWC
// 情景灯
#define DevModel_QJD                    @"a010" // RGBWC
//斗胆灯
#define DevModel_DDD                    @"a011" // RGBWC
// 异型灯
#define DevModel_YXD                    @"a012" // RGBWC
// 强波器
#define DevModel_BOOSTER                @"a013"
// T5T8灯管
#define DevModel_T5T8DG                 @"a020" // RGBWC
// T5T8一体灯管
#define DevModel_T5T8YTDG               @"a021" // RGBWC
// 筒灯
#define DevModel_TONGD                  @"a022" // RGBWC
#define DevModel_TONGD_WC               @"a422" // WC
#define DevModel_GATEWAY                @"c100" // 网关

#define DevModel_A208                   @"a208"
#define DevModel_A408                   @"a408"
#define DevModel_A308                   @"a308"
#define remotoWifiGateWayName           @"Wi-Fi连接器"
#define DevModel_RomoteGateWay          @"RqZw4qGfdyjgSd2Q"
#define DevModel_FYS                    @"b000" // 风雨传感器
#define DevModel_KQS                    @"b001" // 空气传感器
#define DevModel_MCS                    @"b002" // 门磁传感器
#define DevModel_HWS                    @"b003" // 人体红外传感器
#define DevModel_SJS                    @"b004" // 水浸传感器
#define DevModel_WDS                    @"b005" // 温度传感器
#define DevModel_YWS                    @"b006" // 烟雾传感器
#define DevModel_ZDS                    @"b007" // 照度传感器

#pragma mark --- 枚举
// 设备状态
typedef NS_ENUM(NSInteger, DeviceStatus) {
    DeviceStatusOffLine = 0,            // 离线
    DeviceStatusOff = 1,                // 关
    DeviceStatusOn = 2,                 // 开
};
typedef NS_ENUM(NSUInteger, NVCCEvent) {
    MESH_DEV_EVT_DEFAULT = 0,
    LIGHT_OFF_EVT,
    LIGHT_ON_EVT,
    LIGHT_RGB_ADJ_EVT,
    LIGHT_CW_ADJ_EVT,
    LIGHT_BRIGHTNESS_ADJ_EVT,
    RC_VALUE_UPDATE_EVT,
    SENSOR_VALUE_UPDATE_EVT        ,
    SENSOR_VALUE_NODIFY,
    GATEWAY_STATU_UPDATE_EVT        ,
    GROUP_ADDR_UPDATE_EVT,
    SCENE_DATA_UPDATE_EVT,
    ALARM_DATA_UPDATE_EVT,
    MESH_DEV_POWER_EVT        ,
};



#pragma mark --- 常量值
/** 特征UUID **/
extern NSString *const kDeviceInfoServerceUUID;
extern NSString *const kDeviceInfoDevInfoServerceUUID;
extern NSString *const kDeviceCharacteristicNotifyUUID; //通知
extern NSString *const kDeviceCharacteristicPairUUID; //登陆
extern NSString *const kDeviceCharacteristicCommandUUID; //command
extern NSString *const kDeviceCharacteristicOTAUUID; //固件升级
extern NSString *const kDeviceCharacteristicFireWare;
/** 获取特征 **/
extern NSString *const kDeviceCharacteristicNotify; //通知
extern NSString *const kDeviceCharacteristicPair; //登陆
extern NSString *const kDeviceCharacteristicCommand; //command
extern NSString *const kDeviceCharacteristicOTA; //固件升

//用户名
extern NSString *const kDeviceLoginUserName;
extern NSString *const kDeviceLoginUserPassword;

//默认模式
extern NSString *const kDeviceDefaultMode;

extern NSString *const kNotificationAtNewDevice; //发现新设备
extern NSString *const kNotificationOTAConnectSuc; //固件升级连接的设备成功
extern NSString *const kNotificationOTAConnectFail; //固件升级失败

//当前homeName
extern NSString *const currentHomeName;
extern NSString *const currentGroupName;
//默认homeName
extern NSString *const defalutHome;


extern NSString *const kNotificationBeginConnectDevice; //通知主界面开始连接设备
extern NSString *const kNotificationUpdateDeviceStatus;

extern NSString *const kNotificationAddDeviceStatus;
extern NSString *const kNotificationBeginScanStatus;
extern NSString *const kNotificationDisConnectDeviceStatus;
extern NSString *const kNotificationNoDeviceStatus;
extern NSString *const kNotificationStarConnectStatus;




