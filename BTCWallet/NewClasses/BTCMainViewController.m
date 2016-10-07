//
//  BTCMainViewController.m
//  BTCWallet
//
//  Created by Admin on 8/18/16.
//

#import "BTCMainViewController.h"
#import "BTCAppDelegate.h"
#import "BTCBubbleView.h"
#import "BTCBouncyBurgerButton.h"
#import "BTCPeerManager.h"
#import "BTCWalletManager.h"
#import "BTCPaymentRequest.h"
#import "UIImage+Utils.h"
#import "Reachability.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <sys/stat.h>
#import <mach-o/dyld.h>

#import "BTCStartViewController.h"
//#import "BTCSendViewController.h"
//#import "BTCReceiveViewController.h"
#import "BTCTrzDetailViewController.h"
//#import "BTCSettingsViewController.h"
#import "BTCCurrencyViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#import "BTCAnimation.h"
#import "BTCProgressView.h"

#import "BTCSideMenuViewController.h"

#define BACKUP_DIALOG_TIME_KEY @"BACKUP_DIALOG_TIME"
#define BALANCE_KEY            @"BALANCE"
#define HAS_AUTHENTICATED_KEY  @"HAS_AUTHENTICATED"


#define SETTINGS_MAX_DIGITS_KEY @"SETTINGS_MAX_DIGITS"


#define TRANSACTION_CELL_HEIGHT 56

static NSString *dateFormat(NSString *template)
{
    NSString *format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
    
    format = [format stringByReplacingOccurrencesOfString:@", " withString:@" "];
    format = [format stringByReplacingOccurrencesOfString:@" a" withString:@"a"];
    format = [format stringByReplacingOccurrencesOfString:@"hh" withString:@"h"];
    format = [format stringByReplacingOccurrencesOfString:@" ha" withString:@"@ha"];
    format = [format stringByReplacingOccurrencesOfString:@"HH" withString:@"H"];
    format = [format stringByReplacingOccurrencesOfString:@"H '" withString:@"H'"];
    format = [format stringByReplacingOccurrencesOfString:@"H " withString:@"H'h' "];
    format = [format stringByReplacingOccurrencesOfString:@"H" withString:@"H'h'"
                                                  options:NSBackwardsSearch|NSAnchoredSearch range:NSMakeRange(0, format.length)];
    return format;
}

@interface BTCMainViewController ()

@property (strong, nonatomic) IBOutlet UITableView *btcTableView;

@property (nonatomic, assign) uint64_t balance;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSData *file;
@property (nonatomic, strong) Reachability *reachability;

@property (nonatomic, strong) id txStatusObserver;

@property (nonatomic, strong) id urlObserver, fileObserver, protectedObserver, balanceObserver, seedObserver;
@property (nonatomic, strong) id reachabilityObserver, syncStartedObserver, syncFinishedObserver, syncFailedObserver;
@property (nonatomic, strong) id activeObserver, resignActiveObserver, foregroundObserver, backgroundObserver;

@property (nonatomic, assign) NSTimeInterval timeout, start;
@property (nonatomic, assign) SystemSoundID pingsound;


@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *transactions;

@property (nonatomic, strong) NSMutableDictionary *txDates;
@property (strong, nonatomic) IBOutlet UILabel *amountLabel;
@property (strong, nonatomic) IBOutlet UILabel *localAmountLabel;

@property (strong, nonatomic) IBOutlet BTCProgressView *progressView;


@end

@implementation BTCMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addLeftMenuButtonWithImage:[UIImage imageNamed:@"menu_icon"]];
    self.navigationItem.title = @"Wallet";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCNoTranzactionCell" bundle:nil] forCellReuseIdentifier:@"NoTxCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCTranzactionCell" bundle:nil] forCellReuseIdentifier:@"TransactionCell"];
    
    // detect jailbreak so we can throw up an idiot warning, in viewDidLoad so it can't easily be swizzled out
    struct stat s;
    BOOL jailbroken = (stat("/bin/sh", &s) == 0) ? YES : NO; // if we can see /bin/sh, the app isn't sandboxed
    
    // some anti-jailbreak detection tools re-sandbox apps, so do a secondary check for any MobileSubstrate dyld images
    for (uint32_t count = _dyld_image_count(), i = 0; i < count && ! jailbroken; i++) {
        if (strstr(_dyld_get_image_name(i), "MobileSubstrate")) jailbroken = YES;
    }
    
