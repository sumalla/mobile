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

#import "SAVControl.h"
#import "SAVControlPrivate.h"
#import "SavantPrivate.h"
#import "SAVStateManagerPrivate.h"
#import "SAVConnection.h"
#import "SAVSystem.h"
#import "SAVDataPrivate.h"
#import "SAVMessages.h"
#import "SAVDemoServer.h"
@import Extensions;
#import "SAVSettings.h"
#import "SAVCloudServices.h"
#import "SAVProvisioningManager.h"
#import "SAVCredentialManager.h"
#import "rpmSharedLogger.h"
#import "SDK/SDK-Swift.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

NSString *const SCSResponseErrorDomain = @"SCSResponseErrorDomain";
NSString *const SAVCustomServerAddress = @"SAVCustomServerAddress";
NSString *const SAVSystemDataSubdirectory = @"Systems";
NSString *const SAVSystemManifestFile = @"uimanifest.json";
NSString *const SAVSystemInfoFile = @"system.json";

static NSString *kSAVStateManagerRestoreKey = @"kSAVStateManagerRestoreKey";
static NSString *kSAVDemoServerRestoreKey   = @"kSAVDemoServerRestoreKey";

@interface SAVControl () <DiscoveryDelegate, SystemStatusDelegate, SAVDemoServerDelegate, SAVKeychainKeyValueStoreErrorReportingDelegate>

@property (nonatomic) SAVSystem *currentSystem;
@property (nonatomic) NSString *currentUser;

@property (nonatomic, getter = isBrowsing) BOOL browsing;
@property (nonatomic, getter = isSuspended) BOOL suspended;
@property (nonatomic, getter = isAuthorized) BOOL authorized;
@property (nonatomic, getter = isEstablished) BOOL established;
@property (nonatomic) BOOL reconnectAutomatically;
@property (nonatomic) NSString *currentPassword;
@property (nonatomic) NSDictionary *restorationInfo;
@property (nonatomic) NSMutableArray *queuedMessages;
@property (nonatomic) NSSet *tempZoneBlacklist;
@property (nonatomic) NSSet *zoneBlacklist;
@property (nonatomic) NSSet *tempServiceBlacklist;
@property (nonatomic) NSSet *serviceBlacklist;

@end

@implementation SAVControl

@dynamic currentUserName, lowerCaseUserName;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.controlMode = SAVControlModeFull;

#ifdef DEBUG
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif

        DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
        fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:fileLogger withLevel:DDLogLevelDebug];

        self.discoveryObservers = [NSHashTable weakObjectsHashTable];
        self.systemStatusObservers = [NSHashTable weakObjectsHashTable];
        self.homeMonitorObservers = [NSPointerArray weakObjectsPointerArray];
        self.mediaResponseObservers = [NSHashTable weakObjectsHashTable];
        self.binaryTransferObservers = [NSHashTable weakObjectsHashTable];
        self.cameraObservers = [NSMapTable strongToWeakObjectsMapTable];
        self.suspensionObservers = [NSHashTable weakObjectsHashTable];
        self.disResultObservers = [NSMutableDictionary dictionary];
        self.connectionManager = [[SAVConnectionManager alloc] init];
        self.demoServer = [[SAVDemoServer alloc] init];
        self.demoServer.delegate = self;
        
        [SAVKeychainKeyValueStore setServiceName:@"ZD95U33GBT.com.savantav.Controller.KeychainKeyValueStore"];
        
        SAVCloudServerAddress address = SAVCloudServerAddressUnknown;
        
#ifdef SERVER_PRODUCTION
        address = SAVCloudServerAddressProduction;
#elif defined(SERVER_ALPHA)
        address = SAVCloudServerAddressAlpha;
#elif defined(SERVER_DEV1)
        address = SAVCloudServerAddressDev1;
#elif defined(SERVER_DEV2)
        address = SAVCloudServerAddressDev2;
#elif defined(SERVER_BETA)
        address = SAVCloudServerAddressBeta;
#elif defined(SERVER_QA)
        address = SAVCloudServerAddressQA;
#elif defined(DEBUG)
        address = SAVCloudServerAddressDev2;
#endif

        self.cloudServerAddress = address;

        [SAVKeychainKeyValueStore setErrorDelegate:self];
    }

    return self;
}

