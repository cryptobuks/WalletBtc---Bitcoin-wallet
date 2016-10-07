//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>

@interface BTCBouncyBurgerButton : UIButton

@property (nonatomic, assign) BOOL x;

- (void)setX:(BOOL)x completion:(void (^)(BOOL finished))completion;

@end
