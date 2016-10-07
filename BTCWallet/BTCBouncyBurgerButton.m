//
//  Created by Admin on 9/8/16.
//

#import "BTCBouncyBurgerButton.h"

#define BAR_WIDTH   20.0
#define BAR_HEIGHT  2.0
#define BAR_SPACING 7.0

@interface BTCBouncyBurgerButton ()

@property (nonatomic, strong) UIView *bar1, *bar2, *bar3;

@end

@implementation BTCBouncyBurgerButton

- (instancetype)customInit
{
    CGFloat x = (self.bounds.size.width + self.contentEdgeInsets.left - self.contentEdgeInsets.right)/2.0,
            y = (self.bounds.size.height + self.contentEdgeInsets.top - self.contentEdgeInsets.bottom)/2.0;

    self.bar1 = [[UIView alloc] initWithFrame:CGRectMake(x - BAR_WIDTH/2.0, y - BAR_SPACING, BAR_WIDTH, BAR_HEIGHT)];
    self.bar2 = [[UIView alloc] initWithFrame:CGRectMake(x - BAR_WIDTH/2.0, y, BAR_WIDTH, BAR_HEIGHT)];
    self.bar3 = [[UIView alloc] initWithFrame:CGRectMake(x - BAR_WIDTH/2.0, y + BAR_SPACING, BAR_WIDTH, BAR_HEIGHT)];
    self.bar1.userInteractionEnabled = self.bar2.userInteractionEnabled = self.bar3.userInteractionEnabled = NO;
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = self.currentTitleColor;
    [self addSubview:self.bar1];
    [self addSubview:self.bar2];
    [self addSubview:self.bar3];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (! (self = [super initWithCoder:aDecoder])) return nil;
    return [self customInit];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (! (self = [super initWithFrame:frame])) return nil;
    return [self customInit];
}

- (void)setX:(BOOL)x
{
    [self setX:x completion:nil];
}

- (void)setX:(BOOL)x completion:(void (^)(BOOL finished))completion;
{
    _x = x;

    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.bar1.transform = CGAffineTransformMakeRotation(M_PI_4*(x ? 1.5 : -0.35));
        self.bar1.center = CGPointMake(self.bar1.center.x, self.bar2.center.y - (x ? 0.0 : BAR_SPACING));
        self.bar2.alpha = (x) ? 0.0 : 1.0;
        self.bar3.transform = CGAffineTransformMakeRotation(M_PI_4*(x ? -1.5 : 0.35));
        self.bar3.center = CGPointMake(self.bar3.center.x, self.bar2.center.y + (x ? 0.0 : BAR_SPACING));
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.3 initialSpringVelocity:0.0
         options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.bar1.transform = CGAffineTransformMakeRotation(x ? M_PI_4 : 0.0);
            self.bar3.transform = CGAffineTransformMakeRotation(x ? -M_PI_4 : 0.0);
        } completion:completion];
    }];
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    [super setTitleColor:color forState:state];
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = self.currentTitleColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    super.highlighted = highlighted;
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = self.currentTitleColor;
}

- (void)setEnabled:(BOOL)enabled
{
    super.enabled = enabled;
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = self.currentTitleColor;
}

- (void)setSelected:(BOOL)selected
{
    super.selected = selected;
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = self.currentTitleColor;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(BAR_WIDTH, BAR_SPACING*2 + BAR_HEIGHT);
}

@end
