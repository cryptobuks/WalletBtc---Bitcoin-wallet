//
//  Created by Admin on 9/8/16.
//

#import "BTCTransaction.h"
#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    BTCAWTransactionTypeSent,
    BTCAWTransactionTypeReceive,
    BTCAWTransactionTypeMove,
    BTCAWTransactionTypeInvalid
} BTCAWTransactionType;

@interface BTCAppleWatchTransactionData : NSObject <NSCoding>

@property (nonatomic, strong) NSString *amountText;
@property (nonatomic, strong) NSString *amountTextInLocalCurrency;
@property (nonatomic, strong) NSString *dateText;
@property (nonatomic) BTCAWTransactionType type;

+ (instancetype)appleWatchTransactionDataFrom:(BTCTransaction *)transaction;

@end
