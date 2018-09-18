//
//  WZDeviceModel.m
//  MKBabyBlueDemo
//
//  Created by 微智电子 on 2017/9/8.
//  Copyright © 2017年 微智电子. All rights reserved.
//

#import "WZDeviceModel.h"
#import "WZConstantClass.h"


@implementation WZDeviceModel

- (instancetype)initWithAdvertisementData:(NSDictionary *)advertisementData
                               peripheral:(CBPeripheral *)peripheral
                                     RSSI:(NSNumber *)RSSI{
    self = [super init];
    if (self) {
        
        _devModel = [NSString new];
        _devId = [NSString new];
        _name = [NSString new];
        
        
        NSString *localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        NSString *facturerData = [[[advertisementData objectForKey:@"kCBAdvDataManufacturerData"] description] stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (facturerData.length >= 42) {
            
            NSString *tempStr = [facturerData substringWithRange:NSMakeRange(1, 4)];
            uint32_t tempVid = [self getIntValueByHex:tempStr];
            
            if (tempVid == BTDevInfo_UID || tempVid == BTDevInfo_UID_0) {
                
                self.peripheral = peripheral;
                self.name = localName;
                self.devId = [[peripheral identifier] UUIDString];
                self.manufactureID = tempVid;
                self.rssi = [RSSI intValue];
                tempStr = [facturerData substringWithRange:NSMakeRange(5, 4)];
                self.devModel = tempStr;
                tempStr = [facturerData substringWithRange:NSMakeRange(9, 8)];
                self.mac = [self getIntValueByHex:tempStr];
                tempStr = [facturerData substringWithRange:NSMakeRange(29, 4)];
                self.productId = [self getIntValueByHex:tempStr];
                tempStr = [facturerData substringWithRange:NSMakeRange(33, 2)];
                self.status = (int)[self getIntValueByHex:tempStr];
                tempStr = [facturerData substringWithRange:NSMakeRange(35, 2)];
                self.address = (int)[self getIntValueByHex:tempStr];
            }
            
        }else{
        
            NSLog(@"============facturerData.length < 42 ==========");
            NSLog(@"facturerData:%@",facturerData);
            
        }
        
    }
    return self;
}

+ (int)getMeshIdForAdvertisement:(NSDictionary *)dic{
    int meshId = 0;
    NSString *facturerData = [[[dic objectForKey:@"kCBAdvDataManufacturerData"] description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (facturerData.length >= 42) {
        NSString *tempStr = [facturerData substringWithRange:NSMakeRange(35, 4)];
        meshId = (int)[[self alloc] getIntValueByHex:tempStr];
    }
    return meshId;
}

- (uint32_t)getIntValueByHex:(NSString *)getStr {
    NSScanner *tempScaner = [[NSScanner alloc] initWithString:getStr];
    uint32_t tempValue;
    [tempScaner scanHexInt:&tempValue];
    return tempValue;
}

- (NSString *)description{

    return [NSString stringWithFormat:@"name=%@，address=%u",self.name,self.address>>8];
}
@end
