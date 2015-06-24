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

//##OBJCLEAN_SKIP##

#import "RPMAsyncConnection.h"
#import "RPMCommunicationUtils.h"
#import "RPMCommunicationConstants.h"

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmGeneralUtils/rpmUtils.h>
#import <rpmGeneralUtils/scsCredentials.h>
#else
#import "rpmSharedLogger.h"
#endif

#include <arpa/inet.h>

@interface RPMAsyncConnection ()
@property (readwrite, assign) RPMAsyncConnection *parent;
@property (readwrite, retain) NSString *host;
@property (readwrite, retain) RPMWebSocket *localWebSocket;
- (id)initWithSocket: (RPMWebSocket*)webSocket;
- (void)removeService;
- (void)removeServiceAfterDelay;
- (void)startBrowse;
- (void)stopBrowse;
- (void)publish;
- (BOOL)createClient;

@end

@implementation RPMAsyncConnection

@synthesize useDiscoveryServer=_useDiscoveryServer;
@synthesize securityLevel=_securityLevel;
@synthesize delegate=_delegate;
@synthesize delegateThread=_delegateThread;
@synthesize port=_port;
@synthesize connectionAttemptTimeout=_connectionAttemptTimeout;
@synthesize userInfo = _userInfo;
@synthesize parent = _parent;
@synthesize host = _host;
@synthesize connectedClients=_connectedClients;
@synthesize isServer=_isServer;
@synthesize localWebSocket=_localSocket;
@synthesize useLoopback=_useLoopback;
@synthesize cloudEnabled=_cloudEnabled;

- (id)initClientWithServiceName: (NSString*)serviceName
                           type: (NSString*)serviceType
                     systemName: (NSString*)systemName
                       delegate: (id)delegate
{
    self = [super init];
    if (self)
    {
        _serviceName = [serviceName retain];
        _serviceType = [serviceType retain];
        _systemName = [systemName retain];
        _delegate = delegate;
        _securityLevel = RPM_WS_SSL;
    }
    return self;
}

- (id)initClientWithHost:(NSString *)host
                    port:(int)port
                  secure:(RPMWebSocketClientSSL)securityLevel
                delegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        _host = [host retain];
        _port = port;
        _delegate = delegate;
        _securityLevel = securityLevel;
    }
    return self;
}

- (id)initServerWithServiceName:(NSString *)serviceName
                           type:(NSString *)serviceType
                     systemName:(NSString *)systemName
                         secure:(BOOL)secure
                       delegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        _serviceName = [serviceName retain];
        _serviceType = [serviceType retain];
        _systemName = [systemName retain];
        _delegate = delegate;
        _securityLevel = secure ? RPM_WS_SSL : RPM_WS_NoSSL;
        _isServer = YES;
    }
    return self;
}

- (id)initServerWithSystemName:(NSString *)systemName
                      uniqueID:(NSString *)uid
                        secure:(BOOL)secure
                      delegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        _useDiscoveryServer = YES;
        _systemName = [systemName retain];
        _systemUID = [uid retain];
        _delegate = delegate;
        _securityLevel = secure ? RPM_WS_SSL : RPM_WS_NoSSL;
        _isServer = YES;
    }
    return self;
}

- (id)initServerWithPort:(int)port
                  secure:(BOOL)secure
                delegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        _port = port;
        _delegate = delegate;
        _securityLevel = secure ? RPM_WS_SSL : RPM_WS_NoSSL;
        _isServer = YES;
    }
    return self;
}

