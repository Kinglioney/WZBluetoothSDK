//
//  WZBLEDataModel.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/14.
//  Copyright © 2017年 make. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFDataBaseModel.h"
#import "WZConstantClass.h"


@class CBPeripheral;


@interface WZBLEDataModel : FFDataBaseModel


@property (nonatomic, strong) CBPeripheral      *per;           // 设备连接对象
@property (nonatomic, assign) NSInteger        macAddr;         // 设备 Mac 地址
@property (nonatomic,   copy) NSString          *home;          // localName
@property (nonatomic,   copy) NSString          *name;          // 设备名称
@property (nonatomic,   copy) NSString          *devModel;      // 设备类型
@property (nonatomic, assign) int               address;        // 设备地址,meshid
@property (nonatomic, assign) int               addressLong;    // 设备长地址
@property (nonatomic, assign) DeviceStatus      state;          // 状态: 0-离线状态, 1-在线关灯状态,  2-在线开灯状态
@property (nonatomic, assign) int               brightness;     // 亮度: 0-100

@property (nonatomic, assign) NVCCEvent         nvccevet;
@property (nonatomic, assign) BOOL              ismember;       //保留字段

@end

@interface Group:FFDataBaseModel
/**默认从0x8011开始*/
@property (nonatomic,assign) int groupAddress;
/**icon */
@property (nonatomic,copy) NSString *imageName;
/**name */
@property (nonatomic,copy) NSString *name;
/**设备地址*/
@property (nonatomic,strong) NSMutableArray *deviceArray;
/**Description */
@property (nonatomic,assign) BOOL isMembership;

//自带id和默认name的初始化方法
- (instancetype)initWithDB;

+ (int)getGroupIdWithAdress:(int)addr;

+ (NSInteger)getRowWithGourpId:(int)groupId;
@end


@interface ColorInfo : NSObject
@property (nonatomic,assign) double red; // 红色
@property (nonatomic,assign) double green; // 绿色
@property (nonatomic,assign) double blue; // 蓝色
@property (nonatomic,assign) double warm; // 暖色
@property (nonatomic,assign) double cold; // 冷色
@property (nonatomic,assign) double lum; // 亮度值
@end

@interface  GroupInfo: NSObject
/**int */
@property (nonatomic,assign) int devAddr;
/**mesh id */
@property (nonatomic,strong) NSArray *groupArray;
@end



@interface AlarmInfo : FFDataBaseModel
/**网络名 */
@property (nonatomic,copy) NSString *homeName;
@property (nonatomic,assign) int addrL;         // 设备长地址两个字节
@property (nonatomic,assign) int addrS;         // 设备短地址一个字节
@property (nonatomic,assign) int alarmCount;         // 闹钟总个数
@property (nonatomic,assign) int alarmId;            // 索引号
@property (nonatomic,assign) BOOL valid;    // 闹钟是否有效
@property (nonatomic,assign) BOOL isOn;
@property (nonatomic,assign) BOOL isWeek;
@property (nonatomic,assign) int type; //1:场景  2:device
@property (nonatomic,assign) int event;
@property (nonatomic,assign) int actionAndModel;     // bit 组合参数: bit0~bit3：闹钟的执行动作, 0：off； 1：on； 2： scene, bit4~bit6：闹钟的类型, 0：DAY； 1：WEEK, bit7：闹钟的使能标识。1为使能。当进行Alarm Add命令的时候，app应把该bit置1，默认为打开闹钟
@property (nonatomic,assign) int month;              // 月份，范围：1~12，当闹钟类型为 day 时，为保留字节，无意义
@property (nonatomic,assign) int dayOrCycle;        // 日期，当闹钟类型为 day 时，为重复星期，bit0为周日，bit1~bit6为周一到周六
@property (nonatomic,assign) int hour;
@property (nonatomic,assign) int minute;
@property (nonatomic,assign) int second;
@property (nonatomic,assign) int sceneId;
/**持续时间 */
@property (nonatomic,assign) int duration;
@property (nonatomic,assign) int justOne; //仅一次
@property (nonatomic,assign) int timeInterval;

- (int)getAlarmId;
+ (NSString *)binaryToWeekStr:(int)binary;
@end




@interface CustInfo : NSObject
@property (nonatomic,assign) int addrL;             // 设备长地址两个字节
@property (nonatomic,assign) int addrS;             // 设备短地址一个字节
@property (nonatomic,assign) int type;              // 数据类型标识，01表示设备类型标识, 02
@property (nonatomic,assign) int model;             // 设备类型
@property (nonatomic,copy) NSString *deviceCodeStr;  // 设备固件编码
@property (nonatomic,copy) NSString *modelStr;    // 设备类型字符串

@property (nonatomic, copy) NSString *deviceVersion;  //设备版本
@property (nonatomic, copy) NSString *macAddressStr; //mac地址
// 传感器实时数据
@property (nonatomic,assign) int currentValue;
@end



/*
@interface SensorInfo : NSObject
@property (nonatomic,assign) int addrL;             // 设备长地址两个字节
@property (nonatomic,assign) int addrS;             // 设备短地址一个字节
@property (nonatomic,assign) int relationId;        // 关系 ID （列 ID）
@property (nonatomic,assign) int isEnable;          // 使能标记，勾选、取消勾选、删除（1-3）
@property (nonatomic,assign) int oneType;           // 传感器关系，小于、等于、大于（1-3）
@property (nonatomic,assign) double oneValue;       // 传感器设定值
@property (nonatomic,assign) int oneAction;         // 执行动作， 开、关、场景（1-3）
@property (nonatomic,assign) int oneSceneId;        // 场景 ID
@property (nonatomic,assign) int twoType;           // 传感器关系，小于、等于、大于（1-3）
@property (nonatomic,assign) double twoValue;       // 传感器设定值
@property (nonatomic,assign) int twoAction;         // 执行动作， 开、关、场景（1-3）
@property (nonatomic,assign) int twoSceneId;        // 场景 ID
@end
*/

@interface SceneInfo: FFDataBaseModel
@property (nonatomic,assign) int addrL;         // 设备长地址两个字节
@property (nonatomic,assign) int addrS;         // 设备短地址一个字节
@property (nonatomic,copy) NSString *name;   //名字
@property (nonatomic,assign) int sceneCount;         // 场景个数
@property (nonatomic,assign) int senceId;       // 场景数据索引号
@property (nonatomic,assign) double lum;           // 亮度值
@property (nonatomic,assign) double red;           // 红色
@property (nonatomic,assign) double green;         // 绿色
@property (nonatomic,assign) double blue;          // 蓝色
@property (nonatomic,assign) double warm;          // 暖色
@property (nonatomic,assign) double cold;          // 冷色
/**
 1~13 场景id
 14 小夜灯
 15 昼
 16 夜节律
 */
+ (int)getNextSceneId;
@end

@interface SceneDeviceAddr:FFDataBaseModel
@property (nonatomic,assign) int senceId;       // 场景数据索引号
@property (nonatomic,assign) int deviceAddr;       // 设备地址

@end
