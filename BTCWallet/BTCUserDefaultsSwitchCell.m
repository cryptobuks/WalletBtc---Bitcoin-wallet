//
//  Created by Admin on 9/8/16.
//

#import "BTCUserDefaultsSwitchCell.h"

@interface BTCUserDefaultsSwitchCell ()

@property (nonatomic, copy) NSString *_userDefaultsKey;
- (void)updateUi;

@end

@implementation BTCUserDefaultsSwitchCell

- (void)setUserDefaultsKey:(NSString *)key
{
    self._userDefaultsKey = key;
    [self updateUi];
}

- (void)didUpdateSwitch:(id)sender
{
    if (self._userDefaultsKey)
        [[NSUserDefaults standardUserDefaults] setBool:self.theSwitch.on forKey:self._userDefaultsKey];
}

- (void)updateUi
{
    if (self._userDefaultsKey)
        self.theSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:self._userDefaultsKey];
}

- (void)awakeFromNib {
    if (self._userDefaultsKey)
        self.theSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:self._userDefaultsKey];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
