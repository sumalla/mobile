    //====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2013 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2013 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2013 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

#import "SAVDiscoveryPrivate.h"
#import "SavantPrivate.h"
#import "SAVCloudServices.h"
#import "RPMDiscoveryScanner.h"
#import "SAVSystem.h"
#import "SAVCoalescedTimer.h"
#import "rpmSharedLogger.h"
#import "SAVControlPrivate.h"
@import Extensions;

NSString *const SAVDiscoveryCloudSystemsKey = @"SAVDiscoveryCloudSystemsKey";
NSString *const SAVDiscoveryLocalSystemsKey = @"SAVDiscoveryLocalSystemsKey";
NSString *const SAVDiscoveryProvisionableSystemsKey = @"SAVDiscoveryProvisionableSystemsKey";

NSString *const SAVDiscoveryPeripheralLightingKey = @"SAVDiscoveryPeripheralLightingKey";
NSString *const SAVDiscoveryPeripheralLampModuleKey = @"SAVDiscoveryPeripheralLampModuleKey";
NSString *const SAVDiscoveryPeripheralCameraKey = @"SAVDiscoveryPeripheralCameraKey";
NSString *const SAVDiscoveryPeripheralControllersKey = @"SAVDiscoveryPeripheralControllersKey";

@interface SAVDiscovery () <RPMDiscoveryScannerDelegate, SAVProvisioningManagerDelegate>

@property (nonatomic) NSHashTable *delegates;
@property (nonatomic) RPMDiscoveryScanner *scanner;
@property (nonatomic) NSMutableDictionary *localSystems;
@property (nonatomic, copy) NSArray *lastCloudSystems;
@property (nonatomic, copy) NSArray *cloudSystems;
@property (nonatomic, copy) SCSCancelBlock cloudDiscoveryCancel;
@property (nonatomic) SAVCoalescedTimer *systemsUpdateTimer;
@property (nonatomic, copy) NSDictionary *groupedSystems;
@property (nonatomic, copy) NSDictionary *groupedPeripherals;
@property (nonatomic, weak) NSTimer *initialUpdateTimer;
@property (nonatomic) NSArray *provisionableSystems;
@property (nonatomic) NSArray *provisionablePeripherals;
@property (nonatomic) NSArray *previousProvisionableSystems;
@property (nonatomic) NSArray *previousProvisionablePeripherals;
@property (nonatomic) NSArray *provisionableLightingPeripherals;
@property (nonatomic) NSArray *provisionableCameraPeripherals;

@end

@implementation SAVDiscovery

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.delegates = [NSHashTable weakObjectsHashTable];
        self.localSystems = [NSMutableDictionary dictionary];
        self.cloudSystems = @[];
        self.groupedSystems = @{};
        self.provisionableSystems = @[];
        self.previousProvisionableSystems = @[];
        self.provisionablePeripherals = @[];
        self.previousProvisionablePeripherals = @[];
    }
    
    return self;
}

- (void)dealloc
{
    self.scanner.delegate = nil;
}

- (void)addDiscoveryObserver:(id<DiscoveryDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(DiscoveryDelegate)]);
    [self.delegates addObject:observer];
    
    if ([self.delegates count] == 1)
    {
        [self startBrowse];
    }
}

- (void)removeDiscoveryObserver:(id<DiscoveryDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(DiscoveryDelegate)]);
    [self.delegates removeObject:observer];
    
    if ([self.delegates count] == 0)
    {
        [self stopBrowse];
    }
}

- (void)startBrowse
{
    if (!self.scanner)
    {
        self.systemsUpdateTimer = [[SAVCoalescedTimer alloc] init];
        self.systemsUpdateTimer.timeInverval = .1;
        
        self.scanner = [[RPMDiscoveryScanner alloc] init];
        self.scanner.delegate = self;

        if ([Savant cloud].hasCloudCredentials)
        {
            [self scanCloudSystemsAndAllowRetry:YES];
            
            if (self.scanImmediately)
            {
                [self.scanner startScan];
            }
        }
        else
        {
            [self.scanner startScan];
            
            SAVWeakSelf;
            self.initialUpdateTimer = [NSTimer sav_scheduledBlockWithDelay:1 block:^{
                [wSelf updateSystemsList];
            }];
        }
    }

    [[SAVProvisioningManager sharedInstance] addDelegate:self];
    [[SAVProvisioningManager sharedInstance] startBrowse];
}