#if TARGET_IPHONE_SIMULATOR
    jailbroken = NO;
#endif
    
    _balance = UINT64_MAX;
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
 //   manager.localCurrencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
    
    self.urlObserver =
   
    
    
    
    self.foregroundObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           if (! manager.noWallet) {
                                                               
                                                               [[BTCPeerManager sharedInstance] connect];
                                                              // [self.sendViewController updateClipboardText];
                                                               
                                                               
                                                           }
                                                       }];
    
    self.backgroundObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           if (! manager.noWallet) { // lockdown the app
                                                               manager.didAuthenticate = NO;
                                                       //        self.navigationItem.titleView = self.logo;
                                                        //       self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"burger"];
                                                        //       self.navigationItem.rightBarButtonItem = self.lock;
                                                        //       self.pageViewController.view.alpha = 1.0;
                                                               [UIApplication sharedApplication].applicationIconBadgeNumber = 0; // reset app badge number
                                                           }
                                                       }];
    
    self.activeObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                        //   [self.blur removeFromSuperview];
                                                        //   self.blur = nil;
                                                       }];
    
    self.resignActiveObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
                                                           UIImage *img;
                                                           
                                                           if (! [keyWindow viewWithTag:-411]) { // only take a screenshot if no views are marked highly sensitive
                                                               UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
                                                               [keyWindow drawViewHierarchyInRect:[UIScreen mainScreen].bounds afterScreenUpdates:NO];
                                                               img = UIGraphicsGetImageFromCurrentImageContext();
                                                               UIGraphicsEndImageContext();
                                                           }
                                                           else img = [UIImage imageNamed:@"wallpaper-default"];
                                                           
                                                       //    [self.blur removeFromSuperview];
                                                        //   self.blur = [[UIImageView alloc] initWithImage:[img blurWithRadius:3]];
                                                       //    [keyWindow.subviews.lastObject addSubview:self.blur];
                                                       }];
    
    self.reachabilityObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (! manager.noWallet && self.reachability.currentReachabilityStatus != NotReachable &&
                                                          [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
                                                          [[BTCPeerManager sharedInstance] connect];
                                                      }
                                                      else if (! manager.noWallet && self.reachability.currentReachabilityStatus == NotReachable) {
                                                       //   [self showErrorBar];
                                                      }
                                                  }];
    
    self.balanceObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletBalanceChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      double progress = [BTCPeerManager sharedInstance].syncProgress;
                                                      
                                                      if (_balance != UINT64_MAX && progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0) { // wait for sync
                                                          self.balance = _balance; // this updates the local currency value with the latest exchange rate
                                                          
                                                          self.amountLabel.text = [[BTCWalletManager sharedInstance] stringForAmount:self.balance];
                                                          self.localAmountLabel.text = [[BTCWalletManager sharedInstance] localCurrencyStringForAmount:self.balance];
                                                          
                                                          return;
                                                      }
                                                      
                                                 //     [self showBackupDialogIfNeeded];
                                                 //     [self.receiveViewController updateAddress];
                                                      self.balance = manager.wallet.balance;
                                                      self.amountLabel.text = [[BTCWalletManager sharedInstance] stringForAmount:self.balance];
                                                      self.localAmountLabel.text = [[BTCWalletManager sharedInstance] localCurrencyStringForAmount:self.balance];
                                                      
                                                      //hystory
                                                      BTCTransaction *tx = self.transactions.firstObject;
                                                      
                                                      self.transactions = manager.wallet.allTransactions;
                                                      if (self.transactions.firstObject != tx) {
                                                          [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                                                        withRowAnimation:UITableViewRowAnimationAutomatic];
                                                      }
                                                      else [self.tableView reloadData];
                                                      
                                                    }];
    
    self.seedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletManagerSeedChangedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                       //    [self.receiveViewController updateAddress];
                                                           self.balance = manager.wallet.balance;
                                                           [[NSUserDefaults standardUserDefaults] removeObjectForKey:HAS_AUTHENTICATED_KEY];
                                                       }];
    
    self.syncStartedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncStartedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           if (self.reachability.currentReachabilityStatus == NotReachable) return;
                                                        //   [self hideErrorBar];
                                                           [self startActivityWithTimeout:0];
                                                       }];
    
    self.syncFinishedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFinishedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                                                           self.navigationItem.title = @"Wallet";
                                                         //  [self showBackupDialogIfNeeded];
                                                         //  if (! self.percent.hidden) [self hideTips];
                                                         //  self.percent.hidden = YES;
                                                         //  if (! manager.didAuthenticate) self.navigationItem.titleView = self.logo;
                                                         //  [self.receiveViewController updateAddress];
                                                           self.balance = manager.wallet.balance;
                                                       }];
    
    self.syncFailedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerSyncFailedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                                                         //  [self showBackupDialogIfNeeded];
                                                         //  [self.receiveViewController updateAddress];
                                                         //  [self showErrorBar];
                                                       }];
    
    if (! self.txStatusObserver) {
        self.txStatusObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerTxStatusNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               self.transactions = manager.wallet.allTransactions;
                                                               [self.tableView reloadData];
                                                           }];
    }
    
    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    
    
    if (manager.watchOnly) { // watch only wallet
        UILabel *label = [UILabel new];
        
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0];
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"watch only";
        [label sizeToFit];
        label.center = CGPointMake(self.view.frame.size.width - label.frame.size.width,
                                   self.view.frame.size.height - (label.frame.size.height + 5)*2);
        [self.view addSubview:label];
    }
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[[NSBundle mainBundle] URLForResource:@"coinflip"
                                                                                withExtension:@"aiff"], &_pingsound);
    
    if (! manager.noWallet) {
        //TODO: do some kickass quick logo animation, fast circle spin that slows
       // self.splash.hidden = YES;
        self.navigationController.navigationBar.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
    
    if (jailbroken && manager.wallet.totalReceived + manager.wallet.totalSent > 0) {
        [[[UIAlertView alloc] initWithTitle:@"WARNING"
                                    message:@"DEVICE SECURITY COMPROMISED\n"
                                                              "Any 'jailbreak' app can access any other app's keychain data "
                                                              "(and steal your bitcoins). "
                                                              "Wipe this wallet immediately and restore on a secure device."
                                   delegate:self cancelButtonTitle:@"ignore"
                          otherButtonTitles:@"wipe", nil] show];
    }
    else if (jailbroken) {
        [[[UIAlertView alloc] initWithTitle:@"WARNING"
                                    message:@"DEVICE SECURITY COMPROMISED\n"
                                                              "Any 'jailbreak' app can access any other app's keychain data "
                                                              "(and steal your bitcoins)."
                                   delegate:self cancelButtonTitle:@"ignore"
                          otherButtonTitles:@"close app", nil] show];
    }
}




- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
   // if ([BTCWalletManager sharedInstance].didAuthenticate) [self unlock:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
 //   self.didAppear = YES;
    
    [[UIApplication sharedApplication]setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    if (! self.protectedObserver) {
        self.protectedObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable
                                                          object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                              [self performSelector:@selector(protectedViewDidAppear) withObject:nil afterDelay:0.0];
                                                          }];
    }
    
    if ([UIApplication sharedApplication].protectedDataAvailable) {
        [self performSelector:@selector(protectedViewDidAppear) withObject:nil afterDelay:0.0];
    }
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.transactions = [manager.wallet.allTransactions copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    [super viewDidAppear:animated];
}

- (void)protectedViewDidAppear
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (self.protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.protectedObserver];
    self.protectedObserver = nil;
    
    if ([defs integerForKey:SETTINGS_MAX_DIGITS_KEY] == 5) {
        manager.format.currencySymbol = @"m" BTC NARROW_NBSP;
        manager.format.maximumFractionDigits = 5;
        manager.format.maximum = @((MAX_MONEY/SATOSHIS)*1000);
    }
    else if ([defs integerForKey:SETTINGS_MAX_DIGITS_KEY] == 8) {
        manager.format.currencySymbol = BTC NARROW_NBSP;
        manager.format.maximumFractionDigits = 8;
        manager.format.maximum = @(MAX_MONEY/SATOSHIS);
    }
    
    
    if (manager.noWallet) {
        if (! manager.passcodeEnabled) {
            [[[UIAlertView alloc] initWithTitle:@"turn device passcode on"
                                        message:@"\nA device passcode is needed to safeguard your wallet. Go to settings and "
                                                                  "turn passcode on to continue."
                                       delegate:self cancelButtonTitle:nil otherButtonTitles:@"close app", nil] show];
        }
        else {
            
            [self presentViewController:[BTCStartViewController new] animated:YES completion:^{
                //none
            }];
            
            manager.didAuthenticate = YES;
          //  [self unlock:nil];
        }
    }
    else {
        if (_balance == UINT64_MAX && [defs objectForKey:BALANCE_KEY]) self.balance = [defs doubleForKey:BALANCE_KEY];
      //  self.splash.hidden = YES;
        //[self.receiveViewController updateAddress];
     //   if (self.reachability.currentReachabilityStatus == NotReachable) [self showErrorBar];
        
        if (self.navigationController.visibleViewController == self) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
        
#if SNAPSHOT
        return;
#endif
       
        
        if ([BTCWalletManager sharedInstance].pin.length != 4) {
            if (! [defs boolForKey:HAS_AUTHENTICATED_KEY]) {
                while (! [manager authenticateWithPrompt:nil andTouchId:NO]) { }
                [defs setBool:YES forKey:HAS_AUTHENTICATED_KEY];
                //   [self unlock:nil];
            }
        }
         /*
        if (! [defs boolForKey:HAS_AUTHENTICATED_KEY]) {
            while (! [manager authenticateWithPrompt:nil andTouchId:NO]) { }
            [defs setBool:YES forKey:HAS_AUTHENTICATED_KEY];
         //   [self unlock:nil];
        }
       // */
        
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            [[BTCPeerManager sharedInstance] connect];
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0; // reset app badge number
            
         //   if (self.url) [self.sendViewController handleURL:self.url], self.url = nil;
         //   if (self.file) [self.sendViewController handleFile:self.file], self.file = nil;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
    self.txStatusObserver = nil;
    [super viewWillDisappear:animated];
}


- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.reachability stopNotifier];
    if (self.urlObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.urlObserver];
    if (self.fileObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.fileObserver];
    if (self.protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.protectedObserver];
    if (self.foregroundObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.foregroundObserver];
    if (self.backgroundObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.backgroundObserver];
    if (self.activeObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.activeObserver];
    if (self.resignActiveObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.resignActiveObserver];
    if (self.reachabilityObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.reachabilityObserver];
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.seedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.seedObserver];
    if (self.syncStartedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncStartedObserver];
    if (self.syncFinishedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFinishedObserver];
    if (self.syncFailedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFailedObserver];
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
    AudioServicesDisposeSystemSoundID(self.pingsound);
}

- (void)setBalance:(uint64_t)balance
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (balance > _balance && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [self.view addSubview:[[[BTCBubbleView viewWithText:[NSString
                                                            stringWithFormat:@"received %@ (%@)", [manager stringForAmount:balance - _balance],
                                                            [manager localCurrencyStringForAmount:balance - _balance]]
                                                    center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
                               popOutAfterDelay:3.0]];
        [self ping];
    }
    
    _balance = balance;
    
    // use setDouble since setInteger won't hold a uint64_t
    [[NSUserDefaults standardUserDefaults] setDouble:balance forKey:BALANCE_KEY];
    
   // if (self.percent.hidden) {
    //    self.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:balance],
   //                                  [manager localCurrencyStringForAmount:balance]];
   // }
}

- (void)startActivityWithTimeout:(NSTimeInterval)timeout
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    if (timeout > 1 && start + timeout > self.start + self.timeout) {
        self.timeout = timeout;
        self.start = start;
    }
    
    if (timeout <= DBL_EPSILON) {
        if ([[BTCPeerManager sharedInstance] timestampForBlockHeight:[BTCPeerManager sharedInstance].lastBlockHeight] +
            60*60*24*7 < [NSDate timeIntervalSinceReferenceDate]) {
            if ([BTCWalletManager sharedInstance].seedCreationTime + 60*60*24 < start) {
            //    self.percent.hidden = NO;
                self.navigationItem.titleView = nil;
                self.navigationItem.title = @"syncing...";
            }
        }
        else [self performSelector:@selector(showSyncing) withObject:nil afterDelay:5.0];
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  //  self.progress.hidden = self.pulse.hidden = NO;
    self.progressView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{ self.progressView.alpha = 1.0; }];
    [self updateProgress];
}

