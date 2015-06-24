//
//  SAVDemoServer.m
//  SavantControl
//
//  Created by Nathan Trapp on 4/25/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVControl.h"
#import "SAVDemoServer.h"
#import "SAVHVACDemoRouter.h"
#import "SAVPoolDemoRouter.h"
#import "SAVScenesDemoRouter.h"
#import "SAVUserDataDemoRouter.h"
#import "SAVLightingDemoRouter.h"
#import "SAVLMQDemoRouter.h"
#import "SAVFavoritesDemoRouter.h"
#import "RPMAsyncConnection.h"
#import "rpmSharedLogger.h"
#import "RPMDiscoveryServer.h"
#import "SAVMutableService.h"
#import "Savant.h"
@import Extensions;

@interface SAVDemoServer () <SystemStatusDelegate>
{
    NSDictionary *_demoStates;
    NSString *_checksum;
}

@property RPMAsyncConnection *demoServer;
@property RPMAsyncConnection *webSocket;
@property BOOL connected;
@property BOOL needsUpdate;
@property BOOL sentInitialStates;
@property NSString *uid;
@property NSString *configUID;
@property (readonly, atomic) NSString *checksum;
@property NSString *protocolVersion;
@property NSDictionary *deviceInfo;
@property NSCountedSet *registeredStates;
@property (atomic) NSMutableDictionary *allStates;
@property (readonly, atomic) NSDictionary *demoStates;
@property BOOL authorized;

@property BOOL demoThreadRunning;
@property NSThread *demoThread;

@property NSHashTable *routers;
@property NSMutableArray *internalRouters;

@end

@implementation SAVDemoServer

@dynamic port;

- (void)startDemoServer
{
    // Don't allow multiple UI Servers
    if (self.demoThreadRunning)
    {
        return;
    }

    RPMLogInfo(@"Demo Server Thread Started");

    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:0];

    self.demoThreadRunning = YES;

    [NSThread detachNewThreadSelector:@selector(doStartDemoServerThread:) toTarget:self withObject:lock];

    [lock lockWhenCondition:1];
    [lock unlock];
}

- (void)doStartDemoServerThread:(NSConditionLock *)lock
{
    @autoreleasepool
    {
        self.demoThread = [NSThread currentThread];
        self.demoThread.name = @"Demo Server";

        [lock lock];
        [lock unlockWithCondition:1];

        self.demoServer = [[RPMAsyncConnection alloc] initServerWithPort:0 secure:NO delegate:self];
        [self.demoServer startConnection];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate demoServerIsReady];
        });

        self.internalRouters = [NSMutableArray array];
        self.registeredStates = [NSCountedSet set];
        self.allStates = [self.demoStates mutableCopy];

        [[Savant control] addSystemStatusObserver:self];

        NSRunLoop *rl = [NSRunLoop currentRunLoop];

        while (self.demoThreadRunning)
        {
            [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        RPMLogInfo(@"Demo Server Thread Stopped");
    }
}

- (void)stopDemoServer
{
    if ([NSThread currentThread] == self.demoThread)
    {
        self.demoThreadRunning = NO;
        [self.demoServer invalidate];
        self.demoServer = nil;
        self.registeredStates = nil;
        self.allStates = nil;
        self.authorized = NO;
        self.internalRouters = nil;
        self.routers = nil;
        _demoStates = nil;
        _checksum = nil;
    }
    else if (self.demoThread)
    {
        [self performSelector:_cmd onThread:self.demoThread withObject:nil waitUntilDone:NO];
    }
}

- (void)addRouter:(id <SAVDemoRouter>)router
{
    NSParameterAssert([router conformsToProtocol:@protocol(SAVDemoRouter)]);

    @synchronized(self.routers)
    {
        if (!self.routers)
        {
            self.routers = [NSHashTable weakObjectsHashTable];
        }

        [self.routers addObject:router];
    }
}

