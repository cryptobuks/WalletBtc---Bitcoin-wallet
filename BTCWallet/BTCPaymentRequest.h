//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

@class BTCPaymentProtocolRequest, BTCPaymentProtocolPayment, BTCPaymentProtocolACK;

// BIP21 bitcoin payment request URI https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki
@interface BTCPaymentRequest : NSObject

@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, strong) NSString *paymentAddress;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) uint64_t amount;
@property (nonatomic, strong) NSString *r; // BIP72 URI: https://github.com/bitcoin/bips/blob/master/bip-0072.mediawiki
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly) BTCPaymentProtocolRequest *protocolRequest; // receiver converted to BIP70 request object

+ (instancetype)requestWithString:(NSString *)string;
+ (instancetype)requestWithData:(NSData *)data;
+ (instancetype)requestWithURL:(NSURL *)url;

- (instancetype)initWithString:(NSString *)string;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithURL:(NSURL *)url;

// fetches a BIP70 request over HTTP and calls completion block
// https://github.com/bitcoin/bips/blob/master/bip-0070.mediawiki
+ (void)fetch:(NSString *)url timeout:(NSTimeInterval)timeout
completion:(void (^)(BTCPaymentProtocolRequest *req, NSError *error))completion;

// posts a BIP70 payment object to the specified URL
+ (void)postPayment:(BTCPaymentProtocolPayment *)payment to:(NSString *)paymentURL
timeout:(NSTimeInterval)timeout completion:(void (^)(BTCPaymentProtocolACK *ack, NSError *error))completion;

@end
