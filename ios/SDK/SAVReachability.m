/*
 File: Reachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 Version: 3.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
 
 SAVReachability.m
 SavantControl
 
 Created by Stephen Silber on 4/23/15.
 */

@import Extensions;
@import CoreBluetooth;
@import SystemConfiguration.CaptiveNetwork;

#import "SAVReachability.h"
#import "Reachability.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <net/if.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface SAVReachability () <CBPeripheralManagerDelegate>

@property (nonatomic) NSString *currentSSID;
@property (nonatomic, getter=isWifiEnabled) BOOL wifiEnabled;
@property (nonatomic, getter=isBluetoothEnabled) BOOL bluetoothEnabled;

@property (nonatomic) NSHashTable *observers;
@property (nonatomic) CBPeripheralManager *bluetoothManager;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;

@end

static NSString *const SAVReachabilityKeySSID = @"SSID";

@implementation SAVReachability

+ (SAVReachability *)sharedInstance
{
    static SAVReachability *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [[SAVReachability alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.observers = [NSHashTable weakObjectsHashTable];
        
        dispatch_queue_t queue = dispatch_get_main_queue();
        self.bluetoothManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue];
        
        NSString *remoteHostName = @"www.savant.com";
        self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
        [self.hostReachability startNotifier];
        
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        [self.internetReachability startNotifier];
        
        self.wifiReachability = [Reachability reachabilityForLocalWiFi];
        [self.wifiReachability startNotifier];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        #endif
        
    }
    
    return self;
}

- (void)dealloc
{
    
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    #endif
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [self.wifiReachability stopNotifier];
    [self.internetReachability stopNotifier];
    [self.hostReachability stopNotifier];
}

- (void)appEnteredForeground:(NSNotification *)note
{
    if (self.wifiEnabled)
    {
        NSDictionary *ssidInfo = [self fetchSSIDInfo];
        if (ssidInfo[SAVReachabilityKeySSID])
        {
            self.currentSSID = ssidInfo[SAVReachabilityKeySSID];
        }
    }
    else
    {
        self.currentSSID = nil;
    }
}

#pragma mark - Wifi manager

- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    
    self.wifiEnabled = [self isWifiRadioEnabled];

    if (self.wifiEnabled)
    {
        NSDictionary *ssidInfo = [self fetchSSIDInfo];
        if (ssidInfo[SAVReachabilityKeySSID])
        {
            self.currentSSID = ssidInfo[SAVReachabilityKeySSID];
        }
    }
    else
    {
        self.currentSSID = nil;
    }
}

#pragma mark - Bluetooth manager

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOff:
            self.bluetoothEnabled = NO;
            break;
        case CBPeripheralManagerStatePoweredOn:
            self.bluetoothEnabled = YES;
            break;
        default:
            break;
    }
}

#pragma mark - Reachability Observer handling

- (void)addReachabilityObserver:(id<SAVReachabilityDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVReachabilityDelegate)]);
    [self.observers addObject:observer];
    
    [self updateObserverOfBluetoothStatus:observer];
    [self updateObserverOfWifiStatus:observer];
    [self updateObserverOfCurrentSSID:observer];
}

- (void)removeReachabilityObserver:(id<SAVReachabilityDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVReachabilityDelegate)]);
    [self.observers removeObject:observer];
}

- (void)updateObserverOfWifiStatus:(id<SAVReachabilityDelegate>)observer
{
    if ([observer respondsToSelector:@selector(wifiStatusDidChange:)])
    {
        [observer wifiStatusDidChange:self.isWifiEnabled];
    }
}

- (void)updateObserversOfWifiStatus
{
    for (id<SAVReachabilityDelegate> observer in [self.observers copy])
    {
        [self updateObserverOfWifiStatus:observer];
    }
}

- (void)updateObserverOfBluetoothStatus:(id<SAVReachabilityDelegate>)observer
{
    if ([observer respondsToSelector:@selector(bluetoothStatusDidChange:)])
    {
        [observer bluetoothStatusDidChange:self.isBluetoothEnabled];
    }
}

- (void)updateObserversOfBluetoothStatus
{
    for (id<SAVReachabilityDelegate> observer in [self.observers copy])
    {
        [self updateObserverOfBluetoothStatus:observer];
    }
}

- (void)updateObserverOfCurrentSSID:(id<SAVReachabilityDelegate>)observer
{
    if ([observer respondsToSelector:@selector(currentSSIDDidChange:)])
    {
        [observer currentSSIDDidChange:self.currentSSID];
    }
}

- (void)updateObserversOfCurrentSSID
{
    for (id<SAVReachabilityDelegate> observer in [self.observers copy])
    {
        [self updateObserverOfCurrentSSID:observer];
    }
}

- (void)setBluetoothEnabled:(BOOL)bluetoothEnabled
{
    if (_bluetoothEnabled != bluetoothEnabled)
    {
        _bluetoothEnabled = bluetoothEnabled;
        [self updateObserversOfBluetoothStatus];
    }
}

- (void)setWifiEnabled:(BOOL)wifiEnabled
{
    if (_wifiEnabled != wifiEnabled)
    {
        _wifiEnabled = wifiEnabled;
        [self updateObserversOfWifiStatus];
    }
}

- (void)setCurrentSSID:(NSString *)currentSSID
{
    if (![_currentSSID isEqualToString:currentSSID])
    {
        _currentSSID = currentSSID;
        [self updateObserversOfCurrentSSID];
    }
}

#pragma mark - Wifi utility methods

/** Returns first non-empty SSID network info dictionary.
 *  @see CNCopyCurrentNetworkInfo */
- (NSDictionary *)fetchSSIDInfo
{
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    return SSIDInfo;
}

- (BOOL)isWifiRadioEnabled {
    
    NSCountedSet * cset = [NSCountedSet new];
    
    struct ifaddrs *interfaces;
    
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
            }
        }
    }
    
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

#pragma mark - Debug Description

- (NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"BT: %d - WiFi: %d - SSID: %@", self.isBluetoothEnabled, self.isWifiEnabled, self.currentSSID];
    return description;
}

@end
