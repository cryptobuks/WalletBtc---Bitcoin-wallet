//
//  Created by Admin on 9/8/16.
//

#import "BTCPhoneWCSessionManager.h"
#import "BTCAppleWatchSharedConstants.h"
#import "BTCAppleWatchTransactionData.h"
#import "BTCPaymentRequest.h"
#import "BTCPeerManager.h"
#import "BTCTransaction+Utils.h"
#import "BTCWalletManager.h"
#import "UIImage+Utils.h"
#import <WatchConnectivity/WatchConnectivity.h>

@interface BTCPhoneWCSessionManager () <WCSessionDelegate>

@property WCSession *session;
@property id balanceObserver, syncFinishedObserver, syncFailedObserver;

@end

@implementation BTCPhoneWCSessionManager

+ (instancetype)sharedInstance
{
    static BTCPhoneWCSessionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        // prevent pre watchOS iOS access the feature
        if ([WCSession class] && [WCSession isSupported]) {
            self.session = [WCSession defaultSession];
            self.session.delegate = self;
            [self.session activateSession];
            [self sendApplicationContext];
            
            self.balanceObserver =
                [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletBalanceChangedNotification object:nil
                queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                    if ([BTCPeerManager sharedInstance].syncProgress == 1.0) [self sendApplicationContext];
                }];

            self.syncFinishedObserver =
                [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFinishedNotification
                object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                    [self sendApplicationContext];
                }];

            self.syncFailedObserver =
                [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFailedNotification object:nil
                queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                    [self sendApplicationContext];
                }];
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.syncFinishedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFinishedObserver];
    if (self.syncFailedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFailedObserver];
}

- (BOOL)reachable
{
    return self.session.reachable;
}

- (void)notifyTransactionString:(NSString *)notification
{
    if (self.reachable) {
        NSDictionary *msg = @{
            AW_PHONE_NOTIFICATION_KEY: notification,
            AW_PHONE_NOTIFICATION_TYPE_KEY: @(AWPhoneNotificationTypeTxReceive)
        };

        [self.session sendMessage:msg
            replyHandler:^(NSDictionary<NSString *, id> *_Nonnull replyMessage) {
                NSLog(@"received response from balance update notification to watch: %@", replyMessage);
            }
            errorHandler:^(NSError *_Nonnull error) {
                NSLog(@"got an error sending a balance update notification to watch");
            }];
        
        NSLog(@"sent a balance update notification to watch: %@", msg);
    }
}

#pragma mark - WKSession delegate

- (void)session:(WCSession *)session
    didReceiveMessage:(NSDictionary<NSString *, id> *)message
         replyHandler:(void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
{
    NSLog(@"BTCPhoneWCSessionManager didReceiveMessage %@", message);

    if ([message[AW_SESSION_REQUEST_TYPE] integerValue] == AWSessionRquestTypeFetchData) {
        switch ([message[AW_SESSION_REQUEST_DATA_TYPE_KEY] integerValue]) {
        case AWSessionRquestDataTypeApplicationContextData:
            [self handleApplicationContextDataRequest:message replyHandler:replyHandler];
            // sync with peer whenever there is a request coming, so we can update watch side.
            [(id<UIApplicationDelegate>)[UIApplication sharedApplication].delegate
                                      application:[UIApplication sharedApplication]
                performFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
                    NSLog(@"watch triggered background fetch completed with result %lu", (unsigned long)result);
                }];
            break;
            
        case AWSessionRquestDataTypeQRCodeBits: {
            BTCWalletManager *manager = [BTCWalletManager sharedInstance];
            BTCPaymentRequest *req = [BTCPaymentRequest requestWithString:manager.wallet.receiveAddress];

            req.amount = [message[AW_SESSION_QR_CODE_BITS_KEY] integerValue];
            NSLog(@"watch requested a qr code amount %lld", req.amount);

            UIImage *img = [[UIImage imageWithQRCodeData:req.data color:[CIColor colorWithRed:0.0 green:0.0 blue:0.0]]
                            resize:CGSizeMake(150, 150) withInterpolationQuality:kCGInterpolationNone];
            NSData *dat = UIImagePNGRepresentation(img);

            replyHandler(@{AW_QR_CODE_BITS_KEY: dat});
            break;
        }
        
        default: replyHandler(@{});
        }
    }
    else {
        replyHandler(@{});
    }
}

#pragma mark - request handlers

- (void)handleApplicationContextDataRequest:(NSDictionary *)request
                               replyHandler:(void (^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
{
    NSDictionary *replay =
        @{AW_SESSION_RESPONSE_KEY: [NSKeyedArchiver archivedDataWithRootObject:[self applicationContextData]]};

    replyHandler(replay);
}

- (void)sendApplicationContext
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BTCAppleWatchData *appleWatchData = [self applicationContextData];

        [self.session updateApplicationContext:@{
            AW_APPLICATION_CONTEXT_KEY: [NSKeyedArchiver archivedDataWithRootObject:appleWatchData]
        }
                                         error:nil];
    });
}

