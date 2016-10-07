//
//  BTCReceiveViewController.m
//  BTCWallet
//
//  Created by Admin on 8/18/16.
//

#import "BTCReceiveViewController.h"
#import "BTCPaymentRequest.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"
#import "BTCTransaction.h"
#import "BTCAppGroupConstants.h"
#import "UIImage+Utils.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "BTCBubbleView.h"
#import <MessageUI/MessageUI.h>
#import "BTCSideMenuViewController.h"

#import "BTCAnimation.h"


#define QR_IMAGE_FILE [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"qr.png"]

@interface BTCReceiveViewController ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, BTCNumberViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *btcQrImage;
@property (strong, nonatomic) IBOutlet UITextView *btcTextView;

@property (nonatomic, strong) UIImage *qrImage;
@property (nonatomic, strong) NSUserDefaults *groupDefs;
@property (strong, nonatomic) IBOutlet UILabel *amountLabel;
@property (nonatomic, strong) id balanceObserver, txStatusObserver;
@property (strong, nonatomic) IBOutlet UIButton *amountButton;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation BTCReceiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addLeftMenuButtonWithImage:[UIImage imageNamed:@"menu_icon"]];
    self.title = [NSLocalizedString(@"receive", nil) capitalizedString];
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    BTCPaymentRequest *req;
    
    self.groupDefs = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_ID];
    req = (_paymentRequest) ? _paymentRequest :
    [BTCPaymentRequest requestWithString:[self.groupDefs stringForKey:APP_GROUP_RECEIVE_ADDRESS_KEY]];
    
    if (req.isValid) {
        if (! _qrImage) {
            _qrImage = [[UIImage imageWithContentsOfFile:QR_IMAGE_FILE] resize:self.btcQrImage.bounds.size
                                                      withInterpolationQuality:kCGInterpolationNone];;
        }
        
        self.btcQrImage.image = _qrImage;
        self.btcTextView.text = req.paymentAddress;
    }
    else self.btcTextView.text = @"";
    
    if (req.amount > 0) {
        self.amountButton.hidden = YES;
        
        self.amountLabel.text = [NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:req.amount],
                           [manager localCurrencyStringForAmount:req.amount]];
        
        NSString *btnTitle = [NSLocalizedString(@"share", nil) capitalizedString];
        UIBarButtonItem *shareBtn = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStylePlain target:self action:@selector(sendWithEmail:)];
        shareBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItem = shareBtn;
    }else {
        NSString *btnTitle = [NSLocalizedString(@"share", nil) capitalizedString];
        UIBarButtonItem *shareBtn = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStylePlain target:self action:@selector(sendWithEmail:)];
        shareBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
        
        btnTitle = [NSLocalizedString(@"amount", nil) capitalizedString];
        UIBarButtonItem *amountBtn = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStylePlain target:self action:@selector(requestAmount:)];
        amountBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
        
        self.navigationItem.rightBarButtonItems = @[amountBtn, shareBtn];
    }
    
  //  self.addressButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self updateAddress];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
}

- (void)updateAddress
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BTCWalletManager *manager = [BTCWalletManager sharedInstance];
        BTCPaymentRequest *req = self.paymentRequest;
        UIImage *image = [UIImage imageWithQRCodeData:req.data color:[CIColor colorWithRed:0.0 green:0.0 blue:0.0]];
        
        self.qrImage = [image resize:(self.btcQrImage ? self.btcQrImage.bounds.size : CGSizeMake(250.0, 250.0))
            withInterpolationQuality:kCGInterpolationNone];
        
        if (req.amount == 0) {
            if (req.isValid) {
                [self.groupDefs setObject:req.data forKey:APP_GROUP_REQUEST_DATA_KEY];
                [self.groupDefs setObject:self.paymentAddress forKey:APP_GROUP_RECEIVE_ADDRESS_KEY];
                [UIImagePNGRepresentation(image) writeToFile:QR_IMAGE_FILE atomically:YES];
            }
            else {
                [self.groupDefs removeObjectForKey:APP_GROUP_REQUEST_DATA_KEY];
                [self.groupDefs removeObjectForKey:APP_GROUP_RECEIVE_ADDRESS_KEY];
                [[NSFileManager defaultManager] removeItemAtPath:QR_IMAGE_FILE error:nil];
            }
            
            [self.groupDefs synchronize];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.btcQrImage.image = self.qrImage;
            self.btcTextView.text = self.paymentAddress;
            
            if (req.amount > 0) {
                self.amountLabel.text = [NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:req.amount],
                                   [manager localCurrencyStringForAmount:req.amount]];
                
                if (! self.balanceObserver) {
                    self.balanceObserver =
                    [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletBalanceChangedNotification
                                                                      object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                                          [self checkRequestStatus];
                                                                      }];
                }
                
                if (! self.txStatusObserver) {
                    self.txStatusObserver =
                    [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerTxStatusNotification
                                                                      object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                                          [self checkRequestStatus];
                                                                      }];
                }
            }
        });
    });
}

