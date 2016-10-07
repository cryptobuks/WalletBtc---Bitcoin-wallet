//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BTCWallet.h"
#import "BTCMnemonic.h"

#define BTC          @"\xC9\x83"     // capital B with stroke (utf-8)
#define BITS         @"\xC6\x80"     // lowercase b with stroke (utf-8)
#define NARROW_NBSP  @"\xE2\x80\xAF" // narrow no-break space (utf-8)
#define LDQUOTE      @"\xE2\x80\x9C" // left double quote (utf-8)
#define RDQUOTE      @"\xE2\x80\x9D" // right double quote (utf-8)
#define DISPLAY_NAME [NSString stringWithFormat:LDQUOTE @"%@" RDQUOTE,\
                      NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"]]

#define WALLET_NEEDS_BACKUP_KEY                @"WALLET_NEEDS_BACKUP"
FOUNDATION_EXPORT NSString* _Nonnull const BTCWalletManagerSeedChangedNotification;

@protocol BTCMnemonic;

@interface BTCWalletManager : NSObject<UIAlertViewDelegate, UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, readonly) BTCWallet * _Nullable wallet;
@property (nonatomic, readonly) BOOL noWallet; // true if keychain is available and we know that no wallet exists on it
@property (nonatomic, readonly) BOOL watchOnly; // true if this is a "watch only" wallet with no signing ability
@property (nonatomic, strong) id<BTCKeySequence> _Nullable sequence;
@property (nonatomic, strong) id<BTCMnemonic> _Nullable mnemonic;
@property (nonatomic, readonly) NSData * _Nullable masterPublicKey;//master public key used to generate wallet addresses
@property (nonatomic, copy) NSString * _Nullable seedPhrase; // requesting seedPhrase will trigger authentication
@property (nonatomic, readonly) NSTimeInterval seedCreationTime; // interval since refrence date, 00:00:00 01/01/01 GMT
@property (nonatomic, readonly) NSTimeInterval secureTime; // last known time from an ssl server connection
@property (nonatomic, assign) uint64_t spendingLimit; // amount that can be spent using touch id without pin entry
@property (nonatomic, readonly) NSString * _Nullable authPrivateKey; // private key for signing authenticated api calls
@property (nonatomic, copy) NSDictionary * _Nullable userAccount; // client api user id and auth token
@property (nonatomic, readonly, getter=isTouchIdEnabled) BOOL touchIdEnabled; // true if touch id is enabled
@property (nonatomic, readonly, getter=isPasscodeEnabled) BOOL passcodeEnabled; // true if device passcode is enabled
@property (nonatomic, assign) BOOL didAuthenticate; // true if the user authenticated after this was last set to false
@property (nonatomic, readonly) NSNumberFormatter * _Nullable format; // bitcoin currency formatter
@property (nonatomic, readonly) NSNumberFormatter * _Nullable localFormat; // local currency formatter
@property (nonatomic, copy) NSString * _Nullable localCurrencyCode; // local currency ISO code
@property (nonatomic, readonly) double localCurrencyPrice; // exchange rate in local currency units per bitcoin
@property (nonatomic, readonly) NSArray * _Nullable currencyCodes; // list of supported local currency codes
@property (nonatomic, readonly) NSArray * _Nullable currencyNames; // names for local currency codes

@property (nonatomic, strong) NSString *pin;

+ (instancetype _Nullable)sharedInstance;

- (NSString * _Nullable)generateRandomSeed; // generates a random seed, saves to keychain and returns the seedPhrase
- (NSData * _Nullable)seedWithPrompt:(NSString * _Nullable)authprompt forAmount:(uint64_t)amount;//auth user,return seed
- (NSString * _Nullable)seedPhraseWithPrompt:(NSString * _Nullable)authprompt; // authenticates user, returns seedPhrase
- (BOOL)authenticateWithPrompt:(NSString * _Nullable)authprompt andTouchId:(BOOL)touchId; // prompt user to authenticate
- (BOOL)setPin; // prompts the user to set or change wallet pin and returns true if the pin was successfully set

// queries and calls the completion block with unspent outputs for the given address
- (void)utxosForAddresses:(NSArray * _Nonnull)address
completion:(void (^ _Nonnull)(NSArray * _Nonnull utxos, NSArray * _Nonnull amounts, NSArray * _Nonnull scripts,
                              NSError * _Null_unspecified error))completion;

// given a private key, queries for unspent outputs and calls the completion block with a signed
// transaction that will sweep the balance into wallet (doesn't publish the tx)
- (void)sweepPrivateKey:(NSString * _Nonnull)privKey withFee:(BOOL)fee
completion:(void (^ _Nonnull)(BTCTransaction * _Nonnull tx, uint64_t fee, NSError * _Null_unspecified error))completion;

- (int64_t)amountForString:(NSString * _Nullable)string;
- (NSString * _Nonnull)stringForAmount:(int64_t)amount;
- (int64_t)amountForLocalCurrencyString:(NSString * _Nonnull)string;
- (NSString * _Nonnull)localCurrencyStringForAmount:(int64_t)amount;
- (void)updateFeePerKb;

@end