#pragma mark - Logs

- (NSDictionary *)logData
{
    NSMutableDictionary *logs = [NSMutableDictionary dictionary];
    
    for (NSString *logFilePath in [[[[DDLog allLoggers] lastObject] logFileManager] sortedLogFilePaths])
    {
        NSString *fileName = [logFilePath lastPathComponent];
        NSData *fileData = [NSData dataWithContentsOfFile:logFilePath];
        logs[fileName] = fileData;
    }

    return [logs copy];
}

#pragma mark - Connection management

- (void)addSystemStatusObserver:(id<SystemStatusDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SystemStatusDelegate)]);
    [self.systemStatusObservers addObject:observer];

    if ([observer respondsToSelector:@selector(connectionDidChangeToState:)])
    {
        [observer connectionDidChangeToState:self.connectionState];
    }
}

- (void)removeSystemStatusObserver:(id<SystemStatusDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SystemStatusDelegate)]);
    [self.systemStatusObservers removeObject:observer];
}

- (void)addSuspensionObserver:(id<SuspensionDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SuspensionDelegate)]);
    [self.suspensionObservers addObject:observer];
}

- (void)removeSuspensionObserver:(id<SuspensionDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SuspensionDelegate)]);
    [self.suspensionObservers removeObject:observer];
}

- (void)connectToSystem:(SAVSystem *)system
{
    if (![self.deviceUID length])
    {
        [NSException raise:NSInternalInconsistencyException format:@"SavantControl must have a non-zero length deviceUID set"];
        return;
    }

    NSParameterAssert(system);
    self.currentUser = nil;
    self.currentPassword = nil;
    self.currentSystem = system;
    [self.connectionManager setSystem:system];
    [self.connectionManager start];
}

- (void)connectToDemoSystem
{
    SAVSystem *demoSystem = [[SAVSystem alloc] init];
    demoSystem.localAddress = @"127.0.0.1";
    demoSystem.name = NSLocalizedString(@"Example Home", nil);
    demoSystem.localScheme = @"ws";
    demoSystem.localPort = self.demoServer.port;
    demoSystem.hostID = @"demo";
    demoSystem.homeID = @"demo";
    demoSystem.notificationsEnabled = YES;
    self.reconnectAutomatically = YES;

    self.currentSystem = demoSystem;

    if (self.demoServer.isReady)
    {
        [self.connectionManager setSystem:demoSystem];
        [self.connectionManager start];
    }
    else
    {
        [self.demoServer startDemoServer];
    }
}

- (BOOL)loadPreviousConnection
{
    SAVSystem *system = [self lastConnectedSystem];

    NSString *user = nil;
    NSString *password = nil;

    if (system.isCloudSystem)
    {
        if (![Savant credentials].cloudAuthenticationToken)
        {
            system = nil;
        }
    }
    else
    {
        user = [Savant credentials].lastConnectedUserName;
        password = [Savant credentials].lastConnectedPassword;

        if (!(user && password))
        {
            system = nil;
        }
    }

    BOOL success = system ? YES : NO;

    if (success)
    {
        self.currentSystem = system;
        success = [self mountDatabase];
    }

    if (success)
    {
        self.reconnectAutomatically = YES;

        if ([system.localAddress isEqualToString:@"127.0.0.1"])
        {
            [self connectToDemoSystem];
        }
        else
        {
            [self connectToSystem:system];
        }

        self.currentUser = user;
        self.currentPassword = password;
    }
    else
    {
        self.currentSystem = nil;
    }

    return success;
}

- (void)disconnect
{
    [self disconnectIsInternal:NO];
}

- (void)suspend
{
    if (!self.isSuspended)
    {
        self.suspended = YES;
        self.reconnectAutomatically = YES;
        [self saveResotrationInfo];
        [self disconnectIsInternal:YES];
    }
}

- (void)resume
{
    if (self.isSuspended)
    {
        self.suspended = NO;
        [self _loadPreviousConnection];
    }
}

