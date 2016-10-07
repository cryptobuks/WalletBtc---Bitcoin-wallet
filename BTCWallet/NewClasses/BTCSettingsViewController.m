//
//  BTCSettingsViewController.m
//  BTCWallet
//
//  Created by Admin on 8/22/16.
//

#import "BTCSettingsViewController.h"
#import "BTCWalletManager.h"
#import "BTCBubbleView.h"
#import "BTCPeerManager.h"
#import "BTCUserDefaultsSwitchCell.h"
#include <WebKit/WebKit.h>
#include <asl.h>
#import <MessageUI/MessageUI.h>
#import "BTCSideMenuViewController.h"
#import "BTCMainViewController.h"
#import "BTCAppDelegate.h"

#import "BTCCurrencyViewController.h"
//#import "BTCAboutViewController.h"
#import "BTCKeyViewController.h"
#define SETTINGS_MAX_DIGITS_KEY @"SETTINGS_MAX_DIGITS"

@interface BTCSettingsViewController ()

@property (nonatomic, assign) BOOL touchId;
@property (nonatomic, strong) UITableViewController *selectorController;
@property (nonatomic, strong) NSArray *selectorOptions;
@property (nonatomic, strong) NSString *selectedOption, *noOptionsText;
@property (nonatomic, assign) NSUInteger selectorType;
@property (nonatomic, strong) UISwipeGestureRecognizer *navBarSwipe;
@property (nonatomic, strong) id balanceObserver, txStatusObserver;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation BTCSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addLeftMenuButtonWithImage:[UIImage imageNamed:@"menu_icon"]];
    self.title = [NSLocalizedString(@"settings", nil) capitalizedString];
    
    self.touchId = [BTCWalletManager sharedInstance].touchIdEnabled;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCDislocureCell" bundle:nil] forCellReuseIdentifier:@"DisclosureCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCRestoreCell" bundle:nil] forCellReuseIdentifier:@"RestoreCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCActionCell" bundle:nil] forCellReuseIdentifier:@"ActionCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCSelectorCell" bundle:nil] forCellReuseIdentifier:@"SelectorCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCSelectorOptionCell" bundle:nil] forCellReuseIdentifier:@"SelectorOptionCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCUnitCell" bundle:nil] forCellReuseIdentifier:@"UnitCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCFeeCell" bundle:nil] forCellReuseIdentifier:@"FeeCell"];
    [self.tableView registerClass:[BTCUserDefaultsSwitchCell class] forCellReuseIdentifier:@"SwitchCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    // observe the balance change notification to update the balance display
    if (! self.balanceObserver) {
        self.balanceObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCWalletBalanceChangedNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               if (self.selectorType == 0) {
                                                                   self.selectorController.title =
                                                                   [NSString stringWithFormat:@"%@ = %@",
                                                                    [manager localCurrencyStringForAmount:SATOSHIS/manager.localCurrencyPrice],
                                                                    [manager stringForAmount:SATOSHIS/manager.localCurrencyPrice]];
                                                               }
                                                           }];
    }
    
    if (! self.txStatusObserver) {
        self.txStatusObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerTxStatusNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               [(id)[self.navigationController.topViewController.view viewWithTag:412] setText:self.stats];
                                                           }];
    }
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isMovingFromParentViewController || self.navigationController.isBeingDismissed) {
        if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
        self.balanceObserver = nil;
        if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
        self.txStatusObserver = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
}

- (UITableViewController *)selectorController
{
    if (_selectorController) return _selectorController;
    _selectorController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    _selectorController.transitioningDelegate = self.navigationController.viewControllers.firstObject;
    _selectorController.tableView.dataSource = self;
    _selectorController.tableView.delegate = self;
    _selectorController.tableView.backgroundColor = [UIColor clearColor];
    return _selectorController;
}

- (void)setBackgroundForCell:(UITableViewCell *)cell tableView:(UITableView *)tableView indexPath:(NSIndexPath *)path
{
    [cell viewWithTag:100].hidden = (path.row > 0);
    [cell viewWithTag:101].hidden = (path.row + 1 < [self tableView:tableView numberOfRowsInSection:path.section]);
}

