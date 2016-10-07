//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

#define SEQUENCE_GAP_LIMIT_EXTERNAL 10
#define SEQUENCE_GAP_LIMIT_INTERNAL 5

@protocol BTCKeySequence<NSObject>
@required

- (NSData *)masterPublicKeyFromSeed:(NSData *)seed;
- (NSData *)publicKey:(uint32_t)n internal:(BOOL)internal masterPublicKey:(NSData *)masterPublicKey;
- (NSString *)privateKey:(uint32_t)n internal:(BOOL)internal fromSeed:(NSData *)seed;
- (NSArray *)privateKeys:(NSArray *)n internal:(BOOL)internal fromSeed:(NSData *)seed;

@end
