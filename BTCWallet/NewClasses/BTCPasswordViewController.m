//
//  BTCPasswordViewController.m
//  BTCWallet
//
//  Created by Admin on 8/29/16.
//

#import "BTCPasswordViewController.h"
#import "BTCWalletManager.h"

@interface BTCPasswordViewController ()
@property (strong, nonatomic) IBOutlet UIView *circlesView;
@property (strong, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) NSString *passStr;
@property (strong, nonatomic) NSDate *errorDate;
@property (readwrite, nonatomic) int erCount;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@end

@implementation BTCPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    _erCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"erCount"];
    _errorDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateE"];
    self.passStr = @"";
    [self setButtons];
    
    for (UIView *v in self.circlesView.subviews) {
        v.layer.cornerRadius = v.frame.size.width / 2.0;
//        v.layer.borderColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;
        v.layer.borderColor = [UIColor whiteColor].CGColor;
        v.layer.borderWidth = 0.5;
    }
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //none
    }];
}

- (void)setButtons{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){ //ipad
        width = 320.0;
    }
    if (MAX(width, height) < 500) { //iphone4
        width = 260;
    }
    
    self.buttonsView.frame = CGRectMake((self.view.bounds.size.width - width) / 2.0, height - width * 1.3333, width, width * 1.3333);
    
    const int space = 16;
    float wh = (width - (space * 4.f)) / 3.f;
    
    CGFloat padWidth = wh * 3.f + (space * 3.f) + 1;
    CGFloat padHeight = wh * 4.f + (space * 4.f) + 1;
    
    for (UIView *v in self.buttonsView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            int x = (v.tag - 1) % 3;
            int y = floor((v.tag - 1) / 3.f);
            v.frame = CGRectMake(space + space * x + wh * x , space + space * y + wh * y, wh, wh);
        }else if ([v isKindOfClass:[UIView class]]) {
            int index = v.tag - 20;
            if (index < 4) {
                v.frame = CGRectMake(space/2.f + space * index + wh * index, space/2.f, 1, padHeight);
            }else {
                index -= 4;
                v.frame = CGRectMake(space/2.f, space/2.f + space * index + wh * index, padWidth, 1);
            }
        }
    }
}

- (IBAction)buttonPressed:(UIButton *)sender {
    if ([sender.currentTitle rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
        self.passStr = [NSString stringWithFormat:@"%@%@", self.passStr, sender.currentTitle];
    }else{
        self.passStr = [self.passStr substringToIndex:self.passStr.length-(self.passStr.length>0)];
    }
}

- (void)setPassStr:(NSString *)passStr{
    _passStr = passStr;
    
    for (UIView *v in self.circlesView.subviews) {
        if (v.tag > 0) {
            if (v.tag <= _passStr.length) {
//                v.backgroundColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
                v.backgroundColor = [UIColor whiteColor];
            }else{
//                v.backgroundColor = [UIColor whiteColor];
                v.backgroundColor = [UIColor clearColor];
            }
        }
    }
    
    if (_passStr.length == 4) {
        if (_errorDate) {
            NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:_errorDate];
            int multiplier = floor(_erCount / 3.0);
            int secondsToWait = 60 * multiplier;
            if (secondsToWait > secondsBetween) {
                NSLog(@"error to wait = %f", secondsBetween - secondsToWait);
                self.passStr = @"";
                [[[UIAlertView alloc] initWithTitle:@"Wallet Locked" message:[NSString stringWithFormat:@"Wait %d seconds",(int)(secondsToWait - secondsBetween)] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                
                return;
            }
        }
        
        
        NSString *pin = [BTCWalletManager sharedInstance].pin;
        if ([_passStr isEqualToString:pin]) {
            [self correctPasswd];
        }else{
            [self performSelector:@selector(errorPasswd) withObject:nil afterDelay:0.1];
        }
    }
}

- (void)correctPasswd{
    _errorDate = nil;
    _erCount = 0;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"dateE"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"erCount"];
    self.unlocked = YES;
    [self exit:nil];
}

- (void)errorPasswd{
    self.passStr = @"";
    [self shakeAnimation:self.circlesView];
    
    if (_erCount % 3 == 0) {
        _errorDate = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"dateE"];
    }
    
    _erCount++;
    [[NSUserDefaults standardUserDefaults] setInteger:_erCount forKey:@"erCount"];
}

-(void)shakeAnimation:(UIView*) view {
    const int reset = 5;
    const int maxShakes = 6;
    
    //pass these as variables instead of statics or class variables if shaking two controls simultaneously
    static int shakes = 0;
    static int translate = reset;
    
    [UIView animateWithDuration:0.09-(shakes*.01) // reduce duration every shake from .09 to .04
                          delay:0.01f//edge wait delay
                        options:(enum UIViewAnimationOptions) UIViewAnimationCurveEaseInOut
                     animations:^{view.transform = CGAffineTransformMakeTranslation(translate, 0);}
                     completion:^(BOOL finished){
                         if(shakes < maxShakes){
                             shakes++;
                             
                             //throttle down movement
                             if (translate>0)
                                 translate--;
                             
                             //change direction
                             translate*=-1;
                             [self shakeAnimation:view];
                         } else {
                             view.transform = CGAffineTransformIdentity;
                             shakes = 0;//ready for next time
                             translate = reset;//ready for next time
                             return;
                         }
                     }];
}



@end
