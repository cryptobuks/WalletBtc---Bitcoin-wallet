//
//  Created by Admin on 9/8/16.
//

#import "BTCTxMetadataEntity.h"
#import "BTCTransaction.h"
#import "NSManagedObject+Sugar.h"
#import "NSData+Bitcoin.h"
#import "NSMutableData+Bitcoin.h"

@implementation BTCTxMetadataEntity

@dynamic blob;
@dynamic txHash;
@dynamic type;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx
{
    NSMutableData *data = [NSMutableData dataWithData:tx.data];

    [data appendUInt32:tx.blockHeight];
    [data appendUInt32:tx.timestamp];

    [self.managedObjectContext performBlockAndWait:^{
        self.blob = data;
        self.type = TX_MDTYPE_MSG;
        self.txHash = [NSData dataWithBytes:tx.txHash.u8 length:sizeof(UInt256)];
    }];
    
    return self;
}

- (BTCTransaction *)transaction
{
    __block BTCTransaction *tx = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSData *data = self.blob;
    
        if (data.length > sizeof(uint32_t)*2) {
            tx = [BTCTransaction transactionWithMessage:data];
            tx.blockHeight = [data UInt32AtOffset:data.length - sizeof(uint32_t)*2];
            tx.timestamp = [data UInt32AtOffset:data.length - sizeof(uint32_t)];
        }
    }];
    
    return tx;
}

@end
