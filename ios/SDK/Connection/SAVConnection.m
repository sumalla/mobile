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

#import "SAVConnection.h"
#import "rpmSharedLogger.h"
#import "SAVServiceRequest.h"
#import "SAVSystem.h"
#import "SAVControlPrivate.h"
#import "SAVBinaryTransferManager.h"
#import "SAVLocalUser.h"
#import "SRWebSocket.h"
#import "MessagePack.h"
#import "mfiSharedCocoaExtensions.h"
#import "SavantPrivate.h"

static const long kBinaryCompletionHeaderOffset = 1;

@import Extensions;

@interface SAVConnection () <SAVBinaryTransferManagerConfigDelegate, SRWebSocketDelegate>

@property (nonatomic) SRWebSocket *connection;
@property (nonatomic) uint32_t protocolVersion;
@property (nonatomic) NSString *scheme;
@property (nonatomic) NSString *address;
@property (nonatomic) NSNumber *port;
@property (nonatomic) NSString *hostID;
@property (nonatomic) NSString *homeID;
@property (nonatomic) NSString *hostName;
@property (nonatomic, getter = isConnected) BOOL connected;
@property (nonatomic, getter = isUpdateAvailable) BOOL updateAvailable;
@property (nonatomic, getter = isAuthenticationNeeded) BOOL authenticationNeeded;
@property (nonatomic, getter = isRemote) BOOL remote;
@property (nonatomic) NSString *currentUser;
@property (nonatomic, copy) NSDictionary *userData;
@property (nonatomic) NSMutableDictionary *cameraImages;
@property (nonatomic) NSMutableDictionary *outstandingMediaRequests;
@property (nonatomic) NSMutableDictionary *binaryTransfers;
@property (nonatomic) SAVBinaryTransferManager *transferManager;
@property (nonatomic) dispatch_queue_t binaryQueue;
@property (nonatomic, copy) NSArray *availableUsers;
@property (nonatomic) SAVSystem *system;
@property (nonatomic) RPMWebSocketClientSSL securityLevel;

@end

@implementation SAVConnection

- (void)dealloc
{
    self.connection.delegate = nil;
    [self.connection close];
    [self.transferManager invalidate];
}