- (void)signOut
{
    [[Savant scs] signOut];
    [[Savant credentials] signOut];
    
    dispatch_async_global(^{
        NSString *lastSystem = [[[Savant control] systemsPath] stringByAppendingPathComponent:@"connection-info.json"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:lastSystem])
        {
            [[NSFileManager defaultManager] removeItemAtPath:lastSystem error:NULL];
        }
        
        for (SAVSystem *system in [[Savant control] savedSystems])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[[Savant control] systemPathForUID:system.hostID] error:NULL];
        }
        
        [[Savant images] purgeCache];
        [UIImage sav_clearImageCache];
    });
}

#pragma mark -

- (NSArray *)savedSystems
{
    NSArray *systemContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self systemsPath] error:nil];
    NSMutableArray *savedSystems = [NSMutableArray array];

    for (NSString *currSystemUID in systemContents)
    {
        SAVSystem *system = [self systemForUID:currSystemUID];
        if (system)
        {
            [savedSystems addObject:system];
        }
    }

    return savedSystems;
}

- (void)removeSavedSystemWithUID:(NSString *)uid
{
    [[NSFileManager defaultManager] removeItemAtPath:[self systemPathForUID:uid] error:nil];
}

#pragma mark - Messages

- (void)addCameraObserver:(id <CameraFetchDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(CameraFetchDelegate)]);
    [self.cameraObservers setObject:observer forKey:[observer registeredName]];
}

- (void)removeCameraObserver:(id <CameraFetchDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(CameraFetchDelegate)]);
    [self.cameraObservers removeObjectForKey:[observer registeredName]];
}

- (void)addDISResultObserver:(id <DISResultDelegate>)observer forApp:(NSString *)app
{
    NSParameterAssert([observer conformsToProtocol:@protocol(DISResultDelegate)]);

    NSHashTable *observers = [self.disResultObservers objectForKey:app];
    if (!observers)
    {
        observers = [NSHashTable weakObjectsHashTable];
        [self.disResultObservers setObject:observers forKey:app];
    }

    [observers addObject:observer];
}

- (void)removeDISResultObserver:(id <DISResultDelegate>)observer forApp:(NSString *)app
{
    NSParameterAssert([observer conformsToProtocol:@protocol(DISResultDelegate)]);

    NSHashTable *observers = [self.disResultObservers objectForKey:app];
    if (observers)
    {
        [observers removeObject:observer];
    }

    if (![observers count])
    {
        [self.disResultObservers removeObjectForKey:app];
    }
}

- (void)addBinaryTransferObserver:(id<ConnectionBinaryTransferDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(ConnectionBinaryTransferDelegate)]);
    [self.binaryTransferObservers addObject:observer];
}

- (void)removeBinaryTransferObserver:(id<ConnectionBinaryTransferDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(ConnectionBinaryTransferDelegate)]);
    [self.binaryTransferObservers removeObject:observer];
}

- (void)sendMessage:(SAVMessage *)message
{
    [self sendMessages:@[message]];
}

- (void)sendMessages:(NSArray *)messages
{
    if (!self.isAuthorized)
    {
        NSArray *messagesToSend = [messages filteredArrayUsingBlock:^BOOL(SAVMessage *message) {
            return !message.requiresAuthentication;
        }];

        NSArray *messagesToQueue = [messages filteredArrayUsingBlock:^BOOL(SAVMessage *message) {
            return message.requiresAuthentication;
        }];

        if ([messagesToSend count])
        {
            [self.connectionManager.connection sendMessages:messagesToSend];
        }

        if ([messagesToQueue count])
        {
            [self saveMessages:messagesToQueue];
        }
    }
    else
    {
        [self.connectionManager.connection sendMessages:messages];
    }
}

#pragma mark - Media

- (CBPPromise *)sendMediaRequest:(SAVMediaRequest *)request
{
    return [self.connectionManager.connection sendMediaRequest:request];
}

- (void)cancelMediaRequest:(CBPPromise *)promise
{
    [self.connectionManager.connection cancelMediaRequest:promise];
}

#pragma mark - Host Services

- (SCSCancelBlock)fetchEndpointForCamera:(SAVCameraEntity*)camera completionHandler:(SCSResponseBlock)completionHandler {
    return [Savant.hostServices fetchEndpointForCamera:camera completionHandler:completionHandler];
}

#pragma mark - Local user management

- (NSArray *)localUsers
{
    return self.connectionManager.connection.availableUsers;
}

