//
//  BTCNumberViewController.h
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import <UIKit/UIKit.h>

@class BTCNumberViewController;

@protocol BTCNumberViewControllerDelegate <NSObject>
@required
- (void)numberViewController:(BTCNumberViewController *)numberViewController selectedAmount:(uint64_t)amount;
@end

@interface BTCNumberViewController : UIViewController

@property (nonatomic, assign) id<BTCNumberViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *to;

@end
