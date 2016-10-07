//
//  BTCSendViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCSendViewController.h"
#import "BTCCameraViewController.h"

#import "BTCBubbleView.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"
#import "BTCPaymentRequest.h"
#import "BTCPaymentProtocol.h"
#import "BTCKey.h"
#import "BTCTransaction.h"
#import "NSString+Bitcoin.h"
#import "NSMutableData+Bitcoin.h"
#import "NSData+Bitcoin.h"

#import "BTCNumberViewController.h"
#import "BTCCameraViewController.h"
#import "BTCMainViewController.h"
#import "BTCSideMenuViewController.h"
#import "BTCAppDelegate.h"

#import "BTCAnimation.h"

#define SCAN_TIP      @"Scan someone else's QR code to get their bitcoin address. "\
"You can send a payment to anyone with an address."
#define CLIPBOARD_TIP @"Bitcoin addresses can also be copied to the clipboard. "\
"A bitcoin address always starts with '1' or '3'."

#define LOCK @"\xF0\x9F\x94\x92" // unicode lock symbol U+1F512 (utf-8)
#define REDX @"\xE2\x9D\x8C"     // unicode cross mark U+274C, red x emoji (utf-8)
#define NBSP @"\xC2\xA0"         // no-break space (utf-8)

static NSString *sanitizeString(NSString *s)
{
    NSMutableString *sane = [NSMutableString stringWithString:(s) ? s : @""];
    
    CFStringTransform((CFMutableStringRef)sane, NULL, kCFStringTransformToUnicodeName, NO);
    return sane;
}

@interface BTCSendViewController ()<BTCNumberViewControllerDelegate, BTCCameraViewControllerDelegate>

@property (nonatomic, assign) BOOL clearClipboard, useClipboard, showBalance, canChangeAmount;
@property (nonatomic, strong) BTCTransaction *sweepTx;
@property (nonatomic, strong) BTCPaymentProtocolRequest *request;
@property (nonatomic, strong) NSURL *url, *callback;
@property (nonatomic, assign) uint64_t amount;
@property (nonatomic, strong) NSString *okAddress, *okIdentity;
@property (nonatomic, strong) id clipboardObserver;

@property (strong, nonatomic) IBOutlet UIButton *scanQrButton;
@property (strong, nonatomic) IBOutlet UIButton *payAddressButton;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) UIViewController *mainController;

@end

@implementation BTCSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addLeftMenuButtonWithImage:[UIImage imageNamed:@"menu_icon"]];
    self.title = [NSLocalizedString(@"send", nil) capitalizedString];
    
    [self updateClipboardText];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self cancel:nil];
    
   
}

