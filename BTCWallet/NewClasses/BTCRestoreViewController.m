//
//  BTCRestoreViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCRestoreViewController.h"
#import "BTCWalletManager.h"
#import "BTCMnemonic.h"
#import "BTCAddressEntity.h"
#import "NSMutableData+Bitcoin.h"
#import "NSString+Bitcoin.h"
#import "NSManagedObject+Sugar.h"
#import "BTCAnimation.h"

#define PHRASE_LENGTH 12

@interface BTCRestoreViewController ()<UITextViewDelegate>
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIView *topBar;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttomSpace;

@property (strong, nonatomic) IBOutlet UITextView *textView;
@end

@implementation BTCRestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.layer.cornerRadius = 5.0;
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.textView.textColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    // Do any additional setup after loading the view from its nib.
    
    NSString *btnTitle = [NSLocalizedString(@"main", nil) capitalizedString];
    
    UIBarButtonItem *mainBtn = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    mainBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    self.navigationItem.leftBarButtonItem = mainBtn;
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    
    // Get the size of the keyboard.
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    //Given size may not account for screen rotation
    int height = MIN(keyboardSize.height,keyboardSize.width);
    int width = MAX(keyboardSize.height,keyboardSize.width);
    
    self.buttomSpace.constant = height;
}

- (void)keyboardWasHidden{
    self.buttomSpace.constant = 0;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [self.textView becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if (![text isEqualToString:@"\n"]) {
        return YES;
    }
    
    if ([textView.text isEqualToString:@""]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSString *phrase = [manager.mnemonic cleanupPhrase:textView.text], *incorrect = nil;
    BOOL isLocal = YES, noWallet = manager.noWallet;
    
    if (! [textView.text hasPrefix:@"watch"] && ! [phrase isEqual:textView.text]) textView.text = phrase;
    phrase = [manager.mnemonic normalizePhrase:phrase];
    
    NSArray *a = CFBridgingRelease(CFStringCreateArrayBySeparatingStrings(SecureAllocator(), (CFStringRef)phrase,
                                                                          CFSTR(" ")));
    
    for (NSString *word in a) {
        if (! [manager.mnemonic wordIsLocal:word]) isLocal = NO;
        if ([manager.mnemonic wordIsValid:word]) continue;
        incorrect = word;
        break;
    }
    
    if ([phrase isEqual:@"wipe"]) { // shortcut word to force the wipe option to appear
        [self.textView resignFirstResponder];
        [self performSelector:@selector(wipeWithPhrase:) withObject:phrase afterDelay:0.0];
    }
    else if (incorrect && noWallet && [textView.text hasPrefix:@"watch"]) { // address list watch only wallet
        manager.seedPhrase = @"wipe";
        
        [[NSManagedObject context] performBlockAndWait:^{
            int32_t n = 0;
            
            for (NSString *s in [textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                                                     alphanumericCharacterSet].invertedSet]) {
                if (! [s isValidBitcoinAddress]) continue;
                
                BTCAddressEntity *e = [BTCAddressEntity managedObject];
                
                e.address = s;
                e.index = n++;
                e.internal = NO;
            }
        }];
        
        [NSManagedObject saveContext];
        textView.text = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (incorrect) {
        // textField.selectedTextRange = [textField.text.lowercaseString rangeOfString:incorrect];
        
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:[NSString stringWithFormat:@"\"%@\" is not a recovery phrase word",
                                             incorrect] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil]
         show];
    }
    else if (a.count != PHRASE_LENGTH) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:[NSString stringWithFormat:@"recovery phrase must have %d words",
                                             PHRASE_LENGTH] delegate:nil cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    else if (isLocal && ! [manager.mnemonic phraseIsValid:phrase]) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"bad recovery phrase" delegate:nil
                          cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
    }
    else if (! noWallet) {
        [self.textView resignFirstResponder];
        [self performSelector:@selector(wipeWithPhrase:) withObject:phrase afterDelay:0.0];
    }
    else {
        //TODO: offer the user an option to move funds to a new seed if their wallet device was lost or stolen
        manager.seedPhrase = phrase;
        textView.text = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    return NO;
}


- (BOOL)textViewShouldReturn:(UITextView *)textView{
    
    if ([textView.text isEqualToString:@""]) {
        [textView resignFirstResponder];
        return YES;
    }
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSString *phrase = [manager.mnemonic cleanupPhrase:textView.text], *incorrect = nil;
    BOOL isLocal = YES, noWallet = manager.noWallet;
    
    if (! [textView.text hasPrefix:@"watch"] && ! [phrase isEqual:textView.text]) textView.text = phrase;
    phrase = [manager.mnemonic normalizePhrase:phrase];
    
    NSArray *a = CFBridgingRelease(CFStringCreateArrayBySeparatingStrings(SecureAllocator(), (CFStringRef)phrase,
                                                                          CFSTR(" ")));
    
    for (NSString *word in a) {
        if (! [manager.mnemonic wordIsLocal:word]) isLocal = NO;
        if ([manager.mnemonic wordIsValid:word]) continue;
        incorrect = word;
        break;
    }
    
    if ([phrase isEqual:@"wipe"]) { // shortcut word to force the wipe option to appear
        [self.textView resignFirstResponder];
        [self performSelector:@selector(wipeWithPhrase:) withObject:phrase afterDelay:0.0];
    }
    else if (incorrect && noWallet && [textView.text hasPrefix:@"watch"]) { // address list watch only wallet
        manager.seedPhrase = @"wipe";
        
        [[NSManagedObject context] performBlockAndWait:^{
            int32_t n = 0;
            
            for (NSString *s in [textView.text componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                                                     alphanumericCharacterSet].invertedSet]) {
                if (! [s isValidBitcoinAddress]) continue;
                
                BTCAddressEntity *e = [BTCAddressEntity managedObject];
                
                e.address = s;
                e.index = n++;
                e.internal = NO;
            }
        }];
        
        [NSManagedObject saveContext];
        textView.text = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (incorrect) {
       // textField.selectedTextRange = [textField.text.lowercaseString rangeOfString:incorrect];
        
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:[NSString stringWithFormat:@"\"%@\" is not a recovery phrase word",
                                             incorrect] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil]
         show];
    }
    else if (a.count != PHRASE_LENGTH) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:[NSString stringWithFormat:@"recovery phrase must have %d words",
                                             PHRASE_LENGTH] delegate:nil cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    else if (isLocal && ! [manager.mnemonic phraseIsValid:phrase]) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"bad recovery phrase" delegate:nil
                          cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
    }
    else if (! noWallet) {
        [self.textView resignFirstResponder];
        [self performSelector:@selector(wipeWithPhrase:) withObject:phrase afterDelay:0.0];
    }
    else {
        //TODO: offer the user an option to move funds to a new seed if their wallet device was lost or stolen
        manager.seedPhrase = phrase;
        textView.text = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    return YES;
}

- (void)wipeWithPhrase:(NSString *)phrase
{    
    @autoreleasepool {
        BTCWalletManager *manager = [BTCWalletManager sharedInstance];
        
        if ([phrase isEqual:@"wipe"]) phrase = manager.seedPhrase; // this triggers authentication request
        
        if (phrase) {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"recovery phrase doesn't match"
                                       delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
        }
        else [self.textView becomeFirstResponder];
    }
}

- (IBAction)goBack:(id)sender {
    [BTCAnimation dismissControllerFromMain:self direction:BTCAnimationDirectionBottom];
  //  [self dismissViewControllerAnimated:YES completion:^{
        //none
  //  }];
}
- (IBAction)tapDetected:(id)sender {
    [self.textView resignFirstResponder];
}

@end
