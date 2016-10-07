//
//  BTCTrzDetailViewController.m
//  BTCWallet
//
//  Created by Admin on 8/22/16.
//

#import "BTCTrzDetailViewController.h"

#import "BTCTransaction.h"
#import "BTCWalletManager.h"
#import "BTCPeerManager.h"
#import "BTCCopyLabel.h"
#import "NSString+Bitcoin.h"
#import "NSData+Bitcoin.h"

#define TRANSACTION_CELL_HEIGHT 75

@interface BTCTrzDetailViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *outputText, *outputDetail, *outputAmount;
@property (nonatomic, assign) int64_t sent, received;
@property (nonatomic, strong) id txStatusObserver;

@end

@implementation BTCTrzDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCIdCell" bundle:nil] forCellReuseIdentifier:@"IdCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCSubtitleCell" bundle:nil] forCellReuseIdentifier:@"SubtitleCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCDetailCell" bundle:nil] forCellReuseIdentifier:@"DetailCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCTitleCell" bundle:nil] forCellReuseIdentifier:@"TitleCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"BTCTrzMinCell" bundle:nil] forCellReuseIdentifier:@"TransactionCell"];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exit:)];
    doneBtn.tintColor = [UIColor colorWithRed:241.0/255.0 green:149.0/255.0 blue:81.0/255.0 alpha:1.0];
    
    self.navigationItem.leftBarButtonItem = doneBtn;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (! self.txStatusObserver) {
        self.txStatusObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BTCPeerManagerTxStatusNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               BTCTransaction *tx = [[BTCWalletManager sharedInstance].wallet
                                                                                    transactionForHash:self.transaction.txHash];
                                                               
                                                               if (tx) self.transaction = tx;
                                                               [self.tableView reloadData];
                                                           }];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
    self.txStatusObserver = nil;
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
}

- (void)setTransaction:(BTCTransaction *)transaction
{
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSMutableArray *text = [NSMutableArray array], *detail = [NSMutableArray array], *amount = [NSMutableArray array];
    uint64_t fee = [manager.wallet feeForTransaction:transaction];
    NSUInteger outputAmountIndex = 0;
    
    _transaction = transaction;
    self.sent = [manager.wallet amountSentByTransaction:transaction];
    self.received = [manager.wallet amountReceivedFromTransaction:transaction];
    
    for (NSString *address in transaction.outputAddresses) {
        uint64_t amt = [transaction.outputAmounts[outputAmountIndex++] unsignedLongLongValue];
        
        if (address == (id)[NSNull null]) {
            if (self.sent > 0) {
                [text addObject:NSLocalizedString(@"unknown address", nil)];
                [detail addObject:NSLocalizedString(@"payment output", nil)];
                [amount addObject:@(-amt)];
            }
        }
        else if ([manager.wallet containsAddress:address]) {
            if (self.sent == 0 || self.received == self.sent) {
                [text addObject:address];
                [detail addObject:NSLocalizedString(@"wallet address", nil)];
                [amount addObject:@(amt)];
            }
        }
        else if (self.sent > 0) {
            [text addObject:address];
            [detail addObject:NSLocalizedString(@"payment address", nil)];
            [amount addObject:@(-amt)];
        }
    }
    
    if (self.sent > 0 && fee > 0 && fee != UINT64_MAX) {
        [text addObject:@""];
        [detail addObject:NSLocalizedString(@"bitcoin network fee", nil)];
        [amount addObject:@(-fee)];
    }
    
    self.outputText = text;
    self.outputDetail = detail;
    self.outputAmount = amount;
}

