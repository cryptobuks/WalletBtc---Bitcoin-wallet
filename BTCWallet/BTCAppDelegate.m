//
//  Created by Admin on 9/8/16.
//

#import "BTCAppDelegate.h"
#import "BTCPeerManager.h"
#import "BTCWalletManager.h"
#import "BTCPhoneWCSessionManager.h"
#import <WebKit/WebKit.h>
#import "BTCPasswordViewController.h"
#import "BTCSideMenuViewController.h"
#import "BTCSideMenuOptions.h"
#import "BTCMenuViewController.h"

#if BITCOIN_TESTNET
#pragma message "testnet build"
#endif

#if SNAPSHOT
#pragma message "snapshot build"
#endif

@interface BTCAppDelegate ()

// the nsnotificationcenter observer for wallet balance
@property id balanceObserver;

@property (nonatomic, strong)BTCPasswordViewController *pass;

// the most recent balance as received by notification
@property uint64_t balance;


@end

@implementation BTCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"trzPriority"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"trzPriority"];
    }

    // use background fetch to stay synced with the blockchain
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    UIPageControl.appearance.pageIndicatorTintColor = [UIColor lightGrayColor];
    UIPageControl.appearance.currentPageIndicatorTintColor = [UIColor blackColor];

   // [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
   //  setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]}
   //  forState:UIControlStateNormal];

    if (launchOptions[UIApplicationLaunchOptionsURLKey]) {
        NSData *file = [NSData dataWithContentsOfURL:launchOptions[UIApplicationLaunchOptionsURLKey]];

        if (file.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:BTCFileNotification object:nil
             userInfo:@{@"file":file}];
        }
    }

    // start the event manager

    //TODO: bitcoin protocol/payment protocol over multipeer connectivity

    //TODO: accessibility for the visually impaired

    //TODO: fast wallet restore using webservice and/or utxo p2p message

    //TODO: ask user if they need to sweep to a new wallet when restoring because it was compromised

    //TODO: figure out deterministic builds/removing app sigs: http://www.afp548.com/2012/06/05/re-signining-ios-apps/

    //TODO: implement importing of private keys split with shamir's secret sharing:
    //      https://github.com/cetuscetus/btctool/blob/bip/bip-xxxx.mediawiki

    [BTCPhoneWCSessionManager sharedInstance];
    
    // observe balance and create notifications
    [self setupBalanceNotification:application];
    [self setupPreferenceDefaults];
    
    
    
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.main = [BTCMainViewController new];
    BTCMenuViewController *menuVC = [BTCMenuViewController new];
    UINavigationController *contentNavigation = [[UINavigationController alloc] initWithRootViewController:self.main];
    
    BTCSideMenuOptions *options = [[BTCSideMenuOptions alloc] init];
    options.contentViewScale = 1.0;
    options.contentViewOpacity = 0.5;
    options.shadowOpacity = 0.0;
    BTCSideMenuViewController *sideMenuController = [[BTCSideMenuViewController alloc] initWithMenuViewController:menuVC
                                                                                            contentViewController:contentNavigation
                                                                                                          options:options];
    
    sideMenuController.menuFrame = CGRectMake(0, 0, 260.0, self.window.bounds.size.height);
    
    
    self.window.rootViewController=sideMenuController;
    [self.window makeKeyAndVisible];
    
    [self showPasswordOnController:self.window.rootViewController];
    return YES;
}



- (void)applicationWillEnterForeground:(UIApplication *)application{
   // [self showPassword];
}

- (void)applicationWillResignActive:(UIApplication *)application{
   // [self showPasswordOnController:[[self class] topMostController]];
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
     [self showPasswordOnController:[[self class] topMostController]];
}

- (void)showPasswordOnController:(UIViewController*)controller{
    if ([BTCWalletManager sharedInstance].pin.length < 4)return;
    if ([controller isKindOfClass:[BTCPasswordViewController class]]) {
        return;
    }
    if (_pass && _pass.unlocked) {
        _pass = nil;
    }
    if (!_pass) {
        _pass = [BTCPasswordViewController new];
        [controller presentViewController:_pass animated:NO completion:^{
            //
        }];
    }
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.balance == UINT64_MAX) self.balance = [BTCWalletManager sharedInstance].wallet.balance;
        [self updatePlatform];
        [self registerForPushNotifications];
    });
}