- (instancetype)initWithURL:(NSURL *)url system:(SAVSystem *)system securityLevel:(RPMWebSocketClientSSL)securityLevel
{
    self = [super init];

    if (self)
    {
        self.scheme = [url scheme];
        self.address = [url host];
        self.port = [url port];
        self.securityLevel = securityLevel;

        if (!self.port)
        {
            if ([self.scheme isEqualToString:@"wss"])
            {
                self.port = @443;
            }
            else if ([self.scheme isEqualToString:@"ws"])
            {
                self.port = @80;
            }
        }

        self.system = system;
        self.transferManager = [[SAVBinaryTransferManager alloc] init];
        self.transferManager.configDelegate = self;
        self.binaryQueue = dispatch_queue_create("com.savantav.Controller.binaryQueue", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

- (void)connect
{
    NSString *scheme = nil;
    BOOL allowInsecureConnections = NO;

    switch (self.securityLevel)
    {
        case RPM_WS_NoSSL:
            scheme = @"ws";
            break;
        case RPM_WS_SSL:
            scheme = @"wss";
            break;
        case RPM_WS_SSLAllowSelfSigned:
            scheme = @"wss";
            allowInsecureConnections = YES;
            break;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", scheme, self.address, self.port]];
    self.connection = [[SRWebSocket alloc] initWithURL:url protocols:@[@"rpm-protocol"]];
    self.connection.allowInsecureConnections = allowInsecureConnections;
    self.connection.delegate = self;
    self.connection.sendDataSafely = NO;
    [self.connection open];
}

- (void)disconnect
{
    for (CBPPromise *promise in self.outstandingMediaRequests.allValues)
    {
        [promise invalidateWithError:nil];
    }

    self.outstandingMediaRequests = nil;

    self.connection.delegate = nil;
    [self.connection close];
    self.connection = nil;
}

- (void)attemptAuthenticationWithUser:(NSString *)user andPassword:(NSString *)password
{
    self.currentUser = user;
    SAVAuthRequestMessage *authRequest = [[SAVAuthRequestMessage alloc] init];
    authRequest.user = user;
    authRequest.password = password;
    [self sendMessage:authRequest];
}

- (void)attemptAuthenticationWithToken:(NSString *)token
{
    SAVAuthRequestMessage *authRequest = [[SAVAuthRequestMessage alloc] init];
    authRequest.token = token;
    [self sendMessage:authRequest];
}

- (void)_sendDevicePresent
{
    SAVDevicePresentMessage *devicePresentMessage = [[SAVDevicePresentMessage alloc] init];
    devicePresentMessage.OS = [NSString stringWithFormat:@"%@ %@", [Savant control].deviceOperatingSystem, [Savant control].deviceOperatingSystemVersion];
    devicePresentMessage.name = [Savant control].deviceName;
    devicePresentMessage.model = [NSString stringWithFormat:@"%@%@", [Savant control].deviceModel, [Savant control].deviceModelVersion];
    devicePresentMessage.make = [Savant control].deviceManufacturer;
    devicePresentMessage.UID = [Savant control].deviceUID;
    devicePresentMessage.configurationID = self.configurationGUID;
    devicePresentMessage.homeID = self.system.homeID;
    devicePresentMessage.app = [NSString stringWithFormat:@"%@ (%@)", [Savant control].appName, [Savant control].appVersion];
    devicePresentMessage.type = [Savant control].deviceModel;

    if ([self.statusDelegate connectionIsConnectedToCloudSystem:self])
    {
        devicePresentMessage.cloudToken = [Savant credentials].cloudAuthenticationToken;
    }

    [self sendMessage:devicePresentMessage];
}

- (BOOL)userRequiresAuthentication:(NSString *)user
{
    BOOL userRequiresAuthentication = NO;

    if (self.isRemote)
    {
        userRequiresAuthentication = YES;
    }
    else
    {
        NSString *correctCaseUserName = nil;

        for (SAVLocalUser *u in self.availableUsers)
        {
            NSString *userName = u.accountName;

            if ([userName caseInsensitiveCompare:user] == NSOrderedSame)
            {
                correctCaseUserName = userName;
                break;
            }
        }

        userRequiresAuthentication = [[self.userData objectForKey:correctCaseUserName] boolValue];
    }

    return userRequiresAuthentication;
}

#pragma mark - Message Sending

- (BOOL)sendMessage:(SAVMessage *)message
{
    NSParameterAssert(message);

    return [self sendMessages:@[message]];
}

- (BOOL)sendMessages:(NSArray *)messages
{
    if (self.connection.readyState == SRReadyStateOpen && [messages count])
    {
        NSMutableDictionary *messagesByURI = [NSMutableDictionary dictionary];

        for (SAVMessage *message in messages)
        {
            if ([message requiresBinaryTransfer] && [message isKindOfClass:[SAVBinaryTransfer class]])
            {
                SAVBinaryTransfer *binaryTransfer = (SAVBinaryTransfer *)message;

                NSInputStream *inStream = [NSInputStream inputStreamWithData:binaryTransfer.data];
                [inStream open];

                NSDictionary *identifier = @{@"stream": inStream,
                                             @"length": @([binaryTransfer.data length]),
                                             @"type": @(RPM_WEBSOCKET_FILEUPLOAD_TYPE),
                                             @"identifier": [binaryTransfer dictionaryRepresentation]};

                [self handleStreamWithIdentifier:identifier];
            }
            else
            {
                NSMutableArray *messagesToSend = messagesByURI[message.uri];
                if (!messagesToSend)
                {
                    messagesToSend = [NSMutableArray array];
                    messagesByURI[message.uri] = messagesToSend;
                }

                [messagesToSend addObject:[message dictionaryRepresentation]];
            }
        }

        for (NSString *uri in messagesByURI)
        {
            NSData *data = [@{@"URI": uri, @"messages": messagesByURI[uri]} messagePack];
            [self.connection sendData:data];
        }

        return YES;
    }

    return NO;
}

- (CBPPromise *)sendMediaRequest:(SAVMediaRequest *)request
{
    CBPPromise *promise = nil;

    if (self.connection.readyState == SRReadyStateOpen && request)
    {
        if (!self.outstandingMediaRequests)
        {
            self.outstandingMediaRequests = [NSMutableDictionary dictionary];
        }

        promise = [[CBPPromise alloc] init];
        self.outstandingMediaRequests[[request dictionaryRepresentation]] = promise;
        [self sendMessage:request];
    }

    return promise;
}

- (void)cancelMediaRequest:(CBPPromise *)promise
{
    [promise invalidateWithError:nil];

    __block NSString *keyToRemove = nil;

    [self.outstandingMediaRequests enumerateKeysAndObjectsUsingBlock:^(NSString *key, CBPPromise *obj, BOOL *stop) {
        if (obj == promise)
        {
            keyToRemove = key;
        }
    }];

    if (keyToRemove)
    {
        [self.outstandingMediaRequests removeObjectForKey:keyToRemove];
    }
}

#pragma mark - Message Handling

- (void)handleMessages:(NSArray *)messages withURI:(NSString *)uri
{
    if ([@"session/deviceRecognized" isEqualToString:uri])
    {
        for (NSDictionary *message in messages)
        {
            [self handleDeviceRecognized:[SAVDeviceResponseMessage messageWithDictionary:message]];
        }
    }
    else if ([@"session/authenticationResponse" isEqualToString:uri])
    {
        for (NSDictionary *message in messages)
        {
            [self handleAuthenticationResponse:[SAVAuthResponseMessage messageWithDictionary:message]];
        }
    }
    else if ([uri hasPrefix:@"state"])
    {
        if ([uri hasSuffix:@"update"])
        {
            NSMutableDictionary *newStates = [NSMutableDictionary dictionary];

            for (NSDictionary *message in messages)
            {
                NSString *value = [NSString stringWithFormat:@"%@", message[@"value"]];
                [newStates setObject:value forKey:[message objectForKey:@"state"]];
            }

            for (NSString *stateName in newStates)
            {
                [self.stateDelegate connection:self didReceiveStateUpdate:[SAVStateUpdate messageWithState:stateName value:newStates[stateName]]];
            }
        }
    }
    else if ([uri hasPrefix:@"dis"])
    {
        NSArray *pathComponets = [uri componentsSeparatedByString:@"/"];

        for (NSDictionary *message in messages)
        {
            if ([uri hasSuffix:@"update"] && [pathComponets count] == 3)
            {
                SAVDISFeedback *feedback = [[SAVDISFeedback alloc] initWithApp:[pathComponets objectAtIndex:1] state:[message objectForKey:@"state"] value:[message objectForKey:@"value"]];
                [self.disDelegate connection:self didReceiveDISFeedback:feedback];
            }
            else if ([uri hasSuffix:@"request"] && [pathComponets count] == 3)
            {
                SAVDISResults *result = [[SAVDISResults alloc] initWithApp:[pathComponets objectAtIndex:1] request:[message objectForKey:SAVMESSAGE_DIS_REQUEST_KEY] results:[message objectForKey:SAVMESSAGE_DIS_RESULTS_KEY]];
                [self.disDelegate connection:self didReceiveDISResults:result];
            }
        }
    }
    else if ([uri hasPrefix:@"media"])
    {
        NSDictionary *message = [[messages lastObject] lastObject];
        NSDictionary *query = message[@"query"];
        NSArray *lmqResults = message[@"results"];

        CBPPromise *promise = self.outstandingMediaRequests[query];

        if (promise)
        {
            [promise deliver:lmqResults];
            [self.outstandingMediaRequests removeObjectForKey:query];
        }
    }
    else if ([uri isEqualToString:@"status"])
    {
        //-------------------------------------------------------------------
        // TODO: Complete status
        //-------------------------------------------------------------------
    }
}

- (void)handleDeviceRecognized:(SAVDeviceResponseMessage *)deviceRecognized
{
    self.hostID = deviceRecognized.hostID;
    self.homeID = deviceRecognized.homeID;
    self.hostName = deviceRecognized.hostName;
    self.remote = deviceRecognized.remote;
    self.updateAvailable = deviceRecognized.update;
    self.protocolVersion = deviceRecognized.protocolVersion;

    if (self.system.isManualConnection)
    {
        self.system.hostID = self.hostID;
    }

    if ([[Savant control] didConnectToSystemWithProtocolVersion:self.protocolVersion])
    {
        NSMutableDictionary *userData = nil;
        NSMutableArray *availableUsers = nil;

        if (!deviceRecognized.remote)
        {
            userData = [NSMutableDictionary dictionary];
            availableUsers = [NSMutableArray array];

            for (NSDictionary *curUserDict in deviceRecognized.users)
            {
                [userData setObject:@([curUserDict[@"authRequired"] boolValue])
                             forKey:curUserDict[@"user"]];

                SAVLocalUser *user = [[SAVLocalUser alloc] initWithDictionary:curUserDict];
                [availableUsers addObject:user];
            }
        }

        self.userData = userData;
        self.availableUsers = [availableUsers sortedArrayUsingComparator:^NSComparisonResult(SAVLocalUser *user1, SAVLocalUser *user2) {
            return [user1.accountName compare:user2.accountName options:NSCaseInsensitiveNumericSearch];
        }];

        [self.statusDelegate connectionDidConnect:self];

        if (deviceRecognized.authentication)
        {
            if (deviceRecognized.authorized)
            {
                [self downloadConfigurationIfNecessary];
            }
            else
            {
                [self requestAuthentication];
            }
        }
        else
        {
            [self downloadConfigurationIfNecessary];
        }
    }
}

- (void)handleAuthenticationResponse:(SAVAuthResponseMessage *)authenticationResponse
{
    BOOL authorized = authenticationResponse.authorized;

    if (authorized)
    {
        if (authenticationResponse.hostToken && self.system.homeID)
        {
            [[Savant credentials] setHostToken:authenticationResponse.hostToken forHomeID:self.system.homeID];
        }

        [Savant control].admin = authenticationResponse.isAdmin;
        [[Savant control] updateServiceBlacklist:authenticationResponse.serviceBlacklist andZoneBlacklist:authenticationResponse.zoneBlacklist];
        [[Savant control] connectionDidAuthorizeForUser:self.currentUser];
        [self downloadConfigurationIfNecessary];
    }
    else
    {
        if ([self.statusDelegate connectionIsConnectedToCloudSystem:self])
        {
            if (self.system.homeID)
            {
                [[Savant credentials] setHostToken:nil forHomeID:self.system.homeID];
            }

            [self.statusDelegate connection:self authenticationAttemptDidFailWithCode:authenticationResponse.errorCode];
        }
        else
        {
            [[Savant control] connectionDidReceiveAuthChallengeForUser:self.currentUser];
        }
    }

    self.currentUser = nil;
}

- (void)downloadConfigurationIfNecessary
{
    //-------------------------------------------------------------------
    // Check if there is an update available, and if the SDK is in a mode
    // that allows configuration downloads. The watch glance view and
    // scene extension both don't allow configuration downloads.
    //-------------------------------------------------------------------
    if (self.isUpdateAvailable && [Savant control].controlMode & SAVControlModeConfigurationDownloads)
    {
        SAVConfigRequest *configRequest = [[SAVConfigRequest alloc] init];
        [self sendMessage:configRequest];
    }
    else
    {
        [self.statusDelegate connectionIsReady:self];
    }
}

- (void)requestAuthentication
{
    if ([[Savant control].pinCodeDelegate respondsToSelector:@selector(checkUserLevelSecurityBeforeAuthenticating:)])
    {
        SAVWeakSelf;
        [[Savant control].pinCodeDelegate checkUserLevelSecurityBeforeAuthenticating:^(BOOL shouldContinue) {
            if (shouldContinue)
            {
                [wSelf.statusDelegate connectionDidRequestAuthentication:self];
            }
            else
            {
                //-------------------------------------------------------------------
                // CBP TODO: handle disconnection.
                //-------------------------------------------------------------------
            }
        }];
    }
    else
    {
        [self.statusDelegate connectionDidRequestAuthentication:self];
    }
}

#pragma mkar - SRWebSocketDelegate methods

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [self _sendDevicePresent];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.connected = NO;

    if ([self.statusDelegate respondsToSelector:@selector(connectionDidDisconnect:)])
    {
        [self.statusDelegate connectionDidDisconnect:self];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveData:(NSData *)data
{
    NSUInteger type = RPM_WEBSOCKET_MSGPACK_TYPE_CHECK([data getByte:0x00]) ? RPM_WEBSOCKET_MSGPACK_TYPE : [data getByte:0x00];

    switch (type)
    {
        case RPM_WEBSOCKET_MSGPACK_TYPE:
        {
            NSDictionary *message = (NSDictionary *)[MessagePackParser parseData:data];

            if ([message isKindOfClass:[NSDictionary class]])
            {
                NSString *uri = message[@"URI"];
                NSArray *messages = message[@"messages"];
                [self handleMessages:messages withURI:uri];
            }

            break;
        }
        case RPM_WEBSOCKET_FILEUPLOAD_TYPE:
        case RPM_WEBSOCKET_SECURITYCAM_TYPE:
        case RPM_WEBSOCKET_SAVANTCAM_TYPE:
        case RPM_WEBSOCKET_USERINTERFACE_TYPE:
        case RPM_WEBSOCKET_MEDIADATABASEUPLOAD_TYPE:
        {
            dispatch_async(self.binaryQueue, ^{
                uint64_t beSize;
                [data getBytes:&beSize range:NSMakeRange(2, 8)];

                NSUInteger messageType = [data getByte:0x00];
                NSUInteger expectedLength = (NSUInteger)OSSwapBigToHostInt64(beSize);

                NSInteger versionAndCompletion = [data getByte:kBinaryCompletionHeaderOffset];
                BOOL complete = versionAndCompletion & 0x80;

                int32_t beSessionLen;
                [data getBytes:&beSessionLen range:NSMakeRange(10, 4)];

                NSString *identifier = nil;

                if (RPM_WEBSOCKET_MSGPACK_TYPE_CHECK([data getByte:14]))
                {
                    identifier = [[data subdataWithRange:NSMakeRange(14, OSSwapBigToHostInt32(beSessionLen))] messagePackParse];
                }
                else
                {
                    identifier = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(14, OSSwapBigToHostInt32(beSessionLen))] encoding:NSUTF8StringEncoding];
                }

                NSData *messageData = [data subdataWithRange:NSMakeRange(14 + OSSwapBigToHostInt32(beSessionLen), [data length] - OSSwapBigToHostInt32(beSessionLen) - 14)];

                [self.transferManager updateDownloadWithIdentifier:identifier
                                                              data:messageData
                                                    expectedLength:expectedLength
                                                          complete:complete
                                                              type:messageType];
            });
            
            break;
        }
        default:
            RPMLogErr(@"Encountered unexpected websocket type %ld %@", (long)type, data);
            break;
    }
}

- (void)webSocket:(SRWebSocket *)webSocket writeDidFinishWithIdentifier:(id)identifier
{
    [self handleStreamWithIdentifier:(NSDictionary *)identifier];
}

#pragma mark - WebSocket stream helper

- (NSMutableData *)binaryHeaderWithType:(NSUInteger)type size:(uint64_t)size complete:(BOOL)complete identifer:(id)identifier
{
    NSMutableData *header = [NSMutableData data];

    [header appendByte:(unsigned char)type]; // 1 byte, security camera type

    int version = 0x1; // 0x7F (bits 6-0)
    int completeShift = (complete ? 0x1 : 0x0) << 7;  // 0x80 (bit 7)
    int versionAndCompletion = (version + completeShift);

    [header appendByte:(unsigned char)versionAndCompletion]; // 1 byte, in-complete marker

    uint64_t  beSize = OSSwapHostToBigInt64(size);
    [header appendBytes:&beSize length:8]; // 8 bytes, data size swapped to network BE endian format

    NSData *session = nil;

    if ([identifier isKindOfClass:[NSDictionary class]])
    {
        session = [(NSDictionary*)identifier messagePack];
    }
    else if ([identifier isKindOfClass:[NSString class]])
    {
        identifier = identifier ? identifier : @"";
        session = [(NSString *)identifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([identifier respondsToSelector:@selector(stringValue)])
    {
        identifier = [(id)identifier stringValue];
        session = [(NSString *)identifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        RPMLogErr(@"Unexpected identifier: %@", identifier);
    }

    uint32_t beSessionLen = OSSwapHostToBigInt32(session.length);
    [header appendBytes:&beSessionLen length:4]; // 4 bytes, session length swapped to network BE endian format
    [header appendData:session]; // session id (variable length)
    
    return header;
}

- (void)handleStreamWithIdentifier:(NSDictionary *)streamIdentifier
{
    NSDictionary *identifier = (NSDictionary *)streamIdentifier[@"identifier"];
    NSUInteger type = [streamIdentifier[@"type"] unsignedIntegerValue];
    uint64_t length = [streamIdentifier[@"length"] unsignedLongLongValue];
    NSInputStream *dataStream = (NSInputStream *)streamIdentifier[@"stream"];

    if ([streamIdentifier[@"complete"] boolValue])
    {
        return;
    }

    static const size_t targetMTUSize = 1500;

    NSMutableData *header = [self binaryHeaderWithType:type size:length complete:0x00 identifer:identifier];
    NSUInteger dataLength = targetMTUSize - header.length; // (starts after header, max packet length of MTU bytes)
    uint8_t dataBuffer[targetMTUSize];

    NSInteger bytesRead = [dataStream read:dataBuffer maxLength:dataLength];

    NSMutableData *sendData = [NSMutableData dataWithData:header];

    BOOL done = NO;

    if (![dataStream hasBytesAvailable])
    {
        int completionAndVersion;
        [sendData getBytes:&completionAndVersion range:NSMakeRange(1, 1)];

        int version = completionAndVersion & 0x7F;
        unsigned char completeByte = 0x80 + version;

        [sendData replaceBytesInRange:NSMakeRange(kBinaryCompletionHeaderOffset, 1) withBytes:&completeByte length:sizeof(completeByte)]; // complete marker
        [dataStream close];
        done = YES;
    }

    if (bytesRead > 0)
    {
        [sendData appendBytes:dataBuffer length:(NSUInteger)bytesRead];
    }

    if (done)
    {
        NSMutableDictionary *mStreamIdentifier = [streamIdentifier mutableCopy];
        mStreamIdentifier[@"complete"] = @YES;
        streamIdentifier = [mStreamIdentifier copy];
    }

    [self.connection sendPartialData:sendData withIdentifier:streamIdentifier];
}

#pragma mark - SAVBinaryTransferManagerConfigDelegate

- (void)transferManagerDidFinishUntarringConfig:(SAVBinaryTransferManager *)transferManager
{
    [self.statusDelegate connectionIsReady:self];
}

@end
