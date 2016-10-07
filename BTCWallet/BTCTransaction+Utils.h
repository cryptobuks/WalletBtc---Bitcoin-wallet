//
//  Created by Admin on 9/8/16.
//

#import "BTCTransaction.h"

typedef enum : NSInteger {
    BTCTransactionTypeSent,
    BTCTransactionTypeReceive,
    BTCTransactionTypeMove,
    BTCTransactionTypeInvalid
} BTCTransactionType;

@interface BTCTransaction (Utils)

- (BTCTransactionType)transactionType;
- (NSString*)amountText;
- (NSString*)localCurrencyTextForAmount;
- (NSString*)dateText;
- (NSDate*)transactionDate;

@end