- (void)startConnection
{
    [_publishRetryTimer invalidate];
    [_publishRetryTimer release];
    _publishRetryTimer = nil;
    
    if (!self.connectionAttemptTimeout)
    {
        self.connectionAttemptTimeout = 6;
    }
    
    if (_isServer)
    {
        [_localSocket invalidate];
        [_localSocket release];
        _localSocket = [[RPMWebSocket alloc] init];
        _localSocket.useLoopback = self.useLoopback;
        _localSocket.port = _port;
        _localSocket.delegate = self;
        _localSocket.delegateThread = self.delegateThread;
        
        if ([_localSocket createServerWithSSL:self.securityLevel])
        {
            [self publish];
        }
        else
        {
            [_publishRetryTimer invalidate];
            [_publishRetryTimer release];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
            _publishRetryTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 + (fmodf(((float)arc4random())/10000.0, 3.5)))//RPM_WEBSOCKET_PUBLISH_RETRYTIMEOUT
                                                                   target:self
                                                                 selector:@selector(startConnection)
                                                                 userInfo:nil
                                                                  repeats:NO] retain];
#pragma clang diagnostic pop
        }
    }
    else
    {
        // User wishes to browse for server
        if (_serviceType && _serviceType)
        {
            // Uses new discovery server to locate server
            if (self.useDiscoveryServer)
            {
                // TODO: Implement discovery scanner
            }
            // Uses bonjour to locate server
            else
            {
                [self startBrowse];
            }
        }
        // Connect directly with supplied info
        else
        {
            [self createClient];
        }
    }
}

- (void)invalidate
{
    _delegate = nil;
    
    [self stopBrowse];
    
    [_bonjourService stop];
    [_bonjourService release];
    _bonjourService = nil;
    
    [_clientConnectRetry invalidate];
    [_clientConnectRetry release];
    _clientConnectRetry = nil;
    
    [_clientConnectTimeout invalidate];
    [_clientConnectTimeout release];
    _clientConnectTimeout = nil;
    
    [_publishRetryTimer invalidate];
    [_publishRetryTimer release];
    _publishRetryTimer = nil;

    _localSocket.userInfo = nil;
    _localSocket.delegate = nil;
    [_localSocket invalidate];
    [_localSocket release];
    _localSocket = nil;

    [self.parent.connectedClients removeObject:self];

    for (RPMAsyncConnection *connection in _connectedClients)
    {
        connection.localWebSocket.userInfo = nil;
    }

    [_connectedClients removeAllObjects];
    [_connectedClients release];
    _connectedClients = nil;
}

- (void)dealloc
{
    [_connectedClients release];
    _connectedClients = nil;

    [_savantService invalidate];
    [_savantService release];
    _savantService = nil;
    
    [_host release];
    _host = nil;
    
    [_serviceName release];
    _serviceName = nil;
    
    [_serviceType release];
    _serviceType = nil;
    
    [_systemName release];
    _systemName = nil;
    
    [_systemUID release];
    _systemUID = nil;
    
    [_bonjourBrowser release];
    _bonjourBrowser = nil;
    
    [_bonjourService release];
    _bonjourService = nil;
    
    [_clientConnectRetry release];
    _clientConnectRetry = nil;

    [_clientConnectTimeout invalidate];
    [_clientConnectTimeout release];
    _clientConnectTimeout = nil;

    [_publishRetryTimer invalidate];
    [_publishRetryTimer release];
    _publishRetryTimer = nil;

    [_localSocket release];
    _localSocket = nil;

#ifndef GNUSTEP
    [_savantBrowser release];
    _savantBrowser = nil;
#endif
    
    [_userInfo release];
    _userInfo = nil;
    
    [super dealloc];
}

- (void)setInterfaceExtractionProgress:(NSNumber *)progress
{
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    _savantService.interfaceExtractionProgress = progress;
#endif
}

- (int)port
{
    return (_port) ? _port : [_localSocket port];
}