- (void)removeRouter:(id <SAVDemoRouter>)router
{
    NSParameterAssert([router conformsToProtocol:@protocol(SAVDemoRouter)]);

    @synchronized(self.routers)
    {
        [self.routers removeObject:router];
    }
}

- (void)sendBinaryData:(NSData *)data ofType:(NSUInteger)type withIdentifier:(id)identifier
{
    [self.webSocket sendBinaryData:data type:type identifier:identifier toUID:self.uid];
}

- (BOOL)sendMessage:(SAVMessage *)message
{
    NSParameterAssert([message isKindOfClass:[SAVMessage class]]);

    return [self sendMessages:@[message]];
}

- (BOOL)sendMessages:(NSArray *)messages
{
    if (self.isReady && [messages count])
    {
        NSMutableDictionary *messagesByURI = [NSMutableDictionary dictionary];

        for (SAVMessage *message in messages)
        {
            if ([message requiresBinaryTransfer])
            {
                SAVBinaryTransfer *binaryTransfer = (SAVBinaryTransfer *)message;
                [self.webSocket sendBinaryData:binaryTransfer.data type:RPM_WEBSOCKET_FILEUPLOAD_TYPE identifier:[message dictionaryRepresentation] toUID:nil];
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
            [self sendURIToDevice:uri withMessages:messagesByURI[uri]];
        }

        return YES;
    }

    return NO;
}

- (void)dispatchMessagesToRouters:(NSArray *)messages
{
    for (SAVMessage *message in messages)
    {
        [self dispatchMessageToRouters:message];
    }
}

- (BOOL)dispatchMessageToRouters:(SAVMessage *)message
{
    BOOL handled = NO;

    for (id <SAVDemoRouter> router in self.routers)
    {
        if ([message isKindOfClass:[SAVDISRequest class]])
        {
            if ([router handleDISRequest:(SAVDISRequest *)message])
            {
                handled = YES;
                break;
            }
        }
        else if ([message isKindOfClass:[SAVMediaRequest class]])
        {
            if ([router handleMediaRequest:(SAVMediaRequest *)message])
            {
                handled = YES;
                break;
            }
        }
        else if ([message isKindOfClass:[SAVServiceRequest class]])
        {
            if ([router handleServiceRequest:(SAVServiceRequest *)message])
            {
                handled = YES;
                break;
            }
        }
        else if ([message isKindOfClass:[SAVFileRequest class]])
        {
            if ([router handleFileRequest:(SAVFileRequest *)message])
            {
                handled = YES;
                break;
            }
        }
    }

    return handled;
}

#pragma mark - Properties

- (NSDictionary *)demoStates
{
    if (!_demoStates)
    {
        NSString *demoStatePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"demo-states" ofType:@".json"];

        if ([[NSFileManager defaultManager] fileExistsAtPath:demoStatePath])
        {
            NSData *jsonData = [NSData dataWithContentsOfFile:demoStatePath];

            _demoStates = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:NULL];
        }
    }

    return _demoStates;
}

- (NSString *)checksum
{
    if (!_checksum)
    {
        NSString *manifestPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"uimanifest" ofType:@".json"];

        if ([[NSFileManager defaultManager] fileExistsAtPath:manifestPath])
        {
            NSData *jsonData = [NSData dataWithContentsOfFile:manifestPath];

            NSDictionary *manfiest = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:NULL];

            _checksum = manfiest[@"GUID"];
        }
    }

    return _checksum;
}

- (int)port
{
    return self.demoServer.port;
}

- (BOOL)isReady
{
    return self.demoServer.isReady;
}

- (BOOL)isValid
{
    return self.demoServer.isValid;
}

#pragma mark - Internal

- (void)handleURI:(NSString *)uri forMessage:(NSDictionary *)message webSocket:(RPMAsyncConnection *)webSocket
{
    [self handleURI:uri forMessage:message webSocket:webSocket abort:NULL];
}