- (void)stopBrowse
{
    [self.systemsUpdateTimer invalidate];
    self.systemsUpdateTimer = nil;
    
    self.scanner.delegate = nil;
    [self.scanner stopScan];
    self.scanner = nil;
    
    if (self.cloudDiscoveryCancel)
    {
        self.cloudDiscoveryCancel();
    }
    
    self.lastCloudSystems = nil;
    [self.localSystems removeAllObjects];
    self.cloudSystems = @[];
    self.provisionableSystems = @[];
    self.previousProvisionableSystems = @[];
    
    [[SAVProvisioningManager sharedInstance] removeDelegate:self];
    [[SAVProvisioningManager sharedInstance] stopBrowse];
}

- (BOOL)update
{
    BOOL success = NO;
    if ([Savant cloud].hasCloudCredentials)
    {
        success = YES;
        [self scanCloudSystemsAndAllowRetry:YES];
    }
    
    return success;
}

- (NSArray *)combinedCloudAndLocalSystems
{
    NSMutableArray *combinedCloudAndLocalSystems = [NSMutableArray array];
    
    NSArray *cloudSystems = self.groupedSystems[SAVDiscoveryCloudSystemsKey];
    
    if ([cloudSystems count])
    {
        [combinedCloudAndLocalSystems addObjectsFromArray:cloudSystems];
    }
    
    NSArray *localSystems = self.groupedSystems[SAVDiscoveryLocalSystemsKey];
    
    if ([localSystems count])
    {
        [combinedCloudAndLocalSystems addObjectsFromArray:localSystems];
    }
    
    return [combinedCloudAndLocalSystems copy];
}

- (NSArray *)combinedPeripherals
{
    NSMutableArray *combinedPeripherals = [NSMutableArray array];
    
    NSArray *lightingPeripherals = self.groupedPeripherals[SAVDiscoveryPeripheralLightingKey];
    
    if ([lightingPeripherals count])
    {
        [combinedPeripherals addObjectsFromArray:lightingPeripherals];
    }
    
    NSArray *lampModulePeripherals = self.groupedPeripherals[SAVDiscoveryPeripheralLampModuleKey];
    
    if ([lampModulePeripherals count])
    {
        [combinedPeripherals addObjectsFromArray:lampModulePeripherals];
    }
    
    NSArray *cameraPeripherals = self.groupedPeripherals[SAVDiscoveryPeripheralCameraKey];
    
    if ([cameraPeripherals count])
    {
        [combinedPeripherals addObjectsFromArray:cameraPeripherals];
    }
    
    NSArray *controllerPeripherals = self.groupedPeripherals[SAVDiscoveryPeripheralControllersKey];
    
    if ([controllerPeripherals count])
    {
        [combinedPeripherals addObjectsFromArray:controllerPeripherals];
    }
    
    return [combinedPeripherals copy];
}

- (void)scanCloudSystemsAndAllowRetry:(BOOL)allowRetry
{
    SAVWeakSelf;
    self.cloudDiscoveryCancel = [[Savant scs] listHomes:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        SAVStrongWeakSelf;
        NSArray *cloudSystems = SAV_AS_CLASS(data, NSArray);

        if (success && cloudSystems)
        {
            if (![cloudSystems isEqualToArray:sSelf.lastCloudSystems])
            {
                sSelf.lastCloudSystems = cloudSystems;
                sSelf.cloudSystems = [SAVDiscovery parseCloudSystems:cloudSystems];
            }
        }
        else
        {
            RPMLogErr(@"Cloud discovery error: %@", error);
            
            if (allowRetry)
            {
                [sSelf scanCloudSystemsAndAllowRetry:NO];
                RPMLogErr(@"Retrying to scan for cloud systems");
            }
        }
        
        [sSelf didUpdateSystemsList]; /* update immediately */
        [sSelf.scanner startScan];
    }];
}

