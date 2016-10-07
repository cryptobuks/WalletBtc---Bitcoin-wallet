//
//  Created by Admin on 9/8/16.
//

#import "BTCPeerEntity.h"
#import "BTCPeer.h"
#import "NSData+Bitcoin.h"
#import "NSManagedObject+Sugar.h"
#import <arpa/inet.h>

@implementation BTCPeerEntity

@dynamic address;
@dynamic timestamp;
@dynamic port;
@dynamic services;
@dynamic misbehavin;

- (instancetype)setAttributesFromPeer:(BTCPeer *)peer
{
    //TODO: store IPv6 addresses
    if (peer.address.u64[0] != 0 || peer.address.u32[2] != CFSwapInt32HostToBig(0xffff)) return nil;

    [self.managedObjectContext performBlockAndWait:^{
        self.address = CFSwapInt32BigToHost(peer.address.u32[3]);
        self.port = peer.port;
        self.timestamp = peer.timestamp;
        self.services = peer.services;
        self.misbehavin = peer.misbehavin;
    }];

    return self;
}

- (BTCPeer *)peer
{
    __block BTCPeer *peer = nil;
        
    [self.managedObjectContext performBlockAndWait:^{
        UInt128 address = { .u32 = { 0, 0, CFSwapInt32HostToBig(0xffff), CFSwapInt32HostToBig(self.address) } };

        peer = [[BTCPeer alloc] initWithAddress:address port:self.port timestamp:self.timestamp services:self.services];
        peer.misbehavin = self.misbehavin;
    }];

    return peer;
}

@end