- (NSString *)stats
{
    static NSDateFormatter *fmt = nil;
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    if (! fmt) {
        fmt = [NSDateFormatter new];
        fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Mdjma" options:0 locale:[NSLocale currentLocale]];
    }
    
    return [NSString stringWithFormat:@"rate: %@ = %@\nupdated: %@\nblock #%d of %d\n"
                                                        "connected peers: %d\ndl peer: %@",
            [manager localCurrencyStringForAmount:SATOSHIS/manager.localCurrencyPrice],
            [manager stringForAmount:SATOSHIS/manager.localCurrencyPrice],
            [fmt stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:manager.secureTime]].lowercaseString,
            [BTCPeerManager sharedInstance].lastBlockHeight,
            [BTCPeerManager sharedInstance].estimatedBlockHeight,
            [BTCPeerManager sharedInstance].peerCount,
            [BTCPeerManager sharedInstance].downloadPeerName];
}

#pragma mark - IBAction

- (IBAction)done:(id)sender
{
//    [self dismissViewControllerAnimated:YES completion:^{
//        //none
//    }];
//    BTCMainViewController *main = [BTCMainViewController new];
    BTCMainViewController *main = [(BTCAppDelegate *)[[UIApplication sharedApplication] delegate] main];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:main];
    [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
}




#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 1;
        case 1: return 3;
        case 2: return 2;
        case 3: return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *disclosureIdent = @"DisclosureCell", *restoreIdent = @"RestoreCell", *actionIdent = @"ActionCell",
    *selectorIdent = @"SelectorCell", *unitIndent = @"UnitCell", *feeCell = @"FeeCell";
    UITableViewCell *cell = nil;
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    switch (indexPath.section) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:disclosureIdent];
            
            switch (indexPath.row) {
                case 1:
                    cell.textLabel.text = NSLocalizedString(@"about", nil);
                    break;
                    
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"recovery phrase", nil);
                    break;
            }
            
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:selectorIdent];
                    cell.detailTextLabel.text = manager.localCurrencyCode;
                    break;
                    
                case 1:{
                    cell = [tableView dequeueReusableCellWithIdentifier:unitIndent];
                    UISegmentedControl *sg = [cell viewWithTag:1];
                    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
                    NSUInteger digits = manager.format.maximumFractionDigits;
                    sg.selectedSegmentIndex = floor(digits / 4.0);
                    [sg addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
                }
                    break;
                    
                case 2:{
                    cell = [tableView dequeueReusableCellWithIdentifier:feeCell];
                    UISegmentedControl *sg = [cell viewWithTag:1];
                    sg.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"trzPriority"];
                    [sg addTarget:self action:@selector(feeSegmentSelected:) forControlEvents:UIControlEventValueChanged];
                }
                    break;
                    
                case 3:
                    if (self.touchId) {
                        cell = [tableView dequeueReusableCellWithIdentifier:selectorIdent];
                        cell.textLabel.text = @"touch id limit";
                        cell.detailTextLabel.text = [manager stringForAmount:manager.spendingLimit];
                    } else {
                        goto _switch_cell;
                    }
                    break;
                case 4:
                {
                _switch_cell:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
                    BTCUserDefaultsSwitchCell *switchCell = (BTCUserDefaultsSwitchCell *)cell;
                    switchCell.titleLabel.text = @"enable receive notifications";
                    [switchCell setUserDefaultsKey:USER_DEFAULTS_LOCAL_NOTIFICATIONS_KEY];
                    break;
                }
                    
            }
            
            break;
            
        case 2:
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:actionIdent];
                    cell.textLabel.text = NSLocalizedString(@"change passcode", nil);
                    break;

                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:actionIdent];
                    cell.textLabel.text = NSLocalizedString(@"rescan blockchain", nil);
                    break;
                    
                case 2:
                    cell = [tableView dequeueReusableCellWithIdentifier:restoreIdent];
                    break;
                    
            }
            break;
            
    }
    
 //   [self setBackgroundForCell:cell tableView:tableView indexPath:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return nil;
            
        case 1:
            return nil;
            
        case 2:
            return nil;
            
        case 3:
            return NSLocalizedString(@"rescan blockchain if you think you may have missing transactions, "
                                     "or are having trouble sending (rescanning can take several minutes)", nil);
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    
    if (sectionTitle.length == 0) return 22.0;
    
    CGRect textRect = [sectionTitle boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 20.0, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:13]} context:nil];
    
    return textRect.size.height + 22.0 + 10.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                                     [self tableView:tableView heightForHeaderInSection:section])];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0.0, sectionHeader.frame.size.width - 20.0,
                                                                    sectionHeader.frame.size.height - 22.0)];
    
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    titleLabel.textColor = [UIColor grayColor];
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    titleLabel.numberOfLines = 0;
    sectionHeader.backgroundColor = [UIColor clearColor];
    [sectionHeader addSubview:titleLabel];
    
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return (section + 1 == [self numberOfSectionsInTableView:tableView]) ? 22.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *sectionFooter = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                                     [self tableView:tableView heightForFooterInSection:section])];
    sectionFooter.backgroundColor = [UIColor clearColor];
    return sectionFooter;
}

