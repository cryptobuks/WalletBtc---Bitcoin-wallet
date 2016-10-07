//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BTCTransaction.h"
#import "BTCKeySequence.h"
#import "NSData+Bitcoin.h"

FOUNDATION_EXPORT NSString* _Nonnull const BTCWalletBalanceChangedNotification;

#define SATOSHIS           100000000LL
#define MAX_MONEY          (21000000LL*SATOSHIS)
#define DEFAULT_FEE_PER_KB ((5000ULL*1000 + TX_INPUT_SIZE - 1)/TX_INPUT_SIZE) // bitcoind 0.11 min relay fee on one txin
#define MIN_FEE_PER_KB     ((TX_FEE_PER_KB*1000 + 190)/191) // minimum relay fee on a 191byte tx
#define MAX_FEE_PER_KB     ((100100ULL*1000 + 190)/191) // slightly higher than a 1000bit fee on a 191byte tx

typedef struct _BRUTXO {
    UInt256 hash;
    unsigned long n; // use unsigned long instead of uint32_t to avoid trailing struct padding (for NSValue comparisons)
} BTCUTXO;

#define brutxo_obj(o) [NSValue value:&(o) withObjCType:@encode(BTCUTXO)]
#define brutxo_data(o) [NSData dataWithBytes:&((struct { uint32_t u[256/32 + 1]; }) {\
    o.hash.u32[0], o.hash.u32[1], o.hash.u32[2], o.hash.u32[3],\
    o.hash.u32[4], o.hash.u32[5], o.hash.u32[6], o.hash.u32[7],\
    CFSwapInt32HostToLittle((uint32_t)o.n) }) length:sizeof(UInt256) + sizeof(uint32_t)]

@class BTCTransaction;
@protocol BTCKeySequence;

@interface BTCWallet : NSObject

// current wallet balance excluding transactions known to be invalid
@property (nonatomic, readonly) uint64_t balance;

// returns the first unused external address
@property (nonatomic, readonly) NSString * _Nullable receiveAddress;

// returns the first unused internal address
@property (nonatomic, readonly) NSString * _Nullable changeAddress;

// all previously generated external addresses
@property (nonatomic, readonly) NSSet * _Nonnull allReceiveAddresses;

// all previously generated internal addresses
@property (nonatomic, readonly) NSSet * _Nonnull allChangeAddresses;

// NSValue objects containing UTXO structs
@property (nonatomic, readonly) NSArray * _Nonnull unspentOutputs;

// latest 100 transactions sorted by date, most recent first
@property (nonatomic, readonly) NSArray * _Nonnull recentTransactions;

// all wallet transactions sorted by date, most recent first
@property (nonatomic, readonly) NSArray * _Nonnull allTransactions;

// the total amount spent from the wallet (excluding change)
@property (nonatomic, readonly) uint64_t totalSent;

// the total amount received by the wallet (excluding change)
@property (nonatomic, readonly) uint64_t totalReceived;

// fee per kb of transaction size to use when including tx fee
@property (nonatomic, assign) uint64_t feePerKb;

// outputs below this amount are uneconomical due to fees
@property (nonatomic, readonly) uint64_t minOutputAmount;

// largest amount that can be sent from the wallet after fees
@property (nonatomic, readonly) uint64_t maxOutputAmount;

- (instancetype _Nullable)initWithContext:(NSManagedObjectContext * _Nullable)context
                                 sequence:(id<BTCKeySequence> _Nonnull)sequence
                          masterPublicKey:(NSData * _Nullable)masterPublicKey
                            seed:(NSData * _Nullable(^ _Nonnull)(NSString * _Nullable authprompt, uint64_t amount))seed;

// true if the address is controlled by the wallet
- (BOOL)containsAddress:(NSString * _Nonnull)address;

// true if the address was previously used as an input or output in any wallet transaction
- (BOOL)addressIsUsed:(NSString * _Nonnull)address;

// Wallets are composed of chains of addresses. Each chain is traversed until a gap of a certain number of addresses is
// found that haven't been used in any transactions. This method returns an array of <gapLimit> unused addresses
// following the last used address in the chain. The internal chain is used for change addresses and the external chain
// for receive addresses.
- (NSArray * _Nullable)addressesWithGapLimit:(NSUInteger)gapLimit internal:(BOOL)internal;

// returns an unsigned transaction that sends the specified amount from the wallet to the given address
- (BTCTransaction * _Nullable)transactionFor:(uint64_t)amount to:(NSString * _Nonnull)address withFee:(BOOL)fee;

// returns an unsigned transaction that sends the specified amounts from the wallet to the specified output scripts
- (BTCTransaction * _Nullable)transactionForAmounts:(NSArray * _Nonnull)amounts
                                   toOutputScripts:(NSArray * _Nonnull)scripts withFee:(BOOL)fee;

// sign any inputs in the given transaction that can be signed using private keys from the wallet
- (BOOL)signTransaction:(BTCTransaction * _Nonnull)transaction withPrompt:(NSString * _Nonnull)authprompt;

// true if the given transaction is associated with the wallet (even if it hasn't been registered), false otherwise
- (BOOL)containsTransaction:(BTCTransaction * _Nonnull)transaction;

// adds a transaction to the wallet, or returns false if it isn't associated with the wallet
- (BOOL)registerTransaction:(BTCTransaction * _Nonnull)transaction;

// removes a transaction from the wallet along with any transactions that depend on its outputs
- (void)removeTransaction:(UInt256)txHash;

// returns the transaction with the given hash if it's been registered in the wallet (might also return non-registered)
- (BTCTransaction * _Nullable)transactionForHash:(UInt256)txHash;

// true if no previous wallet transaction spends any of the given transaction's inputs, and no inputs are invalid
- (BOOL)transactionIsValid:(BTCTransaction * _Nonnull)transaction;

// true if transaction cannot be immediately spent (i.e. if it or an input tx can be replaced-by-fee, via BIP125)
- (BOOL)transactionIsPending:(BTCTransaction * _Nonnull)transaction;

// true if tx is considered 0-conf safe (valid and not pending, timestamp is greater than 0, and no unverified inputs)
- (BOOL)transactionIsVerified:(BTCTransaction * _Nonnull)transaction;

// set the block heights and timestamps for the given transactions, use a height of TX_UNCONFIRMED and timestamp of 0 to
// indicate a transaction and it's dependents should remain marked as unverified (not 0-conf safe)
- (void)setBlockHeight:(int32_t)height andTimestamp:(NSTimeInterval)timestamp forTxHashes:(NSArray * _Nonnull)txHashes;

// returns the amount received by the wallet from the transaction (total outputs to change and/or receive addresses)
- (uint64_t)amountReceivedFromTransaction:(BTCTransaction * _Nonnull)transaction;

// retuns the amount sent from the wallet by the trasaction (total wallet outputs consumed, change and fee included)
- (uint64_t)amountSentByTransaction:(BTCTransaction * _Nonnull)transaction;

// returns the fee for the given transaction if all its inputs are from wallet transactions, UINT64_MAX otherwise
- (uint64_t)feeForTransaction:(BTCTransaction * _Nonnull)transaction;

// historical wallet balance after the given transaction, or current balance if transaction is not registered in wallet
- (uint64_t)balanceAfterTransaction:(BTCTransaction * _Nonnull)transaction;

// returns the block height after which the transaction is likely to be processed without including a fee
- (uint32_t)blockHeightUntilFree:(BTCTransaction * _Nonnull)transaction;

// fee that will be added for a transaction of the given size in bytes
- (uint64_t)feeForTxSize:(NSUInteger)size;

@end
