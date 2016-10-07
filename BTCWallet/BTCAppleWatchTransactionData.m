//
//  Created by Admin on 9/8/16.
//

#import "BTCAppleWatchTransactionData.h"
#import "BTCTransaction+Utils.h"

#define AW_TRANSACTION_DATA_AMOUNT_KEY @"AW_TRANSACTION_DATA_AMOUNT_KEY"
#define AW_TRANSACTION_DATA_AMOUNT_IN_LOCAL_CURRENCY_KEY @"AW_TRANSACTION_DATA_AMOUNT_IN_LOCAL_CURRENCY_KEY"
#define AW_TRANSACTION_DATA_DATE_KEY @"AW_TRANSACTION_DATA_DATE_KEY"
#define AW_TRANSACTION_DATA_TYPE_KEY @"AW_TRANSACTION_DATA_TYPE_KEY"

@implementation BTCAppleWatchTransactionData

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        _amountText = [decoder decodeObjectForKey:AW_TRANSACTION_DATA_AMOUNT_KEY];
        _amountTextInLocalCurrency = [decoder decodeObjectForKey:AW_TRANSACTION_DATA_AMOUNT_IN_LOCAL_CURRENCY_KEY];
        _dateText = [decoder decodeObjectForKey:AW_TRANSACTION_DATA_DATE_KEY];
        _type = [[decoder decodeObjectForKey:AW_TRANSACTION_DATA_TYPE_KEY] intValue];
    }
    
    return self;
}

+ (instancetype)appleWatchTransactionDataFrom:(BTCTransaction *)transaction
{
    BTCAppleWatchTransactionData *appleWatchTransactionData;
    
    if (transaction) {
        appleWatchTransactionData = [BTCAppleWatchTransactionData new];
        appleWatchTransactionData.amountText = transaction.amountText;
        appleWatchTransactionData.amountTextInLocalCurrency = transaction.localCurrencyTextForAmount;
        appleWatchTransactionData.dateText = transaction.dateText;
        
        switch (transaction.transactionType) {
            case BTCTransactionTypeSent: appleWatchTransactionData.type = BTCAWTransactionTypeSent; break;
            case BTCTransactionTypeReceive: appleWatchTransactionData.type = BTCAWTransactionTypeReceive; break;
            case BTCTransactionTypeMove: appleWatchTransactionData.type = BTCAWTransactionTypeMove; break;
            case BTCTransactionTypeInvalid: appleWatchTransactionData.type = BTCAWTransactionTypeInvalid; break;
        }
    }
    
    return appleWatchTransactionData;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
    if (_amountText) [encoder encodeObject:_amountText forKey:AW_TRANSACTION_DATA_AMOUNT_KEY];
    if (_amountTextInLocalCurrency) [encoder encodeObject:_amountTextInLocalCurrency
                                                   forKey:AW_TRANSACTION_DATA_AMOUNT_IN_LOCAL_CURRENCY_KEY];
    if (_dateText) [encoder encodeObject:_dateText forKey:AW_TRANSACTION_DATA_DATE_KEY];
    if (_type) [encoder encodeObject:@(_type) forKey:AW_TRANSACTION_DATA_TYPE_KEY];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        BTCAppleWatchTransactionData *otherTx = object;

        return ([self.amountText isEqual:otherTx.amountText] &&
                [self.amountTextInLocalCurrency isEqual:otherTx.amountTextInLocalCurrency] &&
                [self.dateText isEqual:otherTx.dateText] && self.type == otherTx.type) ? YES : NO;
    }
    else return NO;
}

@end