- (void)updateProgress
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
    
    double progress = [BTCPeerManager sharedInstance].syncProgress;

    self.progressView.progress = progress;
    
    if (progress + DBL_EPSILON >= 1.0) {
        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
    }
    else [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.2];
    
    /*
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
    
    static int counter = 0;
    NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - self.start;
    double progress = [BTCPeerManager sharedInstance].syncProgress;
    
    if (progress > DBL_EPSILON && ! self.percent.hidden && self.tipView.alpha > 0.5) {
        self.tipView.text = [NSString stringWithFormat:NSLocalizedString(@"block #%d of %d", nil),
                             [BTCPeerManager sharedInstance].lastBlockHeight,
                             [BTCPeerManager sharedInstance].estimatedBlockHeight];
    }
    
    if (self.timeout > 1.0 && 0.1 + 0.9*elapsed/self.timeout < progress) progress = 0.1 + 0.9*elapsed/self.timeout;
    
    if ((counter % 13) == 0) {
        self.pulse.alpha = 1.0;
        [self.pulse setProgress:progress animated:progress > self.pulse.progress];
        [self.progress setProgress:progress animated:progress > self.progress.progress];
        
        if (progress > self.progress.progress) {
            [self performSelector:@selector(setProgressTo:) withObject:@(progress) afterDelay:1.0];
        }
        else self.progress.progress = progress;
        
        [UIView animateWithDuration:1.59 delay:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.pulse.alpha = 0.0;
        } completion:nil];
        
        [self.pulse performSelector:@selector(setProgress:) withObject:nil afterDelay:2.59];
    }
    else if ((counter % 13) >= 5) {
        [self.progress setProgress:progress animated:progress > self.progress.progress];
        [self.pulse setProgress:progress animated:progress > self.pulse.progress];
    }
    
    counter++;
    self.percent.text = [NSString stringWithFormat:@"%0.1f%%", (progress > 0.1 ? progress - 0.1 : 0.0)*111.0];
    
    if (progress + DBL_EPSILON >= 1.0) {
        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
        if (! self.percent.hidden) [self hideTips];
        self.percent.hidden = YES;
        if (! [BTCWalletManager sharedInstance].didAuthenticate) self.navigationItem.titleView = self.logo;
    }
    else [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.2];
    */
}


- (void)stopActivityWithSuccess:(BOOL)success
{
    double progress = [BTCPeerManager sharedInstance].syncProgress;
    
    self.start = self.timeout = 0.0;
    if (progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0) return; // not done syncing
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   // if (self.progress.alpha < 0.5) return;
    
    if (success) {
    //    [self.progress setProgress:1.0 animated:YES];
    //    [self.pulse setProgress:1.0 animated:YES];
        
        [UIView animateWithDuration:0.2 animations:^{
      //      self.progress.alpha = self.pulse.alpha = 0.0;
        } completion:^(BOOL finished) {
       //     self.progress.hidden = self.pulse.hidden = YES;
       //     self.progress.progress = self.pulse.progress = 0.0;
        }];
    }
    else {
      //  self.progress.hidden = self.pulse.hidden = YES;
     //   self.progress.progress = self.pulse.progress = 0.0;
    }
}

