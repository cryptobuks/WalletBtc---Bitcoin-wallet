//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import "BTCKeySequence.h"

#define BIP32_HARD 0x80000000

// BIP32 is a scheme for deriving chains of addresses from a seed value
// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki

@interface BTCBIP32Sequence : NSObject<BTCKeySequence>

- (NSData *)masterPublicKeyFromSeed:(NSData *)seed;
- (NSData *)publicKey:(uint32_t)n internal:(BOOL)internal masterPublicKey:(NSData *)masterPublicKey;
- (NSString *)privateKey:(uint32_t)n internal:(BOOL)internal fromSeed:(NSData *)seed;
- (NSArray *)privateKeys:(NSArray *)n internal:(BOOL)internal fromSeed:(NSData *)seed;

// key used for authenticated API calls, i.e. bitauth: https://github.com/bitpay/bitauth
- (NSString *)authPrivateKeyFromSeed:(NSData *)seed;

// key used for BitID: https://github.com/bitid/bitid/blob/master/BIP_draft.md
- (NSString *)bitIdPrivateKey:(uint32_t)n forURI:(NSString *)uri fromSeed:(NSData *)seed;

- (NSString *)serializedPrivateMasterFromSeed:(NSData *)seed;
- (NSString *)serializedMasterPublicKey:(NSData *)masterPublicKey;

@end