- (UIViewController *)mainController{
    BTCAppDelegate *delegate = (BTCAppDelegate*)[UIApplication sharedApplication].delegate;
    return delegate.main;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.scanQrButton.layer.masksToBounds = YES;
    self.scanQrButton.layer.cornerRadius = self.scanQrButton.bounds.size.height / 2.0;
    self.scanQrButton.backgroundColor = [UIColor clearColor];
    self.scanQrButton.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.scanQrButton.layer.borderWidth = 1.0;
    
    self.payAddressButton.layer.masksToBounds = YES;
    self.payAddressButton.layer.cornerRadius = self.payAddressButton.bounds.size.height / 2.0;
    self.payAddressButton.backgroundColor = [UIColor clearColor];
    self.payAddressButton.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.payAddressButton.layer.borderWidth = 1.0;
    
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.layer.cornerRadius = 5.0;
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.textView.textColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)camera:(BTCCameraViewController *)cam didScanAddress:(NSString *)address{
    BTCPaymentRequest *request = [BTCPaymentRequest requestWithString:address];
   // if ([BTCBitID isBitIDURL:request.url]) {
         if (1+1==3) {
      //  [cam stop];
     //   [self.navigationController dismissViewControllerAnimated:YES completion:^{
     //       [self handleBitIDURL:request.url];
     //       [cam errorScan];
     //   }];
    } else if (request.isValid || [address isValidBitcoinPrivateKey] || [address isValidBitcoinBIP38Key] ||
               (request.r.length > 0 && [request.scheme isEqual:@"bitcoin"])) {
        [cam scanDone];
        
        if (request.r.length > 0) { // start fetching payment protocol request right away
            [BTCPaymentRequest fetch:request.r timeout:5.0
                         completion:^(BTCPaymentProtocolRequest *req, NSError *error) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (error) request.r = nil;
                                 
                                 if (error && ! request.isValid) {
                                     [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                                                 message:error.localizedDescription delegate:nil
                                                       cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
                                     [self cancel:nil];
                                     // continue here and handle the invalid request inside confirmRequest:
                                 }
                                 
                                 [self dismissViewControllerAnimated:YES completion:^{
                                     [cam errorScan];
                                 }];
                                 
                                 if (error) {
                                     [self confirmRequest:request]; // payment protocol fetch failed, so use standard request
                                 }
                                 else {
                                     [self confirmProtocolRequest:req];
                                 }
                             });
                         }];
        }
        else { // standard non payment protocol request
            [self dismissViewControllerAnimated:YES completion:^{
                [cam errorScan];
                if (request.amount > 0) self.canChangeAmount = YES;
            }];
            
            if (request.isValid && self.showBalance) {
             //   [self showBalance:request.paymentAddress];
                [self cancel:nil];
            }
            else [self confirmRequest:request];
        }
    } else {
        [BTCPaymentRequest fetch:request.r timeout:5.0
                     completion:^(BTCPaymentProtocolRequest *req, NSError *error) { // check to see if it's a BIP73 url
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [NSObject cancelPreviousPerformRequestsWithTarget:cam selector:@selector(errorScan) object:nil];
                             
                             if (req) {
                                 [cam stop];
                                 [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                     [cam errorScan];
                                 }];
                                 
                                 [self confirmProtocolRequest:req];
                             }
                             else {                                 
                                 if (([request.scheme isEqual:@"bitcoin"] && request.paymentAddress.length > 1) ||
                                     [request.paymentAddress hasPrefix:@"1"] || [request.paymentAddress hasPrefix:@"3"]) {
                                     
                                 }
                                 
                                 [cam  performSelector:@selector(errorScan) withObject:nil afterDelay:0.35];
                             }
                         });
                     }];
    }
    
}

- (IBAction)cancel:(id)sender
{
    self.url = self.callback = nil;
    self.sweepTx = nil;
    self.amount = 0;
    self.okAddress = self.okIdentity = nil;
    self.clearClipboard = self.useClipboard = NO;
    self.canChangeAmount = self.showBalance = NO;
    self.scanQrButton.enabled = self.payAddressButton.enabled = YES;
    [self updateClipboardText];
}

- (void)updateClipboardText
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *str = [[UIPasteboard generalPasteboard].string
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *text = @"";
        UIImage *img = [UIPasteboard generalPasteboard].image;
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        NSCharacterSet *separators = [NSCharacterSet alphanumericCharacterSet].invertedSet;
        
        if (str) {
            [set addObject:str];
            [set addObjectsFromArray:[str componentsSeparatedByCharactersInSet:separators]];
        }
        
        if (img && &CIDetectorTypeQRCode) {
            @synchronized ([CIContext class]) {
                for (CIQRCodeFeature *qr in [[CIDetector detectorOfType:CIDetectorTypeQRCode context:[CIContext
                                                                                                      contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}] options:nil]
                                             featuresInImage:[CIImage imageWithCGImage:img.CGImage]]) {
                    [set addObject:[qr.messageString
                                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            }
        }
        
        for (NSString *s in set) {
            BTCPaymentRequest *req = [BTCPaymentRequest requestWithString:s];
            
            if ([req.paymentAddress isValidBitcoinAddress]) {
                text = (req.label.length > 0) ? sanitizeString(req.label) : req.paymentAddress;
                break;
            }
            else if ([s hasPrefix:@"bitcoin:"]) {
                text = sanitizeString(s);
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat textWidth = [text sizeWithAttributes:@{NSFontAttributeName:self.textView.font}].width + 12;
            
            self.textView.text = text;
         //   if (textWidth < self.clipboardButton.bounds.size.width ) textWidth = self.clipboardButton.bounds.size.width;
            if (textWidth > self.view.bounds.size.width - 16.0) textWidth = self.view.bounds.size.width - 16.0;
         //   self.clipboardXLeft.constant = (self.view.bounds.size.width - textWidth)/2.0;
            [self.textView scrollRangeToVisible:NSMakeRange(0, 0)];
        });
    });
}

