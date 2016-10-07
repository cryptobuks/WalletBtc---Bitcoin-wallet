//
//  Created by Admin on 9/8/16.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface BTCAddressEntity : NSManagedObject

@property (nonatomic, retain) NSString *address;
@property (nonatomic) int32_t index;
@property (nonatomic) BOOL internal;

@end