// Applications may reject specific types of extensions based on the extension point identifier.
// Constants representing common extension point identifiers are provided further down.
// If unimplemented, the default behavior is to allow the extension point identifier.
- (BOOL)application:(UIApplication *)application
shouldAllowExtensionPointIdentifier:(NSString *)extensionPointIdentifier
{
    return NO; // disable extensions such as custom keyboards for security purposes
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
annotation:(id)annotation
{
    if (! [url.scheme isEqual:@"bitcoin"]) {
        [[[UIAlertView alloc] initWithTitle:@"Not a bitcoin URL" message:url.absoluteString delegate:nil
          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/10), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BTCURLNotification object:nil userInfo:@{@"url":url}];
    });

    return YES;
}

- (void)application:(UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    __block id protectedObserver = nil, syncFinishedObserver = nil, syncFailedObserver = nil;
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    void (^cleanup)() = ^() {
        completion = nil;
        if (protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:protectedObserver];
        if (syncFinishedObserver) [[NSNotificationCenter defaultCenter] removeObserver:syncFinishedObserver];
        if (syncFailedObserver) [[NSNotificationCenter defaultCenter] removeObserver:syncFailedObserver];
        protectedObserver = syncFinishedObserver = syncFailedObserver = nil;
    };

    if ([BTCPeerManager sharedInstance].syncProgress >= 1.0) {
        NSLog(@"background fetch already synced");
        if (completion) completion(UIBackgroundFetchResultNoData);
        return;
    }

    // timeout after 25 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 25*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (completion) {
            NSLog(@"background fetch timeout with progress: %f", [BTCPeerManager sharedInstance].syncProgress);
            completion(([BTCPeerManager sharedInstance].syncProgress > 0.1) ? UIBackgroundFetchResultNewData :
                       UIBackgroundFetchResultFailed);
            cleanup();
        }
        //TODO: disconnect
    });

    protectedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable object:nil
        queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"background fetch protected data available");
            [[BTCPeerManager sharedInstance] connect];
        }];

    syncFinishedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFinishedNotification object:nil
        queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"background fetch sync finished");
            if (completion) completion(UIBackgroundFetchResultNewData);
            cleanup();
        }];

    syncFailedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFailedNotification object:nil
        queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"background fetch sync failed");
            if (completion) completion(UIBackgroundFetchResultFailed);
            cleanup();
        }];

    NSLog(@"background fetch starting");
    [[BTCPeerManager sharedInstance] connect];

}

- (void)setupBalanceNotification:(UIApplication *)application
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    self.balance = UINT64_MAX; // this gets set in applicationDidBecomActive:
    
    self.balanceObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletBalanceChangedNotification object:nil queue:nil
        usingBlock:^(NSNotification * _Nonnull note) {
            if (self.balance < manager.wallet.balance) {
                BOOL send = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_LOCAL_NOTIFICATIONS_KEY];
                NSString *noteText = [NSString stringWithFormat:NSLocalizedString(@"received %@ (%@)", nil),
                                      [manager stringForAmount:manager.wallet.balance - self.balance],
                                      [manager localCurrencyStringForAmount:manager.wallet.balance - self.balance]];
                
                NSLog(@"local notifications enabled=%d", send);
                
                // send a local notification if in the background
                if (application.applicationState == UIApplicationStateBackground ||
                    application.applicationState == UIApplicationStateInactive) {
                    [UIApplication sharedApplication].applicationIconBadgeNumber =
                        [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
                    
                    if (send) {
                        UILocalNotification *note = [[UILocalNotification alloc] init];
                        
                        note.alertBody = noteText;
                        note.soundName = @"coinflip";
                        [[UIApplication sharedApplication] presentLocalNotificationNow:note];
                        NSLog(@"sent local notification %@", note);
                    }
                }
                
                // send a custom notification to the watch if the watch app is up
                [[BTCPhoneWCSessionManager sharedInstance] notifyTransactionString:noteText];
            }
            
            self.balance = manager.wallet.balance;
        }];
}

- (void)setupPreferenceDefaults {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    // turn on local notifications by default
    if (! [defs boolForKey:USER_DEFAULTS_LOCAL_NOTIFICATIONS_SWITCH_KEY]) {
        NSLog(@"enabling local notifications by default");
        [defs setBool:true forKey:USER_DEFAULTS_LOCAL_NOTIFICATIONS_SWITCH_KEY];
        [defs setBool:true forKey:USER_DEFAULTS_LOCAL_NOTIFICATIONS_KEY];
    }
}

- (void)updatePlatform {
}
//*
- (void)registerForPushNotifications {
    
}
// */

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    NSLog(@"Handle events for background url session; identifier=%@", identifier);
}

- (void)dealloc
{
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
}

@end
