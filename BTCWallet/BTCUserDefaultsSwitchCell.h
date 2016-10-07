//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>

@interface BTCUserDefaultsSwitchCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UISwitch *theSwitch;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
- (IBAction)didUpdateSwitch:(id)sender;
- (void)setUserDefaultsKey:(NSString *)key;

@end