- (BOOL)hasSavedPasswordForUser:(NSString *)user
{
    BOOL hasSavedPassword = [[Savant credentials] passwordForUserName:user] ? YES : NO;

    if (!hasSavedPassword)
    {
        hasSavedPassword = ![self userRequiresAuthentication:user];
    }

    return hasSavedPassword;
}

- (BOOL)userRequiresAuthentication:(NSString *)user
{
    return [self.connectionManager.connection userRequiresAuthentication:user];
}

- (void)loginToLocalUser:(NSString *)user password:(NSString *)password
{
    self.currentUser = user ? user : @"";
    self.currentPassword = password ? password : @"";
    [self.connectionManager.connection attemptAuthenticationWithUser:user andPassword:password];
}

- (void)loginToLocalUserWithSavedPassword:(NSString *)user
{
    [self loginToLocalUser:user password:[[Savant credentials] passwordForUserName:user]];
}

#pragma mark - DiscoveryDelegate

- (void)discovery:(SAVDiscovery *)discovery didFindSystem:(SAVSystem *)system
{
    for (id<DiscoveryDelegate> curObserver in self.discoveryObservers)
    {
        if ([curObserver respondsToSelector:@selector(discovery:didFindSystem:)])
        {
            [curObserver discovery:discovery didFindSystem:system];
        }
    }
}

- (void)discovery:(SAVDiscovery *)discovery didLoseSystem:(SAVSystem *)system
{
    for (id<DiscoveryDelegate> curObserver in self.discoveryObservers)
    {
        if ([curObserver respondsToSelector:@selector(discovery:didLoseSystem:)])
        {
            [curObserver discovery:discovery didLoseSystem:system];
        }
    }
}

- (void)discovery:(SAVDiscovery *)discovery didUpdateSystem:(SAVSystem *)system
{
    for (id<DiscoveryDelegate> curObserver in self.discoveryObservers)
    {
        if ([curObserver respondsToSelector:@selector(discovery:didUpdateSystem:)])
        {
            [curObserver discovery:discovery didUpdateSystem:system];
        }
    }
}

- (void)discoveryDidUpdateSystemList:(SAVDiscovery *)discovery
{
    for (id<DiscoveryDelegate> curObserver in self.discoveryObservers)
    {
        if ([curObserver respondsToSelector:@selector(discoveryDidUpdateSystemList:)])
        {
            [curObserver discoveryDidUpdateSystemList:discovery];
        }
    }
}

#pragma mark - SystemStatusDelegate methods

- (void)connectionDidConnect
{
    self.established = YES;

    for (id<SystemStatusDelegate> delegate in [self.systemStatusObservers copy])
    {
        if ([delegate respondsToSelector:@selector(connectionDidConnect)])
        {
            [delegate connectionDidConnect];
        }
    }
}

- (BOOL)didConnectToSystemWithProtocolVersion:(uint32_t)protocolVersion
{
    BOOL stayConnected = YES;
    BOOL assign = YES;

    for (id<SystemStatusDelegate> observer in [self.systemStatusObservers copy])
    {
        if ([observer respondsToSelector:@selector(didConnectToSystemWithProtocolVersion:)])
        {
            BOOL value = [observer didConnectToSystemWithProtocolVersion:protocolVersion];

            if (assign)
            {
                stayConnected = value;
            }

            if (!stayConnected)
            {
                //-------------------------------------------------------------------
                // Not staying connected takes priority over staying connected. So
                // ignore values once NO has been set for stayConnected at least once.
                //-------------------------------------------------------------------
                assign = NO;
            }
        }
    }

    return stayConnected;
}

- (void)connectionDidFailToConnect
{
    self.authorized = NO;

    if (self.isEstablished)
    {
        [self saveResotrationInfo];
        self.reconnectAutomatically = YES;

        for (id<SystemStatusDelegate> observer in [self.systemStatusObservers copy])
        {
            if ([observer respondsToSelector:@selector(establishedConnectionDidFail)])
            {
                [observer establishedConnectionDidFail];
            }
        }

        self.established = NO;
    }

    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidFailToConnect)])
        {
            [curObserver connectionDidFailToConnect];
        }
    }
}

