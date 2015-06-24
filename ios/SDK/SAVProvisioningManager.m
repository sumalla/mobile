//
//  SAVProvisioningManager.m
//  Savant
//
//  Created by Julian Locke on 4/30/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVProvisioningManager.h"
#import "SAVSystem.h"

#define BTLE_TIMER_INTERVAL 2
#define BTLE_MISSED_SCAN_LIMIT 6

typedef NS_ENUM(NSInteger, ProvisionableDeviceDiscoveryState)
{
    ProvisionableDeviceDiscoveryStateDeviceFound,
    ProvisionableDeviceDiscoveryStateDeviceConnected,
    ProvisionableDeviceDiscoveryStateDeviceDisconnected,
};

@interface SAVProvisioningManager ()

@property WifiProvisioner *provisioner;

@property (strong, nonatomic) NSMutableSet *delegates;

@property (strong, nonatomic) NSMutableArray *discoveredDevices;
@property (strong, nonatomic) NSMutableArray *connectedDevices;

@property (strong, nonatomic) NSTimer *scanTimer;
@property (nonatomic, getter=isScanning) BOOL scanning;

@end

@implementation SAVProvisioningManager

+ (instancetype)sharedInstance
{
    static SAVProvisioningManager *sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SAVProvisioningManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.provisioner = [[WifiProvisioner alloc] initWithDelegate:self];
        self.delegates = [[NSMutableSet alloc] init];
        self.discoveredDevices = [[NSMutableArray alloc] init];
        self.connectedDevices = [[NSMutableArray alloc] init];
        self.scanTimer = nil;
        self.scanning = NO;
    }
    
    return self;
}

#pragma mark public

- (void)startBrowse
{
    if (!self.isScanning)
    {
        [self.provisioner restartWithAlert:NO];
        self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:BTLE_TIMER_INTERVAL target:self selector:@selector(scan:) userInfo:nil repeats:YES];
        self.scanning = YES;
    }
}

- (void)stopBrowse
{
    if (self.isScanning)
    {
        [self.provisioner stopScan];
        [self invalidateScanTimer];
        self.scanning = NO;
    }
}

- (void)connectToDevice:(ProvisionableDevice *)device
{
    [self.provisioner connectToProvisionableDevice:device];
}

- (void)disconnectFromDevice:(ProvisionableDevice *)device
{
    [self.provisioner disconnectFromProvisionableDevice:device];
}

- (void)provisionDevice:(ProvisionableDevice *)device withWifiCredentials:(WifiCredentials *)credentials
{
    [self.provisioner provisionDevice:device credentials:credentials];
}

- (void)addDelegate:(id<SAVProvisioningManagerDelegate>)delegate
{
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SAVProvisioningManagerDelegate>)delegate
{
    [self.delegates removeObject:delegate];
}

#pragma mark private methods

- (void)invalidateScanTimer
{
    [self.scanTimer invalidate];
    self.scanTimer = nil;
}

- (void)scan:(NSTimer *)timer
{
    ProvisionableDevice *deviceToRemove = nil;
    
    for (ProvisionableDevice *device in self.discoveredDevices)
    {
        if (++device.scanLives > BTLE_MISSED_SCAN_LIMIT)
        {
            deviceToRemove = device;
        }
    }
    
    if (deviceToRemove)
    {
        [self.discoveredDevices removeObject:deviceToRemove];
        [self didUpdateProvisionableDevices];
    }
    
    [self.provisioner scan];
}

- (void)didUpdateProvisionableDevices
{
    for (id<SAVProvisioningManagerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(didUpdateProvisionableDevices:)])
        {
            [delegate didUpdateProvisionableDevices:self.discoveredDevices];
        }
    }
}

- (void)didUpdateConnectedDevices
{
    for (id<SAVProvisioningManagerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(didUpdateConnectedDevices:)])
        {
            [delegate didUpdateConnectedDevices:self.connectedDevices];
        }
    }
}

