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

#import "SAVConnectionManager.h"
#import "SAVDiscoveryPrivate.h"
#import "SAVConnection.h"
#import "SAVStateManager.h"
#import "SAVControlPrivate.h"
#import "SAVSystem.h"
#import "rpmSharedLogger.h"
#import "SAVCredentialManager.h"
#import "SavantPrivate.h"
@import Extensions;

@interface SAVConnectionManager () <DiscoveryDelegate, ConnectionStatusDelegate, ConnectionStateUpdateDelegate, ConnectionDISDelegate>

@property (nonatomic) NSTimeInterval connectionTimeoutInterval;
@property (nonatomic) NSTimeInterval retryInterval;
@property (nonatomic) SAVConnectionState connectionState;
@property (nonatomic) SAVConnectionState internalConnectionState;
@property (nonatomic) SAVConnection *connection;
@property (nonatomic) SAVDiscovery *discoveryScanner;
@property (nonatomic) NSURL *currentURL;
@property (nonatomic, weak) NSTimer *connectionTimeoutTimer;
@property (nonatomic, weak) NSTimer *tryNextConnectionTimer;
@property (nonatomic) SAVCoalescedTimer *cloudUpdateTimer;

@end

@implementation SAVConnectionManager

- (id)init
{
    self = [super init];

    if (self)
    {
        self.connectionTimeoutInterval = 5;
        self.retryInterval = 2;
        self.cloudUpdateTimer = [[SAVCoalescedTimer alloc] init];
        self.cloudUpdateTimer.timeInverval = 6;
    }

    return self;
}

- (void)setSystem:(SAVSystem *)system
{
    if (![system.hostID isEqualToString:_system.hostID])
    {
        [self stop];

        if (system)
        {
            if (system.lastURL)
            {
                self.currentURL = system.lastURL;

                if ([self.currentURL isEqual:system.localURL])
                {
                    self.internalConnectionState = SAVConnectionStateLocal;
                }
                else if ([self.currentURL isEqual:system.cellURL])
                {
                    self.internalConnectionState = SAVConnectionStateCloud;
                }
            }
            else if (system.localURL)
            {
                self.currentURL = system.localURL;
                self.internalConnectionState = SAVConnectionStateLocal;
            }
            else if (system.cellURL)
            {
                self.currentURL = system.cellURL;
                self.internalConnectionState = SAVConnectionStateCloud;
            }
        }

        NSString *currentSSID = [[UIDevice currentDevice] currentSSID];
        NSString *savedSSID = system.SSID;
        BOOL willAttemptALocalConnection = self.internalConnectionState == SAVConnectionStateLocal;
        BOOL thereIsAnSSID = [currentSSID length] ? YES : NO;
        BOOL thereIsNotAnSSID = !thereIsAnSSID;
        BOOL thereIsASavedSSID = [savedSSID length] ? YES : NO;
        BOOL theSSIDIsNotTheSameAsTheLastConnectedSSID = NO;

        //-------------------------------------------------------------------
        // Check to make sure both SSIDs are valid before comparing. Otherwise
        // the first time you tap a system there will be no savedSSID so we
        // would potentially skip a local connection.
        //-------------------------------------------------------------------
        if (thereIsAnSSID && thereIsASavedSSID && ![currentSSID isEqualToString:savedSSID])
        {
            theSSIDIsNotTheSameAsTheLastConnectedSSID = YES;
        }

        if (willAttemptALocalConnection && (thereIsNotAnSSID || (theSSIDIsNotTheSameAsTheLastConnectedSSID)))
        {
            RPMLogErr(@"Attempting to skip local connection. SSID %d different %d", thereIsNotAnSSID, theSSIDIsNotTheSameAsTheLastConnectedSSID);

            if (system.cellURL)
            {
                //-------------------------------------------------------------------
                // If there is currently no SSID and we are attempting a local
                // conneciton, try using the remote connection instead.
                //-------------------------------------------------------------------
                self.currentURL = system.cellURL;
                self.internalConnectionState = SAVConnectionStateCloud;
            }
            else
            {
                RPMLogErr(@"No remote connections to try, sticking with local.");
            }
        }
    }

    _system = system;
}

