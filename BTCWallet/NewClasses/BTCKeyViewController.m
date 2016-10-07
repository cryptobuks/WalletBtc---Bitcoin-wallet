//
//  BTCKeyViewController.m
//  BTCWallet
//
//  Created by Admin on 8/16/16.
//

#import "BTCKeyViewController.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"
#import "NSMutableData+Bitcoin.h"

@interface BTCKeyViewController ()
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) NSString *seedPhrase;
@property (nonatomic, readonly) BOOL authSuccess;
@end

@implementation BTCKeyViewController

//init
- (instancetype)customInit
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (manager.noWallet) {
        self.seedPhrase = [manager generateRandomSeed];
        [[BTCPeerManager sharedInstance] connect];
    }
    else self.seedPhrase = manager.seedPhrase; // this triggers authentication request
    
    if (self.seedPhrase.length > 0) _authSuccess = YES;
    
    return self;
}

- (instancetype)init
{
    if (! (self = [super init])) return nil;
    return [self customInit];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (! (self = [super initWithCoder:aDecoder])) return nil;
    return [self customInit];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (! (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) return nil;
    return [self customInit];
}

//

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.text = self.seedPhrase;
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.layer.cornerRadius = 5.0;
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0].CGColor;
    self.textView.textColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    doneBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    
    self.navigationItem.leftBarButtonItem = doneBtn;
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (NSString*)seedPhrase{
//    return <#expression#>
//}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //none
    }];
}

@end
