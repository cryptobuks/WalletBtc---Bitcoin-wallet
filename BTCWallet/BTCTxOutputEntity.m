//
//  Created by Admin on 9/8/16.
//

#import "BTCTxOutputEntity.h"
#import "BTCTransactionEntity.h"
#import "BTCTransaction.h"
#import "NSData+Bitcoin.h"
#import "NSManagedObject+Sugar.h"

@implementation BTCTxOutputEntity

@dynamic txHash;
@dynamic n;
@dynamic address;
@dynamic script;
@dynamic value;
@dynamic spent;
@dynamic transaction;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx outputIndex:(NSUInteger)index
{
    [self.managedObjectContext performBlockAndWait:^{
        UInt256 txHash = tx.txHash;
    
        self.txHash = [NSData dataWithBytes:&txHash length:sizeof(txHash)];
        self.n = (int32_t)index;
        self.address = (tx.outputAddresses[index] == [NSNull null]) ? nil : tx.outputAddresses[index];
        self.script = tx.outputScripts[index];
        self.value = [tx.outputAmounts[index] longLongValue];
    }];
    
    return self;
}

@end
