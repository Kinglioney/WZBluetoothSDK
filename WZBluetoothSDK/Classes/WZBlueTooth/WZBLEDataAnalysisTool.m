//
//  WZBLEDataAnalysisTool.m
//  WZBlueToothDemo
//
//  Created by 微智电子 on 2017/9/14.
//  Copyright © 2017年 make. All rights reserved.
//

#import "WZBLEDataAnalysisTool.h"
#import "WZBLEDataModel.h"
#import "WZConstantClass.h"
#import "WZBlueToothManager.h"//
#import "WZBlueToothDataManager.h"//
#import "WZScanDeviceModel.h"
#import "YYModel.h"
#import "NSString+MKEString.h"
#import <iconv.h>
#define LCSTR(str) NSLocalizedString(@(str), nil)
@implementation WZBLEDataAnalysisTool

+(WZBLEDataAnalysisTool*)shareInstance{

    static WZBLEDataAnalysisTool *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[WZBLEDataAnalysisTool alloc]init];
    });
    return tool;
}


// 解析获取设备标准时间数据的通知信息
- (NSMutableDictionary *)notifyDataOfDeviceTimerData:(uint8_t *)bytes {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    for (int i = 10; i < 20; i++) {
        int status = bytes[i];
        [tempArr addObject:@(status)];
    }
    [dic setValue:tempArr forKey:@"DeviceTimeData"];
    return dic;
}




static NSData *ALUTF8NSData(NSData *data) {
    if (!data) return nil;
    const char *iconv_utf8_encoding = "UTF-8";
    iconv_t cd = iconv_open(iconv_utf8_encoding, iconv_utf8_encoding); // 从utf8转utf8
    int one = 1;
    iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one); // 丢弃不正确的字符
    
    size_t inbytesleft, outbytesleft;
    inbytesleft = outbytesleft = data.length;
    char *inbuf  = (char *)data.bytes;
    char *outbuf = malloc(sizeof(char) * data.length);
    char *outptr = outbuf;
    size_t icon = iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft);
    
    if (icon == 0) {
        NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
        iconv_close(cd);
        free(outbuf);
        
        return result;
    }
    return nil;
}

// 解析获取设备用户自定义数据的通知信息
- (CustInfo *)notifyDataOfUserCustomData:(uint8_t *)bytes {
    int model = ((bytes[11] & 0xFF) << 8) | (bytes[12] & 0xff);
    CustInfo *info = [CustInfo new];
    info.addrL = bytes[3] << 8;
    info.addrS = bytes[3];
    
   NSData *data =  [NSData dataWithBytes:bytes length:20];
    NSString *versionStr =  [NSString stringWithFormat:@"%@.%@",[self intToHex:(bytes[17] & 0xFF)],[self intToHex:(bytes[16] & 0xFF)] ];
    if ([versionStr hasPrefix:@"0"]) {
        versionStr = [versionStr substringFromIndex:1];
    }
    info.deviceVersion = versionStr;

    if(bytes[13] == 0x02){
        Byte codeBytes[] = { bytes [14] ,bytes[15],bytes[16],bytes[17],bytes[18],bytes[19]};
        NSData *data = [[NSData alloc] initWithBytes:codeBytes length:6];
        info.deviceCodeStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        //info.macAddressStr = [NSString stringWithFormat:@"%@%@%@%@%@%@",[self intToHex:(bytes[15] & 0xFF)],[self intToHex:(bytes[14] & 0xFF)],[self intToHex:(bytes[13] & 0xFF)],[self intToHex:(bytes[12] & 0xFF)],[self intToHex:(bytes[11] & 0xFF)],[self intToHex:(bytes[10] & 0xFF)]];
    }
  
    info.modelStr = [self intToHex:model];
    switch (bytes[10]) {
        case 0x01: {
            info.type = bytes[10];
            info.model = model;
            info.modelStr = [self intToHex:model];
        } break;
        case 0x02: {
            info.type = bytes[10];
            info.currentValue = model;
        } break;
        case 0x03: {
            info.type = bytes[10];
            info.model = model;
        } break;
        case 0x04: {
            info.type = bytes[10];
            info.model = model;
        } break;
        case 0x05: {
            info.type = bytes[10];
            info.model = model;
        } break;
        case 0x06: {
            info.type = bytes[10];
            info.model = model;
        } break;
        default:
            
            break;
    }
    return info;
}

