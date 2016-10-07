//
//  BTCTrzDetailViewController.h
//  BTCWallet
//
//  Created by Admin on 8/22/16.
//

#import <UIKit/UIKit.h>

@class BTCTransaction;

@interface BTCTrzDetailViewController : UIViewController

@property (nonatomic, strong) BTCTransaction *transaction;
@property (nonatomic, strong) NSString *txDateString;

@end