- (void)showSyncing
{
    double progress = [BTCPeerManager sharedInstance].syncProgress;
    
    if (progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0 &&
        [BTCWalletManager sharedInstance].seedCreationTime + 60*60*24 < [NSDate timeIntervalSinceReferenceDate]) {
      //  self.percent.hidden = NO;
        self.navigationItem.titleView = nil;
        self.navigationItem.title = @"syncing...";
    }
}


- (IBAction)goSend:(id)sender {
//    BTCSendViewController *send = [BTCSendViewController new];
//    [BTCAnimation presentViewController:send onController:self direction:BTCAnimationDirectionLeft];
 //   [self presentViewController:send animated:YES completion:^{
 //       //none
 //   }];
}

- (IBAction)goRecivie:(id)sender {
//    BTCReceiveViewController *recevie = [BTCReceiveViewController new];
//    [BTCAnimation presentViewController:recevie onController:self direction:BTCAnimationDirectionRight];
  //  [self presentViewController:recevie animated:YES completion:nil];
}



/////////////////////////////////////////////
////////////
///////
/////
///
//


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.transactions.count == 0) return 1;
    return  self.transactions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *noTxIdent = @"NoTxCell", *transactionIdent = @"TransactionCell";
    UITableViewCell *cell = nil;
    UILabel *textLabel, *unconfirmedLabel, *detailTextLabel;
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    
    
    if (self.transactions.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:transactionIdent];
        textLabel = (id)[cell viewWithTag:1];
        detailTextLabel = (id)[cell viewWithTag:2];
        unconfirmedLabel = (id)[cell viewWithTag:3];
        
        BTCTransaction *tx = self.transactions[indexPath.row];
        uint64_t received = [manager.wallet amountReceivedFromTransaction:tx],
        sent = [manager.wallet amountSentByTransaction:tx];
        uint32_t blockHeight = self.blockHeight;
        uint32_t confirms = (tx.blockHeight > blockHeight) ? 0 : (blockHeight - tx.blockHeight) + 1;
        
        /*
         received = [@[@(0), @(0), @(54000000), @(0), @(0), @(93000000)][indexPath.row] longLongValue];
         sent = [@[@(1010000), @(10010000), @(0), @(82990000), @(10010000), @(0)][indexPath.row] longLongValue];
         balance = [@[@(42980000), @(43990000), @(54000000), @(0), @(82990000), @(93000000)][indexPath.row]
         longLongValue];
         [self.txDates removeAllObjects];
         tx.timestamp = [NSDate timeIntervalSinceReferenceDate] - indexPath.row*100000;
         confirms = 6;
         */
        textLabel.textColor = [UIColor darkTextColor];
        unconfirmedLabel.hidden = NO;
        unconfirmedLabel.numberOfLines = 2;
        unconfirmedLabel.backgroundColor = [UIColor lightGrayColor];
        detailTextLabel.text = [self dateForTx:tx];
        
        unconfirmedLabel.layer.cornerRadius = unconfirmedLabel.bounds.size.height / 2.0;
        
        if (confirms == 0 && ! [manager.wallet transactionIsValid:tx]) {
            unconfirmedLabel.text = NSLocalizedString(@"INVALID", nil);
            unconfirmedLabel.backgroundColor = [UIColor redColor];
        }
        else if (confirms == 0 && [manager.wallet transactionIsPending:tx]) {
            unconfirmedLabel.text = NSLocalizedString(@"pending", nil);
            unconfirmedLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
            textLabel.textColor = [UIColor grayColor];
        }
        else if (confirms == 0 && ! [manager.wallet transactionIsVerified:tx]) {
             unconfirmedLabel.text = NSLocalizedString(@"unverified", nil);
        }
        else if (confirms < 6) {
             unconfirmedLabel.text = [NSString stringWithFormat:@" %d conf. ",
                                          (int)confirms];
        }else{
            if (sent > 0 && received == sent) {
                unconfirmedLabel.text = NSLocalizedString(@"moved", nil);
                unconfirmedLabel.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
            }
            else if (sent > 0) {
                unconfirmedLabel.text = NSLocalizedString(@"sent", nil);
                unconfirmedLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.33 blue:0.33 alpha:1.0];
            }
            else {
                unconfirmedLabel.text = NSLocalizedString(@"received", nil);
                unconfirmedLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.75 blue:0.0 alpha:1.0];
            }
        }
       
        if (sent > 0 && received == sent) {
            textLabel.text = [manager stringForAmount:sent];
        }
        else if (sent > 0) {
            textLabel.text = [manager stringForAmount:received - sent];
        }
        else {
            textLabel.text = [manager stringForAmount:received];
        }
      
        
    }
    else cell = [tableView dequeueReusableCellWithIdentifier:noTxIdent];
    
    
    
    // [self setBackgroundForCell:cell tableView:tableView indexPath:indexPath];
    return cell;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    switch (section) {
//        case 0:
//            return nil;
//
//        case 1:
//            return nil;
//
//        case 2:
//            return NSLocalizedString(@"rescan blockchain if you think you may have missing transactions, "
//                                     "or are having trouble sending (rescanning can take several minutes)", nil);
//    }
//
//    return nil;
//}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TRANSACTION_CELL_HEIGHT;
    return 44.0;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.transactions.count > 0) [self showTx:self.transactions[indexPath.row]]; // transaction details
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)showTx:(id)sender
{
    BTCTrzDetailViewController *detailController = [BTCTrzDetailViewController new];
    detailController.transaction = sender;
    detailController.txDateString = [self dateForTx:sender];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:detailController];
    [self presentViewController:navigation animated:YES completion:^{
        //none
    }];
}