+ (NSArray *)parseCloudSystems:(NSArray *)unparsedcloudSystems
{
    return [unparsedcloudSystems arrayByMappingBlock:^id(NSDictionary *s) {
        SAVSystem *system = [[SAVSystem alloc] init];
        system.name = [NSNull nilOrIdentityFromObject:s[@"name"]];
        system.hostID = [NSNull nilOrIdentityFromObject:s[@"uid"]];
        system.homeID = [NSNull nilOrIdentityFromObject:s[@"id"]];
        system.cloudSystem = YES;
        system.hasRemoteAccess = [[NSNull nilOrIdentityFromObject:s[@"remoteAccessEnabled"]] boolValue];
        system.cellURL = [NSURL URLWithString:[NSNull nilOrIdentityFromObject:s[@"cellUrl"]]];
        system.cloudOnline = [[NSNull nilOrIdentityFromObject:s[kSAVSystemCloudOnlineKey]] boolValue];
        system.notificationsEnabled = [[NSNull nilOrIdentityFromObject:s[kSAVSystemNotificationsEnabledKey]] boolValue];
        system.notificationsDisabledReason = [NSNull nilOrIdentityFromObject:s[kSAVSystemNotificationsDisabledReasonKey]];
        
        NSString *remoteAccessDisabledReason = [NSNull nilOrIdentityFromObject:s[@"remoteAccessDisabledReason"]];
        
        if ([remoteAccessDisabledReason isEqualToString:@"PERMISSION_NOT_GRANTED"])
        {
            system.remoteAccessDisableReason = SAVSystemRemoteAccessDisabledReasonNotGranted;
        }
        else if ([remoteAccessDisabledReason isEqualToString:@"TRIAL_PERIOD_EXPIRED"])
        {
            system.remoteAccessDisableReason = SAVSystemRemoteAccessDisabledReasonTrialPeriodExpired;
        }
        else if ([remoteAccessDisabledReason isEqualToString:@"PAST_DUE"])
        {
            system.remoteAccessDisableReason = SAVSystemRemoteAccessDisabledReasonTrialPeriodExpired;
        }
        
        if (!system.name)
        {
            system.name = system.hostID;
        }
        
        return system;
    }];
}

#pragma mark - RPMDiscoveryScannerDelegate methods

- (void)foundSavantEndpoint:(NSDictionary *)info
{
    SAVSystem *system = [[SAVSystem alloc] initWithSystemInfo:info];
    
    if (system.version < 2)
    {
        return;
    }
    
    self.localSystems[system.hostID] = system;
    for (id<DiscoveryDelegate> delegate in [self.delegates allObjects])
    {
        if ([delegate respondsToSelector:@selector(discovery:didFindSystem:)])
        {
            [delegate discovery:self
                  didFindSystem:system];
        }
    }
    
    [self updateSystemsList];
}

- (void)lostSavantEndpoint:(NSDictionary *)info
{
    SAVSystem *system = [[SAVSystem alloc] initWithSystemInfo:info];
    
    if (system.version < 2)
    {
        return;
    }
    
    for (id<DiscoveryDelegate> delegate in [self.delegates allObjects])
    {
        if ([delegate respondsToSelector:@selector(discovery:didLoseSystem:)])
        {
            [delegate discovery:self
                  didLoseSystem:system];
        }
    }
    
    [self.localSystems removeObjectForKey:system.hostID];
    [self updateSystemsList];
}

- (void)updatedSavantEndpoint:(NSDictionary *)info
{
    SAVSystem *system = [[SAVSystem alloc] initWithSystemInfo:info];
    
    if (system.version < 2)
    {
        return;
    }
    
    self.localSystems[system.hostID] = system;
    
    for (id<DiscoveryDelegate> delegate in [self.delegates allObjects])
    {
        if ([delegate respondsToSelector:@selector(discovery:didUpdateSystem:)])
        {
            [delegate discovery:self
                didUpdateSystem:system];
        }
    }
    
    [self updateSystemsList];
}