- (BOOL)handleURI:(NSString *)uri forMessage:(NSDictionary *)message webSocket:(RPMAsyncConnection *)webSocket abort:(BOOL *)abort
{
    [self logURI:uri withMessage:message fromWebSocket:webSocket];

    BOOL handledCommand = YES;

    //-------------------------------------------------------------------
    // Handle commands that don't require the connection to be authorized here.
    //-------------------------------------------------------------------
    if ([uri isEqualToString:@"session/devicePresent"])
    {
        self.connected = YES;
        self.deviceInfo = [message objectForKey:@"device"];
        self.uid = self.deviceInfo[@"UID"];
        self.configUID = [message objectForKey:@"configurationID"];
        self.protocolVersion = [message objectForKey:@"protocolVersion"];

        RPMLogErr(@"connected with protocol version %@", self.protocolVersion);

        [self logURI:@"session/devicePresent" withMessage:message fromWebSocket:webSocket];

        if (!self.configUID)
        {
            self.needsUpdate = YES;
        }
        else
        {
            if (![self.checksum isEqualToString: self.configUID])
            {
                self.needsUpdate = YES;
            }
        }

        [self sendDeviceRecognized];
    }
    else if ([uri isEqualToString:@"session/authenticationRequest"])
    {
        self.configUID = self.checksum;

        self.authorized = YES;

        [self sendURI:@"authenticationResponse"
          withMessage:@{@"authorized": @YES,
                  @"configurationUID": self.configUID}
            webSocket:webSocket];
    }
    else if (self.authorized)
    {
        NSArray *messages = [NSArray arrayWithObject:message];
        NSArray *pathComponents = [uri componentsSeparatedByString:@"/"];

        if ([uri hasPrefix:@"state"])
        {
            if ([uri hasSuffix:@"unregister"])
            {
                [self unregisterStates:messages];

                [self dispatchMessagesToRouters:messages];
            }
            else if ([uri hasSuffix:@"register"])
            {
                [self registerStates:messages];

                [self dispatchMessagesToRouters:messages];
            }
            else if ([uri hasSuffix:@"set"])
            {
                [self postStates:messages];
            }
        }
        else if ([uri hasPrefix:@"media"] && [pathComponents count] == 3)
        {
            for (NSDictionary *msg in messages)
            {
                SAVMediaRequest *request = [[SAVMediaRequest alloc] init];
                request.query = msg[SAVMESSAGE_MEDIAREQUEST_KEY_QUERY];
                request.arguments = msg[SAVMESSAGE_MEDIAREQUEST_KEY_QUERYARGUMENTS];
                request.logicalComponent = msg[SAVMESSAGE_MEDIAREQUEST_KEY_LOGICALCOMPONENT];
                request.componentIdentifier = msg[SAVMESSAGE_MEDIAREQUEST_KEY_COMPONENTIDENTIFIER];

                [self dispatchMessageToRouters:request];
            }
        }
        else if ([uri hasPrefix:@"dis"] && [pathComponents count] == 3)
        {
            for (NSDictionary *msg in messages)
            {
                if ([pathComponents[2] isEqualToString:@"request"])
                {
                    SAVDISRequest *request = [[SAVDISRequest alloc] initWithApp:pathComponents[1] request:msg[SAVMESSAGE_DIS_REQUEST_KEY] arguments:msg[SAVMESSAGE_DIS_REQUESTARGS_KEY]];

                    [self dispatchMessageToRouters:request];
                }
                else
                {
                    SAVDISRequest *request = [[SAVDISRequest alloc] initWithApp:pathComponents[1] request:pathComponents[2] arguments:msg];

                    [self dispatchMessageToRouters:request];
                }
            }
        }
        else if ([uri hasPrefix:@"service"] && [pathComponents count] == 2)
        {
            for (NSDictionary *msg in messages)
            {
                SAVMutableService *requestService = [[SAVMutableService alloc] initWithZone:msg[@"zone"]
                                                                                  component:msg[@"component"]
                                                                           logicalComponent:msg[@"logicalComponent"]
                                                                                  variantId:msg[@"variantID"]
                                                                                  serviceId:msg[@"serviceType"]];

                NSArray *services = [[Savant data] servicesFilteredByService:requestService];

                BOOL updateMuteState = NO;

                for (SAVService *service in services)
                {
                    SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
                    request.request = msg[@"request"];
                    request.requestArguments = msg[@"requestArgs"];

                    if ([self dispatchMessageToRouters:request])
                    {
                        break;
                    }
                    else if (request.request)
                    {
                        NSString *scope2 = [request.zoneName stringByAppendingString:@".ActiveServices"];

                        if ([self.allStates[scope2] containsString:service.serviceString] ||
                            [request.request isEqualToString:@"PowerOn"])
                        {
                            if (request.serviceId && [request.request hasPrefix:@"Power"])
                            {
                                NSString *scope = [request.zoneName stringByAppendingString:@".ActiveService"];

                                if ([request.request hasSuffix:@"On"])
                                {
                                    [self sendStateUpdate:@{scope: service.serviceString, scope2: service.serviceString}];
                                }
                                else if ([request.request hasSuffix:@"Off"])
                                {
                                    [self sendStateUpdate:@{scope: @"", scope2: @""}];

                                    if ([request.requestArguments[@"RoomOff"] boolValue] && request.zoneName)
                                    {
                                        //-------------------------------------------------------------------
                                        // This is the special "whole room off" command.
                                        //-------------------------------------------------------------------
                                        SAVServiceRequest *lightingPowerOff = [[SAVServiceRequest alloc] init];
                                        lightingPowerOff.request = @"__RoomLightsOff";
                                        lightingPowerOff.serviceId = @"SVC_ENV_LIGHTING";
                                        lightingPowerOff.zoneName = request.zoneName;
                                        [self dispatchMessagesToRouters:@[lightingPowerOff]];
                                    }
                                }
                            }
                            else if ([request.request hasPrefix:@"Mute"])
                            {
                                updateMuteState = YES;

                                requestService.component = request.component;
                                requestService.logicalComponent = request.logicalComponent;

                                NSString *scope = [request.zoneName stringByAppendingString:@".IsMuted"];

                                if ([request.request hasSuffix:@"On"])
                                {
                                    [self sendStateUpdate:@{scope: @YES}];
                                }
                                else if ([request.request hasSuffix:@"Off"])
                                {
                                    [self sendStateUpdate:@{scope: @NO}];
                                }
                            }
                            else if ([request.request hasPrefix:@"Volume"])
                            {
                                NSString *scope = nil;
                                NSInteger magnitude = [request.requestArguments[@"Magnitude"] integerValue] ? : 1;

                                scope = [request.zoneName stringByAppendingString:@".CurrentVolume"];

                                NSInteger currentVolume = [self.allStates[scope] integerValue];

                                if ([request.request hasSuffix:@"Up"])
                                {
                                    currentVolume += magnitude;
                                }
                                else if ([request.request hasSuffix:@"Down"])
                                {
                                    currentVolume -= magnitude;
                                }

                                if (currentVolume < 0)
                                {
                                    currentVolume = 0;
                                }
                                else if (currentVolume > 50)
                                {
                                    currentVolume = 50;
                                }

                                [self sendStateUpdate:@{scope: @(currentVolume)}];

                                updateMuteState = YES;

                                requestService.component = request.component;
                                requestService.logicalComponent = request.logicalComponent;

                                scope = [request.zoneName stringByAppendingString:@".IsMuted"];

                                [self sendStateUpdate:@{scope: @NO}];
                            }
                            else if ([request.request isEqualToString:@"SetVolume"])
                            {
                                NSString *scope = [request.zoneName stringByAppendingString:@".CurrentVolume"];

                                [self sendStateUpdate:@{scope: request.requestArguments[@"VolumeValue"]}];

                                updateMuteState = YES;

                                requestService.component = request.component;
                                requestService.logicalComponent = request.logicalComponent;

                                scope = [request.zoneName stringByAppendingString:@".IsMuted"];

                                [self sendStateUpdate:@{scope: @NO}];
                            }
                        }
                        else if ([request.request isEqualToString:@"ArmAlarmAway"] ||
                                 [request.request isEqualToString:@"ArmAlarmStay"] ||
                                 [request.request isEqualToString:@"DisarmAlarm"])
                        {
                            NSString *scope = [NSString stringWithFormat:@"%@.%@.CurrentPartitionArmingStatus_%@", request.component, request.logicalComponent, request.requestArguments[@"PartitionNumber"]];
                            
                            NSString *value = nil;
                            
                            if ([request.request isEqualToString:@"ArmAlarmAway"])
                            {
                                value = @"ArmedAway";
                            }
                            else if ([request.request isEqualToString:@"ArmAlarmStay"])
                            {
                                value = @"ArmedStay";
                            }
                            else if ([request.request isEqualToString:@"DisarmAlarm"])
                            {
                                value = @"Disarmed";
                            }
                            
                            if (value)
                            {
                                [self sendStateUpdate:@{scope: value}];
                            }
                        }
                    }
                }

                if (updateMuteState)
                {
                    requestService.zoneName = nil;
                    requestService.variantId = nil;

                    NSArray *sServices = [[Savant data] servicesFilteredByService:requestService];

                    BOOL isGloballyMuted = YES;

                    for (SAVService *service in sServices)
                    {
                        NSString *scope2 = [service.zoneName stringByAppendingString:@".ActiveServices"];

                        if ([self.allStates[scope2] containsString:service.serviceString])
                        {
                            NSString *scope = [service.zoneName stringByAppendingString:@".IsMuted"];
                            isGloballyMuted &= [self.allStates[scope] boolValue];
                        }
                    }

                    NSString *scope = [NSString stringWithFormat:@"%@.%@.isMuted", requestService.component, requestService.logicalComponent];

                    [self sendStateUpdate:@{scope: @(isGloballyMuted)}];
                }
            }
        }
        else if ([uri hasPrefix:@"status"] && [pathComponents count] == 2)
        {
            if ([[pathComponents objectAtIndex:1] isEqualToString:@"device"])
            {
                // for now, do nothing
            }
        }
        else if ([uri isEqualToString:@"session/fileDownload"])
        {
            NSString *filePath = [message objectForKey:@"filePath"];

            if (message[@"URI"])
            {
                SAVFileRequest *fileRequest = [[SAVFileRequest alloc] init];
                fileRequest.fileURI = message[@"URI"];
                fileRequest.payload = message[@"payload"];

                [self dispatchMessageToRouters:fileRequest];
            }
            else if ([[self allowedDownloadPaths] containsObject:filePath] && self.needsUpdate)
            {
                NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"uiconfig" ofType:@".tar.gz"];

                if (bundlePath && [[NSFileManager defaultManager] fileExistsAtPath:bundlePath] && self.needsUpdate)
                {
                    [webSocket sendBinaryFile:bundlePath type:RPM_WEBSOCKET_FILEUPLOAD_TYPE identifier:filePath toUID:self.uid];
                    self.needsUpdate = NO;
                }
                else
                {
                    RPMLogErr(@"could not send file: '%@'", filePath);
                }
            }
        }
        else if ([uri hasPrefix:@"cameras"] && [uri hasSuffix:@"startFetch"] && [pathComponents count] == 3)
        {
            // Do nothing, demo cameras should be reachable
        }
        else if ([uri hasPrefix:@"cameras"] && [uri hasSuffix:@"stopFetch"] && [pathComponents count] == 3)
        {
            // Do nothing, demo cameras should be reachable
        }
        else
        {
            RPMLogErr(@"unrecognized URI: '%@' with message: %@", uri, message);
        }
    }

    return handledCommand;
}

