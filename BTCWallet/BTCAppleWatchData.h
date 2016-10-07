//
//  Created by Admin on 9/8/16.
//

#import "BTCAppleWatchTransactionData.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BTCAppleWatchData : NSObject <NSCoding>

@property (nonatomic, strong) NSString *balance;
@property (nonatomic, strong) NSString *balanceInLocalCurrency;
@property (nonatomic, strong) NSString *receiveMoneyAddress;
@property (nonatomic, strong) NSString *lastestTransction;
// There is no cifilter in watchOS 2, so we have to pass image over.
@property (nonatomic, strong) UIImage *receiveMoneyQRCodeImage;
@property (nonatomic, strong) NSArray<BTCAppleWatchTransactionData *> *transactions;
@property (nonatomic) BOOL hasWallet;

@end