// 解析获取群组时候的通知信息
- (GroupInfo *)notifyDataOfAddToGroup:(uint8_t *)bytes {
    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    for (int i = 10; i < 19; i++) {
        if (bytes[i] != 0xff) {
            int grpAddr = bytes[i];
            [tempArr addObject:@([[self intToHex:grpAddr] integerValue])];
        }
    }
    // 传递地址
    int addr = ((bytes[3] & 0xFF) << 8) | bytes[4];
    GroupInfo *info = [[GroupInfo alloc] init];
    info.devAddr =  addr;
    info.groupArray = [NSArray arrayWithArray:tempArr];
    return info;
}

// 解析获取设备灯珠状态的通知信息
- (NSArray *)notifyDataOfDeviceStatus:(uint8_t *)bytes {

    NSMutableArray *tempArr = [[NSMutableArray alloc] init];
    for (int i = 10; i < 17; i++) {
        int status = bytes[i];
        [tempArr addObject:@(status)];
    }
    
    return tempArr;
}

// 解析获取设备闹钟信息的通知解析
- (AlarmInfo *)notifyDataOfAlarmInfo:(uint8_t *)bytes {
    
    AlarmInfo *info = [[AlarmInfo alloc] init];
    info.addrL = bytes[3] << 8;
    info.addrS = bytes[3];
    info.alarmCount = bytes[19];
    if (bytes[10] != 0x00) {
        info.valid = YES;
    } else {
        info.valid = NO;
    }
    info.alarmId = bytes[11];
    info.actionAndModel = bytes[12];
    NSArray *array = [self converByteToBitsArray:bytes[12]];
    
    if (array) {
        info.isOn = [array[0] boolValue];
        info.isWeek = [array[3] boolValue];
        if ([array[3] integerValue] == 0) {
            info.type = 0; // Day
        }
        if ([array[3] integerValue] == 1) {
            info.type = 1; // Week
        }
        if ([array[6] integerValue] == 1 && [array[7] integerValue] == 0) {
            info.event = 2; // Scene
        }
        if ([array[7] integerValue] == 0 && [array[6] integerValue] == 0) {
            info.event = 0; // Off
        }
        if ([array[7] integerValue] == 1) {
            info.event = 1; // On
        }
    }
    info.month = bytes[13];
    info.dayOrCycle = bytes[14];
    info.hour = bytes[15];
    info.minute = bytes[16];
    info.second = bytes[17];
    info.sceneId = bytes[18];
    return info;
}

