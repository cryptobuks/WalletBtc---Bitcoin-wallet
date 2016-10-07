//
//  BTCLabelLocalizable.m
//  BTCWallet
//
//  Created by Admin on 9/28/16.
//  Copyright © 2016 MyOrg. All rights reserved.
//

#import "BTCLabelLocalizable.h"

@implementation BTCLabelLocalizable

- (void)awakeFromNib{
    [super awakeFromNib];
    self.text = self.text;
}

- (void)setText:(NSString *)text{
    [super setText:NSLocalizedString(text, nil)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