- (void)onWebSocketConnect: (RPMWebSocket*)webSocket
{
    RPMAsyncConnection *connection = self;
    
    // A new client has connected to a server, create a new connection to represent
    // the remote client and inform delegate
    if (webSocket != _localSocket)
    {
        connection = [[[RPMAsyncConnection alloc] initWithSocket:webSocket] autorelease];
        connection.host = webSocket.host;
        connection.port = webSocket.port;
        connection.delegate = _delegate;
        connection.parent = self;
        webSocket.userInfo = connection;

        if (!_connectedClients)
        {
            _connectedClients = [[NSMutableArray alloc] init];
        }
        
        [_connectedClients addObject: connection];
    }
    
    [_clientConnectTimeout invalidate];
    [_clientConnectTimeout release];
    _clientConnectTimeout = nil;
    
    if ([connection.delegate respondsToSelector:@selector(onAsyncConnect:)])
    {
        [connection.delegate onAsyncConnect:connection];
    }
}

- (void)onWebSocketDisconnect:(RPMWebSocket *)webSocket
{
    // A client has disconnected from the server, inform delgate and remove from
    // connected clients
    if (webSocket != _localSocket)
    {
        RPMAsyncConnection *connection = webSocket.userInfo;

        if ([connection.delegate respondsToSelector:@selector(onAsyncDisconnect:)])
        {
            [connection.delegate onAsyncDisconnect:connection];
        }

        [_connectedClients removeObject:webSocket.userInfo];
        webSocket.userInfo = nil;
    }
    else
    {
        [_clientConnectTimeout invalidate];
        [_clientConnectTimeout release];
        _clientConnectTimeout = nil;
        
        [_clientConnectRetry invalidate];
        [_clientConnectRetry release];

        // Start client retry
        if (_serviceType && _serviceName)
        {
            _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                                    target:self
                                                                  selector:@selector(startBrowse)
                                                                  userInfo:nil
                                                                   repeats:NO] retain];
        }
        else
        {
            _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                                    target:self
                                                                  selector:@selector(createClient)
                                                                  userInfo:nil
                                                                   repeats:NO] retain];
        }

        if ([self.delegate respondsToSelector:@selector(onAsyncDisconnect:)])
        {
            [self.delegate onAsyncDisconnect:self];
        }
    }
}

- (void)onMessage:(id)message from:(RPMWebSocket *)webSocket
{
    RPMAsyncConnection *connection = self;
    
    if (webSocket != _localSocket)
    {
        connection = webSocket.userInfo;
    }
    
    if ([connection.delegate respondsToSelector:@selector(onMessage:fromAsync:)])
    {
        [connection.delegate onMessage:message fromAsync:connection];
    }
}

- (void)onBinary:(id)message from:(RPMWebSocket *)webSocket
{
    RPMAsyncConnection *connection = self;
    
    if (webSocket != _localSocket)
    {
        connection = webSocket.userInfo;
    }
    
    if ([connection.delegate respondsToSelector:@selector(onBinary:fromAsync:)])
    {
        [connection.delegate onBinary:message fromAsync:connection];
    }
}

- (void)onBinaryTransferDidCompleteWithUID: (NSString*)uid
                                identifier: (NSObject *)identifier
                                      from: (RPMWebSocket *)websocket
{
    RPMAsyncConnection *connection = self;
    
    if (websocket != _localSocket)
    {
        connection = websocket.userInfo;
    }
    
    if ([connection.delegate respondsToSelector:@selector(onBinaryTransferDidCompleteWithUID:identifier:fromAsync:)])
    {
        [connection.delegate onBinaryTransferDidCompleteWithUID:uid identifier:identifier fromAsync:connection];
    }
}

- (void)onCriticalWriteFailureFrom: (RPMWebSocket *)websocket
{
    RPMAsyncConnection *connection = self;

    if (websocket != _localSocket)
    {
        connection = websocket.userInfo;
    }

    if ([connection.delegate respondsToSelector:@selector(onCriticalWriteFailureFromAsync:)])
    {
        [connection.delegate onCriticalWriteFailureFromAsync:connection];
    }
}

- (void)sendMessage:(id)message
{
    [_localSocket sendMessage:message];
}

- (void)startDelayedBinaryTransferOfType:(NSUInteger)type length:(unsigned long long)length identifier:(NSObject*)identifier
{
    [_localSocket startDelayedBinaryTransferOfType:type length:length identifier:identifier];
}

