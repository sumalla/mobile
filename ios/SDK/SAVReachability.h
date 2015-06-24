//
//  SAVReachability.h
//  SavantControl
//
//  Created by Stephen Silber on 4/23/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;

@protocol SAVReachabilityDelegate <NSObject>

@optional

- (void)bluetoothStatusDidChange:(BOOL)enabled;

- (void)wifiStatusDidChange:(BOOL)enabled;

- (void)currentSSIDDidChange:(NSString *)ssid;

@end

@interface SAVReachability : NSObject

@property (nonatomic, readonly, getter=isWifiEnabled) BOOL wifiEnabled;

@property (nonatomic, readonly, getter=isBluetoothEnabled) BOOL bluetoothEnabled;

@property (nonatomic, readonly) NSString *currentSSID;

+ (SAVReachability *)sharedInstance;

- (void)addReachabilityObserver:(id<SAVReachabilityDelegate>)observer;

- (void)removeReachabilityObserver:(id<SAVReachabilityDelegate>)observer;

@end
