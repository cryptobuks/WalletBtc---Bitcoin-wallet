//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BTCMerkleBlock;

@interface BTCMerkleBlockEntity : NSManagedObject

@property (nonatomic, retain) NSData *blockHash;
@property (nonatomic) int32_t height;
@property (nonatomic) int32_t version;
@property (nonatomic, retain) NSData *prevBlock;
@property (nonatomic, retain) NSData *merkleRoot;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) int32_t target;
@property (nonatomic) int32_t nonce;
@property (nonatomic) int32_t totalTransactions;
@property (nonatomic, retain) NSData *hashes;
@property (nonatomic, retain) NSData *flags;

- (instancetype)setAttributesFromBlock:(BTCMerkleBlock *)block;
- (BTCMerkleBlock *)merkleBlock;

@end
