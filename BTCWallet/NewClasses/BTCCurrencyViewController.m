//
//  BTCCurrencyViewController.m
//  BTCWallet
//
//  Created by Admin on 8/22/16.
//

#import "BTCCurrencyViewController.h"
#import "BTCWalletManager.h"
#import "BTCSettingsViewController.h"
#define SETTINGS_MAX_DIGITS_KEY @"SETTINGS_MAX_DIGITS"

@interface BTCCurrencyViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *selectorOptions;
@property (nonatomic, strong) NSString *selectedOption, *noOptionsText;
@property (nonatomic, assign) NSUInteger selectorType;
@end

@implementation BTCCurrencyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCSelectorOptionCell" bundle:nil] forCellReuseIdentifier:@"SelectorOptionCell"];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exit:)];
    done.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    self.navigationItem.leftBarButtonItem = done;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*)selectorOptions{
    if (!_selectorOptions) {
        NSUInteger currencyCodeIndex = 0;
        NSMutableArray *options;
        options = [NSMutableArray array];
        BTCWalletManager *manager = [BTCWalletManager sharedInstance];
        for (NSString *code in manager.currencyCodes) {
            [options addObject:[NSString stringWithFormat:@"%@ - %@", code, manager.currencyNames[currencyCodeIndex++]]];
        }
        self.selectedOption = [options objectAtIndex:[manager.currencyCodes indexOfObject:manager.localCurrencyCode]];
        _selectorOptions = options;
    }
    return _selectorOptions;
}

- (void)viewWillAppear:(BOOL)animated{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[[BTCWalletManager sharedInstance].currencyCodes indexOfObject:[BTCWalletManager sharedInstance].localCurrencyCode] inSection:0]
     atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return self.selectorOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *selectorOptionCell = @"SelectorOptionCell";
    UITableViewCell *cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:selectorOptionCell];
    cell.textLabel.text = self.selectorOptions[indexPath.row];
    cell.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    
    if ([self.selectedOption isEqual:self.selectorOptions[indexPath.row]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
       // cell.contentView.backgroundColor = [UIColor redColor];
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
       // cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.noOptionsText;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSUInteger currencyCodeIndex = 0;
    
    currencyCodeIndex = [self.selectorOptions indexOfObject:self.selectedOption];
    if (indexPath.row < self.selectorOptions.count) self.selectedOption = self.selectorOptions[indexPath.row];
    
    if (self.selectorType == 0) {
        if (indexPath.row < manager.currencyCodes.count) {
            manager.localCurrencyCode = manager.currencyCodes[indexPath.row];
        }
    }
    else manager.spendingLimit = (indexPath.row > 0) ? pow(10, indexPath.row + 6) : 0;
    
    if (currencyCodeIndex < self.selectorOptions.count && currencyCodeIndex != indexPath.row) {
        [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:currencyCodeIndex inSection:0], indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadData];
    return;
    
}



- (IBAction)exit:(id)sender {
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSUInteger digits = (((manager.format.maximumFractionDigits - 2)/3 + 1) % 3)*3 + 2;
    
    manager.format.currencySymbol = [NSString stringWithFormat:@"%@%@" NARROW_NBSP, (digits == 5) ? @"m" : @"",
                                     (digits == 2) ? BITS : BTC];
    manager.format.maximumFractionDigits = digits;
    manager.format.maximum = @(MAX_MONEY/(int64_t)pow(10.0, manager.format.maximumFractionDigits));
    [[NSUserDefaults standardUserDefaults] setInteger:digits forKey:SETTINGS_MAX_DIGITS_KEY];
    manager.localCurrencyCode = manager.localCurrencyCode; // force balance notification
    //self.selectorController.title = [NSString stringWithFormat:@"%@ = %@",
                                     [manager localCurrencyStringForAmount:SATOSHIS/manager.localCurrencyPrice],
                                     [manager stringForAmount:SATOSHIS/manager.localCurrencyPrice];
    [self dismissViewControllerAnimated:YES completion:^{
        //none
    }];
}

@end