- (void)start
{
    RPMLogErr(@"Starting conneciton manager");
    [self startConnection];
}

- (void)stop
{
    RPMLogErr(@"Stopping connection manager");
    self.connectionState = SAVConnectionStateNotConnected;
    self.internalConnectionState = SAVConnectionStateNotConnected;

    [self stopBrowse];
    self.connection.statusDelegate = nil;
    self.connection.stateDelegate = nil;
    self.connection.disDelegate = nil;
    self.connection.messageDelegate = nil;
    [self.connection disconnect];
    self.connection = nil;
    self.currentURL = nil;
    [self invalidateTimers];
    [self.cloudUpdateTimer invalidate];
}

- (void)promoteCurrentSystemToACloudSystem
{
    if (self.system)
    {
        self.system.cloudSystem = YES;
        self.system.hasRemoteAccess = YES;
        [self saveInfo];
    }
}

#pragma mark - Property overrides

- (void)setConnectionState:(SAVConnectionState)connectionState
{
    if (_connectionState != connectionState)
    {
        _connectionState = connectionState;

        [[Savant control] connectionDidChangeToState:connectionState];
    }
}

#pragma mark -

- (void)saveInfo
{
    NSDictionary *systemInfo = [self.system dictionaryRepresentation];

    NSData *data = nil;
    NSError *error = nil;

    if ([systemInfo isKindOfClass:[NSDictionary class]])
    {
        data = [NSJSONSerialization dataWithJSONObject:systemInfo options:0 error:&error];
    }

    if (data)
    {
        if (self.system.hostID)
        {
            [data writeToFile:[[[Savant control] systemPathForUID:self.system.hostID] stringByAppendingPathComponent:SAVSystemInfoFile] atomically:YES];
        }
        else
        {
            RPMLogErr(@"There is no host UID to save information by");
        }

        [data writeToFile:[[[Savant control] systemsPath] stringByAppendingPathComponent:@"connection-info.json"] atomically:YES];
    }
    else
    {
        RPMLogErr(@"Error serializing system info: %@", error);
    }
}

#pragma mark - ConnectionStateDelegate

- (void)connection:(SAVConnection *)connection didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    [[Savant states] didReceiveStateUpdate:stateUpdate];
}

#pragma mark - ConnectionDISDelegate

- (void)connection:(SAVConnection *)connection didReceiveDISFeedback:(SAVDISFeedback *)disFeedback
{
    [[Savant states] didReceiveDISFeedback:disFeedback];
}

- (void)connection:(SAVConnection *)connection didReceiveDISResults:(SAVDISResults *)results
{
    NSDictionary *observers = [[Savant control].disResultObservers copy];

    for (NSString *app in observers)
    {
        if ([results.app isEqualToString:app])
        {
            for (id <DISResultDelegate> observer in observers[app])
            {
                [observer disRequestDidCompleteWithResults:results];
            }
        }
    }
}

#pragma mark - DiscoveryDelegate methods

- (void)discoveryDidUpdateSystemList:(SAVDiscovery *)discovery
{
    for (SAVSystem *system in discovery.combinedCloudAndLocalSystems)
    {
        if ([system.hostID isEqualToString:self.system.hostID] || [system.homeID isEqualToString:self.system.homeID])
        {
            RPMLogErr(@"Discovery did find cloud system");
            [self updateCurrentSystemWithDiscoveredSystem:system];
            break;
        }
    }
}