- (void)connectionDidReceiveAuthChallenge
{
    self.authorized = NO;

    if (self.reconnectAutomatically)
    {
        NSString *user = [Savant credentials].lastConnectedUserName;
        NSString *password = [Savant credentials].lastConnectedPassword;

        if (self.isDemoSystem)
        {
            user = @"Example User";
        }

        if (![self userRequiresAuthentication:user])
        {
            password = @"";
        }

        [self loginToLocalUser:user password:password];
    }

    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidReceiveAuthChallenge)])
        {
            [curObserver connectionDidReceiveAuthChallenge];
        }
    }
}

- (void)connectionDidAuthorizeForUser:(NSString *)user
{
    self.authorized = YES;
    self.currentUser = user;

    if (self.connectionManager.system.isCloudSystem)
    {
        ;
    }
    else
    {
        if (!(self.currentUser && self.currentPassword))
        {
            dispatch_async_main(^{
                [self connectionShouldLogOut];
            });

            return;
        }

        [[Savant credentials] saveUserName:self.currentUser password:self.currentPassword persistPassword:YES];
    }

    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidAuthorizeForUser:)])
        {
            [curObserver connectionDidAuthorizeForUser:user];
        }
    }
}

- (void)connectionDidReceiveAuthChallengeForUser:(NSString *)user
{
    self.authorized = NO;
    self.currentUser = nil;
    self.currentPassword = nil;

    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidReceiveAuthChallengeForUser:)])
        {
            [curObserver connectionDidReceiveAuthChallengeForUser:user];
        }
    }
}

- (void)connectionIsReady
{
    if (!self.currentUser)
    {
        if (self.isConnectedToACloudSystem)
        {
            self.currentUser = [Savant credentials].cloudEmail;
        }
    }

    if (!self.currentUser)
    {
        self.currentUser = @"";
    }

    [SAVSettings resetAllSettings];

    BOOL serviceBlacklistDidChange = NO;

    if (![self.tempServiceBlacklist isEqualToSet:self.serviceBlacklist])
    {
        if ([self.serviceBlacklist count])
        {
            if (self.tempServiceBlacklist || ![self.tempServiceBlacklist count])
            {
                serviceBlacklistDidChange = YES;
            }
        }
        else
        {
            if ([self.tempServiceBlacklist count])
            {
                serviceBlacklistDidChange = YES;
            }
        }
    }

    self.serviceBlacklist = self.tempServiceBlacklist;
    self.tempServiceBlacklist = nil;

    BOOL zoneBlacklistDidChange = NO;

    if (![self.tempZoneBlacklist isEqualToSet:self.zoneBlacklist])
    {
        if ([self.zoneBlacklist count])
        {
            if (self.tempZoneBlacklist || ![self.tempZoneBlacklist count])
            {
                zoneBlacklistDidChange = YES;
            }
        }
        else
        {
            if ([self.tempZoneBlacklist count])
            {
                zoneBlacklistDidChange = YES;
            }
        }
    }

    self.zoneBlacklist = self.tempZoneBlacklist;
    self.tempZoneBlacklist = nil;

    [self mountDatabase];

    self.authorized = YES;

    [[Savant states] reset];

    if (self.reconnectAutomatically)
    {
        self.reconnectAutomatically = NO;

        if (self.restorationInfo)
        {
            [[Savant states] restoreState:self.restorationInfo[kSAVStateManagerRestoreKey]];
            [self.demoServer restoreState:self.restorationInfo[kSAVDemoServerRestoreKey]];
        }
    }

    self.restorationInfo = nil;

    if ([self.queuedMessages count])
    {
        NSArray *queuedMessages = self.queuedMessages;
        self.queuedMessages = nil;
        [self sendMessages:queuedMessages];
    }

    if (self.controlMode & SAVControlModeGlobalStates)
    {
        [[Savant states] updateGlobalStates];
    }

    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionIsReady)])
        {
            [curObserver connectionIsReady];
        }
    }

    if (zoneBlacklistDidChange || serviceBlacklistDidChange)
    {
        for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
        {
            if ([curObserver respondsToSelector:@selector(connectionPermissionsDidChange)])
            {
                [curObserver connectionPermissionsDidChange];
            }
        }
    }
}

- (void)connectionDidStartConfigurationDownload
{
    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidStartConfigurationDownload)])
        {
            [curObserver connectionDidStartConfigurationDownload];
        }
    }
}

