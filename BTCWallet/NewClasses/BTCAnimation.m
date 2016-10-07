//
//  BTCAnimation.m
//  BTCWallet
//
//  Created by Admin on 8/24/16.
//

#import "BTCAnimation.h"

@implementation BTCAnimation

+ (void)presentViewController:(UIViewController*)controller onController:(UIViewController*)destController direction:(BTCAnimationDirection)direction{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.fillMode = kCAFillModeForwards;
   // transition.timingFunction = UIViewAnimationCurveEaseInOut;
   // transition.type = kCATransitionReveal;
    transition.type = kCATransitionMoveIn;
    
    switch (direction) {
        case BTCAnimationDirectionTop:
            transition.subtype = kCATransitionFromTop;
            break;
        case BTCAnimationDirectionBottom:
            transition.subtype = kCATransitionFromBottom;
            break;
        case BTCAnimationDirectionLeft:
            transition.subtype = kCATransitionFromLeft;
            break;
        case BTCAnimationDirectionRight:
            transition.subtype = kCATransitionFromRight;
            break;
            
        default:
            break;
    }
    
    [destController.view.window.layer addAnimation:transition forKey:kCATransition];
    [destController presentViewController:controller animated:NO completion:nil];
}

+ (void)dismissControllerFromMain:(UIViewController *)controller direction:(BTCAnimationDirection)direction{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.fillMode = kCAFillModeForwards;
    // transition.timingFunction = UIViewAnimationCurveEaseInOut;
   // transition.type = kCATransitionMoveIn;
    transition.type = kCATransitionReveal;
    
    switch (direction) {
        case BTCAnimationDirectionTop:
            transition.subtype = kCATransitionFromTop;
            break;
        case BTCAnimationDirectionBottom:
            transition.subtype = kCATransitionFromBottom;
            break;
        case BTCAnimationDirectionLeft:
            transition.subtype = kCATransitionFromLeft;
            break;
        case BTCAnimationDirectionRight:
            transition.subtype = kCATransitionFromRight;
            break;
            
        default:
            break;
    }
    [controller.view.window.layer addAnimation:transition forKey:kCATransition];
    [controller dismissViewControllerAnimated:NO completion:nil];
}

@end