- (void)sendDeviceRecognized
{
    NSMutableDictionary *response = [NSMutableDictionary dictionary];

    [response setObject:@YES forKey:@"authentication"];
    [response setObject:@(self.needsUpdate) forKey:@"update"];
    [response setObject:@"demo"  forKey:@"hostUID"];
    [response setObject:@NO forKey:@"remote"];
    [response setObject:@"Example Home" forKey:@"hostName"];
    [response setObject:@[@{@"user": @"demo", @"authRequired": @NO}] forKey:@"users"];
    [response setObject:[NSNumber numberWithUnsignedInt:RPM_CURRENT_DISCOVERY_VERSION] forKey:@"protocolVersion"];

    [self sendURI:@"deviceRecognized" withMessage:response webSocket:self.webSocket];

    if (!self.sentInitialStates)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendInitialStates) object:nil];
        [self performSelector:@selector(sendInitialStates) withObject:nil afterDelay:0.5];
    }
}

- (NSArray *)allowedDownloadPaths
{
    static NSArray *allowedDownloadPaths = nil;

    if (allowedDownloadPaths == nil)
    {
        allowedDownloadPaths = [[NSArray alloc] initWithObjects:SAVMESSAGE_CONFIG_PATH, nil];
    }

    return allowedDownloadPaths;
}