- (void)sendBinaryData:(NSData*)data type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid
{
    [_localSocket sendBinaryData:data type:type identifier:identifier toUID:uid];
}

- (void)sendBinaryFile:(NSString*)path type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid
{
    [_localSocket sendBinaryFile:path type:type identifier:identifier toUID:uid];
}

- (void)netServiceBrowser: (NSNetServiceBrowser*)aNetServiceBrowser
           didFindService: (NSNetService*)aNetService
               moreComing: (BOOL)moreComing
{
    RPMLogInfo(@"Found bonjour service %@ on system %@",[aNetService name],_systemName);
	
	if([[aNetService name] isEqualToString: _serviceName])
    {
        [_bonjourService setDelegate: nil];
        [_bonjourService stop];
		[_bonjourService release];
		_bonjourService = nil;
        
        _bonjourService = [aNetService retain];
        [_bonjourService setDelegate: self];
        [_bonjourService resolveWithTimeout: 10];
		
        [_bonjourBrowser setDelegate: nil];
        [_bonjourBrowser stop];
        [_bonjourBrowser release];
        _bonjourBrowser = nil;
    }
}

- (void)netServiceDidResolveAddress: (NSNetService*)aNetService
{
    if(_bonjourService == aNetService)
    {
        for(NSData *currAddr in [_bonjourService addresses])
        {
            struct sockaddr_in *saddr = (struct sockaddr_in *)[currAddr bytes];
            unsigned short port = ntohs( saddr->sin_port);
            
            if((saddr->sin_family == AF_INET) &&
               (ntohs(saddr->sin_port)) &&
               (ntohl(saddr->sin_addr.s_addr)))
            {
                [_host release];
                _host = [[NSString stringWithCString:inet_ntoa(saddr->sin_addr) encoding:NSUTF8StringEncoding] retain];
                _port = port;
                
                NSDictionary *serviceData = [NSNetService dictionaryFromTXTRecordData:[aNetService TXTRecordData]];
                
                NSString *secureRecord = [[[NSString alloc] initWithBytes:[[serviceData objectForKey: @"secure"] bytes]
                                                                   length:[(NSData*)[serviceData objectForKey: @"secure"] length]
                                                                 encoding:NSASCIIStringEncoding] autorelease];
                
                _securityLevel = [secureRecord isEqualToString: @"true"] ? RPM_WS_SSLAllowSelfSigned : RPM_WS_NoSSL;
                
                if ([self createClient])
                {
                    [self removeServiceAfterDelay];
                    return;
                }
            }
        }
    }
}

- (void)netService:(NSNetService*)aNetService
     didNotResolve:(NSDictionary*)errorDict
{
    if([aNetService respondsToSelector: @selector(setDelegate:)])
    {
        [aNetService setDelegate: nil];
    }
    if([aNetService respondsToSelector: @selector(stop)])
    {
        [aNetService stop];
    }
    
    [_clientConnectRetry invalidate];
    [_clientConnectRetry release];
    _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                            target:self
                                                          selector:@selector(startBrowse)
                                                          userInfo:nil
                                                           repeats:NO] retain];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo
{
    [_clientConnectRetry invalidate];
    [_clientConnectRetry release];
    _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                            target:self
                                                          selector:@selector(startBrowse)
                                                          userInfo:nil
                                                           repeats:NO] retain];
}

- (void)netServiceDidPublish:(NSNetService*)sender
{
    [_publishRetryTimer invalidate];
    _publishRetryTimer = nil;
}

