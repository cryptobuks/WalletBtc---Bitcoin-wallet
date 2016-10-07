//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

#define BLOOM_DEFAULT_FALSEPOSITIVE_RATE 0.0005 // same as bitcoinj, use 0.00005 for less data, 0.001 for good anonymity
#define BLOOM_REDUCED_FALSEPOSITIVE_RATE 0.00005
#define BLOOM_UPDATE_NONE                0
#define BLOOM_UPDATE_ALL                 1
#define BLOOM_UPDATE_P2PUBKEY_ONLY       2
#define BLOOM_MAX_FILTER_LENGTH          36000 // this allows for 10,000 elements with a <0.0001% false positive rate

@class BTCTransaction;

@interface BTCBloomFilter : NSObject

@property (nonatomic, readonly) uint32_t tweak;
@property (nonatomic, readonly) uint8_t flags;
@property (nonatomic, readonly, getter = toData) NSData *data;
@property (nonatomic, readonly) NSUInteger elementCount;
@property (nonatomic, readonly) double falsePositiveRate;
@property (nonatomic, readonly) NSUInteger length;

+ (instancetype)filterWithMessage:(NSData *)message;
+ (instancetype)filterWithFullMatch;

- (instancetype)initWithMessage:(NSData *)message;
- (instancetype)initWithFullMatch;
- (instancetype)initWithFalsePositiveRate:(double)fpRate forElementCount:(NSUInteger)count tweak:(uint32_t)tweak
flags:(uint8_t)flags;
- (BOOL)containsData:(NSData *)data;
- (void)insertData:(NSData *)data;
- (void)updateWithTransaction:(BTCTransaction *)tx;

@end
