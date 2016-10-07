//
//  Created by Admin on 9/8/16.
//

#import "BTCTodayViewController.h"
#import "BTCAppGroupConstants.h"
#import "BTCBubbleView.h"
#import "UIImage+Utils.h"
#import <NotificationCenter/NotificationCenter.h>

#define SCAN_URL @"btc://x-callback-url/scanqr"
#define OPEN_URL @"btc://"

@interface BTCTodayViewController () <NCWidgetProviding>

@property (nonatomic, weak) IBOutlet UIImageView *qrImage, *qrOverlay;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UIView *noDataViewContainer;
@property (nonatomic, weak) IBOutlet UIView *topViewContainer;
@property (nonatomic, strong) NSData *qrCodeData;
@property (nonatomic, strong) NSUserDefaults *appGroupUserDefault;
@property (nonatomic, strong) BTCBubbleView *bubbleView;

@end

@implementation BTCTodayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateReceiveMoneyUI];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    [self.bubbleView popOut];
    self.bubbleView = nil;
    if (! completionHandler) return;
    
    // Perform any setup necessary in order to update the view.
    NSData *data = [self.appGroupUserDefault objectForKey:APP_GROUP_REQUEST_DATA_KEY];

    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    if ([self.qrCodeData isEqualToData:data]) {
        self.noDataViewContainer.hidden = YES;
        self.topViewContainer.hidden = NO;
        completionHandler(NCUpdateResultNoData);
    }
    else if (self.qrCodeData) {
        self.qrCodeData = data;
        self.noDataViewContainer.hidden = YES;
        self.topViewContainer.hidden = NO;
        [self updateReceiveMoneyUI];
        completionHandler(NCUpdateResultNewData);
    }
    else {
        self.noDataViewContainer.hidden = NO;
        self.topViewContainer.hidden = YES;
        completionHandler(NCUpdateResultFailed);
    }
}

- (NSUserDefaults *)appGroupUserDefault
{
    if (! _appGroupUserDefault) _appGroupUserDefault = [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_ID];
    return _appGroupUserDefault;
}

- (void)updateReceiveMoneyUI
{
    self.qrCodeData = [self.appGroupUserDefault objectForKey:APP_GROUP_REQUEST_DATA_KEY];
    
    if (self.qrCodeData && self.qrImage.bounds.size.width > 0) {
        self.qrImage.image = self.qrOverlay.image =
            [[UIImage imageWithQRCodeData:self.qrCodeData color:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]]
             resize:self.qrImage.bounds.size withInterpolationQuality:kCGInterpolationNone];
    }

    self.addressLabel.text = [self.appGroupUserDefault objectForKey:APP_GROUP_RECEIVE_ADDRESS_KEY];
}

#pragma mark - NCWidgetProviding

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    return UIEdgeInsetsZero;
}

#pragma mark - UI Events

- (IBAction)scanButtonTapped:(UIButton *)sender
{
    [self.extensionContext openURL:[NSURL URLWithString:SCAN_URL] completionHandler:nil];
}

- (IBAction)openAppButtonTapped:(id)sender
{
    [self.extensionContext openURL:[NSURL URLWithString:OPEN_URL] completionHandler:nil];
}

- (IBAction)qrImageTapped:(id)sender
{
    // UIMenuControl doesn't seem to work in an NCWidget, so use a BTCBubbleView that looks nearly the same
    if (self.bubbleView) {
        if (CGRectContainsPoint(self.bubbleView.frame,
                                [(UITapGestureRecognizer *)sender locationInView:self.bubbleView.superview])) {
            [UIPasteboard generalPasteboard].string = self.addressLabel.text;
        }
    
        [self.bubbleView popOut];
        self.bubbleView = nil;
    }
    else {
        self.bubbleView = [BTCBubbleView viewWithText:@"Copy"
                           tipPoint:CGPointMake(self.addressLabel.center.x, self.addressLabel.frame.origin.y - 5.0)
                           tipDirection:BTCBubbleTipDirectionDown];
        self.bubbleView.alpha = 0;
        self.bubbleView.font = [UIFont systemFontOfSize:14.0];
        self.bubbleView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        [self.addressLabel.superview addSubview:self.bubbleView];
        [self.bubbleView becomeFirstResponder]; //this will cause bubbleview to hide when it loses firstresponder status
        [UIView animateWithDuration:0.2 animations:^{ self.bubbleView.alpha = 1.0; }];
    }
}

- (IBAction)widgetTapped:(id)sender
{
    [self.bubbleView popOut];
    self.bubbleView = nil;
}

@end
