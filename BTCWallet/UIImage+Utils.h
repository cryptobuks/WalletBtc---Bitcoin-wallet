//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

+ (instancetype)imageWithQRCodeData:(NSData *)data color:(CIColor *)color;

- (UIImage *)resize:(CGSize)size withInterpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)blurWithRadius:(CGFloat)radius;

@end