//---------------------------------------------------------------
//
//       Description
//
//       Return Value
//
//       Caveats
//
//       Arguments
//
//---------------------------------------------------------------
- (void)netService:(NSNetService*)netService
     didNotPublish:(NSDictionary*)errorDict
{
    RPMLogErr(@"Failed to publish Async Connection with name \"%@\" and type \"%@\"", _serviceName, _serviceType);
    [_publishRetryTimer invalidate];
    [_publishRetryTimer release];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    _publishRetryTimer = [[NSTimer scheduledTimerWithTimeInterval:RPM_WEBSOCKET_PUBLISH_RETRYTIMEOUT
                                                           target:self
                                                         selector:@selector(publish)
                                                         userInfo:nil
                                                          repeats:NO] retain];
#pragma clang diagnostic pop
}

- (BOOL)isReady
{
    return _localSocket.isReady;
}

- (RPMWebSocketState)websocketState
{
    return _localSocket.websocketState;
}

- (BOOL)isValid
{
    return _localSocket.isReady || _localSocket.isConnecting;
}

- (id)initWithSocket: (RPMWebSocket*)webSocket
{
    self = [super init];
    if (self) {
        _localSocket = [webSocket retain];
        _localSocket.delegate = self;
    }
    return self;
}

- (void)removeService
{
    [self performSelector:@selector(_removeService)];
}

- (void)removeServiceAfterDelay
{
  [self performSelector: @selector(_removeService) withObject: nil afterDelay: 0];
}

- (void)_removeService
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
    if(_bonjourService != nil)
    {
        [_bonjourService setDelegate: nil];
        [_bonjourService stop];
        [_bonjourService release];
        _bonjourService = nil;
    }
}

- (void)startBrowse
{
    [_clientConnectRetry invalidate];
    [_clientConnectRetry release];
    _clientConnectRetry = nil;
    
    [_clientConnectTimeout invalidate];
    [_clientConnectTimeout release];
    _clientConnectTimeout = nil;
    
    [self removeService];
    [self stopBrowse];
    
    _bonjourBrowser = [[NSNetServiceBrowser alloc] init];
    [_bonjourBrowser setDelegate: self];
    [_bonjourBrowser searchForServicesOfType: [RPMCommunicationUtils createAsyncServiceType:_serviceType
                                                                                 systemName:_systemName]
                                    inDomain: RPM_ASYNC_BROWSEDOMAIN];
}

- (void)stopBrowse
{
    [_bonjourBrowser setDelegate: nil];
    [_bonjourBrowser stop];
    [_bonjourBrowser release];
    _bonjourBrowser = nil;
    
#ifndef GNUSTEP
    [_savantBrowser setDelegate:nil];
    [_savantBrowser release];
    _savantBrowser = nil;
#endif
}

- (void)updateCloudProperties
{
#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
    if (self.cloudEnabled && self.useDiscoveryServer) {
        _savantService.homeID = [SCSCredentials sharedCredentials].homeId;
        _savantService.onboardKey = [[SCSCredentials sharedCredentials].users count] ? nil : [SCSCredentials sharedCredentials].onboardKey;
    }
#endif
}

- (void)publish
{
    [_publishRetryTimer invalidate];
    [_publishRetryTimer release];
    _publishRetryTimer = nil;
    
    // Uses new discovery server to publish server
    if (self.useDiscoveryServer)
    {
        if (_systemUID && _systemName)
        {
            [_savantService invalidate];
            [_savantService release];
            _savantService = [[RPMDiscoveryServer alloc] initWithUID:_systemUID
                                                                port:(NSUInteger)self.port
                                                                name:_systemName
                                                              scheme:self.securityLevel != RPM_WS_NoSSL ? RPM_DISCOVERY_SCHEME_SECURE_WEBSOCKET : RPM_DISCOVERY_SCHEME_WEBSOCKET];
            [self updateCloudProperties];
            
            [_savantService startServer];
        }
        else
        {
            RPMLogInfo(@"Not publishing because no system name or uid defined");
        }
    }
    // Uses bonjour to publish server
    else
    {
        if (_serviceType && _serviceName)
        {
            // TODO: Advertise web socket scheme (ws/wss)
            _bonjourService = [[NSNetService alloc] initWithDomain: RPM_ASYNC_BROWSEDOMAIN
                                                              type: [RPMCommunicationUtils createAsyncServiceType:_serviceType
                                                                                                       systemName:_systemName]
                                                              name: _serviceName
                                                              port: self.port];
            NSData *txtData = [NSNetService dataFromTXTRecordDictionary:
                               [NSDictionary dictionaryWithObject:(self.securityLevel != RPM_WS_NoSSL) ? @"true" : @"false" forKey:@"secure"]];
            [_bonjourService setTXTRecordData:txtData];
            [_bonjourService setDelegate: self];
            [_bonjourService publish];
        }
        else
        {
            RPMLogInfo(@"Not publishing because no service type or name defined");
        }
    }
}

