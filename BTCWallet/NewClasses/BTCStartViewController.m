//
//  BTCStartViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCStartViewController.h"
#import "BTCWalletManager.h"
#import "BTCKeyViewController.h"

#import "BTCRestoreViewController.h"
#import "BTCAnimation.h"

@interface BTCStartViewController ()
@property (nonatomic, strong) BTCKeyViewController *seedNav;

@property (strong, nonatomic) IBOutlet UIButton *createWalletButton;
@property (strong, nonatomic) IBOutlet UIButton *recoverWaletButton;
@end

@implementation BTCStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews{
    self.createWalletButton.titleLabel.numberOfLines = 2.0;
    self.createWalletButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.createWalletButton.layer.masksToBounds = YES;
    self.createWalletButton.layer.cornerRadius = self.createWalletButton.bounds.size.height / 2.0;
    self.createWalletButton.backgroundColor = [UIColor clearColor];
    self.createWalletButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.createWalletButton.layer.borderWidth = 1.0;
    
    self.recoverWaletButton.titleLabel.numberOfLines = 2.0;
    self.recoverWaletButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.recoverWaletButton.layer.masksToBounds = YES;
    self.recoverWaletButton.layer.cornerRadius = self.recoverWaletButton.bounds.size.height / 2.0;
    self.recoverWaletButton.backgroundColor = [UIColor clearColor];
    self.recoverWaletButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.recoverWaletButton.layer.borderWidth = 1.0;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (! [BTCWalletManager sharedInstance].noWallet) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)newWallet:(id)sender {
    self.seedNav = [BTCKeyViewController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.seedNav];
     [BTCAnimation presentViewController:navigation onController:self direction:BTCAnimationDirectionTop];
}

- (IBAction)recoverWallet:(id)sender {
    BTCRestoreViewController *contr = [[BTCRestoreViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:contr];
    [BTCAnimation presentViewController:navigation onController:self direction:BTCAnimationDirectionTop];
}

@end