- (uint32_t)blockHeight
{
    static uint32_t height = 0;
    uint32_t h = [BTCPeerManager sharedInstance].lastBlockHeight;
    
    if (h > height) height = h;
    return height;
}

- (void)setTransactions:(NSArray *)transactions
{
    _transactions = [transactions copy];
}



- (NSString *)dateForTx:(BTCTransaction *)tx
{
    static NSDateFormatter *monthDayHourFormatter = nil;
    static NSDateFormatter *yearMonthDayHourFormatter = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{ // BUG: need to watch for NSCurrentLocaleDidChangeNotification
        monthDayHourFormatter = [NSDateFormatter new];
        monthDayHourFormatter.dateFormat = dateFormat(@"Mdja");
        yearMonthDayHourFormatter = [NSDateFormatter new];
        yearMonthDayHourFormatter.dateFormat = dateFormat(@"yyMdja");
    });
    
    NSString *date = self.txDates[uint256_obj(tx.txHash)];
    NSTimeInterval now = [[BTCPeerManager sharedInstance] timestampForBlockHeight:TX_UNCONFIRMED];
    NSTimeInterval year = [NSDate timeIntervalSinceReferenceDate] - 364*24*60*60;
    
    if (date) return date;
    
    NSTimeInterval txTime = (tx.timestamp > 1) ? tx.timestamp : now;
    NSDateFormatter *desiredFormatter = (txTime > year) ? monthDayHourFormatter : yearMonthDayHourFormatter;
    
    date = [desiredFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:txTime]];
    if (tx.blockHeight != TX_UNCONFIRMED) self.txDates[uint256_obj(tx.txHash)] = date;
    return date;
}

- (IBAction)scanQR:(id)sender
{
    //TODO: show scanner in settings rather than dismissing
    UINavigationController *nav = (id)self.navigationController.presentingViewController;
    
    nav.view.alpha = 0.0;
    
    [nav dismissViewControllerAnimated:NO completion:^{
      //  [(id)((BTCRootViewController *)nav.viewControllers.firstObject).sendViewController scanQR:nil];
        [UIView animateWithDuration:0.1 delay:1.5 options:0 animations:^{ nav.view.alpha = 1.0; } completion:nil];
    }];
}

- (IBAction)goSettings:(id)sender {
//    BTCSettingsViewController *sett = [BTCSettingsViewController new];
//    [self presentViewController:sett animated:YES completion:^{
//        //none
//    }];
}

- (void)ping{
    // none
    
}


@end