- (void)connectionDidReceiveConfigurationDownloadUpdate:(float)progress isInstalling:(BOOL)isInstalling
{
    for (id<SystemStatusDelegate> curObserver in [self.systemStatusObservers copy])
    {
        if ([curObserver respondsToSelector:@selector(connectionDidReceiveConfigurationDownloadUpdate:isInstalling:)])
        {
            [curObserver connectionDidReceiveConfigurationDownloadUpdate:progress isInstalling:YES];
        }
    }
}

- (void)connectionDidChangeToState:(SAVConnectionState)state
{
    for (id<SystemStatusDelegate> delegate in [self.systemStatusObservers copy])
    {
        if ([delegate respondsToSelector:@selector(connectionDidChangeToState:)])
        {
            [delegate connectionDidChangeToState:state];
        }
    }
}

- (void)connectionShouldLogOut
{
    [self disconnect];
    [self signOut];

    for (id<SystemStatusDelegate> delegate in [self.systemStatusObservers copy])
    {
        if ([delegate respondsToSelector:@selector(connectionShouldLogOut)])
        {
            [delegate connectionShouldLogOut];
        }
    }
}

#pragma mark - SAVDemoServerDelegate methods

- (void)demoServerIsReady
{
    if (self.isDemoSystem)
    {
        [self connectToDemoSystem];
    }
}

#pragma mark - Property overrides

- (NSString *)lowerCaseUserName
{
    NSString *lowerCaseUserName = nil;

    if (self.isConnectedToACloudSystem && !self.isDemoSystem)
    {
        lowerCaseUserName = [Savant credentials].cloudEmail;
    }
    else
    {
        lowerCaseUserName = self.currentUser;
    }

    return [lowerCaseUserName lowercaseString];
}

- (NSString *)currentUserName
{
    NSString *currentUserName = nil;

    if (self.isConnectedToACloudSystem && !self.isDemoSystem)
    {
        NSString *cloudUserName = [Savant credentials].cloudUserName;
        NSString *cloudEmail = [Savant credentials].cloudEmail;
        currentUserName = cloudUserName ? cloudUserName : cloudEmail;
    }
    else
    {
        currentUserName = self.currentUser;
    }

    return currentUserName;
}

- (SAVConnectionState)connectionState
{
    return self.connectionManager.connectionState;
}

- (BOOL)isConnectedToSystem
{
    return (self.connectionState != SAVConnectionStateNotConnected);
}

- (BOOL)isConnectedRemotely
{
    return self.connectionManager.connection.isRemote;
}

- (BOOL)isDemoSystem
{
    return [self.currentSystem.localAddress isEqualToString:@"127.0.0.1"] ? YES : NO;
}

- (BOOL)isConnectedToACloudSystem
{
    return self.currentSystem.isCloudSystem || self.isDemoSystem;
}

- (void)setAdmin:(BOOL)admin
{
    if (_admin != admin)
    {
        _admin = admin;
        
        for (id<SystemStatusDelegate> delegate in [self.systemStatusObservers copy])
        {
            if ([delegate respondsToSelector:@selector(connectionAdminStatusDidChange)])
            {
                [delegate connectionAdminStatusDidChange];
            }
        }
    }
}

- (NSString *)cloudWebScheme
{
    return @"https";
}

- (NSString *)cloudWebAddress
{
    NSString *address = nil; /* default to production */
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (self.cloudServerAddress)
    {
        case SAVCloudServerAddressUnknown:
        case SAVCloudServerAddressProduction:
            address = @"api.savantcs.com";
            break;
        case SAVCloudServerAddressAlpha:
            address = @"calpha1-edge.savantcs.com";
            break;
        case SAVCloudServerAddressBeta:
            address = @"cbeta1-edge.savantcs.com";
            break;
        case SAVCloudServerAddressQA:
            //            address = @"nothingyet.com";
            break;
        case SAVCloudServerAddressDev1:
            address = @"cdev1-edge.savantcs.com";
            break;
        case SAVCloudServerAddressDev2:
            address = @"cdev2-edge.savantcs.com";
            break;
        case SAVCloudServerAddressTraining:
            address = @"ctrn1-edge.savantcs.com";
            break;
        default:
            break;
    }
#pragma clang diagnostic pop
    
    return address;
}

