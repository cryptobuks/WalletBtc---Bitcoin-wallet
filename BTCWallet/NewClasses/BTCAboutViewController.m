//
//  BTCAboutViewController.m
//  BTCWallet
//
//  Created by Admin on 8/23/16.
//

#import "BTCAboutViewController.h"
#import "BTCSideMenuViewController.h"

@interface BTCAboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation BTCAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self addLeftMenuButtonWithImage:[UIImage imageNamed:@"menu_icon"]];
    self.title = [NSLocalizedString(@"about", nil) capitalizedString];
    
    self.versionLabel.text = [NSString stringWithFormat:@"v %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
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
- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

@end
