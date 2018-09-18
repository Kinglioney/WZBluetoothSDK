//
//  WSTOpCode.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2018/6/2.
//  Copyright © 2018年 make. All rights reserved.
//

#ifndef WSTOpCode_h
#define WSTOpCode_h
//开关灯 设备定位
#define DEVICE_SWITCH  0xD0
//查询群组信息
#define GROUP_INFO_QUERY  0xDD
//更新设备时间
#define UPDATE_DEVICE_TIME 0xE4
//删除设备
#define KICKOUT_DEVICE  0xE3
//色彩调节
#define SET_COLOR 0xE2
//设备状态查询
#define DEVICE_STATUS_QUERY  0xDA
//亮度调节
#define SET_BRIGHTNESS  0xD2
//分配或取消设备群组地址绑定 删除群组
#define GROUP_DEVICE_MANAGE  0xD7
//添加和删除昼夜节律
#define SUNRISE_SUNSET_MANAGE 0xE5
//添加定时 删除定时 修改定时
#define ALARM_MANAGE  0xE5
//读取定时
#define READ_ALARM 0xE6
//场景管理
#define SCENE_MANAGE  0xEE
//加载场景
#define LOAD_SCENE 0xEF
//读取场景
#define READ_SCENE 0xC0
//Mesh OTA
#define MESH_OTA  0xC6
//修改勿扰模式的亮度
#define DND_BRIGHTNESS  0xEE
//修改勿扰模式的时间
#define DND_TIME  0xFF
//获取到固件版本
#define GET_FIRMWARE  0xC7
//获取自定义的数据-(设备类型/固件编码)
#define GET_CUSTOM_DATA 0xEA

#endif /* WSTOpCode_h */
