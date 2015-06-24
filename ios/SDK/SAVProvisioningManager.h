//
//  SAVProvisioningManager.h
//  Savant
//
//  Created by Julian Locke on 4/30/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;
@import Provisioner;

@protocol SAVProvisioningManagerDelegate <NSObject>

@optional

- (void)didUpdateProvisionableDevices:(NSArray *)devices;
- (void)didUpdateConnectedDevices:(NSArray *)devices;

- (void)didConnectToProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success;
- (void)didProvisionProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success error:(NSError *)error;

- (void)didReviceBTLEUnsupported;

@end

@interface SAVProvisioningManager : NSObject <WifiProvisionerDelegate>

@property (readonly, nonatomic, getter=isScanning) BOOL scanning;

+ (instancetype)sharedInstance;

- (void)startBrowse;
- (void)stopBrowse;

- (void)connectToDevice:(ProvisionableDevice *)device;
- (void)disconnectFromDevice:(ProvisionableDevice *)device;

- (void)provisionDevice:(ProvisionableDevice *)device withWifiCredentials:(WifiCredentials *)credentials;

- (void)addDelegate:(id<SAVProvisioningManagerDelegate>)delegate;
- (void)removeDelegate:(id<SAVProvisioningManagerDelegate>)delegate;

@end