#pragma mark - Message Sending

- (void)sendURIFromDevice:(NSString *)uri withMessages:(NSArray *)messages
{
    if (uri)
    {
        if ([messages count])
        {
            for (NSDictionary *message in messages)
            {
                [self sendURIFromDevice:uri withMessage:message];
            }
        }
        else
        {
            [self sendURIFromDevice:uri withMessage:[NSDictionary dictionary]];
        }
    }
}

- (void)sendURIFromDevice:(NSString *)uri withMessage:(NSDictionary *)message
{
    if (message)
    {
        [self handleURI:uri forMessage:message webSocket:nil];
    }
}

- (void)sendURIToDevice:(NSString *)uri withMessages:(NSArray *)messages
{
    if (uri && self.webSocket)
    {
        NSDictionary *response = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messages, @"messages",
                                  uri, @"URI",
                                  nil];

        RPMLogInfo(@"sending response: %@", response);

        [self.webSocket sendMessage:response];
    }
}

- (void)sendURI:(NSString *)uri withMessage:(NSDictionary *)message webSocket:(RPMAsyncConnection *)webSocket
{
    NSString *sessionURI = [@"session/" stringByAppendingString:uri];
    NSArray *messages = [NSArray arrayWithObject:message];

    if (webSocket)
    {
        NSDictionary *response = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messages, @"messages",
                                  sessionURI, @"URI",
                                  nil];

        [webSocket sendMessage:response];
    }
}

