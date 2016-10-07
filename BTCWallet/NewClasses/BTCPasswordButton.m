//
//  BTCPasswordButton.m
//  BTCWallet
//
//  Created by Admin on 8/30/16.
//

#import "BTCPasswordButton.h"

@implementation BTCPasswordButton

- (void)awakeFromNib{
    [super awakeFromNib];
    /*
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 2.0, self.frame.size.width, 2.0)];
    v.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:v];
     */
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    
    self.layer.cornerRadius = self.frame.size.width / 2.0;
   // self.layer.borderWidth = 3.0;
    self.layer.borderColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