- (void)showAbout
{
//    BTCAboutViewController *about = [BTCAboutViewController new];
//    [self presentViewController:about animated:YES completion:^{
//        //none
//    }];
}

- (void)showRecoveryPhrase
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                message:[NSString stringWithFormat:@"\n%@\n\n%@\n\n%@\n",
                                         [NSLocalizedString(@"\nDO NOT let anyone see your recovery\n"
                                                            "phrase or they can spend your bitcoins.\n", nil)
                                          stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]],
                                         [NSLocalizedString(@"\nNEVER type your recovery phrase into\n"
                                                            "password managers or elsewhere.\n"
                                                            "Other devices may be infected.\n", nil)
                                          stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]],
                                         [NSLocalizedString(@"\nDO NOT take a screenshot.\n"
                                                            "Screenshots are visible to other apps\n"
                                                            "and devices.\n", nil)
                                          stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]]
                               delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                      otherButtonTitles:NSLocalizedString(@"show", nil), nil] show];
}

- (void)showCurrencySelector
{
    BTCCurrencyViewController *curr = [BTCCurrencyViewController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:curr];
    
    [self presentViewController:navigation animated:YES completion:^{
        //none
    }];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: include an option to generate a new wallet and sweep old balance if backup may have been compromized
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 1: // about
                    [self showAbout];
                    break;
                    
                case 0: // recovery phrase
                    [self showRecoveryPhrase];
                    break;
            }
            
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0: // local currency
                    [self showCurrencySelector];
                    
                    break;
                    
                case 1:
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                    break;
                    
                case 2: // touch id spending limit
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    /*
                    if (self.touchId) {
                        [self performSelector:@selector(touchIdLimit:) withObject:nil afterDelay:0.0];
                        break;
                    } else {
                        goto _deselect_switch;
                    }
                     */
                    break;
                case 3:
                _deselect_switch:
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                    break;
            }
            
            break;
            
        case 2:
            switch (indexPath.row) {
                case 0: // change passcode
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [manager performSelector:@selector(setPin) withObject:nil afterDelay:0.0];
                    break;
                    
                case 1: // rescan blockchain
                    [[BTCPeerManager sharedInstance] rescan];
                    [self done:nil];
                    break;
            }
            
            break;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        return;
    }
    
    BTCKeyViewController *key = [BTCKeyViewController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:key];
    
    [self presentViewController:navigation animated:YES completion:nil];
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //none;
    }];
}

- (void)feeSegmentSelected:(UISegmentedControl*)sender{
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:@"trzPriority"];
    [[BTCWalletManager sharedInstance] updateFeePerKb];
}

- (void)segmentSelected:(UISegmentedControl*)sender{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSUInteger digits;
    switch (sender.selectedSegmentIndex) {
        case 0:
            digits = 2;
            break;
        case 1:
            digits = 5;
            break;
        case 2:
            digits = 8;
            break;
            
        default:
            break;
    }
    
    manager.format.currencySymbol = [NSString stringWithFormat:@"%@%@" NARROW_NBSP, (digits == 5) ? @"m" : @"",
                                     (digits == 2) ? BITS : BTC];
    manager.format.maximumFractionDigits = digits;
    manager.format.maximum = @(MAX_MONEY/(int64_t)pow(10.0, manager.format.maximumFractionDigits));
    [[NSUserDefaults standardUserDefaults] setInteger:digits forKey:SETTINGS_MAX_DIGITS_KEY];
    manager.localCurrencyCode = manager.localCurrencyCode; // force balance notification
    //self.selectorController.title = [NSString stringWithFormat:@"%@ = %@",
    [manager localCurrencyStringForAmount:SATOSHIS/manager.localCurrencyPrice],
    [manager stringForAmount:SATOSHIS/manager.localCurrencyPrice];
    
    [self.tableView reloadData];
}

@end
