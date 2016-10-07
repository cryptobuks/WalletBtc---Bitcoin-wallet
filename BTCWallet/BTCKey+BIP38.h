//
//  Created by Admin on 9/8/16.
//

#import "BTCKey.h"

// BIP38 is a method for encrypting private keys with a passphrase
// https://github.com/bitcoin/bips/blob/master/bip-0038.mediawiki

@interface BTCKey (BIP38)

// decrypts a BIP38 key using the given passphrase or retuns nil if passphrase is incorrect
+ (instancetype)keyWithBIP38Key:(NSString *)key andPassphrase:(NSString *)passphrase;

// generates an "intermediate code" for an EC multiply mode key, salt should be 64bits of random data
+ (NSString *)BIP38IntermediateCodeWithSalt:(uint64_t)salt andPassphrase:(NSString *)passphrase;

// generates an "intermediate code" for an EC multiply mode key with a lot and sequence number, lot must be less than
// 1048576, sequence must be less than 4096, and salt should be 32bits of random data
+ (NSString *)BIP38IntermediateCodeWithLot:(uint32_t)lot sequence:(uint16_t)sequence salt:(uint32_t)salt
passphrase:(NSString *)passphrase;

// generates a BIP38 key from an "intermediate code" and 24 bytes of cryptographically random data (seedb),
+ (NSString *)BIP38KeyWithIntermediateCode:(NSString *)code seedb:(NSData *)seedb;

- (instancetype)initWithBIP38Key:(NSString *)key andPassphrase:(NSString *)passphrase;

// encrypts receiver with passphrase and returns BIP38 key
- (NSString *)BIP38KeyWithPassphrase:(NSString *)passphrase;

@end
