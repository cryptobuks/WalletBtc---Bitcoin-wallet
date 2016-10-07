//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BTCTransactionEntity, BTCTransaction;

@interface BTCTxInputEntity : NSManagedObject

@property (nonatomic, retain) NSData *txHash;
@property (nonatomic) int32_t n;
@property (nonatomic, retain) NSData *signature;
@property (nonatomic) int32_t sequence;
@property (nonatomic, retain) BTCTransactionEntity *transaction;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx inputIndex:(NSUInteger)index;

@end
