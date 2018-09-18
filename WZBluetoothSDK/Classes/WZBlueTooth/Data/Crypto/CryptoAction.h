//
//  CryptoAction.h
//  Rio Light
//
//  Created by TrusBe Sil on 16/2/26.
//  Copyright © 2016年 we-smart Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CryptoAction : NSObject

+ (BOOL)getRandPro:(uint8_t *)prand Len:(int)len;

// prand    16 字节随机数
// Presult  16 字节
+ (BOOL)encryptPair:(NSString *)uName Pas:(NSString *)uPas Prand:(uint8_t *)prand PResult:(uint8_t *)presult;

+ (BOOL)getSectionKey:(NSString *)uName Pas:(NSString *)uPas Prandm:(uint8_t *)prandm Prands:(uint8_t *)prands PResult:(uint8_t *)presult;

+ (BOOL)encryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)micLen Ps:(uint8_t *)ps Len:(int)len;

+ (BOOL)decryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)micLen Ps:(uint8_t *)ps Len:(int)len;

+ (BOOL)getNetworkInfo:(uint8_t *)pcmd Opcode:(int)opcode Str:(NSString *)str Psk:(uint8_t *)psk;

+ (BOOL)getNetworkInfoByte:(uint8_t *)pcmd Opcode:(int)opcode Str:(uint8_t *)str Psk:(uint8_t *)psk;


@end
