//
//  Created by Admin on 9/8/16.
//

#import "BTCTxInputEntity.h"
#import "BTCTransactionEntity.h"
#import "BTCTransaction.h"
#import "BTCTxOutputEntity.h"
#import "NSData+Bitcoin.h"
#import "NSManagedObject+Sugar.h"

@implementation BTCTxInputEntity

@dynamic txHash;
@dynamic n;
@dynamic signature;
@dynamic sequence;
@dynamic transaction;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx inputIndex:(NSUInteger)index
{
    [self.managedObjectContext performBlockAndWait:^{
        UInt256 hash = UINT256_ZERO;
        
        [tx.inputHashes[index] getValue:&hash];
        self.txHash = [NSData dataWithBytes:&hash length:sizeof(hash)];
        self.n = [tx.inputIndexes[index] intValue];
        self.signature = (tx.inputSignatures[index] != [NSNull null]) ? tx.inputSignatures[index] : nil;
        self.sequence = [tx.inputSequences[index] intValue];
    
        // mark previously unspent outputs as spent
        [[BTCTxOutputEntity objectsMatching:@"txHash == %@ && n == %d", self.txHash, self.n].lastObject setSpent:YES];
    }];
    
    return self;
}

@end
