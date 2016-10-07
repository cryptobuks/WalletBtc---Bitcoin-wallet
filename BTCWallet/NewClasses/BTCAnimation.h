//
//  BTCAnimation.h
//  BTCWallet
//
//  Created by Admin on 8/24/16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    BTCAnimationDirectionLeft,
    BTCAnimationDirectionRight,
    BTCAnimationDirectionTop,
    BTCAnimationDirectionBottom
} BTCAnimationDirection;

@interface BTCAnimation : NSObject

+ (void)presentViewController:(UIViewController*)controller onController:(UIViewController*)destController direction:(BTCAnimationDirection)direction;
+ (void)dismissControllerFromMain:(UIViewController *)controller direction:(BTCAnimationDirection)direction;


@end
