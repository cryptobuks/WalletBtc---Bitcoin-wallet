//
//  SideMenuOptions.h
//  BTCWallet
//
//  Created by Admin on 9/29/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BTCSideMenuOptions : NSObject <NSCopying>

@property (nonatomic, assign) CGFloat bezelWidth;
@property (nonatomic, assign) CGFloat contentViewScale;
@property (nonatomic, assign) CGFloat contentViewOpacity;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) BOOL panFromBezel;
@property (nonatomic, assign) BOOL panFromNavBar;
@property (nonatomic, assign) CGFloat animationDuration;

@end
