//
//  SAVProvisioner.h
//  Savant
//
//  Created by Julian Locke on 5/5/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;
@class ProvisionableDevice;
@class WifiCredentials;

@protocol SAVProvisionerDelegate <NSObject>

- (void)didProvisionProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success error:(NSError *)error;

@end

@interface SAVProvisioner : NSObject

- (void)provisionDevice:(ProvisionableDevice *)device withWifiCredentials:(WifiCredentials *)credentials;

- (void)addDelegate:(id<SAVProvisionerDelegate>)delegate;
- (void)removeDelegate:(id<SAVProvisionerDelegate>)delegate;

@end