- (void)checkRequestStatus
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    BTCPaymentRequest *req = self.paymentRequest;
    uint64_t total = 0, fuzz = [manager amountForLocalCurrencyString:[manager localCurrencyStringForAmount:1]]*2;
    
    if (! [manager.wallet addressIsUsed:self.paymentAddress]) return;
    
    for (BTCTransaction *tx in manager.wallet.allTransactions) {
        if ([tx.outputAddresses containsObject:self.paymentAddress]) continue;
        if (tx.blockHeight == TX_UNCONFIRMED &&
            [[BTCPeerManager sharedInstance] relayCountForTransaction:tx.txHash] < PEER_MAX_CONNECTIONS) continue;
        total += [manager.wallet amountReceivedFromTransaction:tx];
        
        if (total + fuzz >= req.amount) {
            UIView *view = self.navigationController.presentingViewController.view;
            
            [self done:nil];
            [view addSubview:[[[BTCBubbleView viewWithText:[NSString
                                                           stringWithFormat:NSLocalizedString(@"received %@ (%@)", nil), [manager stringForAmount:total],
                                                           [manager localCurrencyStringForAmount:total]]
                                                   center:CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2)] popIn] popOutAfterDelay:3.0]];
            break;
        }
    }
}

- (BTCPaymentRequest *)paymentRequest
{
    if (_paymentRequest) return _paymentRequest;
    return [BTCPaymentRequest requestWithString:self.paymentAddress];
}

- (NSString *)paymentAddress
{
    if (_paymentRequest) return _paymentRequest.paymentAddress;
    return [BTCWalletManager sharedInstance].wallet.receiveAddress;
}

- (IBAction)done:(id)sender
{
    //[BTCAnimation dismissControllerFromMain:self direction:BTCAnimationDirectionLeft];
}


#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BTCAmountViewControllerDelegate

- (void)numberViewController:(BTCNumberViewController *)numberViewController selectedAmount:(uint64_t)amount{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (amount < manager.wallet.minOutputAmount) {
        [[[UIAlertView alloc] initWithTitle:@"amount too small"
                                    message:[NSString stringWithFormat:@"bitcoin payments can't be less than %@",
                                             [manager stringForAmount:manager.wallet.minOutputAmount]]
                                   delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        return;
    }
    
    BTCReceiveViewController *receiveController = [BTCReceiveViewController new];
    
    receiveController.paymentRequest = self.paymentRequest;
    receiveController.paymentRequest.amount = amount;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:receiveController];
    [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
    [numberViewController dismissViewControllerAnimated:YES completion:nil];
//    [numberViewController presentViewController:receiveController animated:YES completion:^{
//        //nil
//    }];
}

- (IBAction)requestAmount:(id)sender {
    BTCNumberViewController * contr = [BTCNumberViewController new];
    contr.delegate = self;
    [self presentViewController:contr animated:YES completion:nil];
}

- (IBAction)sendWithEmail:(id)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeController = [MFMailComposeViewController new];
        
        composeController.subject = @"Bitcoin address";
        [composeController setMessageBody:self.paymentRequest.string isHTML:NO];
        [composeController addAttachmentData:UIImagePNGRepresentation(self.btcQrImage.image) mimeType:@"image/png"
                                    fileName:@"qr.png"];
        composeController.mailComposeDelegate = self;
        [self.navigationController presentViewController:composeController animated:YES completion:nil];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"email not configured", nil) delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
    }
}

- (IBAction)exit:(id)sender {
   // [BTCAnimation dismissControllerFromMain:self direction:BTCAnimationDirectionLeft];
   ///*
//    if (self.amountLabel.text.length > 0) {
//        [BTCAnimation dismissControllerFromMain:self.presentingViewController.presentingViewController direction:BTCAnimationDirectionLeft];
//        //[self.parentViewController.parentViewController dismissViewControllerAnimated:YES completion:nil];
//       // [self.presentingViewController.presentingViewController performSelector:@selector(exit:) withObject:nil];
//    }else{
//        [BTCAnimation dismissControllerFromMain:self direction:BTCAnimationDirectionLeft];
//    }
    // */
}

- (IBAction)resetQR:(id)sender {
    self.paymentRequest = nil;
    [self updateAddress];
}


@end
