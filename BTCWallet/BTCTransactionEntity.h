//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BTCTxInputEntity;
@class BTCTxOutputEntity;
@class BTCTransaction;

@interface BTCTransactionEntity : NSManagedObject

@property (nonatomic, retain) NSData *txHash;
@property (nonatomic) int32_t blockHeight;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic, retain) NSOrderedSet *inputs;
@property (nonatomic, retain) NSOrderedSet *outputs;
@property (nonatomic) int32_t lockTime;

- (instancetype)setAttributesFromTx:(BTCTransaction *)tx;
- (BTCTransaction *)transaction;

@end

// These generated accessors are all broken because NSOrderedSet is not a subclass of NSSet.
// This known core data bug has remained unaddressed for over three years: http://openradar.appspot.com/10114310
// Per core data release notes, use [NSObject<NSKeyValueCoding> mutableOrderedSetValueForKey:] instead.
@interface BTCTransactionEntity (CoreDataGeneratedAccessors)

- (void)insertObject:(BTCTxInputEntity *)value inInputsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromInputsAtIndex:(NSUInteger)idx;
- (void)insertInputs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeInputsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInInputsAtIndex:(NSUInteger)idx withObject:(BTCTxInputEntity *)value;
- (void)replaceInputsAtIndexes:(NSIndexSet *)indexes withInputs:(NSArray *)values;
- (void)addInputsObject:(BTCTxInputEntity *)value;
- (void)removeInputsObject:(BTCTxInputEntity *)value;
- (void)addInputs:(NSOrderedSet *)values;
- (void)removeInputs:(NSOrderedSet *)values;
- (void)insertObject:(BTCTxOutputEntity *)value inOutputsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromOutputsAtIndex:(NSUInteger)idx;
- (void)insertOutputs:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeOutputsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInOutputsAtIndex:(NSUInteger)idx withObject:(BTCTxOutputEntity *)value;
- (void)replaceOutputsAtIndexes:(NSIndexSet *)indexes withOutputs:(NSArray *)values;
- (void)addOutputsObject:(BTCTxOutputEntity *)value;
- (void)removeOutputsObject:(BTCTxOutputEntity *)value;
- (void)addOutputs:(NSOrderedSet *)values;
- (void)removeOutputs:(NSOrderedSet *)values;
@end
