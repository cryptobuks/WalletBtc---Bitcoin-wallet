//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    BTCBubbleTipDirectionDown = 0,
    BTCBubbleTipDirectionUp
} BTCBubbleTipDirection;

@interface BTCBubbleView : UIView

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) CGPoint tipPoint;
@property (nonatomic, assign) BTCBubbleTipDirection tipDirection;
@property (nonatomic, strong) UIView *customView;

+ (instancetype)viewWithText:(NSString *)text center:(CGPoint)center;
+ (instancetype)viewWithText:(NSString *)text tipPoint:(CGPoint)point tipDirection:(BTCBubbleTipDirection)direction;

- (instancetype)popIn;
- (instancetype)popOut;
- (instancetype)popOutAfterDelay:(NSTimeInterval)delay;

@end