- (void)setBackgroundForCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)path
{
    [cell viewWithTag:100].hidden = (path.row > 0);
    [cell viewWithTag:101].hidden = (path.row + 1 < [self tableView:self.tableView numberOfRowsInSection:path.section]);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0: return 3;
        case 1: return (self.sent > 0) ? self.outputText.count : self.transaction.inputAddresses.count;
        case 2: return (self.sent > 0) ? self.transaction.inputAddresses.count : self.outputText.count;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    BTCCopyLabel *detailLabel;
    UILabel *textLabel, *subtitleLabel, *amountLabel, *localCurrencyLabel;
    BTCWalletManager *manager = [BTCWalletManager sharedInstance];
    NSUInteger peerCount = [BTCPeerManager sharedInstance].peerCount;
    NSUInteger relayCount = [[BTCPeerManager sharedInstance] relayCountForTransaction:self.transaction.txHash];
    NSString *s;
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"IdCell" forIndexPath:indexPath];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    textLabel = (id)[cell viewWithTag:1];
                    detailLabel = (id)[cell viewWithTag:2];
                    [self setBackgroundForCell:cell indexPath:indexPath];
                    textLabel.text = NSLocalizedString(@"id:", nil);
                    s = [NSString hexWithData:[NSData dataWithBytes:self.transaction.txHash.u8
                                                             length:sizeof(UInt256)].reverse];
                    detailLabel.text = [NSString stringWithFormat:@"%@\n%@", [s substringToIndex:s.length/2],
                                        [s substringFromIndex:s.length/2]];
                    detailLabel.copyableText = s;
                    break;
                    
                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"TitleCell" forIndexPath:indexPath];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    textLabel = (id)[cell viewWithTag:1];
                    detailLabel = (id)[cell viewWithTag:2];
                    subtitleLabel = (id)[cell viewWithTag:3];
                    [self setBackgroundForCell:cell indexPath:indexPath];
                    textLabel.text = NSLocalizedString(@"status:", nil);
                    subtitleLabel.text = nil;
                    
                    if (self.transaction.blockHeight != TX_UNCONFIRMED) {
                        detailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"confirmed in block #%d", nil),
                                            self.transaction.blockHeight, self.txDateString];
                        subtitleLabel.text = self.txDateString;
                    }
                    else if (! [manager.wallet transactionIsValid:self.transaction]) {
                        detailLabel.text = NSLocalizedString(@"double spend", nil);
                    }
                    else if ([manager.wallet transactionIsPending:self.transaction]) {
                        detailLabel.text = NSLocalizedString(@"pending", nil);
                    }
                    else if (! [manager.wallet transactionIsVerified:self.transaction]) {
                        detailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"seen by %d of %d peers", nil),
                                            relayCount, peerCount];
                    }
                    else detailLabel.text = NSLocalizedString(@"verified, waiting for confirmation", nil);
                    
                    break;
                    
                case 2:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"TransactionCell"];
                    [self setBackgroundForCell:cell indexPath:indexPath];
                    textLabel = (id)[cell viewWithTag:1];
                    localCurrencyLabel = (id)[cell viewWithTag:5];
                    
                    if (self.sent > 0 && self.sent == self.received) {
                        textLabel.text = [manager stringForAmount:self.sent];
                        localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                                   [manager localCurrencyStringForAmount:self.sent]];
                    }
                    else {
                        textLabel.text = [manager stringForAmount:self.received - self.sent];
                        localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                                   [manager localCurrencyStringForAmount:self.received - self.sent]];
                    }
                    
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 1: // drop through
        case 2:
            if ((self.sent > 0 && indexPath.section == 1) || (self.sent == 0 && indexPath.section == 2)) {
                if ([self.outputText[indexPath.row] length] > 0) {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell" forIndexPath:indexPath];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                }
                else cell = [tableView dequeueReusableCellWithIdentifier:@"SubtitleCell" forIndexPath:indexPath];
                
                detailLabel = (id)[cell viewWithTag:2];
                subtitleLabel = (id)[cell viewWithTag:3];
                amountLabel = (id)[cell viewWithTag:1];
                localCurrencyLabel = (id)[cell viewWithTag:5];
                detailLabel.text = self.outputText[indexPath.row];
                subtitleLabel.text = self.outputDetail[indexPath.row];
                amountLabel.text = [manager stringForAmount:[self.outputAmount[indexPath.row] longLongValue]];
                amountLabel.textColor = (self.sent > 0) ? [UIColor colorWithRed:1.0 green:0.33 blue:0.33 alpha:1.0] :
                [UIColor colorWithRed:0.0 green:0.75 blue:0.0 alpha:1.0];
                localCurrencyLabel.textColor = amountLabel.textColor;
                localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                           [manager localCurrencyStringForAmount:[self.outputAmount[indexPath.row]
                                                                                  longLongValue]]];
            }
            else if (self.transaction.inputAddresses[indexPath.row] != (id)[NSNull null]) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell" forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                detailLabel = (id)[cell viewWithTag:2];
                subtitleLabel = (id)[cell viewWithTag:3];
                amountLabel = (id)[cell viewWithTag:1];
                localCurrencyLabel = (id)[cell viewWithTag:5];
                detailLabel.text = self.transaction.inputAddresses[indexPath.row];
                amountLabel.text = nil;
                localCurrencyLabel.text = nil;
                
                if ([manager.wallet containsAddress:self.transaction.inputAddresses[indexPath.row]]) {
                    subtitleLabel.text = NSLocalizedString(@"wallet address", nil);
                }
                else subtitleLabel.text = NSLocalizedString(@"spent address", nil);
            }
            else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell" forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                detailLabel = (id)[cell viewWithTag:2];
                subtitleLabel = (id)[cell viewWithTag:3];
                amountLabel = (id)[cell viewWithTag:1];
                localCurrencyLabel = (id)[cell viewWithTag:5];
                detailLabel.text = NSLocalizedString(@"unknown address", nil);
                subtitleLabel.text = NSLocalizedString(@"spent input", nil);
                amountLabel.text = nil;
                localCurrencyLabel.text = nil;
            }
            
            [self setBackgroundForCell:cell indexPath:indexPath];
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return nil;
        case 1: return (self.sent > 0) ? NSLocalizedString(@"to:", nil) : NSLocalizedString(@"from:", nil);
        case 2: return (self.sent > 0) ? NSLocalizedString(@"from:", nil) : NSLocalizedString(@"to:", nil);
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: return 44.0;
        case 1: return (self.sent > 0 && [self.outputText[indexPath.row] length] == 0) ? 40 : 60.0;
        case 2: return 60.0;
    }
    
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    
    if (sectionTitle.length == 0) return 22.0;
    
    CGRect textRect = [sectionTitle boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 30.0, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:17]} context:nil];
    
    return textRect.size.height + 12.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerview = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                                  [self tableView:tableView heightForHeaderInSection:section])];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, headerview.frame.size.width - 30.0,
                                                                    headerview.frame.size.height - 12.0)];
    
    titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    titleLabel.numberOfLines = 0;
    headerview.backgroundColor = [UIColor colorWithRed:239.0 / 255.0 green:246.0 / 255.0 blue:1.0 alpha:1.0];
    [headerview addSubview:titleLabel];
    
    return headerview;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger i = [self.tableView.indexPathsForVisibleRows indexOfObject:indexPath];
    UITableViewCell *cell = (i < self.tableView.visibleCells.count) ? self.tableView.visibleCells[i] : nil;
    BTCCopyLabel *copyLabel = (id)[cell viewWithTag:2];
    
    copyLabel.selectedColor = [UIColor clearColor];
    if (cell.selectionStyle != UITableViewCellSelectionStyleNone) [copyLabel toggleCopyMenu];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //none
    }];
}



@end