// 解析获取设备场景信息的通知解析
- (SceneInfo *)notifyDataOfSceneInfo:(uint8_t *)bytes {

    SceneInfo *info = [[SceneInfo alloc] init];
    info.addrL = bytes[3] << 8;
    info.addrS = bytes[3];
    info.sceneCount = bytes[18];
    info.senceId = bytes[10];
    info.lum = bytes[11];
    info.red = bytes[12];
    info.green = bytes[13];
    info.blue = bytes[14];
    info.warm = bytes[15];
    info.cold = bytes[16];
    return info;
}
// 将状态回复的两条指令合并
- (WZBLEDataModel *)getDeviceModelWithBytes:(uint8_t *)bytes isFirst:(BOOL)isFirst {
    WZBLEDataModel *model = nil;
    //bytes 最多有2个设备信息
   //67 6b 9b 0 0 d3 42 dc 11 2 1 5f 64 ff 0 0 0 0 0 0
    if (bytes[8] == 0x11 && bytes[9] == 0x02) {
        int com = bytes[7];
        int devAd = 0;
        
        // 命令码
        if (com == 0xdc) {
            devAd = bytes[10];
            if (devAd == 0) {
                return nil;
            }
            devAd = isFirst ? bytes[10] : bytes[14];
            model = [self getDeviceWithAddress:devAd];
            if (!model) {
                return nil;
            } else {
                if (isFirst) {//第一个设备
                    if (bytes[11] == 0) {
                        model.state = DeviceStatusOffLine;
                        model.brightness = 0;
                    } else {
                        model.brightness = bytes[12];
                        if (bytes[12] == 0) {
                            model.state = 1;
                        } else {
                            model.state = 2;
                        }
                    }
                } else {
                    if (bytes[15] == 0) {
                        model.state = DeviceStatusOffLine;
                        model.brightness = 0;
                    } else {
                        model.brightness = bytes[16];
                        if (bytes[16] == 0) {
                            model.state = 1;
                        } else {
                            model.state = 2;
                        }
                    }
                }
            }
            //上报
            model.nvccevet = isFirst ?  bytes[13] &0xff : bytes[17] &0xff;
        }
        
    }
   
    if (model) {
       NSArray * models = [WZBLEDataModel selectFromClassPredicateWithFormat:[NSString stringWithFormat:@"where home = '%@'and address = '%d'",[WZBlueToothManager shareInstance].userName,model.address]];
        if (models.count>0) { //存在
            WZBLEDataModel *device = models.firstObject;
            device.state = model.state;
            device.brightness = model.brightness;
            device.nvccevet = model.nvccevet;
            [device updateObject];
        }else{
            model.devModel = kDeviceDefaultMode;
            model.home = [WZBlueToothManager shareInstance].userName;
            model.nvccevet = model.nvccevet;
            [model insertObject];
        }
        [self checkCurrentHomeMeshId:model];
    }
    
    return model;
}

- (WZBLEDataModel *)getDeviceWithAddress:(uint32_t)address {
    if (address != 0) {
        WZBLEDataModel *devItem = [[WZBLEDataModel alloc] init];
        // 将地址转换成位置，例如 1->256 (0001->0100)
        uint32_t newAddress = address;
        devItem.address = newAddress;
        return devItem;
    } else {
        return nil;
    }
}
//多设备入网的查询
- (void)checkCurrentHomeMeshId:(WZBLEDataModel *)model{

    NSString *userName = [WZBlueToothManager shareInstance].userName;
    NSString *str = [NSString stringWithFormat:@"where home = '%@'",userName];
    NSArray *devices = [WZScanDeviceModel selectFromClassPredicateWithFormat:str];
    BOOL isExist = NO;
    for (WZScanDeviceModel *device in devices) {
        if (device.address == model.address && [device.home isEqualToString:userName]) {
            isExist = YES;
            break;
        }
    }
    if (isExist == NO) { //别的设备 入网过的device
         WZScanDeviceModel *device = [[WZScanDeviceModel alloc]init];
        device.home = userName;
//        device.per = device.per;
        device.address = model.address;
        device.devModel = model.devModel;
        device.compound = [NSString stringWithFormat:@"%@-%ld", userName, (long)(model.address)];
        [device insertObject];
    }
    
}
// 地址更改解析
- (uint32_t)analysisedAddressAfterSettingWithBytes:(uint8_t *)bytes {
    uint32_t result[2];
    result[0] = bytes[10];
    result[1] = bytes[11];
    return *result;
}

#pragma mark - 工具
+ (void)saveDevicesToUserDefault:(NSArray<WZBLEDataModel*>*)array{
    NSMutableArray * passSource = [@[] mutableCopy];
    for (WZBLEDataModel *model in array) {
        id str = [model yy_modelToJSONObject];
        [passSource addObject:str];
    }
    [[NSUserDefaults standardUserDefaults]setObject:passSource forKey:@"singleDevice"];
}