- (NSString *)cloudAssAddress
{
    NSString *address = nil; /* default to production */
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (self.cloudServerAddress)
    {
        case SAVCloudServerAddressUnknown:
        case SAVCloudServerAddressProduction:
            address = @"ass.savantcs.com";
            break;
        case SAVCloudServerAddressAlpha:
            address = @"calpha1-ass.savantcs.com";
            break;
        case SAVCloudServerAddressBeta:
            address = @"cbeta1-ass.savantcs.com";
            break;
        case SAVCloudServerAddressQA:
            //            address = @"nothingyet.com";
            break;
        case SAVCloudServerAddressDev1:
            address = @"cdev1-ass.savantcs.com";
            break;
        case SAVCloudServerAddressDev2:
            address = @"cdev2-ass.savantcs.com";
            break;
        case SAVCloudServerAddressTraining:
            address = @"ctrn1-ass.savantcs.com";
            break;
        default:
            break;
    }
#pragma clang diagnostic pop
    
    return address;
}

- (NSInteger)cloudWebPort
{
    return 443;
}

- (NSString *)cloudWebAPIKey
{
    NSString *apiKey = nil; /* default to production */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    switch (self.cloudServerAddress)
    {
        case SAVCloudServerAddressUnknown:
        case SAVCloudServerAddressProduction:
            apiKey = @"A6OFt820z11WCKoFo3C7BzK4l4hWT0";
            break;
        case SAVCloudServerAddressAlpha:
            apiKey = @"JKx2ReCG33dj60znaD8Z1gl837Hdo4";
            break;
        case SAVCloudServerAddressBeta:
            apiKey = @"jo48qx4PUpx9pb1BNApHo9eAPa1ZU4";
            break;
        case SAVCloudServerAddressQA:
//            apiKey = @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
            break;
        case SAVCloudServerAddressDev1:
            apiKey = @"oAwacBGyBJ9W9hd5yg99YTioP01plL";
            break;
        case SAVCloudServerAddressDev2:
            apiKey = @"57t9fElnbi21v46Vs4F9hfxWN6mpjc";
            break;
        case SAVCloudServerAddressTraining:
            apiKey = @"S47XSkH8693I6F8msNR61HwpXT8N69";
            break;
        default:
            break;
    }
#pragma clang diagnostic pop

    return apiKey;
}

- (NSURL *)cloudControlURL
{
    //-------------------------------------------------------------------
    // Developers can override this and return whatever they need.
    //-------------------------------------------------------------------
    return nil;
}

#pragma mark - Internal

- (void)saveMessages:(NSArray *)messages
{
    if (!self.queuedMessages)
    {
        self.queuedMessages = [NSMutableArray array];
    }

    [self.queuedMessages addObjectsFromArray:messages];
}

- (SAVSystem *)_loadPreviousConnection
{
    self.reconnectAutomatically = YES;

    SAVSystem *system = [self lastConnectedSystem];

    if (system)
    {
        if ([system.localAddress isEqualToString:@"127.0.0.1"])
        {
            [self connectToDemoSystem];
        }
        else
        {
            [self connectToSystem:system];
        }
    }

    return system;
}

- (SAVSystem *)lastConnectedSystem
{
    SAVSystem *system = nil;
    NSData *connectionInfoData = [NSData dataWithContentsOfFile:[[self systemsPath] stringByAppendingPathComponent:@"connection-info.json"]];

    if ([connectionInfoData length])
    {
        NSError *error = nil;
        NSDictionary *connectionInfo = [NSJSONSerialization JSONObjectWithData:connectionInfoData options:0 error:&error];

        if ([connectionInfo isKindOfClass:[NSDictionary class]])
        {
            system = [[SAVSystem alloc] initWithSystemInfo:connectionInfo];
        }
        else
        {
            RPMLogErr(@"Error loading last system: %@", error);
        }
    }
    else
    {
        RPMLogErr(@"No connection info for last system.");
    }

    return system;
}

