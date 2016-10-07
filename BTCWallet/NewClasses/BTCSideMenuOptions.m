//
//  SideMenuOptions.m
//  BTCWallet
//
//  Created by Admin on 9/29/16.
//

#import "BTCSideMenuOptions.h"

@implementation BTCSideMenuOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bezelWidth = 20.0f;
        _contentViewScale = 0.96f;
        _contentViewOpacity = 0.4f;
        _shadowOpacity = 0.5;
        _shadowRadius = 3;
        _shadowOffset = CGSizeMake(8,0);
        _panFromBezel = YES;
        _panFromNavBar = YES;
        _animationDuration = 0.4f;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    
    BTCSideMenuOptions *options = [[BTCSideMenuOptions alloc] init];
    options.bezelWidth = self.bezelWidth;
    options.contentViewOpacity = self.contentViewOpacity;
    options.contentViewScale = self.contentViewScale;
    options.panFromBezel = self.panFromBezel;
    options.panFromNavBar = self.panFromNavBar;
    options.animationDuration = self.animationDuration;
    options.shadowOffset = self.shadowOffset;
    options.shadowOpacity = self.shadowOpacity;
    options.shadowRadius = self.shadowRadius;
    return options;
}

@end