- (BTCAppleWatchData *)applicationContextData
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSArray *transactions = manager.wallet.recentTransactions;
    UIImage *qrCodeImage = self.qrCode;
    BTCAppleWatchData *appleWatchData = [[BTCAppleWatchData alloc] init];
    
    appleWatchData.balance = [manager stringForAmount:manager.wallet.balance];
    appleWatchData.balanceInLocalCurrency = [manager localCurrencyStringForAmount:manager.wallet.balance];
#if SNAPSHOT
    appleWatchData.balance = [manager stringForAmount:42980000],
    appleWatchData.balanceInLocalCurrency = [manager localCurrencyStringForAmount:42980000];
#endif
    appleWatchData.receiveMoneyAddress = manager.wallet.receiveAddress;
    appleWatchData.transactions = [[self recentTransactionListFromTransactions:transactions] copy];
    appleWatchData.receiveMoneyQRCodeImage = qrCodeImage;
    appleWatchData.hasWallet = ! manager.noWallet;
    
    if (transactions.count > 0) {
        appleWatchData.lastestTransction = [self lastTransactionStringFromTransaction:transactions[0]];
    }
    
    return appleWatchData;
}

- (NSString *)lastTransactionStringFromTransaction:(BTCTransaction *)transaction
{
    if (transaction) {
        NSString *timeDescriptionString = [self timeDescriptionStringFrom:transaction.transactionDate];
        NSString *transactionTypeString;
        
        if (timeDescriptionString == nil) {
            timeDescriptionString = transaction.dateText;
        }

        switch (transaction.transactionType) {
        case BTCAWTransactionTypeSent: transactionTypeString = @"sent"; break;
        case BTCAWTransactionTypeReceive: transactionTypeString = @"received"; break;
        case BTCAWTransactionTypeMove: transactionTypeString = @"moved"; break;
        case BTCAWTransactionTypeInvalid: transactionTypeString = @"invalid transaction"; break;
        }

        return [NSString
            stringWithFormat:@"%@ %@ %@ , %@", transactionTypeString,
                             [transaction.amountText stringByReplacingOccurrencesOfString:@"-" withString:@""],
                             (transaction.localCurrencyTextForAmount.length > 2)
                                 ? transaction.localCurrencyTextForAmount
                                 : @"",
                             timeDescriptionString];
    }
    
    return @"no transaction";
}

- (NSString *)timeDescriptionStringFrom:(NSDate *)date
{
    if (date) {
        NSDate *now = [NSDate date];
        NSTimeInterval secondsSinceTransaction = [now timeIntervalSinceDate:date];
        
        if (secondsSinceTransaction < 60) {
            return @"just now";
        }
        else if (secondsSinceTransaction / 60 < 60) {
            return [NSString stringWithFormat:@"%@ minutes ago", @((NSInteger)(secondsSinceTransaction / 60))];
        }
        else if (secondsSinceTransaction / 60 / 60 < 24) {
            return [NSString stringWithFormat:@"%@ hours ago", @((NSInteger)(secondsSinceTransaction / 60 / 60))];
        }
    }
    
    return nil;
}

- (UIImage *)qrCode
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSData *req = [BTCPaymentRequest requestWithString:manager.wallet.receiveAddress].data;
    
    return [[UIImage imageWithQRCodeData:req color:[CIColor colorWithRed:0.0 green:0.0 blue:0.0]]
            resize:CGSizeMake(150, 150) withInterpolationQuality:kCGInterpolationNone];
}

#pragma mark - data helper methods

- (NSArray *)recentTransactionListFromTransactions:(NSArray *)transactions
{
    NSMutableArray *transactionListData = [[NSMutableArray alloc] init];
    
    for (BTCTransaction *transaction in transactions) {
        [transactionListData addObject:[BTCAppleWatchTransactionData appleWatchTransactionDataFrom:transaction]];
    }

#if SNAPSHOT
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    [transactionListData removeAllObjects];

    for (int i = 0; i < 6; i++) {
        BTCTransaction *tx = [BTCTransaction new];
        BTCAppleWatchTransactionData *txData = [BTCAppleWatchTransactionData new];
        int64_t amount =
            [@[@(-1010000), @(-10010000), @(54000000), @(-82990000), @(-10010000), @(93000000)][i] longLongValue];

        txData.type = (amount >= 0) ? BTCAWTransactionTypeReceive : BTCAWTransactionTypeSent;
        txData.amountText = [manager stringForAmount:amount];
        txData.amountTextInLocalCurrency = [manager localCurrencyStringForAmount:amount];
        tx.timestamp = [NSDate timeIntervalSinceReferenceDate] - i * 100000;
        txData.dateText = tx.dateText;
        [transactionListData addObject:txData];
    }
#endif

    return transactionListData;
}

@end
