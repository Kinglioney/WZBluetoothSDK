//
//  SceneModel.h
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2018/6/13.
//  Copyright © 2018年 make. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SceneModel : NSObject

//场景的id
@property (nonatomic, assign) int              sceneId;
//场景的红色通道
@property (nonatomic, assign) int              sceneRed;
//场景的绿色通道
@property (nonatomic,assign) int               sceneGreen;
//场景的蓝色通道
@property (nonatomic,assign) int               sceneBlue;
//场景的暖色通道
@property (nonatomic,assign) int               sceneWarm;
//场景的冷色通道
@property (nonatomic,assign) int               sceneCold;
//场景的亮度通道
@property (nonatomic,assign) int               sceneBrightness;

@end