- (BOOL)createClient
{
    _localSocket.userInfo = nil;
    _localSocket.delegate = nil;
    [_localSocket invalidate];
    [_localSocket release];
    
    _localSocket = [[RPMWebSocket alloc] init];
    _localSocket.host = _host;
    _localSocket.port = _port;
    _localSocket.delegate = self;
    _localSocket.delegateThread = self.delegateThread;
    
    if ([_localSocket createClientWithSSL:self.securityLevel])
    {
        [self removeService];
        [self stopBrowse];
        // Start timer for Async client connect
        [_clientConnectTimeout invalidate];
        [_clientConnectTimeout release];
        _clientConnectTimeout = nil;
        
        [_clientConnectRetry invalidate];
        [_clientConnectRetry release];
        _clientConnectRetry = nil;
        
        _clientConnectTimeout = [[NSTimer scheduledTimerWithTimeInterval:self.connectionAttemptTimeout
                                                                  target:self
                                                                selector:@selector(clientConnectTimeout)
                                                                userInfo:nil
                                                                 repeats:NO] retain];
        return YES;
    }
    else
    {
        [_clientConnectTimeout invalidate];
        [_clientConnectTimeout release];
        _clientConnectTimeout = nil;
        
        [_clientConnectRetry invalidate];
        [_clientConnectRetry release];
        
        // Start client retry
        if (_serviceType && _serviceType)
        {
            _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                                    target:self
                                                                  selector:@selector(startBrowse)
                                                                  userInfo:nil
                                                                   repeats:NO] retain];
        }
        else
        {
            _clientConnectRetry = [[NSTimer scheduledTimerWithTimeInterval:5
                                                                    target:self
                                                                  selector:@selector(createClient)
                                                                  userInfo:nil
                                                                   repeats:NO] retain];
        }
    }
    
    return NO;
}

- (void)clientConnectTimeout
{
    [self retain];
    
    [_clientConnectTimeout invalidate];
    [_clientConnectTimeout release];
    _clientConnectTimeout = nil;
    
    // Client is blocked trying to connect, try again later
    if (!_isServer && _localSocket.isConnecting)
    {
        BOOL retry = YES;
        
        if ([self.delegate respondsToSelector:@selector(onAsyncConnectionAttemptTimeout:)])
        {
            retry = [self.delegate onAsyncConnectionAttemptTimeout:self];
        }
        
        if (retry)
        {
            _clientConnectTimeout = [[NSTimer scheduledTimerWithTimeInterval:self.connectionAttemptTimeout
                                                                      target:self
                                                                    selector:@selector(clientConnectTimeout)
                                                                    userInfo:nil
                                                                     repeats:NO] retain];
        }
    }
    else if (_serviceType && _serviceType)
    {
        [self startBrowse];
    }
    else
    {
        [self createClient];
    }
    
    [self autorelease];
}

- (void)rpm_performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait
{
#ifdef GNUSTEP
    [self performSelector:aSelector onThread:thr withObject:arg waitUntilDone:wait modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
#else
    [self performSelector:aSelector onThread:thr withObject:arg waitUntilDone:wait];
#endif
}

@end

//##OBJCLEAN_ENDSKIP##
