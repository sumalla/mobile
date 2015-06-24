 //
//  SAVProvisioner.m
//  Savant
//
//  Created by Julian Locke on 5/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVProvisioner.h"
#import "SAVProvisioningManager.h"
#import "SAVControlPrivate.h"
#import "Savant.h"

@interface SAVProvisioner () <SAVProvisioningManagerDelegate>

@property (strong, nonatomic) SAVProvisioningManager *manager;
@property (strong, nonatomic) NSMutableSet *delegates;
@property (strong, nonnull) NSMutableDictionary *credentialsForUIDs;

@end

@implementation SAVProvisioner

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.manager = [SAVProvisioningManager sharedInstance];
        [self.manager addDelegate:self];
        
        self.delegates = [[NSMutableSet alloc] init];
        self.credentialsForUIDs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark Public methods

- (void)addDelegate:(id<SAVProvisionerDelegate>)delegate
{
    [self.delegates addObject:delegate];
    
    if (self.delegates.count > 0)
    {
        [self.manager startBrowse];
    }
}

- (void)removeDelegate:(id<SAVProvisionerDelegate>)delegate
{
    [self.delegates removeObject:delegate];
    
    if (self.delegates.count < 1)
    {
        [self.manager stopBrowse];
    }
}

- (void)provisionDevice:(ProvisionableDevice *)device withWifiCredentials:(WifiCredentials *)credentials
{
    NSLog(@"___%@ Attempt provision", device.uid);
    self.credentialsForUIDs[device.uid] = credentials;
    [self.manager connectToDevice:device];
}

#pragma mark Private methods

- (WifiCredentials *)credentialsForUID:(NSString *)uid
{
    WifiCredentials *credentials = self.credentialsForUIDs[uid];
    [self.credentialsForUIDs removeObjectForKey:uid];
    return credentials;
}

#pragma mark SAVProvisioningManagerDelegate methods

- (void)didConnectToProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success
{
    NSLog(@"___%@ Did connect/fail to connect in provisioner: %@", device.uid, success ? @"success" : @"failure");
    [self.manager provisionDevice:device withWifiCredentials:[self credentialsForUID:device.uid]];
}

- (void)didProvisionProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success error:(NSError *)error
{
    NSLog(@"___%@ Did provision/fail to provision in provisioner: %@ error: %@", device.uid, success ? @"success" : @"failure", error);
    
    for (id<SAVProvisionerDelegate> delegate in self.delegates)
    {
        [delegate didProvisionProvisionableDevice:device success:success error:error];
    }
}

@end
