//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>
#import "BTCMainViewController.h"

#define BTCURLNotification            @"BTCURLNotification"
#define BTCFileNotification           @"BTCFileNotification"

@interface BTCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BTCMainViewController *main;

- (void)registerForPushNotifications;

@end