+ (NSArray<WZBLEDataModel *> *)getDevicesFromUserDefault{
    NSMutableArray *array = [@[] mutableCopy];
   NSArray *devices = [[NSUserDefaults standardUserDefaults]valueForKey:@"singleDevice"];
    for (id str in devices) {
        WZBLEDataModel *model = [WZBLEDataModel yy_modelWithJSON:str];
        [array addObject:model];
    }
    return array;
}

- (void)updateDeviceInfoWithBleUploadModel:(CustInfo *)info{
    
    NSArray *array = [[WZBlueToothDataManager shareInstance]getCurrentDevicesWithOnlie:YES];
    for (WZBLEDataModel *model in array) {
        if (model.address == info.addrS) {
            model.devModel = info.modelStr;
            model.name = [NSString stringWithFormat:@"%@-%d", [MLDeviceHelper getDeviceNameWith:model.devModel], model.address];
            [model updateObject];
        }
    }
}
+ (NSString *)iconAndNameWithModel:(NSString *)model
{
    return [[self alloc] iconAndNameWithModel:model];
}
- (NSString *)iconAndNameWithModel:(NSString *)model {
    NSString *name = [NSString new];
    if ([model hasPrefix:@"a"]) {
        // 灯设备
        if ([model hasSuffix:@"00"]) {
            // 灯带
            name = LCSTR("Strips");
        } else if ([model hasSuffix:@"01"]) {
            // 吊灯
            name = LCSTR("Chandelier");
        } else if ([model hasSuffix:@"02"]) {
            // 轨道灯
            name = LCSTR("TrackLight");
        } else if ([model hasSuffix:@"03"]) {
            // 落地灯
            name = LCSTR("FloorLamp");
        } else if ([model hasSuffix:@"04"]) {
            // 面板灯
            name = LCSTR("PanelLight");
        } else if ([model hasSuffix:@"05"]) {
            // 台灯
            name = LCSTR("TableLamp");
        } else if ([model hasSuffix:@"06"]) {
            // 天花嵌灯
            name = LCSTR("CeilingLights");
        } else if ([model hasSuffix:@"07"]) {
            // 吸顶灯
            name = LCSTR("CeilingLight");
        } else if ([model hasSuffix:@"08"]) {
            // A 型球泡灯
            name = LCSTR("A_ShapeBulb");
        } else if ([model hasSuffix:@"09"]) {
            // B 型蜡烛灯
            name = LCSTR("B_ShapeCandle");
        } else if ([model hasSuffix:@"0a"]) {
            // BR 灯
            name = LCSTR("BR_Light");
        } else if ([model hasSuffix:@"0b"]) {
            // G 型球泡灯
            name = LCSTR("G_ShapeBulb");
        } else if ([model hasSuffix:@"0c"]) {
            // GU10射灯
            name = LCSTR("GU10_Spotlight");
        } else if ([model hasSuffix:@"0d"]) {
            // MR16射灯
            name = LCSTR("MR16_Spotlight");
        } else if ([model hasSuffix:@"0e"]) {
            // PAR 灯
            name = LCSTR("PARLight");
        } else if ([model hasSuffix:@"10"]) {
            // 情景灯
            name = LCSTR("SceneLights");
        } else if ([model hasSuffix:@"11"]) {
            // 斗胆灯
            name = LCSTR("GimbalLight");
        } else if ([model hasSuffix:@"12"]) {
            // 异型灯
            name = LCSTR("ShapedLights");
        } else if ([model hasSuffix:@"20"]) {
            // T5T8 灯管
            name = LCSTR("T5T8_Tubes");
        } else if ([model hasSuffix:@"21"]) {
            // T5T8一体灯管
            name = LCSTR("T5T8_Integrated_Tubes");
        } else if ([model hasSuffix:@"22"]) {
            // 筒灯
            name = LCSTR("DownLight");
        } else {
            // 未知灯具
            name = LCSTR("UnknownDevice");
        }
    } else if ([model hasPrefix:@"b"]) {
        // 传感器
        if ([model hasSuffix:@"00"]) {
            // 风雨传感器
            name = LCSTR("Wind_And_Rain_Sensor");
        } else if ([model hasSuffix:@"01"]) {
            // 空气传感器
            name = LCSTR("AirSensor");
        } else if ([model hasSuffix:@"02"]) {
            // 门磁传感器
            name = LCSTR("MenciSensor");
        } else if ([model hasSuffix:@"03"]) {
            // 人体红外传感器
            name = LCSTR("Human_Body_Infrared_Sensor");
        } else if ([model hasSuffix:@"04"]) {
            // 水浸传感器
            name = LCSTR("FloodingSensor");
        } else if ([model hasSuffix:@"05"]) {
            // 温度传感器
            name = LCSTR("TemperatureSensor");
        } else if ([model hasSuffix:@"06"]) {
            // 烟雾传感器
            name = LCSTR("SmokeSensor");
        } else if ([model hasSuffix:@"07"]) {
            // 照度传感器
            name = LCSTR("IlluminationSensor");
        } else {
            // 未知传感器
            name = LCSTR("UnknownSensor");
        }
    } else if ([model hasPrefix:@"c"]) {
        // 遥控器、开关等配件
        if ([model hasSuffix:@"000"]) {
            // 手持遥控器
            name = LCSTR("Remote");
        } else if ([model hasSuffix:@"001"]) {
            // 开关
            name = LCSTR("Switch");
        } else if( [model hasSuffix:@"100"]){
            //网关设备
            name = LCSTR("Gateway");
        } else if ([model hasSuffix:@"002"]){
            //钥匙扣按钮
            name = LCSTR("钥匙扣按钮");
        }
        else {
            name = LCSTR("UnknownRemote");
        }
    } else {
        // 未知灯具
        name = LCSTR("UnknownDevice");
    }

    return name;
}


