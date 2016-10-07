//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

#define BLOCK_DIFFICULTY_INTERVAL 2016      // number of blocks between difficulty target adjustments
#define BLOCK_UNKNOWN_HEIGHT      INT32_MAX

typedef union _UInt256 UInt256;

@interface BTCMerkleBlock : NSObject

@property (nonatomic, readonly) UInt256 blockHash;
@property (nonatomic, readonly) uint32_t version;
@property (nonatomic, readonly) UInt256 prevBlock;
@property (nonatomic, readonly) UInt256 merkleRoot;
@property (nonatomic, readonly) uint32_t timestamp; // time interval since unix epoch
@property (nonatomic, readonly) uint32_t target;
@property (nonatomic, readonly) uint32_t nonce;
@property (nonatomic, readonly) uint32_t totalTransactions;
@property (nonatomic, readonly) NSData *hashes;
@property (nonatomic, readonly) NSData *flags;
@property (nonatomic, assign) uint32_t height;

@property (nonatomic, readonly) NSArray *txHashes; // the matched tx hashes in the block

// true if merkle tree and timestamp are valid, and proof-of-work matches the stated difficulty target
// NOTE: This only checks if the block difficulty matches the difficulty target in the header. It does not check if the
// target is correct for the block's height in the chain. Use verifyDifficultyFromPreviousBlock: for that.
@property (nonatomic, readonly, getter = isValid) BOOL valid;

@property (nonatomic, readonly, getter = toData) NSData *data;

// message can be either a merkleblock or header message
+ (instancetype)blockWithMessage:(NSData *)message;

- (instancetype)initWithMessage:(NSData *)message;
- (instancetype)initWithBlockHash:(UInt256)blockHash version:(uint32_t)version prevBlock:(UInt256)prevBlock
merkleRoot:(UInt256)merkleRoot timestamp:(uint32_t)timestamp target:(uint32_t)target nonce:(uint32_t)nonce
totalTransactions:(uint32_t)totalTransactions hashes:(NSData *)hashes flags:(NSData *)flags height:(uint32_t)height;

// true if the given tx hash is known to be included in the block
- (BOOL)containsTxHash:(UInt256)txHash;

// Verifies the block difficulty target is correct for the block's position in the chain. Transition time may be 0 if
// height is not a multiple of BLOCK_DIFFICULTY_INTERVAL.
- (BOOL)verifyDifficultyFromPreviousBlock:(BTCMerkleBlock*)previous andTransitionTime:(uint32_t)time;

@end
