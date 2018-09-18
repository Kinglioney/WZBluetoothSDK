//
//  WZBLEDataModel.m
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/14.
//  Copyright © 2017年 make. All rights reserved.
//

#import "WZBLEDataModel.h"

@implementation WZBLEDataModel

- (NSString *)description{

    return [NSString stringWithFormat:@"%@%d",self.name,self.address];
}

- (int)addressLong{
    return self.address<<8;
}


+ (NSArray *)memoryPropertys
{
    return @[@"addressLong",@"ismember"];
}

@end

@implementation Group

- (instancetype)initWithDB{
    
    self = [super init];
    if (self) {
                NSInteger count = [Group selectFromClassAllObject].count;
                self.groupAddress = (int)(0x8000+count);
                self.name = [NSString stringWithFormat:@"自定义群组%ld",count-4];
    }
    return self;
}


+ (int)getGroupIdWithAdress:(int)addr{
    return addr+0x8011;
}

+ (NSInteger)getRowWithGourpId:(int)groupId{
    return groupId;
}

+ (NSArray *)memoryPropertys
{
    return @[@"isMembership"];
}
@end


@implementation ColorInfo


@end


@implementation GroupInfo






@end


@implementation AlarmInfo
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.homeName = [[NSUserDefaults standardUserDefaults] valueForKey:currentHomeName];
        self.second = 0;
        self.month = 0;
        self.sceneId = 0;
    }
    return self;
}

- (int)getAlarmId {
    NSArray *array = [AlarmInfo selectFromClassPredicateWithFormat:[NSString stringWithFormat:@"where homeName = '%@' and addrL = '%d'",[[NSUserDefaults standardUserDefaults] valueForKey:currentHomeName],self.addrL]];
    if (array.count > 0) {
        int index = 1;
        for (int i = 1; i <= 16; i++) {
            BOOL isExist = NO;
            for (AlarmInfo *item in array) {
                if (item.alarmId == i) {
                    isExist = YES;
                    break;
                }
            }
            if (isExist == NO) {
                index = i;
                break;
            }
        }
        return index;
    } else {
        return 1;
    }
}

+ (NSString *)binaryToWeekStr:(int)binary {
    NSString *weekStr = [NSString new];
    switch (binary) {
        case 7:
            weekStr = LCSTR("sun");
            break;
        case 6:
            weekStr = LCSTR("mon");
            break;
        case 5:
            weekStr = LCSTR("tus");
            break;
        case 4:
            weekStr = LCSTR("wed");
            break;
        case 3:
            weekStr = LCSTR("thur");
            break;
        case 2:
            weekStr = LCSTR("fri");
            break;
        case 1:
            weekStr = LCSTR("sat");
            break;
        default:
            break;
    }
    return weekStr;
}
@end


//@implementation SensorInfo
//
//
//@end



@implementation CustInfo


@end

@implementation SceneInfo
+ (int)getNextSceneId{
    int sceneId = (int)([SceneInfo selectFromClassAllObject].count + 1);
    if (sceneId >13) {
        sceneId = 13;
    }
    return sceneId;
}


@end


@implementation SceneDeviceAddr

@end
