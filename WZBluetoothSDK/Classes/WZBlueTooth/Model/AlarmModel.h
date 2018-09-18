//
//  AlarmMode.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2018/6/13.
//  Copyright © 2018年 make. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlarmModel : NSObject

// 定时的Id
@property (nonatomic, assign) int               alarmId;
// 定时的模式（ 周期模式的值不为 0，年月日模式为 0 ）
@property (nonatomic, assign) int               alarmWeek;
//定时的执行的月
@property (nonatomic, assign) int               alarmMonths;
//定时执行的日
@property (nonatomic, assign) int               alarmDays;
//定时执行的时
@property (nonatomic, assign) int               alarmHours;
//定时执行的分
@property (nonatomic, assign) int               alarmMins;
//定时执行的秒
@property (nonatomic, assign) int               alarmSeconds;
//定时的开关状态
@property (nonatomic,assign) BOOL               alarmStatus;
//执行的模式（ 0 为关灯，1为开灯，2为场景 ）
@property (nonatomic, assign) int               alarmEvents;
//执行的场景ID
@property (nonatomic, assign) int               alarmSceneId;

@end
