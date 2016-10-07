//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

#if BITCOIN_TESTNET
#define BITCOIN_MAGIC_NUMBER 0x0709110bu
#else
#define BITCOIN_MAGIC_NUMBER 0xd9b4bef9u
#endif

CF_IMPLICIT_BRIDGING_ENABLED

CFAllocatorRef SecureAllocator();

CF_IMPLICIT_BRIDGING_DISABLED

@interface NSMutableData (Bitcoin)

+ (NSMutableData *)secureData;
+ (NSMutableData *)secureDataWithLength:(NSUInteger)length;
+ (NSMutableData *)secureDataWithCapacity:(NSUInteger)capacity;
+ (NSMutableData *)secureDataWithData:(NSData *)data;

+ (size_t)sizeOfVarInt:(uint64_t)i;

- (void)appendUInt8:(uint8_t)i;
- (void)appendUInt16:(uint16_t)i;
- (void)appendUInt32:(uint32_t)i;
- (void)appendUInt64:(uint64_t)i;
- (void)appendVarInt:(uint64_t)i;
- (void)appendString:(NSString *)s;

- (void)appendScriptPubKeyForAddress:(NSString *)address;
- (void)appendScriptPushData:(NSData *)d;

- (void)appendMessage:(NSData *)message type:(NSString *)type;
- (void)appendNullPaddedString:(NSString *)s length:(NSUInteger)length;
- (void)appendNetAddress:(uint32_t)address port:(uint16_t)port services:(uint64_t)services;

@end