- (void)updateCurrentSystemWithDiscoveredSystem:(SAVSystem *)system
{
    //-------------------------------------------------------------------
    // Only overwrite the currrent systems localURL if the new system has one.
    //-------------------------------------------------------------------
    if (system.localURL)
    {
        self.system.localURL = system.localURL;
    }

    //-------------------------------------------------------------------
    // Never demote a cloud system to a non cloud system, but promotion
    // is ok.
    //-------------------------------------------------------------------
    if (system.isCloudSystem)
    {
        self.system.cloudSystem = YES;
    }

    if (system.homeID)
    {
        self.system.homeID = system.homeID;
    }

    if (system.hostID)
    {
        self.system.hostID = system.hostID;
    }

    if (system.cellURL)
    {
        self.system.cellURL = system.cellURL;
    }

    self.system.cloudOnline = system.cloudOnline;
    self.system.hasRemoteAccess = system.hasRemoteAccess;
    self.system.remoteAccessDisableReason = system.remoteAccessDisableReason;
    self.system.notificationsEnabled = system.areNotificationsEnabled;
    self.system.notificationsDisabledReason = system.notificationsDisabledReason;

    [self saveInfo];
}

- (void)discovery:(SAVDiscovery *)discovery didFindSystem:(SAVSystem *)system
{
    if ([system.hostID isEqualToString:self.system.hostID] || [system.homeID isEqualToString:self.system.homeID])
    {
        if (system.localURL)
        {
            RPMLogErr(@"Connection browser did find local system with url: %@", system.localURL);
            
            self.currentURL = system.localURL;
            self.internalConnectionState = SAVConnectionStateLocal;

            if (self.connectionState != SAVConnectionStateNotConnected)
            {
                [self currentConnectionFailed];
            }

            [self invalidateCurrentConnectionAndTryNextHost:NO];
            [self startConnection];
        }
    }
}

#pragma mark - ConnectionStatusDelegate

- (void)connectionDidConnect:(SAVConnection *)connection
{
    RPMLogAlert(@"Connection did connect to url: %@", self.currentURL);

    [self invalidateTimers];
    self.connectionState = self.internalConnectionState;
    [[Savant control] connectionDidConnect];
    [self.cloudUpdateTimer invalidate];

    if (self.connectionState == SAVConnectionStateLocal)
    {
        [self stopBrowse];
    }
}

- (void)connectionDidRequestAuthentication:(SAVConnection *)connection
{
    if (self.system.isCloudSystem)
    {
        SAVCredentialManager *cm = [Savant credentials];

        NSString *hostToken = [cm hostTokenForHomeID:self.system.homeID];

        if (hostToken)
        {
            [self.connection attemptAuthenticationWithToken:hostToken];
        }
        else if (cm.cloudEmail && cm.cloudPassword)
        {
            [self.connection attemptAuthenticationWithUser:cm.cloudEmail andPassword:cm.cloudPassword];
        }
    }
    else
    {
        [[Savant control] connectionDidReceiveAuthChallenge];
    }
}

- (void)connectionIsReady:(SAVConnection *)connection
{
    RPMLogErr(@"Connection is ready");

    self.system.homeID = connection.homeID;
    self.system.name = self.connection.hostName;
    self.system.lastURL = self.currentURL;
    [[Savant control] connectionIsReady];

    if (self.internalConnectionState == SAVConnectionStateLocal)
    {
        self.system.SSID = [[UIDevice currentDevice] currentSSID];
    }

    [self saveInfo];
}

- (void)connectionDidDisconnect:(SAVConnection *)connection
{
    RPMLogErr(@"Connection did disconnect from url: %@", self.currentURL);
    [self currentConnectionFailed];
}

- (void)connection:(SAVConnection *)connection didFailWithError:(NSError *)error
{
    ;
}

- (BOOL)connectionIsConnectedToCloudSystem:(SAVConnection *)connection
{
    return self.system.isCloudSystem;
}