#pragma mark - Logging

- (void)logURI:(NSString *)uri withMessage:(NSDictionary *)message fromWebSocket:(RPMAsyncConnection *)webSocket
{
    RPMLogInfo(@"received URI: '%@' and message %@", uri, message);
}

#pragma mark - States

- (BOOL)registerState:(NSString *)state
{
    BOOL registered = NO;

    NSUInteger originalCount = [self.registeredStates countForObject:state];

    if (originalCount)
    {
        RPMLogDebug(@"attempting to register state that is already registered: '%@'", state);
    }
    else
    {
        RPMLogDebug(@"registered state: '%@'", state);

        registered = YES;
    }

    [self.registeredStates addObject:state];

    return registered;
}

- (void)registerStates:(NSArray *)states
{
    NSMutableArray *registeredStates = [NSMutableArray array];

    RPMLogDebug(@"attempting to register states: %@", states);

    for (NSDictionary *state in states)
    {
        if ([self registerState:[state objectForKey:@"state"]])
        {
            if ([self.allStates objectForKey: [state objectForKey:@"state"]])
            {
                NSMutableDictionary *stateResponse = [NSMutableDictionary dictionaryWithDictionary:state];
                [stateResponse setObject:[self.allStates objectForKey:[state objectForKey:@"state"]] forKey:@"value"];
                [registeredStates addObject:stateResponse];
            }
        }
    }

    // reply to device with cached values for any newly registered state
    if ([registeredStates count])
    {
        [self sendURIToDevice:@"state/update" withMessages:registeredStates];
    }
}