- (void)confirmRequest:(BTCPaymentRequest *)request
{
    if (! request.isValid) {
        if ([request.paymentAddress isValidBitcoinPrivateKey] || [request.paymentAddress isValidBitcoinBIP38Key]) {
            [self confirmSweep:request.paymentAddress];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"not a valid bitcoin address"
                                        message:request.paymentAddress delegate:nil cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
            [self cancel:nil];
        }
    }
    else if (request.r.length > 0) { // payment protocol over HTTP
        [(id)self.mainController startActivityWithTimeout:20.0];
        
        [BTCPaymentRequest fetch:request.r timeout:20.0 completion:^(BTCPaymentProtocolRequest *req, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id)self.mainController stopActivityWithSuccess:(! error)];
                
                if (error && ! [request.paymentAddress isValidBitcoinAddress]) {
                    [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                                message:error.localizedDescription delegate:nil cancelButtonTitle:@"ok"
                                      otherButtonTitles:nil] show];
                    [self cancel:nil];
                }
                else [self confirmProtocolRequest:(error) ? request.protocolRequest : req];
            });
        }];
    }
    else [self confirmProtocolRequest:request.protocolRequest];
}

- (void)confirmProtocolRequest:(BTCPaymentProtocolRequest *)protoReq
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    BTCTransaction *tx = nil;
    uint64_t amount = 0, fee = 0;
    NSString *address = [NSString addressWithScriptPubKey:protoReq.details.outputScripts.firstObject];
    BOOL valid = protoReq.isValid, outputTooSmall = NO;
    
    if (! valid && [protoReq.errorMessage isEqual:@"request expired"]) {
        [[[UIAlertView alloc] initWithTitle:@"bad payment request" message:protoReq.errorMessage
                                   delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    
    
    if (self.amount == 0) {
        for (NSNumber *outputAmount in protoReq.details.outputAmounts) {
            if (outputAmount.unsignedLongLongValue > 0 && outputAmount.unsignedLongLongValue < TX_MIN_OUTPUT_AMOUNT) {
                outputTooSmall = YES;
            }
            amount += outputAmount.unsignedLongLongValue;
        }
    }
    else amount = self.amount;
    
    if ([manager.wallet containsAddress:address]) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:@"this payment address is already in your wallet"
                                   delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    else if (! [self.okAddress isEqual:address] && [manager.wallet addressIsUsed:address] &&
             [[UIPasteboard generalPasteboard].string isEqual:address]) {
        self.request = protoReq;
        self.okAddress = address;
        [[[UIAlertView alloc] initWithTitle:@"WARNING"
                                    message:@"\nADDRESS ALREADY USED\n\nbitcoin addresses are intended for single use only\n\n"
                                                              "re-use reduces privacy for both you and the recipient and can result in loss if "
                                                              "the recipient doesn't directly control the address"
                                   delegate:self cancelButtonTitle:nil
                          otherButtonTitles:@"ignore", @"cancel", nil] show];
        return;
    }
    else if (protoReq.errorMessage.length > 0 && protoReq.commonName.length > 0 &&
             ! [self.okIdentity isEqual:protoReq.commonName]) {
        self.request = protoReq;
        self.okIdentity = protoReq.commonName;
        [[[UIAlertView alloc] initWithTitle:@"payee identity isn't certified"
                                    message:protoReq.errorMessage delegate:self cancelButtonTitle:nil
                          otherButtonTitles:@"ignore", @"cancel", nil] show];
        return;
    }
    else if (amount == 0 || amount == UINT64_MAX) {
        BTCNumberViewController *number = [[BTCNumberViewController alloc] init];
        number.delegate = self;
        
        self.request = protoReq;
        
        if (protoReq.commonName.length > 0) {
            if (valid && ! [protoReq.pkiType isEqual:@"none"]) {
                number.to = [LOCK @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            }
            else if (protoReq.errorMessage.length > 0) {
                number.to = [REDX @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            }
            else number.to = sanitizeString(protoReq.commonName);
        }
        else number.to = address;
        
        [self presentViewController:number animated:YES completion:nil];
        return;
    }
    else if (amount < TX_MIN_OUTPUT_AMOUNT) {
        [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                    message:[NSString stringWithFormat:@"bitcoin payments can't be less than %@",
                                             [manager stringForAmount:TX_MIN_OUTPUT_AMOUNT]] delegate:nil
                          cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    else if (outputTooSmall) {
        [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                    message:[NSString stringWithFormat:@"bitcoin transaction outputs can't be less than %@",
                                                                                          [manager stringForAmount:TX_MIN_OUTPUT_AMOUNT]]
                                   delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    
    self.request = protoReq;
    
    if (self.amount == 0) {
        tx = [manager.wallet transactionForAmounts:protoReq.details.outputAmounts
                                   toOutputScripts:protoReq.details.outputScripts withFee:YES];
    }
    else {
        tx = [manager.wallet transactionForAmounts:@[@(self.amount)]
                                   toOutputScripts:@[protoReq.details.outputScripts.firstObject] withFee:YES];
    }
    
    if (tx) {
        amount = [manager.wallet amountSentByTransaction:tx] - [manager.wallet amountReceivedFromTransaction:tx];
        fee = [manager.wallet feeForTransaction:tx];
    }
    else {
        fee = [manager.wallet feeForTxSize:[manager.wallet transactionFor:manager.wallet.balance
                                                                       to:address withFee:NO].size];
        fee += (manager.wallet.balance - amount) % 100;
        amount += fee;
    }
    
    for (NSData *script in protoReq.details.outputScripts) {
        NSString *addr = [NSString addressWithScriptPubKey:script];
        
        if (! addr) addr = @"unrecognized address";
        if ([address rangeOfString:addr].location != NSNotFound) continue;
        address = [address stringByAppendingFormat:@"%@%@", (address.length > 0) ? @", " : @"", addr];
    }
    
    NSString *prompt = [self promptForAmount:amount fee:fee address:address name:protoReq.commonName
                                        memo:protoReq.details.memo isSecure:(valid && ! [protoReq.pkiType isEqual:@"none"])];
    
    // to avoid the frozen pincode keyboard bug, we need to make sure we're scheduled normally on the main runloop
    // rather than a dispatch_async queue
    CFRunLoopPerformBlock([[NSRunLoop mainRunLoop] getCFRunLoop], kCFRunLoopCommonModes, ^{
        [self confirmTransaction:tx withPrompt:prompt forAmount:amount];
    });
}

- (void)confirmTransaction:(BTCTransaction *)tx withPrompt:(NSString *)prompt forAmount:(uint64_t)amount
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    BOOL didAuth = manager.didAuthenticate;
    didAuth = YES;
    
    NSLog(@"++++++  max output = %lld",manager.wallet.maxOutputAmount);
    
    if (! tx) { // tx is nil if there were insufficient wallet funds
       // if (! manager.didAuthenticate) [manager seedWithPrompt:prompt forAmount:amount];
        
       // if (manager.didAuthenticate) {
        if (1+1 == 2) {
            uint64_t fuzz = [manager amountForLocalCurrencyString:[manager localCurrencyStringForAmount:1]]*2;
            
            // if user selected an amount equal to or below wallet balance, but the fee will bring the total above the
            // balance, offer to reduce the amount to available funds minus fee
            if (self.amount <= manager.wallet.balance + fuzz && self.amount > 0) {
                int64_t amount = manager.wallet.maxOutputAmount;
                
                NSLog(@"++++++  max output = %lld",manager.wallet.maxOutputAmount);
                
                if (amount > 0 && amount < self.amount) {
                    [[[UIAlertView alloc]
                      initWithTitle:@"insufficient funds for bitcoin network fee"
                      message:[NSString stringWithFormat:@"reduce payment amount by\n%@ (%@)?",
                               [manager stringForAmount:self.amount - amount],
                               [manager localCurrencyStringForAmount:self.amount - amount]] delegate:self
                      cancelButtonTitle:@"cancel"
                      otherButtonTitles:[NSString stringWithFormat:@"%@ (%@)",
                                         [manager stringForAmount:amount - self.amount],
                                         [manager localCurrencyStringForAmount:amount - self.amount]], nil] show];
                    self.amount = amount;
                }
                else {
                    [[[UIAlertView alloc]
                      initWithTitle:@"insufficient funds for bitcoin network fee" message:nil
                      delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
                }
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"insufficient funds" message:nil
                                           delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
            }
        }
        else [self cancelOrChangeAmount];
        
        if (! didAuth) manager.didAuthenticate = NO;
        return;
    }
    
    if (! [manager.wallet signTransaction:tx withPrompt:prompt]) {
        [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                    message:@"error signing bitcoin transaction" delegate:nil
                          cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
    }
    
    if (! didAuth) manager.didAuthenticate = NO;
    
    if (! tx.isSigned) { // user canceled authentication
        [self cancelOrChangeAmount];
        return;
    }
    
    if (self.navigationController.topViewController != self.mainController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    __block BOOL waiting = YES, sent = NO;
    
    [(id)self.mainController startActivityWithTimeout:30.0];
    
    [[BTCPeerManager sharedInstance] publishTransaction:tx completion:^(NSError *error) {
        if (error) {
            if (! waiting && ! sent) {
                [[[UIAlertView alloc] initWithTitle:@"couldn't make payment"
                                            message:error.localizedDescription delegate:nil cancelButtonTitle:@"ok"
                                  otherButtonTitles:nil] show];
                [(id)self.mainController stopActivityWithSuccess:NO];
                [self cancel:nil];
            }
        }
        else if (! sent) { //TODO: show full screen sent dialog with tx info, "you sent b10,000 to bob"
            sent = YES;
            tx.timestamp = [NSDate timeIntervalSinceReferenceDate];
            [manager.wallet registerTransaction:tx];
            [self.view addSubview:[[[BTCBubbleView viewWithText:@"sent!"
                                                        center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
                                   popOutAfterDelay:2.0]];
            [(id)self.mainController stopActivityWithSuccess:YES];
            [(id)self.mainController ping];
            
            if (self.callback) {
                self.callback = [NSURL URLWithString:[self.callback.absoluteString stringByAppendingFormat:@"%@txid=%@",
                                                      (self.callback.query.length > 0) ? @"&" : @"?",
                                                      [NSString hexWithData:[NSData dataWithBytes:tx.txHash.u8
                                                                                           length:sizeof(UInt256)].reverse]]];
                [[UIApplication sharedApplication] openURL:self.callback];
            }
            
            [self reset:nil];
        }
        
        waiting = NO;
    }];
    
    if (self.request.details.paymentURL.length > 0) {
        uint64_t refundAmount = 0;
        NSMutableData *refundScript = [NSMutableData data];
        
        [refundScript appendScriptPubKeyForAddress:manager.wallet.receiveAddress];
        
        for (NSNumber *amt in self.request.details.outputAmounts) {
            refundAmount += amt.unsignedLongLongValue;
        }
        
        BTCPaymentProtocolPayment *payment =
        [[BTCPaymentProtocolPayment alloc] initWithMerchantData:self.request.details.merchantData
                                                  transactions:@[tx] refundToAmounts:@[@(refundAmount)] refundToScripts:@[refundScript] memo:nil];
        
        NSLog(@"posting payment to: %@", self.request.details.paymentURL);
        
        [BTCPaymentRequest postPayment:payment to:self.request.details.paymentURL timeout:20.0
                           completion:^(BTCPaymentProtocolACK *ack, NSError *error) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [(id)self.mainController stopActivityWithSuccess:(! error)];
                                   
                                   if (error) {
                                       if (! waiting && ! sent) {
                                           [[[UIAlertView alloc] initWithTitle:@"" message:error.localizedDescription delegate:nil
                                                             cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
                                           [(id)self.mainController stopActivityWithSuccess:NO];
                                           [self cancel:nil];
                                       }
                                   }
                                   else if (! sent) {
                                       sent = YES;
                                       tx.timestamp = [NSDate timeIntervalSinceReferenceDate];
                                       [manager.wallet registerTransaction:tx];
                                       [self.view addSubview:[[[BTCBubbleView
                                                                viewWithText:(ack.memo.length > 0 ? ack.memo : @"sent!")
                                                                center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
                                                              popOutAfterDelay:(ack.memo.length > 0 ? 3.0 : 2.0)]];
                                       [(id)self.mainController stopActivityWithSuccess:YES];
                                       [(id)self.mainController ping];
                                       
                                       if (self.callback) {
                                           self.callback = [NSURL URLWithString:[self.callback.absoluteString
                                                                                 stringByAppendingFormat:@"%@txid=%@",
                                                                                 (self.callback.query.length > 0) ? @"&" : @"?",
                                                                                 [NSString hexWithData:[NSData dataWithBytes:tx.txHash.u8
                                                                                                                      length:sizeof(UInt256)].reverse]]];
                                           [[UIApplication sharedApplication] openURL:self.callback];
                                       }
                                       
                                       [self reset:nil];
                                   }
                                   
                                   waiting = NO;
                               });
                           }];
    }
    else waiting = NO;
}

- (void)confirmSweep:(NSString *)privKey
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (! [privKey isValidBitcoinPrivateKey] && ! [privKey isValidBitcoinBIP38Key]) return;
    
    BTCBubbleView *statusView = [BTCBubbleView viewWithText:@"checking private key balance..."
                                                   center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)];
    
    statusView.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    statusView.customView = [[UIActivityIndicatorView alloc]
                             initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [(id)statusView.customView startAnimating];
    [self.view addSubview:[statusView popIn]];
    
    [manager sweepPrivateKey:privKey withFee:YES completion:^(BTCTransaction *tx, uint64_t fee, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [statusView popOut];
            
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"" message:error.localizedDescription delegate:self
                                  cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
                [self cancel:nil];
            }
            else if (tx) {
                uint64_t amount = fee;
                
                for (NSNumber *amt in tx.outputAmounts) amount += amt.unsignedLongLongValue;
                self.sweepTx = tx;
                
                NSString *alertFmt = @"Send %@ (%@) from this private key into your wallet? "
                                                       "The bitcoin network will receive a fee of %@ (%@).";
                NSString *alertMsg = [NSString stringWithFormat:alertFmt, [manager stringForAmount:amount],
                                      [manager localCurrencyStringForAmount:amount], [manager stringForAmount:fee],
                                      [manager localCurrencyStringForAmount:fee]];
                [[[UIAlertView alloc] initWithTitle:@"" message:alertMsg delegate:self
                                  cancelButtonTitle:@"cancel"
                                  otherButtonTitles:[NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:amount],
                                                     [manager localCurrencyStringForAmount:amount]], nil] show];
            }
            else [self cancel:nil];
        });
    }];
}



- (NSString *)promptForAmount:(uint64_t)amount fee:(uint64_t)fee address:(NSString *)address name:(NSString *)name
                         memo:(NSString *)memo isSecure:(BOOL)isSecure
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSString *prompt = (isSecure && name.length > 0) ? LOCK @" " : @"";
    
    //BUG: XXX limit the length of name and memo to avoid having the amount clipped
    if (! isSecure && self.request.errorMessage.length > 0) prompt = [prompt stringByAppendingString:REDX @" "];
    if (name.length > 0) prompt = [prompt stringByAppendingString:sanitizeString(name)];
    if (! isSecure && prompt.length > 0) prompt = [prompt stringByAppendingString:@"\n"];
    if (! isSecure || prompt.length == 0) prompt = [prompt stringByAppendingString:address];
    if (memo.length > 0) prompt = [prompt stringByAppendingFormat:@"\n\n%@", sanitizeString(memo)];
    prompt = [prompt stringByAppendingFormat:@"\n\n     amount %@ (%@)",
              [manager stringForAmount:amount - fee], [manager localCurrencyStringForAmount:amount - fee]];
    
    if (fee > 0) {
        prompt = [prompt stringByAppendingFormat:@"\nnetwork fee +%@ (%@)",
                  [manager stringForAmount:fee], [manager localCurrencyStringForAmount:fee]];
        prompt = [prompt stringByAppendingFormat:@"\n         total %@ (%@)",
                  [manager stringForAmount:amount], [manager localCurrencyStringForAmount:amount]];
    }
    
    return prompt;
}

- (void)cancelOrChangeAmount
{
    if (self.canChangeAmount && self.request && self.amount == 0) {
        [[[UIAlertView alloc] initWithTitle:@"change payment amount?"
                                    message:nil delegate:self cancelButtonTitle:@"cancel"
                          otherButtonTitles:@"change", nil] show];
        self.amount = UINT64_MAX;
    }
    else {
        /*
        [[[UIAlertView alloc] initWithTitle:@"Insufficient funds."
                                    message:nil delegate:self cancelButtonTitle:@"ok"
                          otherButtonTitles: nil] show];
            [self cancel:nil];
         */
    }
}

- (IBAction)reset:(id)sender
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    /*
    if (self.navigationController.topViewController != self.mainController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
     */
    
    if (self.clearClipboard) [UIPasteboard generalPasteboard].string = @"";
    self.request = nil;
    [self cancel:sender];
}

- (IBAction)scanQrCode:(id)sender {
    if (! [sender isEqual:self.scanQrButton]) self.showBalance = YES;
    [sender setEnabled:NO];
    
    
    BTCCameraViewController *camera = [BTCCameraViewController new];
    camera.delegate = self;
    
    
    [self presentViewController:camera animated:YES completion:^{
        //none
    }];
}

- (IBAction)payToAddress:(id)sender {
    
    NSString *str = [[UIPasteboard generalPasteboard].string
                     stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    UIImage *img = [UIPasteboard generalPasteboard].image;
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    NSCharacterSet *separators = [NSCharacterSet alphanumericCharacterSet].invertedSet;
    
    if (str) {
        [set addObject:str];
        [set addObjectsFromArray:[str componentsSeparatedByCharactersInSet:separators]];
    }
    
    if (img && &CIDetectorTypeQRCode) {
        @synchronized ([CIContext class]) {
            for (CIQRCodeFeature *qr in [[CIDetector detectorOfType:CIDetectorTypeQRCode
                                                            context:[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}]
                                                            options:nil] featuresInImage:[CIImage imageWithCGImage:img.CGImage]]) {
                [set addObject:[qr.messageString
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
        }
    }
    
    [sender setEnabled:NO];
    self.clearClipboard = YES;
    [self payFirstFromArray:set.array];
}

- (void)payFirstFromArray:(NSArray *)array
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSUInteger i = 0;
    
    for (NSString *str in array) {
        BTCPaymentRequest *req = [BTCPaymentRequest requestWithString:str];
        NSData *data = str.hexToData.reverse;
        
        i++;
        
        // if the clipboard contains a known txHash, we know it's not a hex encoded private key
        if (data.length == sizeof(UInt256) && [manager.wallet transactionForHash:*(UInt256 *)data.bytes]) continue;
        
        if ([req.paymentAddress isValidBitcoinAddress] || [str isValidBitcoinPrivateKey] ||
            [str isValidBitcoinBIP38Key] || (req.r.length > 0 && [req.scheme isEqual:@"bitcoin"])) {
            [self performSelector:@selector(confirmRequest:) withObject:req afterDelay:0.1];// delayed to show highlight
            return;
        }
        else if (req.r.length > 0) { // may be BIP73 url: https://github.com/bitcoin/bips/blob/master/bip-0073.mediawiki
            [BTCPaymentRequest fetch:req.r timeout:5.0 completion:^(BTCPaymentProtocolRequest *req, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) { // don't try any more BIP73 urls
                        [self payFirstFromArray:[array objectsAtIndexes:[array
                                                                         indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                                                                             return (idx >= i && ([obj hasPrefix:@"bitcoin:"] || ! [NSURL URLWithString:obj]));
                                                                         }]]];
                    }
                    else [self confirmProtocolRequest:req];
                });
            }];
            
            return;
        }
    }
    
    [[[UIAlertView alloc] initWithTitle:@""
                                message:NSLocalizedString(@"clipboard doesn't contain a valid bitcoin address", nil) delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
    [self performSelector:@selector(cancel:) withObject:self afterDelay:0.1];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [UIPasteboard generalPasteboard].string = textView.text;
   // [self updateClipboardText];
}

- (void)numberViewController:(BTCNumberViewController *)numberViewController selectedAmount:(uint64_t)amount{
    self.amount = amount;
    [self confirmProtocolRequest:self.request];
}

- (IBAction)exit:(id)sender {
//    [BTCAnimation dismissControllerFromMain:self direction:BTCAnimationDirectionRight];
   // [self dismissViewControllerAnimated:YES completion:^{
        //none
   // }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (buttonIndex == alertView.cancelButtonIndex || [title isEqual:NSLocalizedString(@"cancel", nil)]) {
        if (self.url) {
            self.clearClipboard = YES;
        }
        else [self cancelOrChangeAmount];
    }
    else if (self.sweepTx) {
        [(id)self.mainController startActivityWithTimeout:30];
        
        [[BTCPeerManager sharedInstance] publishTransaction:self.sweepTx completion:^(NSError *error) {
            [(id)self.mainController stopActivityWithSuccess:(! error)];
            
            if (error) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't sweep balance", nil)
                                            message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil] show];
                [self cancel:nil];
                return;
            }
            
            [self.view addSubview:[[[BTCBubbleView viewWithText:NSLocalizedString(@"swept!", nil)
                                                        center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)]
                                    popIn] popOutAfterDelay:2.0]];
            [self reset:nil];
        }];
    }
    else if (self.request) {
        [self confirmProtocolRequest:self.request];
    }
}


@end
