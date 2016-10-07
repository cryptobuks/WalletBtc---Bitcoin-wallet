//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

typedef union _UInt256 UInt256;
typedef union _UInt160 UInt160;

typedef struct {
    uint8_t p[33];
} BTCECPoint;

// adds 256bit big endian ints a and b (mod secp256k1 order) and stores the result in a
// returns true on success
int BTCSecp256k1ModAdd(UInt256 * _Nonnull a, const UInt256 * _Nonnull b);

// multiplies 256bit big endian ints a and b (mod secp256k1 order) and stores the result in a
// returns true on success
int BTCSecp256k1ModMul(UInt256 * _Nonnull a, const UInt256 * _Nonnull b);

// multiplies secp256k1 generator by 256bit big endian int i and stores the result in p
// returns true on success
int BTCSecp256k1PointGen(BTCECPoint * _Nonnull p, const UInt256 * _Nonnull i);

// multiplies secp256k1 generator by 256bit big endian int i and adds the result to ec-point p
// returns true on success
int BTCSecp256k1PointAdd(BTCECPoint * _Nonnull p, const UInt256 * _Nonnull i);

// multiplies secp256k1 ec-point p by 256bit big endian int i and stores the result in p
// returns true on success
int BTCSecp256k1PointMul(BTCECPoint * _Nonnull p, const UInt256 * _Nonnull i);

@interface BTCKey : NSObject

@property (nullable, nonatomic, readonly) NSString *privateKey;
@property (nullable, nonatomic, readonly) NSData *publicKey;
@property (nullable, nonatomic, readonly) NSString *address;
@property (nonatomic, readonly) UInt160 hash160;

+ (nullable instancetype)keyWithPrivateKey:(nonnull NSString *)privateKey;
+ (nullable instancetype)keyWithSecret:(UInt256)secret compressed:(BOOL)compressed;
+ (nullable instancetype)keyWithPublicKey:(nonnull NSData *)publicKey;
+ (nullable instancetype)keyRecoveredFromCompactSig:(nonnull NSData *)compactSig andMessageDigest:(UInt256)md;

- (nullable instancetype)initWithPrivateKey:(nonnull NSString *)privateKey;
- (nullable instancetype)initWithSecret:(UInt256)secret compressed:(BOOL)compressed;
- (nullable instancetype)initWithPublicKey:(nonnull NSData *)publicKey;
- (nullable instancetype)initWithCompactSig:(nonnull NSData *)compactSig andMessageDigest:(UInt256)md;

- (nullable NSData *)sign:(UInt256)md;
- (BOOL)verify:(UInt256)md signature:(nonnull NSData *)sig;

// Pieter Wuille's compact signature encoding used for bitcoin message signing
// to verify a compact signature, recover a public key from the signature and verify that it matches the signer's pubkey
- (nullable NSData *)compactSign:(UInt256)md;

@end