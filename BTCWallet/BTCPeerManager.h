//
//  Created by Admin on 9/8/16.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BTCPeer.h"

FOUNDATION_EXPORT NSString* _Nonnull const BTCPeerManagerSyncStartedNotification;
FOUNDATION_EXPORT NSString* _Nonnull const BTCPeerManagerSyncFinishedNotification;
FOUNDATION_EXPORT NSString* _Nonnull const BTCPeerManagerSyncFailedNotification;
FOUNDATION_EXPORT NSString* _Nonnull const BTCPeerManagerTxStatusNotification;

#define PEER_MAX_CONNECTIONS 3

@class BTCTransaction;

@interface BTCPeerManager : NSObject <BTCPeerDelegate, UIAlertViewDelegate>

@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) uint32_t lastBlockHeight;
@property (nonatomic, readonly) uint32_t estimatedBlockHeight; // last block height reported by current download peer
@property (nonatomic, readonly) double syncProgress;
@property (nonatomic, readonly) NSUInteger peerCount; // number of connected peers
@property (nonatomic, readonly) NSString * _Nullable downloadPeerName;

+ (instancetype _Nullable)sharedInstance;

- (void)connect;
- (void)rescan;
- (void)publishTransaction:(BTCTransaction * _Nonnull)transaction
                completion:(void (^ _Nonnull)(NSError * _Nullable error))completion;
- (NSUInteger)relayCountForTransaction:(UInt256)txHash; // number of connected peers that have relayed the transaction
- (NSTimeInterval)timestampForBlockHeight:(uint32_t)blockHeight; // seconds since reference date, 00:00:00 01/01/01 GMT

@end