+ (NSString *)NameWithModel:(NSString *)model {
    NSString *name = [NSString new];
    if ([model hasPrefix:@"a"]) {
        // 灯设备
        if ([model hasSuffix:@"00"]) {
            // 灯带
            name = @"灯带";
        } else if ([model hasSuffix:@"01"]) {
            // 吊灯
            name = @"吊灯";
        } else if ([model hasSuffix:@"02"]) {
            // 轨道灯
            name = @"轨道灯";
        } else if ([model hasSuffix:@"03"]) {
            // 落地灯
            name = @"落地灯";
        } else if ([model hasSuffix:@"04"]) {
            // 面板灯
            name = @"面板灯";
        } else if ([model hasSuffix:@"05"]) {
            // 台灯
            name = @"台灯";
        } else if ([model hasSuffix:@"06"]) {
            // 天花嵌灯
            name = @"天花嵌灯";
        } else if ([model hasSuffix:@"07"]) {
            // 吸顶灯
            name = @"吸顶灯";
        } else if ([model hasSuffix:@"08"]) {
            // A 型球泡灯
            name = @"A型球泡灯";
        } else if ([model hasSuffix:@"09"]) {
            // B 型蜡烛灯
            name = @"B型蜡烛灯";
        } else if ([model hasSuffix:@"0a"]) {
            // BR 灯
            name = @"BR灯";
        } else if ([model hasSuffix:@"0b"]) {
            // G型球泡灯
            name = @"G型球泡灯";
        } else if ([model hasSuffix:@"0c"]) {
            // GU10射灯
            name = @"GU10射灯";
        } else if ([model hasSuffix:@"0d"]) {
            // MR16射灯
            name = @"MR16射灯";
        } else if ([model hasSuffix:@"0e"]) {
            // PAR灯
            name = @"PAR灯";
        } else if ([model hasSuffix:@"10"]) {
            // 情景灯
            name = @"情景灯";
        } else if ([model hasSuffix:@"11"]) {
            // 斗胆灯
            name = @"斗胆灯";
        } else if ([model hasSuffix:@"12"]) {
            // 异型灯
            name = @"异型灯";
        } else if ([model hasSuffix:@"20"]) {
            // T5T8 灯管
            name = @"T5T8灯管";
        } else if ([model hasSuffix:@"21"]) {
            // T5T8一体灯管
            name = @"T5T8一体灯管";
        } else if ([model hasSuffix:@"22"]) {
            // 筒灯
            name = @"筒灯";
        } else {
            // 未知灯具
            name = @"未知灯具";
        }
    } else if ([model hasPrefix:@"b"]) {
        // 传感器
        if ([model hasSuffix:@"00"]) {
            // 风雨传感器
            name = @"风雨传感器";
        } else if ([model hasSuffix:@"01"]) {
            // 空气传感器
            name = @"空气传感器";
        } else if ([model hasSuffix:@"02"]) {
            // 门磁传感器
            name = @"门磁传感器";
        } else if ([model hasSuffix:@"03"]) {
            // 人体红外传感器
            name = @"人体红外传感器";
        } else if ([model hasSuffix:@"04"]) {
            // 水浸传感器
            name = @"水浸传感器";
        } else if ([model hasSuffix:@"05"]) {
            // 温度传感器
            name = @"温度传感器";
        } else if ([model hasSuffix:@"06"]) {
            // 烟雾传感器
            name = @"烟雾传感器";
        } else if ([model hasSuffix:@"07"]) {
            // 照度传感器
            name = @"照度传感器";
        } else {
            // 未知传感器
            name = @"未知传感器";
        }
    } else if ([model hasPrefix:@"c"]) {
        // 遥控器、开关等配件
        if ([model hasSuffix:@"000"]) {
            // 手持遥控器
            name = @"遥控器";
        } else if ([model hasSuffix:@"001"]) {
            // 开关
            name = @"面板灯";
        } else if( [model hasSuffix:@"100"]){
            //网关设备
            name = @"网关";
        } else if ([model hasSuffix:@"002"]){
            //钥匙扣按钮
            name = @"钥匙扣按钮";
        }
        else {
            name = @"未知灯具";
        }
    } else {
        // 未知灯具
        name = @"未知灯具";
    }
    
    return name;
}

