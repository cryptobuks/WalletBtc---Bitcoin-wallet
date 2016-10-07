//
//  Created by Admin on 9/8/16.
//

#import "BTCTransaction+Utils.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"

@implementation BTCTransaction (Utils)

- (BTCTransactionType)transactionType
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    uint64_t received = [manager.wallet amountReceivedFromTransaction:self],
             sent = [manager.wallet amountSentByTransaction:self];
    uint32_t blockHeight = self.blockHeight;
    uint32_t confirms = ([self lastBlockHeight] > blockHeight) ? 0 : (blockHeight - [self lastBlockHeight]) + 1;

    if (confirms == 0 && ! [manager.wallet transactionIsValid:self]) {
        return BTCTransactionTypeInvalid;
    }
    
    if (sent > 0 && received == sent) {
        return BTCTransactionTypeMove;
    }
    else if (sent > 0) {
        return BTCTransactionTypeSent;
    }
    else return BTCTransactionTypeReceive;
}

- (NSString*)localCurrencyTextForAmount
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    uint64_t received = [manager.wallet amountReceivedFromTransaction:self],

    sent = [manager.wallet amountSentByTransaction:self];

    if (sent > 0 && received == sent) {
        return [NSString stringWithFormat:@"(%@)", [manager localCurrencyStringForAmount:sent]];
    }
    else if (sent > 0) {
        return [NSString stringWithFormat:@"(%@)", [manager localCurrencyStringForAmount:received - sent]];
    }
    else return [NSString stringWithFormat:@"(%@)", [manager localCurrencyStringForAmount:received]];
}

- (NSString*)amountText
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    uint64_t received = [manager.wallet amountReceivedFromTransaction:self],

    sent = [manager.wallet amountSentByTransaction:self];

    if (sent > 0 && received == sent) {
        return [manager stringForAmount:sent];
    }
    else if (sent > 0) {
        return [manager stringForAmount:received - sent];
    }
    else return [manager stringForAmount:received];
}

- (uint32_t)lastBlockHeight
{
    static uint32_t height = 0;
    uint32_t h = [BTCPeerManager sharedInstance].lastBlockHeight;
    
    if (h > height) height = h;
    return height;
}

- (NSString *)dateText
{
    NSDateFormatter *df = [NSDateFormatter new];
    
    df.dateFormat = dateFormat(@"Mdja");

    NSTimeInterval t = (self.timestamp > 1) ? self.timestamp :
                       [[BTCPeerManager sharedInstance] timestampForBlockHeight:self.blockHeight] - 5*60;
    NSString *date = [df stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:t]];

    date = [date stringByReplacingOccurrencesOfString:@"am" withString:@"a"];
    date = [date stringByReplacingOccurrencesOfString:@"pm" withString:@"p"];
    date = [date stringByReplacingOccurrencesOfString:@"AM" withString:@"a"];
    date = [date stringByReplacingOccurrencesOfString:@"PM" withString:@"p"];
    date = [date stringByReplacingOccurrencesOfString:@"a.m." withString:@"a"];
    date = [date stringByReplacingOccurrencesOfString:@"p.m." withString:@"p"];
    date = [date stringByReplacingOccurrencesOfString:@"A.M." withString:@"a"];
    date = [date stringByReplacingOccurrencesOfString:@"P.M." withString:@"p"];
    return date;
}

- (NSDate *)transactionDate
{
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.timestamp];
}

static NSString *dateFormat(NSString *template)
{
    NSString *format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
    
    format = [format stringByReplacingOccurrencesOfString:@", " withString:@" "];
    format = [format stringByReplacingOccurrencesOfString:@" a" withString:@"a"];
    format = [format stringByReplacingOccurrencesOfString:@"hh" withString:@"h"];
    format = [format stringByReplacingOccurrencesOfString:@" ha" withString:@"@ha"];
    format = [format stringByReplacingOccurrencesOfString:@"HH" withString:@"H"];
    format = [format stringByReplacingOccurrencesOfString:@"H '" withString:@"H'"];
    format = [format stringByReplacingOccurrencesOfString:@"H " withString:@"H'h' "];
    format = [format stringByReplacingOccurrencesOfString:@"H" withString:@"H'h'"
              options:NSBackwardsSearch|NSAnchoredSearch range:NSMakeRange(0, format.length)];
    return format;
}

@end