- (void)didConnectToProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success
{
    for (id<SAVProvisioningManagerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(didConnectToProvisionableDevice:success:)])
        {
            [delegate didConnectToProvisionableDevice:device success:success];
        }
    }
}

- (void)didProvisionProvisionableDevice:(ProvisionableDevice *)device success:(BOOL)success error:(NSError *)error
{
    for (id<SAVProvisioningManagerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(didProvisionProvisionableDevice:success:error:)])
        {
            [delegate didProvisionProvisionableDevice:device success:success error:error];
        }
    }
}

- (void)didRecieveBTLEUnsupported
{
    for (id<SAVProvisioningManagerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(didReviceBTLEUnsupported)])
        {
            [delegate didReviceBTLEUnsupported];
        }
    }
}

- (void)updateProvisionableDevice:(ProvisionableDevice *)device stateChanged:(ProvisionableDeviceDiscoveryState)state
{
    switch (state) {
        case ProvisionableDeviceDiscoveryStateDeviceFound:
        {            
            ProvisionableDevice *deviceToRemove = nil;
            
            NSUInteger insertIndex = self.discoveredDevices.count;
            
            for (ProvisionableDevice *existingDevice in self.discoveredDevices)
            {
                if ([existingDevice.uid isEqualToString:device.uid])
                {
                    deviceToRemove = existingDevice;
                    break;
                }
            }
            
            if (deviceToRemove)
            {
                insertIndex = [self.discoveredDevices indexOfObject:deviceToRemove];
                [self.discoveredDevices removeObject:deviceToRemove];
            }
            
            [self.discoveredDevices insertObject:device atIndex:insertIndex];
            [self didUpdateProvisionableDevices];
            break;
        }
        case ProvisionableDeviceDiscoveryStateDeviceConnected:
        {
            [self.discoveredDevices removeObject:device];
            [self didUpdateProvisionableDevices];

            [self.connectedDevices addObject:device];
            [self didUpdateConnectedDevices];
            
            break;
        }
        case ProvisionableDeviceDiscoveryStateDeviceDisconnected:
        {
            [self.connectedDevices removeObject:device];
            [self didUpdateConnectedDevices];
            break;
        }
    }
}

#pragma mark WifiProvisionerDelegate methods

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner foundDevice:(ProvisionableDevice * __null_unspecified)device
{
    [self updateProvisionableDevice:device stateChanged:ProvisionableDeviceDiscoveryStateDeviceFound];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner disconnectedFrom:(ProvisionableDevice * __null_unspecified)device
{
    [self updateProvisionableDevice:device stateChanged:ProvisionableDeviceDiscoveryStateDeviceDisconnected];
    [self.provisioner scan];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner connectedTo:(ProvisionableDevice * __null_unspecified)device
{
    [self updateProvisionableDevice:device stateChanged:ProvisionableDeviceDiscoveryStateDeviceConnected];
    [self didConnectToProvisionableDevice:device success:YES];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner failedToConnectTo:(ProvisionableDevice * __null_unspecified)device
{
    [self didConnectToProvisionableDevice:device success:NO];
    [self.provisioner scan];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner provisionedDevice:(ProvisionableDevice * __null_unspecified)device
{
    [self didProvisionProvisionableDevice:device success:YES error:nil];
    [self.provisioner scan];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner failedToProvisionDevice:(ProvisionableDevice * __null_unspecified)device error:(NSError * __nonnull)error
{
    [self didProvisionProvisionableDevice:device success:NO error:error];
    [self.provisioner scan];
}

- (void)provisioner:(WifiProvisioner * __null_unspecified)provisioner declinedCredentials:(WifiCredentials * __nonnull)credentials forDevice:(ProvisionableDevice * __null_unspecified)device
{
    [self didProvisionProvisionableDevice:device success:NO error:[NSError errorWithDomain:@"Provisioner" code:-1 userInfo:nil]];
}

- (void)provisionerIsUnsupported:(WifiProvisioner * __null_unspecified)provisioner {
    [self didRecieveBTLEUnsupported];
}

@end
