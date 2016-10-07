//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BTCPeer;

@interface BTCPeerEntity : NSManagedObject

@property (nonatomic) int32_t address;
@property (nonatomic) NSTimeInterval timestamp;
@property (nonatomic) int16_t port;
@property (nonatomic) int64_t services;
@property (nonatomic) int16_t misbehavin;

- (instancetype)setAttributesFromPeer:(BTCPeer *)peer;
- (BTCPeer *)peer;

@end