- (void)updateSystemsList
{
    [self.initialUpdateTimer invalidate];
    self.initialUpdateTimer = nil;
    
    SAVWeakSelf;
    [self.systemsUpdateTimer addWorkWithKey:@"update" work:^{
        [wSelf didUpdateSystemsList];
    }];
}

- (void)updatePeripheralsList
{
    NSMutableDictionary *groupedPeripherals = [NSMutableDictionary dictionary];
    
    NSArray *lightingPeripherals = [self.provisionablePeripherals arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] == DeviceTypeLighting)
        {
            return object;
        }
        return nil;
    }];
    
    NSArray *lampModulePeripherals = [self.provisionablePeripherals arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] == DeviceTypeLampModule)
        {
            return object;
        }
        return nil;
    }];
    
    NSArray *cameraPeripherals = [self.provisionablePeripherals arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] == DeviceTypeCamera)
        {
            return object;
        }
        return nil;
    }];
    
    NSArray *controllerPeripherals = [self.provisionablePeripherals arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] == DeviceTypeController)
        {
            return object;
        }
        return nil;
    }];
    
    NSComparator comparator = ^NSComparisonResult(SAVSystem *system1, SAVSystem *system2) {
        return [system1.name compare:system2.name options:NSCaseInsensitiveSearch | NSNumericSearch];
    };
    
    if ([lightingPeripherals count])
    {
        groupedPeripherals[SAVDiscoveryPeripheralLightingKey] = [lightingPeripherals sortedArrayUsingComparator:comparator];
    }
    
    if ([lampModulePeripherals count])
    {
        groupedPeripherals[SAVDiscoveryPeripheralLampModuleKey] = [lampModulePeripherals sortedArrayUsingComparator:comparator];
    }
    
    if ([cameraPeripherals count])
    {
        groupedPeripherals[SAVDiscoveryPeripheralCameraKey] = [cameraPeripherals sortedArrayUsingComparator:comparator];
    }
    
    if ([controllerPeripherals count])
    {
        groupedPeripherals[SAVDiscoveryPeripheralControllersKey] = [controllerPeripherals sortedArrayUsingComparator:comparator];
    }
    
    self.groupedPeripherals = groupedPeripherals;
    
    for (id<DiscoveryDelegate> delegate in [self.delegates allObjects])
    {
        if ([delegate respondsToSelector:@selector(discoveryDidUpdateProvisionablePeripheralList:)])
        {
            [delegate discoveryDidUpdateProvisionablePeripheralList:self];
        }
    }
}

- (void)didUpdateSystemsList
{
    NSMutableDictionary *groupedSystems = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *localSystemsDict = [[self.localSystems copy] mutableCopy];
    
    NSArray *cloudSystems = [self.cloudSystems arrayByMappingBlock:^id(SAVSystem *system) {
        
        SAVSystem *systemToSave = system;
        SAVSystem *localSystem = self.localSystems[system.hostID];
        
        if (localSystem)
        {
            [localSystemsDict removeObjectForKey:system.hostID];
        }
        
        if (!localSystem)
        {
            NSString *hostIDToRemove = nil;
            
            for (SAVSystem *ls in [localSystemsDict allValues])
            {
                if ([ls.homeID isEqualToString:system.homeID])
                {
                    hostIDToRemove = ls.hostID;
                    localSystem = ls;
                    break;
                }
            }
            
            if (hostIDToRemove)
            {
                [localSystemsDict removeObjectForKey:hostIDToRemove];
            }
        }
        
        if (localSystem)
        {
            [localSystemsDict removeObjectForKey:system.hostID];
            localSystem.cloudSystem = system.cloudSystem;
            localSystem.hasRemoteAccess = system.hasRemoteAccess;
            localSystem.cellURL = system.cellURL;
            localSystem.cloudOnline = system.isCloudOnline;
            localSystem.notificationsEnabled = system.notificationsEnabled;
            localSystem.notificationsDisabledReason = system.notificationsDisabledReason;
            systemToSave = localSystem;
        }
        
        return systemToSave;
        
    }];
    
    NSArray *localSystems = [localSystemsDict allValues];
    
    NSArray *provisionableSystems = self.provisionableSystems;
    
    NSComparator comparator = ^NSComparisonResult(SAVSystem *system1, SAVSystem *system2) {
        return [system1.name compare:system2.name options:NSCaseInsensitiveSearch | NSNumericSearch];
    };
    
    if ([localSystems count])
    {
        groupedSystems[SAVDiscoveryLocalSystemsKey] = [localSystems sortedArrayUsingComparator:comparator];
    }
    
    if ([cloudSystems count])
    {
        groupedSystems[SAVDiscoveryCloudSystemsKey] = [cloudSystems sortedArrayUsingComparator:comparator];
    }
    
    if ([provisionableSystems count])
    {
        groupedSystems[SAVDiscoveryProvisionableSystemsKey] = [provisionableSystems sortedArrayUsingComparator:comparator];
    }
    
    self.groupedSystems = groupedSystems;
    
    for (id<DiscoveryDelegate> delegate in [self.delegates allObjects])
    {
        if ([delegate respondsToSelector:@selector(discoveryDidUpdateSystemList:)])
        {
            [delegate discoveryDidUpdateSystemList:self];
        }
    }
}

