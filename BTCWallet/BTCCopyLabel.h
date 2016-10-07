//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>

// subclass of uilabel that allows users to tap the contents and get a "copy" action bubble
@interface BTCCopyLabel : UILabel

@property (nonatomic, strong) NSString *copyableText; // text that can be copied to clipboard, default is [UILabel text]
@property (nonatomic, strong) UIColor *selectedColor; // should generally have an alpha of less than 0.8

- (void)toggleCopyMenu;

@end
