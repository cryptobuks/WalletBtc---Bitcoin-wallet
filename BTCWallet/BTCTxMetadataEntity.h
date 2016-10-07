//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define TX_MDTYPE_MSG 0x01

@class BTCTransaction;

@interface BTCTxMetadataEntity : NSManagedObject

@property (nonatomic, retain) NSData *blob;
@property (nonatomic, retain) NSData *txHash;
@property (nonatomic) int32_t type;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx;
- (BTCTransaction *)transaction;

@end
