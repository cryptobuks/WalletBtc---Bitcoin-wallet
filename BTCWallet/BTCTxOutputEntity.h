//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BTCTransactionEntity, BTCTransaction;

@interface BTCTxOutputEntity : NSManagedObject

@property (nonatomic, retain) NSData *txHash;
@property (nonatomic) int32_t n;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSData *script;
@property (nonatomic) int64_t value;
@property (nonatomic) BOOL spent;
@property (nonatomic, retain) BTCTransactionEntity *transaction;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx outputIndex:(NSUInteger)index;

@end