- (SCSCancelBlock)cloudHomesWithCompletionHandler:(void (^)(BOOL success, NSArray *systems, NSError *error))completionHandler
{
    return [[Savant scs] listHomes:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        NSArray *systems = (NSArray *)data;
        
        if (success && [systems isKindOfClass:[NSArray class]])
        {
            completionHandler(YES, [SAVDiscovery parseCloudSystems:data], nil);
        }
        else
        {
            completionHandler(NO, nil, error);
        }
    }];
}

#pragma mark ProvisionableDeviceDiscoveryDelegate methods

- (void)didUpdateProvisionableDevices:(NSArray *)devices
{
    NSArray *hosts = nil;
    NSArray *peripherals = nil;
    
    hosts = [devices arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] == DeviceTypeHost)
        {
            return object;
        }
        return nil;
    }];
    
    peripherals = [devices arrayByMappingBlock:^id(ProvisionableDevice *object) {
        if ([object deviceType] != DeviceTypeHost)
        {
            return object;
        }
        return nil;
    }];
    
    if (hosts.count)
    {
        [self didUpdateProvisionableHosts:hosts];
    }
    
    if (peripherals.count)
    {
        [self didUpdateProvisionablePeripherals:peripherals];
    }
}

- (void)didReviceBTLEUnsupported
{
    //JRL: TODO
}

#pragma mark ProvisionableDeviceDiscoveryDelegate helper methods

- (void)didUpdateProvisionableHosts:(NSArray *)hosts
{
    if ([self needsUpdateNew:hosts Old:self.previousProvisionableSystems])
    {
        self.previousProvisionableSystems = [self.provisionableSystems copy];
        self.provisionableSystems = hosts;
        [self updateSystemsList];
    }
}

- (void)didUpdateProvisionablePeripherals:(NSArray *)peripherals
{
    if ([self needsUpdateNew:peripherals Old:self.previousProvisionablePeripherals])
    {
        self.previousProvisionablePeripherals = [self.provisionablePeripherals copy];
        self.provisionablePeripherals = peripherals;
        [self updatePeripheralsList];
    }
}

- (BOOL)needsUpdateNew:(NSArray *)new Old:(NSArray *)old
{
    BOOL needsUpdate = NO;
    
    NSMutableSet *previousUIDs = [NSMutableSet setWithArray:[old arrayByMappingBlock:^id(ProvisionableDevice *device) {
        return device.uid;
    }]];
    
    NSMutableSet *currentUIDs = [NSMutableSet setWithArray:[new arrayByMappingBlock:^id(ProvisionableDevice *device) {
        return device.uid;
    }]];
    
    NSMutableSet *previousUIDsIntersectCurrent = [previousUIDs mutableCopy];
    [previousUIDsIntersectCurrent intersectSet:currentUIDs];
    
    if ((previousUIDsIntersectCurrent.count != previousUIDs.count) || (previousUIDsIntersectCurrent.count != currentUIDs.count))
    {
        needsUpdate = YES;
    }
    
    return needsUpdate;
}

@end