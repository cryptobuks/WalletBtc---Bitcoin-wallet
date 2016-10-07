//
//  BTCNumberViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCNumberViewController.h"
#import "BTCPaymentRequest.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"
#import "BTCTransaction.h"

@interface BTCNumberViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *btcField;
@property (strong, nonatomic) IBOutlet UITextField *localField;

@property (strong, nonatomic) IBOutlet UILabel *toDynamic;

@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic, assign) uint64_t amount;
@end

@implementation BTCNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated{
    if (_to.length > 0) {
        [_doneButton setTitle:@"Pay" forState:UIControlStateNormal];
        _toDynamic.text = [NSString stringWithFormat:@"to:%@", _to];
    }else{
        [_doneButton setTitle:@"Done" forState:UIControlStateNormal];
        _toDynamic.text = @"";
    }
}

- (void)viewDidLayoutSubviews{
    self.doneButton.layer.masksToBounds = YES;
    self.doneButton.layer.cornerRadius = self.doneButton.bounds.size.height / 2.0;
    self.doneButton.backgroundColor = [UIColor clearColor];
    self.doneButton.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.doneButton.layer.borderWidth = 1.0;
    
    self.cancelButton.layer.masksToBounds = YES;
    self.cancelButton.layer.cornerRadius = self.cancelButton.bounds.size.height / 2.0;
    self.cancelButton.backgroundColor = [UIColor clearColor];
    self.cancelButton.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.cancelButton.layer.borderWidth = 1.0;
    
    self.btcField.superview.layer.masksToBounds = YES;
    self.btcField.superview.layer.cornerRadius = self.btcField.superview.bounds.size.height / 2.0;
    self.btcField.superview.backgroundColor = [UIColor whiteColor];
    self.btcField.superview.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.btcField.superview.layer.borderWidth = 1.0;
    
    self.localField.superview.layer.masksToBounds = YES;
    self.localField.superview.layer.cornerRadius = self.localField.superview.bounds.size.height / 2.0;
    self.localField.superview.backgroundColor = [UIColor whiteColor];
    self.localField.superview.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.localField.superview.layer.borderWidth = 1.0;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.btcField becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateSecondLabel
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    if (self.btcField.isFirstResponder) {
        uint64_t amount = [manager amountForString:self.btcField.text];
        self.localField.text = [manager localCurrencyStringForAmount:amount];
    }else{
        uint64_t amount = [manager amountForLocalCurrencyString:self.localField.text];
        self.btcField.text = [manager stringForAmount:amount];
    }
}

- (void) textFieldDidBeginEditing:(UITextField *)textField{
    [self updateSecondLabel];
    
    textField.text = @"";
    
    textField.superview.layer.shadowColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    textField.superview.layer.shadowOpacity = 1.0;
    textField.superview.layer.shadowRadius = 2.0;
    textField.superview.layer.masksToBounds = NO;
    textField.superview.layer.shadowOffset = CGSizeMake(0, 1.0);
}

- (void) textFieldDidEndEditing:(UITextField *)textField{
    textField.superview.layer.shadowOpacity = 0.0;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSNumberFormatter *numberFormatter = (textField.tag) ? manager.localFormat : manager.format;
    [numberFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSUInteger decimalLoc = [textField.text rangeOfString:numberFormatter.currencyDecimalSeparator].location;
    NSUInteger minimumFractionDigits = numberFormatter.minimumFractionDigits;
    NSString *textVal = textField.text, *zeroStr = nil;
    NSDecimalNumber *num;
    
    if (! textVal) textVal = @"";
    numberFormatter.minimumFractionDigits = 0;
    zeroStr = [numberFormatter stringFromNumber:@0];
    
    if (string.length == 0) { // delete button
        textVal = [textVal stringByReplacingCharactersInRange:range withString:string];
        
        if (range.location <= decimalLoc) { // deleting before the decimal requires reformatting
            textVal = [numberFormatter stringFromNumber:[numberFormatter numberFromString:textVal]];
        }
        
        if (! textVal || [textVal isEqual:zeroStr]) textVal = @""; // check if we are left with a zero amount
    }
    else if ([string isEqual:numberFormatter.currencyDecimalSeparator] || [string isEqualToString:@","]) {// decimal point button
        if ([string isEqualToString:@","]) {
            string = numberFormatter.currencyDecimalSeparator;
        }
        if (decimalLoc == NSNotFound && numberFormatter.maximumFractionDigits > 0) {
            textVal = (textVal.length == 0) ? [zeroStr stringByAppendingString:string] :
            [textVal stringByReplacingCharactersInRange:range withString:string];
        }
    }
    else { // digit button
        // check for too many digits after the decimal point
        if (range.location > decimalLoc && range.location - decimalLoc > numberFormatter.maximumFractionDigits) {
            numberFormatter.minimumFractionDigits = numberFormatter.maximumFractionDigits;
            num = [NSDecimalNumber decimalNumberWithDecimal:[numberFormatter numberFromString:textVal].decimalValue];
            num = [num decimalNumberByMultiplyingByPowerOf10:1];
            num = [num decimalNumberByAdding:[[NSDecimalNumber decimalNumberWithString:string]
                                              decimalNumberByMultiplyingByPowerOf10:-numberFormatter.maximumFractionDigits]];
            textVal = [numberFormatter stringFromNumber:num];
            if (! [numberFormatter numberFromString:textVal]) textVal = nil;
        }
        else if (textVal.length == 0 && [string isEqual:@"0"]) { // if first digit is zero, append decimal point
            textVal = [zeroStr stringByAppendingString:numberFormatter.currencyDecimalSeparator];
        }
        else if (range.location > decimalLoc && [string isEqual:@"0"]) { // handle multiple zeros after decimal point
            textVal = [textVal stringByReplacingCharactersInRange:range withString:string];
        }
        else {
            NSRange rangeedit;
           // if (textVal.length > 0) {
          //      NSRange numberrange = [textVal rangeOfString:[NSString stringWithFormat:@"%g", [textVal floatValue]]];
           //     rangeedit.location = numberrange.location + numberrange.length;
           //     rangeedit.length = range.length;
          //  }else{
                rangeedit = range;
         //   }
            
            textVal = [numberFormatter stringFromNumber:[numberFormatter numberFromString:[textVal
                                                                                           stringByReplacingCharactersInRange:rangeedit withString:string]]];
        }
    }
    
    if (textVal) textField.text = textVal;
    numberFormatter.minimumFractionDigits = minimumFractionDigits;
    if (textVal.length > 0 && textField.placeholder.length > 0) textField.placeholder = nil;
    
    if (textVal.length == 0 && textField.placeholder.length == 0) {
        textField.placeholder = (textField.tag) ? [manager localCurrencyStringForAmount:0] : [manager stringForAmount:0];
    }
    
    
    
    // self.swapRightLabel.hidden = YES;
    textField.hidden = NO;
    [self updateSecondLabel];
    
    return NO;
}

- (IBAction)pay:(id)sender {
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    self.amount = [manager amountForString:self.btcField.text];
    
    if (self.amount == 0){
        return;
    }
    if ([self.delegate respondsToSelector:@selector(numberViewController:selectedAmount:)]) {
        [self.delegate numberViewController:self selectedAmount:self.amount];
    }
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //none
    }];
}



@end
