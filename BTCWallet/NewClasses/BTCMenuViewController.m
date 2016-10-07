//
//  BTCMenuViewController.m
//  BTCWallet
//
//  Created by Bandu Hao on 9/30/16.
//  Copyright © 2016 MyOrg. All rights reserved.
//

#import "BTCMenuViewController.h"
#import "BTCSendViewController.h"
#import "BTCSideMenuViewController.h"
#import "BTCSendViewController.h"
#import "BTCReceiveViewController.h"
#import "BTCSettingsViewController.h"
#import "BTCAboutViewController.h"
#import "BTCMainViewController.h"
#import "BTCAppDelegate.h"

@interface BTCMenuViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *dataSource;
@property (strong, nonatomic) NSArray *icons;
@property (assign, nonatomic) NSInteger selectedIndex;

@end

@implementation BTCMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = @[
                        @"Wallet",
                        [NSLocalizedString(@"send", nil) capitalizedString],
                        [NSLocalizedString(@"receive", nil) capitalizedString],
                        [NSLocalizedString(@"settings", nil) capitalizedString],
                        [NSLocalizedString(@"about", nil) capitalizedString]
                        ];
    self.icons = @[@"wallet_icon", @"send_icon", @"receive_icon", @"settings_icon", @"about_icon"];
    
    self.selectedIndex = 0;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = self.dataSource[indexPath.row];
    NSString *imageName = self.icons[indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.imageView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.tintColor = [UIColor grayColor];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    if (self.selectedIndex != indexPath.row) {
        switch (index) {
            case 0:
            {
//                BTCMainViewController *main = [BTCMainViewController new];
                BTCMainViewController *main = [(BTCAppDelegate *)[[UIApplication sharedApplication] delegate] main];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:main];
                [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
            }
                break;
            case 1:
            {
                BTCSendViewController *send = [BTCSendViewController new];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:send];
                [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
//                [self.sideMenuController closeMenu];
//                [self presentViewController:send animated:YES completion:nil];
                
            }
                break;
            case 2:
            {
                BTCReceiveViewController *recevie = [BTCReceiveViewController new];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:recevie];
                [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
//            [self.sideMenuController closeMenu];
//            [self presentViewController:recevie animated:YES completion:nil];
            }
                break;
            case 3:
            {
                BTCSettingsViewController *sett = [BTCSettingsViewController new];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:sett];
                [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
//            [self.sideMenuController closeMenu];
//            [self presentViewController:sett animated:YES completion:nil];
            }
                break;
            case 4:
            {
                BTCAboutViewController *about = [BTCAboutViewController new];
                UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:about];
                [self.sideMenuController changeContentViewController:navigation closeMenu:YES];
//            [self.sideMenuController closeMenu];
//            [self presentViewController:about animated:YES completion:nil];
            }
                break;
                
            default:
                break;
        }
    }else {
        [self.sideMenuController closeMenu];
    }
    
    self.selectedIndex = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