- (uint32_t)hexToInt:(NSString *)hexStr {
    NSScanner *tempScaner=[[NSScanner alloc] initWithString:hexStr];
    uint32_t tempValue;
    [tempScaner scanHexInt:&tempValue];
    return tempValue;
}


//将十进制转化为十六进制
- (NSString *)intToHex:(int)value {
    NSString *nLetterValue;
    NSString *str =@"";
    int ttmpig;
    for (int i = 0; i < 9; i++) {
        ttmpig = value % 16;
        value = value / 16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"a";break;
            case 11:
                nLetterValue =@"b";break;
            case 12:
                nLetterValue =@"c";break;
            case 13:
                nLetterValue =@"d";break;
            case 14:
                nLetterValue =@"e";break;
            case 15:
                nLetterValue =@"f";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (value == 0) {
            break;
        }
    }
    //不够一个字节凑0
    if(str.length == 1){
        return [NSString stringWithFormat:@"0%@",str];
    } else {
        return str;
    }
}


- (NSMutableArray *)converByteToBitsArray:(char)byte {
    char buffer[9];
    buffer[8] = 0; //for null
    int j = 8;
    while(j > 0)
    {
        if(byte & 0x01)
        {
            buffer[--j] = '1';
        } else
        {
            buffer[--j] = '0';
        }
        byte >>= 1;
    }
    NSString *myString = [NSString stringWithFormat:@"%s", buffer];
    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[myString length]];
    for (int i = 0; i < [myString length]; i++) {
        NSString *ichar  = [NSString stringWithFormat:@"%c", [myString characterAtIndex:i]];
        [characters addObject:ichar];
    }
    return characters;
}
@end
