//
//  Created by Admin on 9/8/16.
//

#import "BTCTransactionEntity.h"
#import "BTCTxInputEntity.h"
#import "BTCTxOutputEntity.h"
#import "BTCAddressEntity.h"
#import "BTCTransaction.h"
#import "BTCMerkleBlock.h"
#import "NSManagedObject+Sugar.h"
#import "NSData+Bitcoin.h"
#import "NSMutableData+Bitcoin.h"

@implementation BTCTransactionEntity

@dynamic txHash;
@dynamic blockHeight;
@dynamic timestamp;
@dynamic inputs;
@dynamic outputs;
@dynamic lockTime;

+ (void)setContext:(NSManagedObjectContext *)context
{
    [super setContext:context];
    [BTCTxInputEntity setContext:context];
    [BTCTxOutputEntity setContext:context];
}

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx
{
    [self.managedObjectContext performBlockAndWait:^{
        NSMutableOrderedSet *inputs = [self mutableOrderedSetValueForKey:@"inputs"];
        NSMutableOrderedSet *outputs = [self mutableOrderedSetValueForKey:@"outputs"];
        UInt256 txHash = tx.txHash;
        NSUInteger idx = 0;
        
        self.txHash = [NSData dataWithBytes:&txHash length:sizeof(txHash)];
        self.blockHeight = tx.blockHeight;
        self.timestamp = tx.timestamp;
    
        while (inputs.count < tx.inputHashes.count) {
            [inputs addObject:[BTCTxInputEntity managedObject]];
        }
    
        while (inputs.count > tx.inputHashes.count) {
            [inputs removeObjectAtIndex:inputs.count - 1];
        }
    
        for (BTCTxInputEntity *e in inputs) {
            [e setAttributesFromTx:tx inputIndex:idx++];
        }

        while (outputs.count < tx.outputAddresses.count) {
            [outputs addObject:[BTCTxOutputEntity managedObject]];
        }
    
        while (outputs.count > tx.outputAddresses.count) {
            [self removeObjectFromOutputsAtIndex:outputs.count - 1];
        }

        idx = 0;
        
        for (BTCTxOutputEntity *e in outputs) {
            [e setAttributesFromTx:tx outputIndex:idx++];
        }
        
        self.lockTime = tx.lockTime;
    }];
    
    return self;
}

- (BTCTransaction *)transaction
{
    BTCTransaction *tx = [BTCTransaction new];
    
    [self.managedObjectContext performBlockAndWait:^{
        NSData *txHash = self.txHash;
        
        if (txHash.length == sizeof(UInt256)) tx.txHash = *(const UInt256 *)txHash.bytes;
        tx.lockTime = self.lockTime;
        tx.blockHeight = self.blockHeight;
        tx.timestamp = self.timestamp;
    
        for (BTCTxInputEntity *e in self.inputs) {
            txHash = e.txHash;
            if (txHash.length != sizeof(UInt256)) continue;
            [tx addInputHash:*(const UInt256 *)txHash.bytes index:e.n script:nil signature:e.signature
             sequence:e.sequence];
        }
        
        for (BTCTxOutputEntity *e in self.outputs) {
            [tx addOutputScript:e.script amount:e.value];
        }
    }];
    
    return tx;
}

- (void)deleteObject
{
    for (BTCTxInputEntity *e in self.inputs) { // mark inputs as unspent
        [[BTCTxOutputEntity objectsMatching:@"txHash == %@ && n == %d", e.txHash, e.n].lastObject setSpent:NO];
    }

    [super deleteObject];
}

@end