- (void)unregisterState:(NSString *)state
{
    [self.registeredStates removeObject:state];
}

- (void)unregisterStates:(NSArray *)states
{
    RPMLogDebug(@"attempting to unregister states: %@", states);

    for (NSDictionary *state in states)
    {
        [self unregisterState:[state objectForKey:@"state"]];
    }
}

- (void)sendInitialStates
{
    //TODO: handle host status [self updateHostStatusForDevice:self.uid];
    [self sendURIToDevice:@"state/update" withMessages:[self registeredStatesFromStates:self.allStates]];
    self.sentInitialStates = YES;
}

- (void)sendStateUpdate:(NSDictionary *)states
{
    for (NSString *state in states)
    {
        id object = states[state];

        if (object)
        {
            [self.allStates setObject:object forKey:state];
        }
    }

    [self sendURIToDevice:@"state/update" withMessages:[self registeredStatesFromStates:states]];
}

- (void)postStates:(NSArray *)states
{
    NSMutableDictionary *newStates = [NSMutableDictionary dictionary];

    for (NSDictionary *state in states)
    {
        [newStates setObject:state[@"value"] forKey:state[@"state"]];
    }

    [self sendStateUpdate:newStates];
}

- (NSArray *)registeredStatesFromStates:(NSDictionary *)states
{
    NSMutableArray *registeredStates = [NSMutableArray array];

    for (NSString *state in states)
    {
        if ([self.registeredStates containsObject:state])
        {
            [registeredStates addObject:[NSDictionary dictionaryWithObjectsAndKeys:[states objectForKey:state], @"value", state, @"state", nil]];
        }
    }

    return registeredStates;
}

#pragma mark - Async Connection Delegate Callbacks

- (void)onAsyncConnect:(RPMAsyncConnection *)connection
{
    self.webSocket = connection;
}

- (void)onAsyncDisconnect:(RPMAsyncConnection *)connection
{
    self.webSocket = nil;
}

- (void)onMessage:(id)message fromAsync:(RPMAsyncConnection *)connection
{
    if ([message isKindOfClass:[NSDictionary class]])
    {
        BOOL abort = NO;

        NSString *URI = [message objectForKey:@"URI"];
        NSArray *messages = [message objectForKey:@"messages"];

        if (URI && messages)
        {
            NSMutableArray *unhandledMessages = [NSMutableArray array];

            if ([messages count])
            {
                for (NSDictionary *m in messages)
                {
                    if (![self handleURI:URI forMessage:m webSocket:connection abort:&abort])
                    {
                        [unhandledMessages addObject:m];
                    }

                    if (abort)
                    {
                        break;
                    }
                }
            }
            else
            {
                if (![self handleURI:URI forMessage:nil webSocket:connection abort:&abort])
                {
                    [unhandledMessages addObject:[NSDictionary dictionary]];
                }
            }
            
            if (abort)
            {
                // lost connection
            }
            else if ([unhandledMessages count])
            {
                [self sendURIFromDevice:URI withMessages:unhandledMessages];
            }
        }
    }
}

#pragma mark - State restoration

- (id)restorationInfo
{
    return self.allStates ? self.allStates : @{};
}

- (void)restoreState:(id)state
{
    NSParameterAssert([state isKindOfClass:[NSDictionary class]]);
    self.allStates = [state mutableCopy];
}

#pragma mark - SystemStatusDelegate

- (void)connectionIsReady
{
    if ([NSThread currentThread] != self.demoThread)
    {
        [self performSelector:_cmd onThread:self.demoThread withObject:nil waitUntilDone:NO];
        return;
    }

    [self.internalRouters removeAllObjects];

    [self.internalRouters addObject:[[SAVHVACDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVPoolDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVScenesDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVUserDataDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVLMQDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVLightingDemoRouter alloc] init]];
    [self.internalRouters addObject:[[SAVFavoritesDemoRouter alloc] init]];

    for (id <SAVDemoRouter> router in self.internalRouters)
    {
        [self addRouter:router];
    }
}

@end
