//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>

@interface BTCPhoneWCSessionManager : NSObject

@property (nonatomic, readonly) BOOL reachable;

+ (instancetype)sharedInstance;

- (void)notifyTransactionString:(NSString *)notification;

@end