- (void)connection:(SAVConnection *)connection authenticationAttemptDidFailWithCode:(NSUInteger)code
{
    RPMLogErr(@"Connection authentication did fail with code: %lu", (unsigned long)code);

    if (code == SAVAuthenticationErrorCodeInvalidToken)
    {
        [self connectionDidRequestAuthentication:connection];
    }
    else if (code == SAVAuthenticationErrorCodeInvalidUser || code == SAVAuthenticationErrorCodeInvalidPassword)
    {
        dispatch_async_main(^{
            [[Savant control] connectionShouldLogOut];
        });
    }
}

#pragma mark - Internal

- (void)startConnection
{
    [self invalidateTimers];

    if (self.internalConnectionState == SAVConnectionStateCloud)
    {
        [self startBrowse];
    }

    if (self.currentURL)
    {
        RPMWebSocketClientSSL securityLevel = RPM_WS_SSL;

        if (self.internalConnectionState == SAVConnectionStateLocal)
        {
            securityLevel = RPM_WS_SSLAllowSelfSigned;
        }

        if ([Savant control].isDemoSystem)
        {
            securityLevel = RPM_WS_NoSSL;
        }

        RPMLogErr(@"Connection starting with url: %@ and level: %ld", self.currentURL, (long)securityLevel);

        self.connection = [[SAVConnection alloc] initWithURL:self.currentURL system:self.system securityLevel:securityLevel];
    }

    if (self.connection)
    {
        self.connection.configurationGUID = [[Savant control] manifestForSystemUID:self.system.hostID][@"GUID"];
        self.connection.statusDelegate = self;
        self.connection.stateDelegate = self;
        self.connection.disDelegate = self;
        [self.connection connect];
    }
    else
    {
        [self startBrowse];
    }

    SAVWeakSelf;
    self.connectionTimeoutTimer = [NSTimer sav_scheduledBlockWithDelay:self.connectionTimeoutInterval block:^{
        [wSelf connectionDidNotConnectInTime];
    }];
}

- (void)invalidateCurrentConnectionAndTryNextHost:(BOOL)tryNextHost
{
    self.connection.statusDelegate = nil;
    self.connection.stateDelegate = nil;
    self.connection.disDelegate = nil;
    [self.connection disconnect];
    self.connection = nil;

    [self invalidateTimers];

    if (tryNextHost)
    {
        NSTimeInterval timeInterval = self.retryInterval;

        if (self.internalConnectionState == SAVConnectionStateLocal && self.system.hasRemoteAccess && self.system.isCloudOnline && self.system.cellURL)
        {
            //-------------------------------------------------------------------
            // If we just failed on the local connection, and we have a remote
            // connection, don't wait to try it.
            //-------------------------------------------------------------------
            timeInterval = 0;
        }

        SAVWeakSelf;
        self.tryNextConnectionTimer = [NSTimer sav_scheduledBlockWithDelay:timeInterval block:^{
            SAVStrongWeakSelf;
            [sSelf determineNextConnectionAddress];
            [sSelf startConnection];
        }];
    }
}

- (void)currentConnectionFailed
{
    [self.connection disconnect];
    self.connection = nil;

    [self invalidateTimers];

    self.connectionState = SAVConnectionStateNotConnected;

    SAVWeakSelf;
    [self.cloudUpdateTimer addWorkWithKey:@"refresh" work:^{
        [wSelf.discoveryScanner update];
    }];

    [self invalidateCurrentConnectionAndTryNextHost:YES];

    [[Savant control] connectionDidFailToConnect];
}

- (void)connectionDidNotConnectInTime
{
    if (self.currentURL)
    {
        RPMLogErr(@"Connection timeout to url: %@", self.currentURL);
    }
    else
    {
        RPMLogErr(@"Attempting next connection.");
    }

    [self currentConnectionFailed];
}

