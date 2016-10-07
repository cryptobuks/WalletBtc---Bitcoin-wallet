//
//  BTCCameraViewController.h
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import <UIKit/UIKit.h>

@class BTCCameraViewController;

@protocol BTCCameraViewControllerDelegate <NSObject>
@required
- (void)camera:(BTCCameraViewController*)cam didScanAddress:(NSString*)address;
@end

@interface BTCCameraViewController : UIViewController

@property (nonatomic, assign) id<BTCCameraViewControllerDelegate> delegate;

- (void)scanDone;
- (void)errorScan;
- (void)stop;

@end