- (BOOL)mountDatabase
{
    //-------------------------------------------------------------------
    // Return YES if the database could be mounted, or if it was already
    // mounted.
    //-------------------------------------------------------------------
    BOOL success = NO;

    if (self.currentSystem.hostID)
    {
        success = YES;

        if (![Savant data].databasePath && self.controlMode & SAVControlModeDatabase)
        {
            [[Savant data] updateDatabasePath:[self databasePathForSystemUID:self.currentSystem.hostID]];

            if (self.serviceBlacklist && self.zoneBlacklist)
            {
                [[Savant data] updateServiceBlacklist:self.serviceBlacklist zoneBlacklist:self.zoneBlacklist];
            }
        }
    }

    return success;
}

- (void)disconnectIsInternal:(BOOL)isInternal
{
    [self.connectionManager stop];
    self.connectionManager.system = nil;

    if (self.isDemoSystem)
    {
        [self.demoServer stopDemoServer];
    }

    [[Savant data] updateDatabasePath:nil];
    [[Savant states] reset];
    self.currentSystem = nil;
    self.currentUser = nil;
    self.currentPassword = nil;
    self.authorized = NO;
    self.reconnectAutomatically = NO;
    
    if (!isInternal)
    {
        self.tempZoneBlacklist = nil;
        self.zoneBlacklist = nil;
        self.tempServiceBlacklist = nil;
        self.serviceBlacklist = nil;
        self.established = NO;
        self.admin = NO;
        self.restorationInfo = nil;
    }
}

- (NSString *)systemsPath
{
    static NSString *systemsPath = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        systemsPath = [self sharedDataPath];
        systemsPath = [systemsPath stringByAppendingPathComponent:SAVSystemDataSubdirectory];
    });
    
    return systemsPath;
}

- (NSString *)sharedDataPath
{
    static NSString *sharedDataPath = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *groupID = [NSString stringWithFormat:@"group.%@.sharedData", [[NSBundle mainBundle] sav_rootIdentifier]];
        sharedDataPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupID] absoluteString];

        if (sharedDataPath)
        {
            sharedDataPath = [sharedDataPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        }
        else
        {
            sharedDataPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        }
    });

    return sharedDataPath;
}

- (NSString *)systemPathForUID:(NSString *)uid
{
    return [[self systemsPath] stringByAppendingPathComponent:[uid uppercaseString]];
}

- (NSDictionary *)manifestForSystemUID:(NSString *)uid
{
    NSData *manifestData = [NSData dataWithContentsOfFile:[[self systemPathForUID:uid] stringByAppendingPathComponent:SAVSystemManifestFile]];
    return manifestData ? (NSDictionary *)[NSJSONSerialization JSONObjectWithData:manifestData options:0 error:nil] : nil;
}

- (SAVSystem *)systemForUID:(NSString *)uid
{
    NSData *systemData = [NSData dataWithContentsOfFile:[[self systemPathForUID:uid] stringByAppendingPathComponent:SAVSystemInfoFile]];
    return systemData ? [[SAVSystem alloc] initWithSystemInfo:[NSJSONSerialization JSONObjectWithData:systemData options:0 error:nil]] : nil;
}

- (NSString *)databasePathForSystemUID:(NSString *)uid
{
    return [[self systemPathForUID: uid] stringByAppendingPathComponent:kSystemSQLDataFile];
}

- (void)saveResotrationInfo
{
    if (!self.restorationInfo)
    {
        NSMutableDictionary *restorationInfo = [NSMutableDictionary dictionary];
        [restorationInfo setValue:[[Savant states] restorationInfo] forKey:kSAVStateManagerRestoreKey];
        [restorationInfo setValue:[self.demoServer restorationInfo] forKey:kSAVDemoServerRestoreKey];
        self.restorationInfo = [restorationInfo copy];
    }
}

- (void)updateServiceBlacklist:(NSSet *)serviceBlacklist andZoneBlacklist:(NSSet *)zoneBlacklist
{
    self.tempServiceBlacklist = serviceBlacklist;
    self.tempZoneBlacklist = zoneBlacklist;

    if ([Savant data].databasePath)
    {
        [[Savant data] updateServiceBlacklist:serviceBlacklist zoneBlacklist:zoneBlacklist];
    }
}

#pragma mark - SAVKeychainKeyValueStoreErrorReportingDelegate

- (void)didEncounterKeychainError:(NSString *)error
{
    RPMLogErr(@"%@", error);
}

@end
