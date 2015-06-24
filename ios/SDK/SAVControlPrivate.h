//
//  SavantControlPrivate.h
//  SavantControl
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVControl.h"
#import "SAVDemoServer.h"
#import "SAVConnectionManager.h"
#import "SAVProvisioningManager.h"

@class SAVCloudServices;
@class HostServices;
@class SAVAssServices;

extern NSString *const SAVCustomServerAddress;
extern NSString *const SAVSystemDataSubdirectory;
extern NSString *const SAVSystemManifestFile;
extern NSString *const SAVSystemInfoFile;

typedef NS_ENUM(NSInteger, SAVCloudServerAddress)
{
    SAVCloudServerAddressUnknown = -1,
    SAVCloudServerAddressProduction = 0,
    SAVCloudServerAddressAlpha = 1,
    SAVCloudServerAddressBeta = 2,
    SAVCloudServerAddressQA = 3,
    SAVCloudServerAddressDev1 = 4,
    SAVCloudServerAddressDev2 = 5,
    SAVCloudServerAddressTraining = 6,
};

@interface SAVControl () <SystemStatusDelegate>

@property (nonatomic) NSHashTable *discoveryObservers;
@property (nonatomic) NSHashTable *systemStatusObservers;
@property (nonatomic) NSHashTable *mediaResponseObservers;
@property (nonatomic) NSHashTable *binaryTransferObservers;
@property (nonatomic) NSMapTable *cameraObservers;
@property (nonatomic) NSHashTable *suspensionObservers;
@property (nonatomic) NSMutableDictionary *disResultObservers;
@property (nonatomic) SAVDemoServer *demoServer;
@property (nonatomic, readwrite) NSPointerArray *homeMonitorObservers;

@property (nonatomic, readonly) NSString *cloudWebScheme;
@property (nonatomic, readonly) NSString *cloudWebAddress;
@property (nonatomic, readonly) NSInteger cloudWebPort;
@property (nonatomic, readonly) NSString *cloudWebAPIKey;
@property (nonatomic, readonly) NSString *cloudAssAddress;
@property (nonatomic, readonly) NSURL *cloudControlURL;
@property (nonatomic, getter = isAdmin) BOOL admin;
@property (nonatomic) SAVCloudServerAddress cloudServerAddress;
@property (nonatomic, readonly) NSString *lowerCaseUserName;
@property (nonatomic) SAVConnectionManager *connectionManager;

- (void)updateServiceBlacklist:(NSSet *)serviceBlacklist andZoneBlacklist:(NSSet *)zoneBlacklist;

- (NSString *)systemsPath;
- (NSString *)sharedDataPath;
- (NSString *)systemPathForUID:(NSString *)uid;
- (NSDictionary *)manifestForSystemUID:(NSString *)uid;
- (SAVSystem *)systemForUID:(NSString *)uid;
- (NSString *)databasePathForSystemUID:(NSString *)uid;
- (NSArray *)savedSystems;
- (void)removeSavedSystemWithUID:(NSString *)uid;

@end
