//
//  BTCReceiveViewController.h
//  BTCWallet
//
//  Created by Admin on 8/18/16.
//

#import <UIKit/UIKit.h>
#import "BTCNumberViewController.h"

@class BTCPaymentRequest;

@interface BTCReceiveViewController : UIViewController

@property (nonatomic, strong) BTCPaymentRequest *paymentRequest;
- (void)updateAddress;

@end
