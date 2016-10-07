//
//  SideMenuViewController.h
//  BTCWallet
//
//  Created by Admin on 9/29/16.
//

#import <UIKit/UIKit.h>

@class BTCSideMenuOptions;

@interface BTCSideMenuViewController : UIViewController

- (instancetype)initWithMenuViewController:(UIViewController *)menuViewController contentViewController:(UIViewController *)contentViewController;

- (instancetype)initWithMenuViewController:(UIViewController *)menuViewController contentViewController:(UIViewController *)contentViewController options:(BTCSideMenuOptions *)options;

@property (nonatomic, strong, readonly) UIViewController *menuViewController;
@property (nonatomic, strong, readonly) UIViewController *contentViewController;

@property (nonatomic, copy) BTCSideMenuOptions *options;
@property (nonatomic, assign) CGRect menuFrame;

- (void)closeMenu;
- (void)openMenu;
- (void)toggleMenu;
- (void)disable;
- (void)enable;


- (void)changeContentViewController:(UIViewController *)contentViewController closeMenu:(BOOL)closeMenu;
- (void)changeMenuViewController:(UIViewController *)menuViewController closeMenu:(BOOL)closeMenu;

@end

@interface UIViewController (BTCSideMenuViewController)

- (BTCSideMenuViewController *)sideMenuController;
- (void)addLeftMenuButtonWithImage:(UIImage *)buttonImage;

@end
