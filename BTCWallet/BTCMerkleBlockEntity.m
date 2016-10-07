//
//  Created by Admin on 9/8/16.
//

#import "BTCMerkleBlockEntity.h"
#import "BTCMerkleBlock.h"
#import "NSData+Bitcoin.h"
#import "NSManagedObject+Sugar.h"

@implementation BTCMerkleBlockEntity

@dynamic blockHash;
@dynamic height;
@dynamic version;
@dynamic prevBlock;
@dynamic merkleRoot;
@dynamic timestamp;
@dynamic target;
@dynamic nonce;
@dynamic totalTransactions;
@dynamic hashes;
@dynamic flags;

- (instancetype)setAttributesFromBlock:(BTCMerkleBlock *)block;
{
    [self.managedObjectContext performBlockAndWait:^{
        self.blockHash = [NSData dataWithBytes:block.blockHash.u8 length:sizeof(UInt256)];
        self.version = block.version;
        self.prevBlock = [NSData dataWithBytes:block.prevBlock.u8 length:sizeof(UInt256)];
        self.merkleRoot = [NSData dataWithBytes:block.merkleRoot.u8 length:sizeof(UInt256)];
        self.timestamp = block.timestamp - NSTimeIntervalSince1970;
        self.target = block.target;
        self.nonce = block.nonce;
        self.totalTransactions = block.totalTransactions;
        self.hashes = [NSData dataWithData:block.hashes];
        self.flags = [NSData dataWithData:block.flags];
        self.height = block.height;
    }];

    return self;
}

- (BTCMerkleBlock *)merkleBlock
{
    __block BTCMerkleBlock *block = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSData *blockHash = self.blockHash, *prevBlock = self.prevBlock, *merkleRoot = self.merkleRoot;
        UInt256 hash = (blockHash.length == sizeof(UInt256)) ? *(const UInt256 *)blockHash.bytes : UINT256_ZERO,
                prev = (prevBlock.length == sizeof(UInt256)) ? *(const UInt256 *)prevBlock.bytes : UINT256_ZERO,
                root = (merkleRoot.length == sizeof(UInt256)) ? *(const UInt256 *)merkleRoot.bytes : UINT256_ZERO;
        
        block = [[BTCMerkleBlock alloc] initWithBlockHash:hash version:self.version prevBlock:prev merkleRoot:root
                 timestamp:self.timestamp + NSTimeIntervalSince1970 target:self.target nonce:self.nonce
                 totalTransactions:self.totalTransactions hashes:self.hashes flags:self.flags height:self.height];
    }];
    
    return block;
}

@end
