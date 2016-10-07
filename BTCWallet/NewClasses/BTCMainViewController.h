//
//  BTCMainViewController.h
//  BTCWallet
//
//  Created by Admin on 8/18/16.
//

#import <UIKit/UIKit.h>

@interface BTCMainViewController : UIViewController

- (void)startActivityWithTimeout:(NSTimeInterval)timeout;
- (void)stopActivityWithSuccess:(BOOL)success;
- (void)ping;

@end