- (void)determineNextConnectionAddress
{
    NSURL *newURL = self.currentURL;
    SAVConnectionState newConnectionState = self.internalConnectionState;
    NSString *currentSSID = [[UIDevice currentDevice] currentSSID];

    dispatch_block_t remoteAccessDeniedLog = ^{
        RPMLogErr(@"Skipping remote connection attempt. Has remote access: %d. System is online: %d", self.system.hasRemoteAccess, self.system.isCloudOnline);
    };

    RPMLogErr(@"Determining next address based on current connection state: %lu", (unsigned long)self.internalConnectionState);

    switch (self.internalConnectionState)
    {
        case SAVConnectionStateNotConnected:
        case SAVConnectionStateCloud:
        {
            if (self.system.localURL)
            {
                if (currentSSID)
                {
                    //-------------------------------------------------------------------
                    // There is a valid localURL to try. Break out.
                    //-------------------------------------------------------------------
                    RPMLogErr(@"Attempting a local connection with address '%@'.", self.system.localURL);
                    newURL = self.system.localURL;
                    newConnectionState = SAVConnectionStateLocal;
                    break;
                }
                else
                {
                    //-------------------------------------------------------------------
                    // Fall through and try remote.
                    //-------------------------------------------------------------------
                    RPMLogErr(@"Skipping a local connection attempt because there is no valid SSID.");
                }
            }

            if (self.system.hasRemoteAccess && self.system.isCloudOnline)
            {
                RPMLogErr(@"Attempting a remote connection with address '%@'.", self.system.cellURL);
                newConnectionState = SAVConnectionStateCloud;
                newURL = self.system.cellURL;
            }
            else
            {
                remoteAccessDeniedLog();

                if (self.system.localURL)
                {
                    //-------------------------------------------------------------------
                    // Even though we may have previously skipped a local connection a
                    // few lines up, since there's no remote address, it's harmless
                    // to continue trying the local address.
                    //-------------------------------------------------------------------
                    RPMLogErr(@"Falling back to local connection, '%@', because there are no other options.", self.system.localURL);
                    newURL = self.system.localURL;
                    newConnectionState = SAVConnectionStateLocal;
                }
                else
                {
                    RPMLogErr(@"There are no valid addresses to try.");
                    newURL = nil;
                    newConnectionState = SAVConnectionStateNotConnected;
                }
            }

            break;
        }
        case SAVConnectionStateLocal:
        {
            if (self.system.cellURL)
            {
                if (self.system.hasRemoteAccess && self.system.isCloudOnline)
                {
                    RPMLogErr(@"Attempting to switch to a remote connection with address '%@'.", self.system.cellURL);
                    newURL = self.system.cellURL;
                    newConnectionState = SAVConnectionStateCloud;
                }
                else
                {
                    //-------------------------------------------------------------------
                    // Don't nil newURL here, it's the local one so keep it around. Keep
                    // attempting a local connection.
                    //-------------------------------------------------------------------
                    remoteAccessDeniedLog();
                }
            }
            else
            {
                RPMLogErr(@"Continuing to try the local address '%@'.", self.currentURL);
            }

            break;
        }
    }

    self.currentURL = newURL;
    self.internalConnectionState = newConnectionState;

    [self startBrowse];
}

- (void)invalidateTimers
{
    [self.connectionTimeoutTimer invalidate];
    self.connectionTimeoutTimer = nil;
    [self.tryNextConnectionTimer invalidate];
    self.tryNextConnectionTimer = nil;
}

- (void)startBrowse
{
    if (!self.discoveryScanner)
    {
        RPMLogErr(@"Starting connection browser");
        self.discoveryScanner = [[SAVDiscovery alloc] init];
        self.discoveryScanner.scanImmediately = YES;
        [self.discoveryScanner addDiscoveryObserver:self];
    }
}

- (void)stopBrowse
{
    if (self.discoveryScanner)
    {
        RPMLogErr(@"Stopping connection browser");
        [self.discoveryScanner removeDiscoveryObserver:self];
        self.discoveryScanner = nil;
    }
}

@end
