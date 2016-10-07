//
//  BTCButton.m
//
//  Created by Admin on 9/16/16.
//

//localizable

#import "BTCButton.h"

@implementation BTCButton

- (void)awakeFromNib{
    [super awakeFromNib];

    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:self.titleLabel.font.fontName size:15];
    [self setTitle:self.currentTitle forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state{
    NSString *newTitle = title.lowercaseString;
    [super setTitle:[NSLocalizedString(newTitle, nil) lowercaseString] forState:state];
   //  [super setTitle:[NSLocalizedString(newTitle, nil) uppercaseString] forState:state];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
