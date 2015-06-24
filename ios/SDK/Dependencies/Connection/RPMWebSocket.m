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

#import "RPMWebSocket.h"

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/MessagePack.h>
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmGeneralUtils/mfiSharedCocoaExtensions.h>
#import <rpmGeneralUtils/rpmUtils.h>

#else
#import "MessagePack.h"
#import "rpmSharedLogger.h"
#import "mfiSharedCocoaExtensions.h"
#endif

#ifndef GNUSTEP
// need to move these to an appropriate place
#define htobe64(x) OSSwapHostToBigInt64(x)
#define be64toh(x) OSSwapBigToHostInt64(x)
#define htobe32(x) OSSwapHostToBigInt32(x)
#define be32toh(x) OSSwapBigToHostInt32(x)
#endif

#include <sys/socket.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>
#include <ifaddrs.h>

// We should decide on a better place for these on the supported platforms
#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#define RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH  ([[RPMUtils getPathForCerts] stringByAppendingPathComponent: @"libwebsockets-savant-cert.pem"])
#define RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH  ([[RPMUtils getPathForCerts] stringByAppendingPathComponent: @"libwebsockets-savant-key.pem"])
#endif

#define kLWSDefaultServiceTime (20)
#define kLWSMaxConsecutiveWriteFailures (15)

#define kLWSMessageQueueTargetKey   @"t"
#define kLWSMessageQueueSelectorKey @"s"
#define kLWSMessageQueueArgumentKey @"a"

#define kLWSMessageDataKey          (@"data")
#define kLWSMessageStreamKey        (@"stream")
#define kLWSMessageProtocolKey      (@"protocol")

#define kLWSBufferSize              (1024 - LWS_SEND_BUFFER_PRE_PADDING - LWS_SEND_BUFFER_POST_PADDING)

static const long kBinaryCompletionHeaderOffset = 1;

@interface RPMWebSocket ()

@property(readwrite, assign)NSThread* backgroundThread;
@property(readwrite, retain)NSMutableArray* messageQueue;
@property(readwrite, assign)RPMWebSocket* parentWebSocket;
@property(readwrite, assign)BOOL isRegisteredForWritability;
@property(readwrite, assign)BOOL isWritable;
@property(readwrite) struct libwebsocket_context *context;
@property(readwrite, assign)int consecutiveWriteFailures;
@property (retain) NSMutableDictionary *pendingBinaryTransfers;
@property (retain) NSMutableArray *activeBinaryTransfers;
@property (retain) NSMutableArray *connectedWebSockets;
@property (assign) struct per_session_data__rpm_protocol *psd;
@property (readwrite, retain) NSMutableArray *webSocketsToRemove;

- (id)initWithWSI: (struct libwebsocket *)wsi
        webSocket: (RPMWebSocket*)websocket;
- (void)_processMessage: (NSData*)data;
- (NSDictionary*)_processBinaryMessage: (NSData*)msg;
- (void)_receivedPongMessage;
- (void)_createServer;
- (void)_createClient;
- (void)_sendTextMessage: (NSString*)message;
- (void)_sendBinaryMessage: (NSData*)message;
- (void)_writeMessage: (NSDictionary*)payload;
- (void)_newWebSocketConnection: (RPMWebSocket*)websocket;
- (void)_deadWebSocketConnection: (RPMWebSocket*)websocket;
- (BOOL)_setupServerSSLSupport;
- (void)_sendBinaryStreamWithIdentifier:(NSDictionary*)dict;
- (void)_addMessageToQueueWithSelector:(SEL)selector argument:(id)argument;
- (void)_addMessageToQueueHeadWithSelector:(SEL)selector argument:(id)argument;
- (void)_addMessageToQueueWithSelector:(SEL)selector argument:(id)argument atIndex:(NSInteger)idx;
- (void)_serviceMessageQueue;
- (void)_invokeInvocation:(NSDictionary *)invocation;
- (void)_scheduleAPing;
- (void)_sendPingMessage;
- (void)_writePingMessage;
- (void)_sendPongMessage;
- (void)_runServiceLoop;
- (void)_createContextWithInfo:(struct lws_context_creation_info *)contextInfo;
- (void)_doCreateContextWithInfo:(NSValue *)contextInfo;
+ (void)_registerForWebSocketForWritability:(RPMWebSocket *)webSocket;
- (int)_writeBuffer:(unsigned char *)buffer length:(size_t)length writeProtocol:(enum libwebsocket_write_protocol)protocol;
- (NSMutableData*)_binaryHeaderWithType:(NSUInteger)type size:(uint64_t)size complete:(BOOL)complete identifer:(NSObject*)identifier;
- (void)rpm_performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait;
- (void)queueBinaryFile:(NSString *)path withIdentifier:(id)identifier ofType:(NSUInteger)type toUID:(NSString *)uid;
- (void)queueBinaryData:(NSData *)data withIdentifier:(id)identifier ofType:(NSUInteger)type toUID:(NSString *)uid;
- (void)queueBinaryTransfer:(NSDictionary *)transfer withIdentifier:(id)identifier;
- (void)sendNextBinaryTransferWithIdentifier:(id)identifier;
@end

struct per_session_data__rpm_protocol {
    RPMWebSocket *client;
};

static int callback_rpm(struct libwebsocket_context *context,
                        struct libwebsocket *wsi,
                        enum libwebsocket_callback_reasons reason,
                        void *user,
                        void *in,
                        size_t len)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
    RPMWebSocket *localWebsocket = (RPMWebSocket*)libwebsocket_context_user(context);

    if (!localWebsocket)
    {
        return -1;
    }

    switch (reason)
    {
        case LWS_CALLBACK_ESTABLISHED:
        {
            RPMLogNotice(@"Server connection established");

            struct per_session_data__rpm_protocol *psd = (struct per_session_data__rpm_protocol*)user;
            RPMWebSocket *remoteWebsocket = [[[RPMWebSocket alloc] initWithWSI:wsi
                                                                     webSocket:localWebsocket] autorelease];
            remoteWebsocket.psd = psd;

            psd->client = remoteWebsocket;
            remoteWebsocket.websocketState = RPMWebSocketStateOpen;
            [RPMWebSocket _registerForWebSocketForWritability:remoteWebsocket];
            [localWebsocket _newWebSocketConnection: remoteWebsocket];
            break;
        }
        case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
            if (localWebsocket.webSocket && localWebsocket.isReady)
            {
                RPMLogNotice(@"Dead client websocket connection");
                [localWebsocket _deadWebSocketConnection: localWebsocket];
            }
            break;
        case LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH:
            break;
        case LWS_CALLBACK_CLIENT_ESTABLISHED:
            RPMLogNotice(@"Client connection established");
            localWebsocket.websocketState = RPMWebSocketStateOpen;
            [RPMWebSocket _registerForWebSocketForWritability:localWebsocket];
            [localWebsocket _newWebSocketConnection: localWebsocket];
            break;
        case LWS_CALLBACK_CLOSED:
        {
            struct per_session_data__rpm_protocol *psd = (struct per_session_data__rpm_protocol*)user;
            RPMWebSocket *remoteWebsocket = psd->client;

            if (remoteWebsocket && remoteWebsocket.isReady)
            {
                // We're a server, tell the remote websocket it closed
                RPMLogNotice(@"Dead websocket server connection");
                [localWebsocket _deadWebSocketConnection: remoteWebsocket];
            }
            else if (localWebsocket && localWebsocket.webSocket && localWebsocket.isReady)
            {
                // We're a client, close local websocket
                RPMLogNotice(@"Dead websocket client connection");
                [localWebsocket _deadWebSocketConnection: localWebsocket];
            }

            localWebsocket.websocketState = RPMWebSocketStateClosed;

            return -1;
        }
        case LWS_CALLBACK_RECEIVE:
        {
            struct per_session_data__rpm_protocol *psd = (struct per_session_data__rpm_protocol*)user;
            RPMWebSocket *websocketClient = psd->client;

            if (!websocketClient || !websocketClient.webSocket)
            {
                return -1;
            }

            const size_t remaining = libwebsockets_remaining_packet_payload(wsi);

            if (!remaining && libwebsocket_is_final_fragment(wsi))
            {
                if (websocketClient.fragment)
                {
                    [websocketClient.fragment appendBytes:in
                                                   length:len];
                    [websocketClient _processMessage:websocketClient.fragment.data];
                    websocketClient.fragment = nil;
                }
                else
                {
                    [websocketClient _processMessage:[NSData dataWithBytes:in length:len]];
                }
            }
            else
            {
                if (websocketClient.fragment)
                {
                    [websocketClient.fragment appendBytes:in
                                                   length:len];
                }
                else
                {
                    websocketClient.fragment = [RPMWebSocketFragment fragmentWithBytes:in
                                                                                length:len
                                                                             remaining:remaining];
                }
            }

            [localWebsocket _receivedPongMessage];  // for message saturation case not allowing pongs to be sent or received

            break;
        }
        case LWS_CALLBACK_RECEIVE_PING:
        {
            struct per_session_data__rpm_protocol *psd = (struct per_session_data__rpm_protocol*)user;
            RPMWebSocket *websocketClient = psd->client;
            RPMLogDebug(@"Received ping message");
            [websocketClient _sendPongMessage];

            if (!websocketClient)
            {
                return -1;
            }

            break;
        }
        case LWS_CALLBACK_CLIENT_RECEIVE:
        {
            if (!localWebsocket.webSocket)
            {
                return -1;
            }

            const size_t remaining = libwebsockets_remaining_packet_payload(wsi);

            if (!remaining && libwebsocket_is_final_fragment(wsi))
            {
                if (localWebsocket.fragment)
                {
                    [localWebsocket.fragment appendBytes:in
                                                  length:len];
                    [localWebsocket _processMessage:localWebsocket.fragment.data];
                    localWebsocket.fragment = nil;
                }
                else
                {
                    [localWebsocket _processMessage:[NSData dataWithBytes:in length:len]];
                }
            }
            else
            {
                if (localWebsocket.fragment)
                {
                    [localWebsocket.fragment appendBytes:in
                                                  length:len];
                }
                else
                {
                    localWebsocket.fragment = [RPMWebSocketFragment fragmentWithBytes:in
                                                                               length:len
                                                                            remaining:remaining];
                }
            }

            [localWebsocket _receivedPongMessage];  // for message saturation case not allowing pongs to be sent or received
            break;
        }
        case LWS_CALLBACK_CLIENT_RECEIVE_PONG:
            [localWebsocket _receivedPongMessage];
            RPMLogDebug(@"Received pong message");
            break;
        case LWS_CALLBACK_CLIENT_WRITEABLE:
        {
            localWebsocket.isWritable = YES;
            [localWebsocket _serviceMessageQueue];
            break;
        }
        case LWS_CALLBACK_SERVER_WRITEABLE:
        {
            struct per_session_data__rpm_protocol *psd = (struct per_session_data__rpm_protocol*)user;
            RPMWebSocket *websocketClient = psd->client;
            websocketClient.isWritable = YES;
            [websocketClient _serviceMessageQueue];

            if (!websocketClient.isReady)
            {
                return -1;
            }

            break;
        }
        case LWS_CALLBACK_HTTP:
        case LWS_CALLBACK_HTTP_FILE_COMPLETION:
        case LWS_CALLBACK_FILTER_NETWORK_CONNECTION:
        case LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION:
        case LWS_CALLBACK_OPENSSL_LOAD_EXTRA_CLIENT_VERIFY_CERTS:
        case LWS_CALLBACK_OPENSSL_LOAD_EXTRA_SERVER_VERIFY_CERTS:
        case LWS_CALLBACK_OPENSSL_PERFORM_CLIENT_CERT_VERIFICATION:
        case LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER:
        case LWS_CALLBACK_CONFIRM_EXTENSION_OKAY:
        case LWS_CALLBACK_CLIENT_CONFIRM_EXTENSION_SUPPORTED:
            break;
        case LWS_CALLBACK_PROTOCOL_INIT:
            break;
        case LWS_CALLBACK_PROTOCOL_DESTROY:
            break;
            /* external poll() management support */
        case LWS_CALLBACK_ADD_POLL_FD:
        case LWS_CALLBACK_DEL_POLL_FD:
        case LWS_CALLBACK_SET_MODE_POLL_FD:
        case LWS_CALLBACK_CLEAR_MODE_POLL_FD:
        default:
            break;
    }
#pragma clang diagnostic pop

    return 0;
}

static struct libwebsocket_protocols protocols[] = {
    {   "rpm-protocol", callback_rpm, sizeof(struct per_session_data__rpm_protocol), 1024   },
    {   NULL, NULL, 0, 0    }
};

@implementation RPMWebSocket

@synthesize delegate=_delegate;
@synthesize delegateThread=_delegateThread;
@synthesize websocketState=_websocketState;
@synthesize isReady=_readyState;
@synthesize isConnecting=_isConnecting;
@synthesize host=_host;
@synthesize port=_port;
@synthesize secure=_secure;
@synthesize fragment=_fragment;
@synthesize userInfo=_userInfo;
@synthesize messageQueue=_messageQueue;
@synthesize parentWebSocket=_parentWebSocket;
@synthesize isRegisteredForWritability=_isRegisteredForWritability;
@synthesize isWritable=_isWritable;
@synthesize context=_context;
@synthesize webSocket=_webSocket;
@synthesize backgroundThread=_backgroundThread;
@synthesize useLoopback=_useLoopback;
@synthesize consecutiveWriteFailures=_consecutiveWriteFailures;
@synthesize activeBinaryTransfers=_activeBinaryTransfers;
@synthesize pendingBinaryTransfers=_pendingBinaryTransfers;
@synthesize connectedWebSockets=_connectedWebSockets;
@synthesize psd=_psd;
@synthesize webSocketsToRemove=_webSocketsToRemove;

- (BOOL)createClientWithSSL:(RPMWebSocketClientSSL)securityLevel
{
    if (self.context)
    {
        RPMLogErr(@"Client context already exists, cannot create a new one until it is destroyed");
        return NO;
    }

    struct lws_context_creation_info info;
    memset(&info, 0, sizeof(info));

    // We need to give each client a copy of the protocols or received messages will not get routed properly
    const size_t numProtocols = sizeof(protocols)/sizeof(protocols[0]);
    _protocols = malloc(sizeof(struct libwebsocket_protocols)*numProtocols);
    memcpy(_protocols, protocols, sizeof(struct libwebsocket_protocols)*numProtocols);

    info.user = self;
    info.port = CONTEXT_PORT_NO_LISTEN;
    info.protocols = _protocols;
    info.gid = -1;
    info.uid = -1;
    info.options |= LWS_SERVER_OPTION_SKIP_SERVER_CANONICAL_NAME;

#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
    //-------------------------------------------------------------------
    // libssl.a does not contain any valid certs, use the included one here.
    // These certs were grabbed from Keychain from a mac running 10.10.2
    // on 2015-2-5.
    //-------------------------------------------------------------------
    info.ssl_ca_filepath = [[[NSBundle bundleForClass:[self class]] pathForResource:@"Certificates" ofType:@"pem"] cStringUsingEncoding:NSASCIIStringEncoding];
#endif

    _clientSecureLevel = securityLevel;
    [self _createContextWithInfo:&info];
    if (!self.context)
    {
        RPMLogErr(@"Failure creating websocket contex");
        return NO;
    }

    if (!self.delegateThread)
    {
        self.delegateThread = [NSThread currentThread];
    }

    [NSThread detachNewThreadSelector:@selector(_createClient) toTarget:self withObject:nil];

    return YES;
}

- (BOOL)createServerWithSSL:(BOOL)secure
{
    struct lws_context_creation_info info;

    memset(&info, 0, sizeof(info));

    if (!self.port)
    {
        self.port = LWS_ANY_PORT;
    }

    // We need to give each server a copy of the protocols or received messages will not get routed properly
    const size_t numProtocols = sizeof(protocols)/sizeof(protocols[0]);
    _protocols = malloc(sizeof(struct libwebsocket_protocols)*numProtocols);
    memcpy(_protocols, protocols, sizeof(struct libwebsocket_protocols)*numProtocols);

    info.user = self;
    info.protocols = _protocols;
    info.port = self.port;
    info.gid = -1;
    info.uid = -1;
    info.options |= LWS_SERVER_OPTION_SKIP_SERVER_CANONICAL_NAME;

    if (self.useLoopback)
    {
        struct ifaddrs *ifap;
        struct ifaddrs *ifa;
        struct sockaddr_in *sa;
        getifaddrs(&ifap);
        char *liface = NULL;

        for (ifa=ifap; ifa; ifa = (struct ifaddrs *)ifa->ifa_next)
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-align"
            sa = (struct sockaddr_in *)ifa->ifa_addr;
#pragma clang diagnostic pop

            if (sa->sin_family != AF_INET || ifa->ifa_name == NULL)
            {
                continue;
            }

            if (sa->sin_addr.s_addr == htonl(INADDR_LOOPBACK))
            {
                liface = ifa->ifa_name;
                break;
            }
        }

        info.iface = liface;
    }

#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE) && defined(RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH) && defined(RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH)
    if (secure && [self _setupServerSSLSupport])
    {
        info.ssl_cert_filepath = [RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding];
        info.ssl_private_key_filepath = [RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding];
        _secure = YES;
    }
#endif

    [self _createContextWithInfo:&info];

    if (self.context)
    {
        if (self.port == LWS_ANY_PORT)
        {
            // Grab the port it created.
            self.port = libwebsocket_get_listen_port(self.context);
        }

        self.websocketState = RPMWebSocketStateOpen;
    }
    else
    {
        RPMLogErr(@"Failure creating websocket server context on port %i", self.port);
        return NO;
    }

    if (!self.delegateThread)
    {
        self.delegateThread = [NSThread currentThread];
    }

    [NSThread detachNewThreadSelector:@selector(_createServer) toTarget:self withObject:nil];

    return YES;
}

- (void)invalidate
{
    if ([NSThread currentThread] == self.backgroundThread)
    {
        @synchronized (self)
        {
            if (self.webSocket && self.parentWebSocket.context)
            {
                self.webSocket = NULL;
            }

            if (self.psd)
            {
                self.psd->client = NULL;
            }

            if (self.parentWebSocket == self)
            {
                self.messageQueue = nil;
            }
            else
            {
                [self.messageQueue removeAllObjects];
            }

            self.userInfo = nil;
            _shouldExit = YES;
            _delegate = nil;

            //-------------------------------------------------------------------
            // Only add this to the "remove" array, if it hasn't already been removed.
            //-------------------------------------------------------------------
            if ([self.parentWebSocket.connectedWebSockets containsObject:self])
            {
                [self.parentWebSocket.webSocketsToRemove addObject:self];
            }
        }
    }
    else if (self.backgroundThread)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [_invalidateMessage release];
        _invalidateMessage = nil;
        NSMutableDictionary *invocation = [NSMutableDictionary dictionary];
        [invocation setObject:self forKey:kLWSMessageQueueTargetKey];
        [invocation setObject:NSStringFromSelector(_cmd) forKey:kLWSMessageQueueSelectorKey];
        _invalidateMessage = [invocation copy];
        [pool release];
    }
}

- (void)setWebsocketState:(RPMWebSocketState)state
{
    @synchronized (self)
    {
        if (_websocketState != state)
        {
            _websocketState = state;

            self.isReady = (_websocketState == RPMWebSocketStateOpen) ? YES : NO;

            self.isConnecting = (_websocketState == RPMWebSocketStateConnecting) ? YES : NO;
        }
    }
}

- (void)dealloc
{
    [_fragment release];
    [_host release];
    [_userInfo release];
    [_messageQueue release];
    [_connectedWebSockets release];
    [_webSocketsToRemove release];
    _webSocket = NULL;
    [_pendingBinaryTransfers release];
    [_activeBinaryTransfers release];
    [_invalidateMessage release];
    [super dealloc];
}

- (void)sendMessage:(id)message
{
    NSData *sendData = [message messagePack];
    [self _sendBinaryMessage: sendData];
}

- (void)startDelayedBinaryTransferOfType:(NSUInteger)type length:(unsigned long long)length identifier:(NSObject*)identifier
{
    NSMutableData *header = [self _binaryHeaderWithType:type size:length complete:0x00 identifer:identifier];
    [self _sendBinaryMessage:header];
}

- (void)sendBinaryData:(NSData*)data
                  type:(NSUInteger)type
            identifier:(NSObject*)identifier
                 toUID:(NSString *)uid
{
    NSParameterAssert(identifier);

    if (type == RPM_WEBSOCKET_MSGPACK_TYPE)
    {
        [self _sendBinaryMessage: data];
    }
    else
    {
        if ([NSThread currentThread] != self.delegateThread)
        {
            //-------------------------------------------------------------------
            // Call this method on the delegate thread because queueing is not
            // thread safe.
            //-------------------------------------------------------------------
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setValue:data forKey:@"data"];
            [dictionary setValue:[NSNumber numberWithUnsignedInteger:type] forKey:@"type"];
            [dictionary setValue:identifier forKey:@"identifier"];
            [dictionary setValue:uid forKey:@"uid"];

            [self rpm_performSelector:@selector(_sendBinaryData:)
                             onThread:self.delegateThread
                           withObject:dictionary
                        waitUntilDone:NO];

            return;
        }

        if ([self.activeBinaryTransfers containsObject:identifier])
        {
            [self queueBinaryData:data withIdentifier:identifier ofType:type toUID:uid];
        }
        else
        {
            if (!self.activeBinaryTransfers)
            {
                self.activeBinaryTransfers = [NSMutableArray array];
            }

            [self.activeBinaryTransfers addObject:identifier];

            NSInputStream*  inStream = [NSInputStream inputStreamWithData:data];

            NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         inStream, @"stream",
                                         [NSNumber numberWithUnsignedInteger:[data length]], @"length",
                                         [NSNumber numberWithUnsignedInteger:type], @"type",
                                         identifier, @"identifier",
                                         nil];

            if (uid)
            {
                [args setObject:uid forKey:@"uid"];
            }

            [self _addMessageToQueueWithSelector:@selector(_sendBinaryStreamWithIdentifier:)
                                        argument:args];
        }
    }
}

- (void)_sendBinaryData:(NSDictionary *)binaryFile
{
    NSData *data = [binaryFile objectForKey:@"data"];
    NSUInteger type = [[binaryFile objectForKey:@"type"] unsignedIntegerValue];
    id identifier = [binaryFile objectForKey:@"identifier"];
    NSString *uid = [binaryFile objectForKey:@"uid"];
    [self sendBinaryData:data type:type identifier:identifier toUID:uid];
}

- (void)sendBinaryFile:(NSString*)path type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid
{
    NSParameterAssert(identifier);

    if ([NSThread currentThread] != self.delegateThread)
    {
        //-------------------------------------------------------------------
        // Call this method on the delegate thread because queueing is not
        // thread safe.
        //-------------------------------------------------------------------
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:path forKey:@"path"];
        [dictionary setValue:[NSNumber numberWithUnsignedInteger:type] forKey:@"type"];
        [dictionary setValue:identifier forKey:@"identifier"];
        [dictionary setValue:uid forKey:@"uid"];

        [self rpm_performSelector:@selector(_sendBinaryFile:)
                         onThread:self.delegateThread
                       withObject:dictionary
                    waitUntilDone:NO];

        return;
    }

    NSError*        error = NULL;
    NSInputStream*  inStream = [NSInputStream inputStreamWithFileAtPath:path];
    NSDictionary*   attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];

    if (error)
    {
        RPMLogErr(@"Attempt to get attributes on binary file to send failed:  %@", error);
    }
    else
    {
        if ([self.activeBinaryTransfers containsObject:identifier])
        {
            [self queueBinaryFile:path withIdentifier:identifier ofType:type toUID:uid];
        }
        else
        {
            if (!self.activeBinaryTransfers)
            {
                self.activeBinaryTransfers = [NSMutableArray array];
            }

            [self.activeBinaryTransfers addObject:identifier];

            NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:inStream, @"stream",
                                         [NSNumber numberWithUnsignedLongLong:[attrs fileSize]], @"length",
                                         [NSNumber numberWithUnsignedInteger:type], @"type",
                                         identifier, @"identifier",
                                         nil];

            if (uid)
            {
                [args setObject:uid forKey:@"uid"];
            }

            [self _addMessageToQueueWithSelector:@selector(_sendBinaryStreamWithIdentifier:)
                                        argument:args];
        }
    }
}

- (void)_sendBinaryFile:(NSDictionary *)binaryFile
{
    NSString *path = [binaryFile objectForKey:@"path"];
    NSUInteger type = [[binaryFile objectForKey:@"type"] unsignedIntegerValue];
    id identifier = [binaryFile objectForKey:@"identifier"];
    NSString *uid = [binaryFile objectForKey:@"uid"];
    [self sendBinaryFile:path type:type identifier:identifier toUID:uid];
}

#pragma mark - Private implementation

- (void)_createContextWithInfo:(struct lws_context_creation_info *)contextInfo
{
    NSValue *value = [NSValue valueWithBytes:contextInfo objCType:@encode(struct lws_context_creation_info)];

    [self performSelectorOnMainThread:@selector(_doCreateContextWithInfo:)
                           withObject:value
                        waitUntilDone:YES
                                modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)_doCreateContextWithInfo:(NSValue *)contextInfo
{
    struct lws_context_creation_info info;
    [contextInfo getValue:&info];
    self.context = libwebsocket_create_context(&info);

    if (!self.context)
    {
        [self _deleteServerSSLSupport];
    }
}

- (void)_deleteServerSSLSupport
{
    RPMLogErr(@"Deleting invalid SSL certs");
#if !(TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE) && defined(RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH) && defined(RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH)
    [[NSFileManager defaultManager] removeItemAtPath:RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH error:NULL];
#endif
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//  Verifies, and if necessary generates a self-signed key/certificate pair for SSL operation.  Returns whether the support files are in place and/or have been created.
//  Turned off deprecated to cover the dozen or so Apple openssl warnings.  Using openssl over common crypto since libwebsockets uses it internally and it's linux-friendly.
- (BOOL)_setupServerSSLSupport
{
    FILE*   keyFile = NULL;
    FILE*   certFile = NULL;
#if defined(RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH) && defined(RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH)
    keyFile = fopen([RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding], "r");
    certFile = fopen([RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding], "r");

    if (keyFile != NULL)
    {
        fclose(keyFile);
    }
    else
    {
        RPMLogNotice(@"No private key found.");
    }

    if (certFile != NULL)
    {
        fclose(certFile);
    }
    else
    {
        RPMLogNotice(@"No certificate found.");
    }

    if ((keyFile == NULL) || (certFile == NULL))
    {
        RPMLogNotice(@"Creating self-signed certificate / key pair for SSL server...");

        EVP_PKEY*   privateKey = EVP_PKEY_new();

        if (privateKey)
        {
            RSA*    rsaKey = RSA_generate_key(2048, RSA_F4, NULL, NULL);

            if (rsaKey)
            {
                EVP_PKEY_assign_RSA(privateKey, rsaKey);
                keyFile = fopen([RPMWEBSOCKET_SSL_DEFAULT_KEY_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding], "w");

                if (keyFile)
                {
                    PEM_write_PrivateKey(keyFile, privateKey, NULL, NULL, 0, NULL, NULL);
                    fclose(keyFile);
                }
                else
                {
                    RPMLogErr(@"Cannot write private key file.");
                }

                X509*   x509 = X509_new();

                if (x509)
                {
                    X509_NAME*  subjectName;

                    ASN1_INTEGER_set(X509_get_serialNumber(x509), 1);
                    X509_gmtime_adj(X509_get_notBefore(x509), 0);
                    X509_gmtime_adj(X509_get_notAfter(x509), 999999999L);
                    X509_set_pubkey(x509, privateKey);
                    subjectName = X509_get_subject_name(x509);
                    X509_NAME_add_entry_by_txt(subjectName, "C",  MBSTRING_ASC, (unsigned char *)"US", -1, -1, 0);
                    X509_NAME_add_entry_by_txt(subjectName, "O",  MBSTRING_ASC, (unsigned char *)"Savant Systems, LLC", -1, -1, 0);
                    X509_NAME_add_entry_by_txt(subjectName, "CN", MBSTRING_ASC, (unsigned char *)"localhost", -1, -1, 0);
                    X509_set_issuer_name(x509, subjectName);
                    X509_sign(x509, privateKey, EVP_sha1());

                    certFile = fopen([RPMWEBSOCKET_SSL_DEFAULT_CERT_FILEPATH cStringUsingEncoding:NSUTF8StringEncoding], "w");

                    if (certFile)
                    {
                        PEM_write_X509(certFile, x509 );
                        fclose(certFile);
                    }
                    else
                    {
                        RPMLogErr(@"Cannot write certificate file.");
                    }

                    X509_free(x509);
                }
            }

            EVP_PKEY_free(privateKey);
        }
    }
#endif
    return ((keyFile != NULL) && (certFile != NULL));
}
#pragma clang diagnostic pop

static void rpmLogEmitFunction(int level, const char *line)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    switch (level)
    {
        case LLL_ERR:
            RPMLogErr(@"%s", line);
            break;
        case LLL_WARN:
            RPMLogWarning(@"%s", line);
            break;
        case LLL_NOTICE:
            RPMLogNotice(@"%s", line);
            break;
        case LLL_INFO:
            RPMLogInfo(@"%s", line);
            break;
        case LLL_DEBUG:
            RPMLogDebug(@"%s", line);
            break;
        default:
            RPMLogDebug(@"%s", line);
            break;
    }
    [pool release];
}

- (id)initWithWSI: (struct libwebsocket *)wsi
        webSocket: (RPMWebSocket *)websocket
{
    self = [super init];
    if (self)
    {
        _parentWebSocket = websocket;
        self.webSocket = wsi;
        lws_allow_moving_write_buffer(self.webSocket);
        self.messageQueue = [NSMutableArray array];
        self.backgroundThread = websocket.backgroundThread;
        self.delegateThread = websocket.delegateThread;

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
        int sockopt  = RPMWEBSOCKET_SOCKET_SENDBUFFER_SIZE;
        if(setsockopt(libwebsocket_get_socket_fd(wsi), SOL_SOCKET, SO_SNDBUF, (char *)&sockopt, sizeof(sockopt)) < 0)
        {
            RPMLogErr(@"Socket send buffer size error: %d,%s", errno, strerror(errno));
        }
#endif

        struct sockaddr_in addr;
        socklen_t size = sizeof(addr);

        if (getpeername(libwebsocket_get_socket_fd(wsi), (struct sockaddr *)&addr, &size) == 0)
        {
            self.host = [[[NSString alloc] initWithCString:inet_ntoa(addr.sin_addr) encoding:NSASCIIStringEncoding] autorelease];
            self.port = (int)addr.sin_port;
        }
    }
    return self;
}

- (void)_createClient
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    lws_set_log_level(LLL_ERR | LLL_WARN | LLL_NOTICE, rpmLogEmitFunction);

    self.websocketState = RPMWebSocketStateConnecting;

    self.messageQueue = [NSMutableArray array];

    const char *remoteHost = [self.host cStringUsingEncoding:NSUTF8StringEncoding];
    self.webSocket = libwebsocket_client_connect(self.context, remoteHost, self.port, _clientSecureLevel,
                                                 "/", remoteHost, remoteHost,
                                                 protocols[0].name, -1);

    if (self.webSocket == NULL)
    {
        RPMLogErr(@"Failure connecting to websocket server at address %s:%i", remoteHost, self.port);
        _shouldExit = YES;
    }
    else
    {
        lws_allow_moving_write_buffer(self.webSocket);
    }

    [self _runServiceLoop];

    free(_protocols);
    _protocols = NULL;

    [self _deadWebSocketConnection:self];

    [pool release];
}

- (void)_createServer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    lws_set_log_level(LLL_ERR | LLL_WARN | LLL_NOTICE, rpmLogEmitFunction);

    self.messageQueue = [NSMutableArray array];
    self.connectedWebSockets = [NSMutableArray array];
    self.webSocketsToRemove = [NSMutableArray array];
    _isServer = YES;

    [self _runServiceLoop];

    [pool release];
}

- (void)_sendPingMessage
{
    RPMLogDebug(@"%@ sending ping message", self);

    if (_receivedPong)
    {
        _unackedPings = 0;
        _receivedPong = NO;
    }
    else
    {
        RPMLogInfo(@"%@ missed pong message", self);
        _unackedPings++;

        if (_unackedPings >= RPM_WEBSOCKET_MAXUNACKEDPINGS)
        {
            RPMLogErr(@"%@ missed too many pong messages, closing web socket", self);
            _shouldExit = YES;
            return;
        }
    }

    [self _writePingMessage];
}

- (void)_writePingMessage
{
    unsigned char *buff = malloc(LWS_SEND_BUFFER_PRE_PADDING + 1 + LWS_SEND_BUFFER_POST_PADDING);
    unsigned char *p = &buff[LWS_SEND_BUFFER_PRE_PADDING];
    memset(p, 0, 1);

    int retVal = [self _writeBuffer:p length:1 writeProtocol:LWS_WRITE_PING];

    if (retVal)
    {
        RPMLogErr(@"%@ could not write to websocket ping: %d", self, retVal);
    }

    free(buff);
}

- (void)_sendPongMessage
{
    RPMLogDebug(@"%@ sending pong message", self);

    [self _addMessageToQueueWithSelector:@selector(_writePongMessage) argument:nil];
}

- (void)_writePongMessage
{
    unsigned char *buff = malloc(LWS_SEND_BUFFER_PRE_PADDING + 1 + LWS_SEND_BUFFER_POST_PADDING);
    unsigned char *p = &buff[LWS_SEND_BUFFER_PRE_PADDING];
    memset(p, 0, 1);

    int retVal = [self _writeBuffer:p length:1 writeProtocol:LWS_WRITE_PONG];

    if (retVal)
    {
        RPMLogErr(@"%@ could not write to websocket pong: %d", self, retVal);
    }

    free(buff);
}

- (void)_processMessage: (NSData*)data
{
    id message = nil;

    BOOL textOrMsgPack = NO;

    if (lws_frame_is_binary(self.webSocket))
    {
        NSUInteger type = RPM_WEBSOCKET_MSGPACK_TYPE_CHECK([data getByte:0x00]) ? RPM_WEBSOCKET_MSGPACK_TYPE : [data getByte:0x00];

        switch (type) {
            case RPM_WEBSOCKET_MSGPACK_TYPE:
            {
                message = [MessagePackParser parseData:data];
                textOrMsgPack = YES;
                RPMLogDebug(@"<< %@",message);
                break;
            }
            case RPM_WEBSOCKET_FILEUPLOAD_TYPE:
            case RPM_WEBSOCKET_SECURITYCAM_TYPE:
            case RPM_WEBSOCKET_SAVANTCAM_TYPE:
            case RPM_WEBSOCKET_USERINTERFACE_TYPE:
            case RPM_WEBSOCKET_MEDIADATABASEUPLOAD_TYPE:
            {
                message = [self _processBinaryMessage:data];
                break;
            }
            default:
                RPMLogErr(@"Received message of unexpected binary type: %02lx",(unsigned long)type);
                break;
        }

        if (!textOrMsgPack)
        {
            RPMLogDebug(@"Received binary message: %@", message);
        }
    }

    if (message)
    {
        if (textOrMsgPack)
        {
            RPMLogDebug(@"Received message: %@", message);
            [self rpm_performSelector:@selector(_receivedMessage:)
                             onThread:self.delegateThread
                           withObject:message waitUntilDone:NO];
        }
        else
        {
            [self rpm_performSelector:@selector(_receivedBinaryMessage:)
                             onThread:self.delegateThread
                           withObject:message waitUntilDone:NO];
        }
    }
}

- (NSDictionary*)_processBinaryMessage:(NSData*)msg
{
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    uint64_t            beSize;
    int32_t             beSessionLen;
    NSInteger           versionAndCompletion;

    [message setObject:[NSNumber numberWithUnsignedInteger:[msg getByte:0x00]] forKey:@"type"];

    [msg getBytes:&beSize range:NSMakeRange(2, 8)];
    [message setObject:[NSNumber numberWithUnsignedLongLong:be64toh(beSize)] forKey:@"length"];

    versionAndCompletion = [msg getByte:kBinaryCompletionHeaderOffset];
    [message setObject:[NSNumber numberWithBool:versionAndCompletion & 0x80] forKey:@"complete"];
    [message setObject:[NSNumber numberWithInt:versionAndCompletion & 0x7F] forKey:@"version"];

    [msg getBytes:&beSessionLen range:NSMakeRange(10, 4)];
    NSObject *identifier = nil;

    // it's msgpack
    if (RPM_WEBSOCKET_MSGPACK_TYPE_CHECK([msg getByte:14]))
    {
        identifier = [[msg subdataWithRange:NSMakeRange(14, be32toh(beSessionLen))] messagePackParse];
    }
    else
    {
        identifier = [[[NSString alloc] initWithData:[msg subdataWithRange:NSMakeRange(14, be32toh(beSessionLen))] encoding:NSUTF8StringEncoding] autorelease];
    }

    [message setValue:identifier forKey:@"session"];

    [message setObject:[msg subdataWithRange:NSMakeRange(14 + be32toh(beSessionLen), [msg length] - be32toh(beSessionLen) - 14)] forKey:@"data"];

    return [message autorelease];
}

- (void)_receivedMessage: (id)message
{
    if ([self.delegate respondsToSelector: @selector(onMessage:from:)])
    {
        [self.delegate onMessage:message
                            from:self];
    }
}

- (void)_receivedBinaryMessage: (id)message
{
    if ([self.delegate respondsToSelector: @selector(onBinary:from:)])
    {
        [self.delegate onBinary:message
                           from:self];
    }
}

- (void)_finishBinaryTransfer: (NSDictionary *)dict
{
    NSString *uid = [dict objectForKey:@"uid"];
    NSObject *identifier = [dict objectForKey:@"identifier"];

    if (uid && identifier)
    {
        if ([self.delegate respondsToSelector: @selector(onBinaryTransferDidCompleteWithUID:identifier:from:)])
        {
            [self.delegate onBinaryTransferDidCompleteWithUID:uid
                                                   identifier:identifier
                                                         from:self];
        }
    }

    [self sendNextBinaryTransferWithIdentifier:identifier];
}

- (void)_newWebSocketConnection: (RPMWebSocket*)websocket
{
    if (websocket != self)
    {
        [self.connectedWebSockets addObject:websocket];
    }

    if ([self.delegate respondsToSelector: @selector(onWebSocketConnect:)])
    {
        [self.delegate rpm_performSelector: @selector(onWebSocketConnect:)
                                  onThread: self.delegateThread
                                withObject: websocket
                             waitUntilDone: NO];
    }
}

- (void)_deadWebSocketConnection: (RPMWebSocket*)websocket
{
    [websocket retain];

    if ([self.delegate respondsToSelector: @selector(onWebSocketDisconnect:)])
    {
        [self.delegate rpm_performSelector: @selector(onWebSocketDisconnect:)
                                  onThread: self.delegateThread
                                withObject: websocket
                             waitUntilDone: YES];
    }

    [websocket.messageQueue removeAllObjects];
    websocket.webSocket = NULL;

    if (websocket && websocket != self)
    {
        [self.connectedWebSockets removeObject:websocket];
    }

    [websocket invalidate];
    [websocket release];
}

- (void)_sendBinaryMessage:(NSData*)payload
{
    [self _addMessageToQueueWithSelector:@selector(_writeMessage:)
                                argument:[NSDictionary dictionaryWithObjectsAndKeys:payload,kLWSMessageDataKey,[NSNumber numberWithInt:LWS_WRITE_BINARY],kLWSMessageProtocolKey,nil]];
}

- (void)_writeMessage:(NSDictionary*)payload
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSData          *data       = [payload objectForKey:kLWSMessageDataKey];
    NSInputStream   *dataStream = [payload objectForKey:kLWSMessageStreamKey];
    enum libwebsocket_write_protocol writeProtocol = (enum libwebsocket_write_protocol)[[payload objectForKey:kLWSMessageProtocolKey] intValue];

    if (data)
    {
        dataStream = [NSInputStream inputStreamWithData:data];
        [dataStream open];
    }

    if (dataStream)
    {
        UInt8 dataBuffer[kLWSBufferSize];
        NSInteger bytesRead = [dataStream read:dataBuffer maxLength:kLWSBufferSize];

        // this is fragment continuing the previous message
        if (!data)
        {
            writeProtocol = LWS_WRITE_CONTINUATION;
        }

        // this is not the last fragment
        if ([dataStream hasBytesAvailable])
        {
            writeProtocol |= LWS_WRITE_NO_FIN;
        }

        if (bytesRead > 0)
        {
            unsigned char *buff = malloc(LWS_SEND_BUFFER_PRE_PADDING + (unsigned long)bytesRead + LWS_SEND_BUFFER_POST_PADDING);
            unsigned char *p = &buff[LWS_SEND_BUFFER_PRE_PADDING];
            memcpy(p, dataBuffer, (size_t)bytesRead);

            int retVal = [self _writeBuffer:p length:(size_t)bytesRead writeProtocol:writeProtocol];

            if (retVal)
            {
                RPMLogErr(@"%@ could not write to websocket: %d (%ld)", self, retVal, (long)bytesRead);
                [dataStream close];
                return;
            }

            free(buff);
        }

        if ([dataStream hasBytesAvailable])
        {
            [self _addMessageToQueueHeadWithSelector:@selector(_writeMessage:)
                                            argument:[NSDictionary dictionaryWithObject:dataStream forKey:kLWSMessageStreamKey]];
        }
        else
        {
            [dataStream close];
        }
    }
    else
    {
        RPMLogErr(@"No data provided to write message! %@", payload);
    }

    [pool release];
}

- (void)_writeBinaryMessage:(NSData*)payload
{
    const char *bytes = [payload bytes];
    unsigned char *buff = malloc(LWS_SEND_BUFFER_PRE_PADDING + [payload length] + LWS_SEND_BUFFER_POST_PADDING);
    unsigned char *p = &buff[LWS_SEND_BUFFER_PRE_PADDING];
    memcpy(p, bytes, [payload length]);

    int retVal = [self _writeBuffer:p length:[payload length] writeProtocol:LWS_WRITE_BINARY];

    if (retVal)
    {
        if (errno == EWOULDBLOCK)
        {
            RPMLogInfo(@"Websocket would block, queueing");
            [self _addMessageToQueueHeadWithSelector:_cmd argument:payload];
        }
        else
        {
            RPMLogErr(@"%@ could not write to websocket binary: %d (%lu)", self, retVal, (unsigned long)[payload length]);
        }
    }
    else
    {
        [self _receivedPongMessage];
    }

    free(buff);
}

- (void)_sendTextMessage:(NSString*)message
{
    [self _addMessageToQueueWithSelector:@selector(_writeMessage:)
                                argument:[NSDictionary dictionaryWithObjectsAndKeys:[message dataUsingEncoding:NSUTF8StringEncoding],kLWSMessageDataKey,[NSNumber numberWithInt:LWS_WRITE_TEXT],kLWSMessageProtocolKey,nil]];
}

- (void)_receivedPongMessage
{
    _receivedPong = YES;
}

- (void)_destroyContext
{
    if ([NSThread isMainThread])
    {
        @synchronized (self)
        {
            if (self.context)
            {
                libwebsocket_context_destroy(self.context);
                self.context = NULL;
            }

            self.webSocket = NULL;
        }
    }
    else
    {
        [self performSelectorOnMainThread:_cmd
                               withObject:nil
                            waitUntilDone:YES
                                    modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

- (NSMutableData*)_binaryHeaderWithType:(NSUInteger)type size:(uint64_t)size complete:(BOOL)complete identifer:(NSObject*)identifier
{
    NSMutableData *header = [NSMutableData data];

    [header appendByte:(unsigned char)type]; // 1 byte, security camera type

    int version = 0x1; // 0x7F (bits 6-0)
    int completeShift = (complete ? 0x1 : 0x0) << 7;  // 0x80 (bit 7)
    int versionAndCompletion = (version + completeShift);

    [header appendByte:(unsigned char)versionAndCompletion]; // 1 byte, in-complete marker

    uint64_t  beSize = htobe64(size);
    [header appendBytes:&beSize length:8]; // 8 bytes, data size swapped to network BE endian format

    NSData *session = nil;

    if ([identifier isKindOfClass:[NSDictionary class]])
    {
        session = [(NSDictionary*)identifier messagePack];
    }
    else if ([identifier isKindOfClass:[NSString class]])
    {
        identifier = identifier ? identifier : @"";
        session = [(NSString*)identifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([identifier respondsToSelector:@selector(stringValue)])
    {
        identifier = [(id)identifier stringValue];
        session = [(NSString*)identifier dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        RPMLogErr(@"Unexpected identifier: %@",identifier);
    }

    UInt32  beSessionLen = htobe32(session.length);
    [header appendBytes:&beSessionLen length:4]; // 4 bytes, session length swapped to network BE endian format
    [header appendData:session]; // session id (variable length)

    return header;
}

- (void)_sendBinaryStreamSegmentWithIdentifier:(NSDictionary*)dict
{
    const size_t    kTargetMTUSize = 1500;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSInputStream   *dataStream = [dict objectForKey:@"stream"];
    NSUInteger      type = [[dict objectForKey:@"type"] unsignedIntegerValue];
    NSObject        *identifier = [dict objectForKey:@"identifier"];
    uint64_t          length = [[dict objectForKey:@"length"] unsignedLongLongValue];
    NSMutableData   *header = [self _binaryHeaderWithType:type size:length complete:0x00 identifer:identifier];
    NSUInteger      dataLength = kTargetMTUSize - header.length; // (starts after header, max packet length of MTU bytes)
    uint8_t dataBuffer[kTargetMTUSize];
    NSInteger bytesRead = [dataStream read:dataBuffer maxLength:dataLength];

    NSMutableData   *sendData = [NSMutableData dataWithData:header];

    if (![dataStream hasBytesAvailable])
    {
        int completionAndVersion;

        [sendData getBytes:&completionAndVersion range:NSMakeRange(1, 1)];

        int version = completionAndVersion & 0x7F;
        unsigned char complete = 0x80 + version;

        [sendData replaceBytesInRange:NSMakeRange(kBinaryCompletionHeaderOffset, 1) withBytes:&complete length:sizeof(complete)]; // complete marker

        NSString *uid = [dict objectForKey:@"uid"];

        if (uid)
        {
            [self rpm_performSelector:@selector(_finishBinaryTransfer:)
                             onThread:self.delegateThread
                           withObject:[NSDictionary dictionaryWithObjectsAndKeys:uid, @"uid", identifier, @"identifier", nil]
                        waitUntilDone:NO];
        }
        else
        {
            //-------------------------------------------------------------------
            // Call this with just the identifier so that the binary transfer
            // queue can proceed correctly. The delegate won't be called though
            // which is fine for now.
            //-------------------------------------------------------------------
            [self rpm_performSelector:@selector(_finishBinaryTransfer:)
                             onThread:self.delegateThread
                           withObject:[NSDictionary dictionaryWithObject:identifier forKey:@"identifier"]
                        waitUntilDone:NO];
        }
    }

    if (bytesRead > 0)
    {
        [sendData appendBytes:dataBuffer length:(NSUInteger)bytesRead];
    }

    [self _writeBinaryMessage:sendData];

    if ([dataStream hasBytesAvailable])
    {
        [self _addMessageToQueueWithSelector:@selector(_sendBinaryStreamSegmentWithIdentifier:) argument:dict];
    }
    else
    {
        [dataStream close];
    }

    [pool release];
}

- (void)_sendBinaryStreamWithIdentifier:(NSDictionary*)dict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSInputStream   *dataStream = [dict objectForKey:@"stream"];

    [dataStream open];

    [self _sendBinaryStreamSegmentWithIdentifier:dict];

    [pool release];
}

- (void)_addMessageToQueueWithSelector:(SEL)selector argument:(id)argument
{
    [self _addMessageToQueueWithSelector:selector argument:argument atIndex:-1];
}

- (void)_addMessageToQueueHeadWithSelector:(SEL)selector argument:(id)argument
{
    [self _addMessageToQueueWithSelector:selector argument:argument atIndex:0];
}

- (void)_addMessageToQueueWithSelector:(SEL)selector argument:(id)argument atIndex:(NSInteger)idx
{
    if (selector && (self.webSocket || _isServer))
    {
        NSMutableDictionary *invocation = [[NSMutableDictionary alloc] init];

        //-------------------------------------------------------------------
        // Saving self into a dictionary is normally bad, but when invalidate
        // is called before release it will clear the _messageQueue, so this
        // is fine.
        //-------------------------------------------------------------------
        [invocation setObject:self forKey:kLWSMessageQueueTargetKey];

        [invocation setObject:NSStringFromSelector(selector) forKey:kLWSMessageQueueSelectorKey];

        if (argument)
        {
            [invocation setObject:argument forKey:kLWSMessageQueueArgumentKey];
        }

        @synchronized (self)
        {
            if (idx >= 0)
            {
                [self.messageQueue insertObject:invocation atIndex:(NSUInteger)idx];
            }
            else
            {
                [self.messageQueue addObject:invocation];
            }
        }

        [invocation release];
    }
}

- (void)_serviceMessageQueue
{
    @synchronized (self)
    {
        if ((self.isWritable || _isServer) && [self.messageQueue count])
        {
            NSDictionary *invocation = [[self.messageQueue objectAtIndex:0] retain];
            [self.messageQueue removeObjectAtIndex:0];
            [self _invokeInvocation:invocation];
            [invocation release];
        }
        
        if (_invalidateMessage)
        {
            [self _invokeInvocation:_invalidateMessage];
            [_invalidateMessage release];
            _invalidateMessage = nil;
        }
    }
}

- (void)_invokeInvocation:(NSDictionary *)invocation
{
    id target = [invocation objectForKey:kLWSMessageQueueTargetKey];
    SEL selector = NSSelectorFromString([invocation objectForKey:kLWSMessageQueueSelectorKey]);
    id object = [invocation objectForKey:kLWSMessageQueueArgumentKey];
    [target performSelector:selector withObject:object];
}

- (void)_scheduleAPing
{
    //-------------------------------------------------------------------
    // Don't schedule a ping if one is already scheduled. If we do, pings
    // might get backed up and a few could be sent in much quicker
    // intervals than desired.
    //-------------------------------------------------------------------
    @synchronized (self)
    {
        BOOL foundAScheduledPing = NO;

        for (NSDictionary *invocation in self.messageQueue)
        {
            SEL selector = NSSelectorFromString([invocation objectForKey:kLWSMessageQueueSelectorKey]);

            if (selector == @selector(_sendPingMessage))
            {
                foundAScheduledPing = YES;
                break;
            }
        }

        if (foundAScheduledPing)
        {
            RPMLogDebug(@"%@ not scheduling a ping, one is already scheduled", self);
        }
        else
        {
            [self _addMessageToQueueWithSelector:@selector(_sendPingMessage) argument:nil];
        }
    }
}

- (void)_runServiceLoop
{
    self.backgroundThread = [NSThread currentThread];
    [self.backgroundThread setName:@"RPMWebSocket"];

    self.parentWebSocket = self;

    while (!_shouldExit)
    {
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];

        int result = libwebsocket_service(self.context, kLWSDefaultServiceTime);

        if (result < 0)
        {
            switch (errno)
            {
                case EAGAIN:
                case EINTR:
                    //-------------------------------------------------------------------
                    // Probably fine, try again.
                    //-------------------------------------------------------------------
                    break;
                case EFAULT:
                    _shouldExit = YES;
                    RPMLogCrit(@"WebSocket %@: could not service its fd.", self);
                    break;
                case EINVAL:
                    _shouldExit = YES;
                    RPMLogCrit(@"WebSocket %@: invalid poll arguments", self);
                    break;
            }
        }
        else if (!_shouldExit)
        {
            //-------------------------------------------------------------------
            // _webSocket being set signifies that this is a client service loop
            // and clients need to send pings. We can't use an NSTimer because
            // the runloop is not serviced. Instead of managing a dedicated
            // thread just for a timer, use this method.
            //-------------------------------------------------------------------
            if (self.webSocket)
            {
                NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

                //-------------------------------------------------------------------
                // Schedule a ping if we never have before or if the last time we did
                // was >= RPM_WEBSOCKET_CLIENTPINGPERIOD seconds ago.
                //-------------------------------------------------------------------
                if (!_lastPingTime || ((currentTime - _lastPingTime) >= RPM_WEBSOCKET_CLIENTPINGPERIOD))
                {
                    _lastPingTime = currentTime;
                    [self _scheduleAPing];
                }

                [RPMWebSocket _registerForWebSocketForWritability:self];
                [self _serviceMessageQueue];
            }
            else
            {
                for (RPMWebSocket *webSocket in self.connectedWebSockets)
                {
                    [RPMWebSocket _registerForWebSocketForWritability:webSocket];
                    [webSocket _serviceMessageQueue];
                }

                if ([self.messageQueue count])
                {
                    [self _serviceMessageQueue];
                }
                
                if (_invalidateMessage)
                {
                    [self _invokeInvocation:_invalidateMessage];
                    [_invalidateMessage release];
                    _invalidateMessage = nil;
                }

                //-------------------------------------------------------------------
                // Remove any websockets that were invalidated.
                //-------------------------------------------------------------------
                if ([self.webSocketsToRemove count])
                {
                    [self.connectedWebSockets removeObjectsInArray:self.webSocketsToRemove];
                    [self.webSocketsToRemove removeAllObjects];
                }
            }
        }

        [innerPool release];
    }
    
    if (_invalidateMessage)
    {
        [self _invokeInvocation:_invalidateMessage];
        [_invalidateMessage release];
        _invalidateMessage = nil;
    }

    self.backgroundThread = nil;

    [self _destroyContext];

    free(_protocols);
    _protocols = NULL;
}

+ (void)_registerForWebSocketForWritability:(RPMWebSocket *)webSocket
{
    if (webSocket.webSocket && webSocket.isReady && !webSocket.isRegisteredForWritability)
    {
        libwebsocket_callback_on_writable(webSocket.parentWebSocket.context, webSocket.webSocket);
        webSocket.isRegisteredForWritability = YES;
    }
}

- (int)_writeBuffer:(unsigned char *)buffer length:(size_t)length writeProtocol:(enum libwebsocket_write_protocol)protocol
{
    int success = libwebsocket_write(self.webSocket, buffer, length, protocol);

    if (success && errno != EWOULDBLOCK)
    {
        if (++self.consecutiveWriteFailures >= kLWSMaxConsecutiveWriteFailures)
        {
            [self rpm_performSelector:@selector(_criticalWriteFailure) onThread:self.delegateThread withObject:nil waitUntilDone:NO];
        }
    }
    else
    {
        self.consecutiveWriteFailures = 0;
    }

    self.isWritable = NO;
    self.isRegisteredForWritability = NO;

    return success;
}

- (void)_criticalWriteFailure
{
    if ([self.delegate respondsToSelector:@selector(onCriticalWriteFailureFrom:)])
    {
        [self.delegate onCriticalWriteFailureFrom:self];
    }
}

- (void)rpm_performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait
{
#ifdef GNUSTEP
    [self performSelector:aSelector onThread:thr withObject:arg waitUntilDone:wait modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
#else
    [self performSelector:aSelector onThread:thr withObject:arg waitUntilDone:wait];
#endif
}

#pragma mark - Binary Queueing

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
- (void)queueBinaryFile:(NSString *)path withIdentifier:(id)identifier ofType:(NSUInteger)type toUID:(NSString *)uid
{
    NSMutableDictionary *transfer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSNumber numberWithUnsignedInteger:type], @"type", nil];

    if (uid)
    {
        [transfer setObject:uid forKey:@"uid"];
    }

    [self queueBinaryTransfer:transfer withIdentifier:identifier];
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
- (void)queueBinaryData:(NSData *)data withIdentifier:(id)identifier ofType:(NSUInteger)type toUID:(NSString *)uid
{
    NSMutableDictionary *transfer = [NSMutableDictionary dictionaryWithObjectsAndKeys:data, @"data", [NSNumber numberWithUnsignedInteger:type], @"type", nil];

    if (uid)
    {
        [transfer setObject:uid forKey:@"uid"];
    }

    [self queueBinaryTransfer:transfer withIdentifier:identifier];
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
- (void)queueBinaryTransfer:(NSDictionary *)transfer withIdentifier:(id)identifier
{
    NSParameterAssert(identifier);

    if (!self.pendingBinaryTransfers)
    {
        self.pendingBinaryTransfers = [NSMutableDictionary dictionary];
    }

    NSMutableArray *transfers = [self.pendingBinaryTransfers objectForKey:identifier];

    if (!transfers)
    {
        transfers = [NSMutableArray array];
        [self.pendingBinaryTransfers setObject:transfers forKey:identifier];
    }

    [transfers addObject:transfer];
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
- (void)sendNextBinaryTransferWithIdentifier:(id)identifier
{
    NSParameterAssert(identifier);

    NSMutableArray *transfers = [self.pendingBinaryTransfers objectForKey:identifier];

    [self.activeBinaryTransfers removeObject:identifier];

    if ([transfers count])
    {
        NSDictionary *transfer = [transfers objectAtIndex:0];

        NSUInteger type = [[transfer objectForKey:@"type"] unsignedIntegerValue];
        NSString *path = [transfer objectForKey:@"path"];
        NSData *data = [transfer objectForKey:@"data"];
        NSString *uid = [transfer objectForKey:@"uid"];
        
        if (path)
        {
            [self sendBinaryFile:path type:type identifier:identifier toUID:uid];
        }
        else
        {
            [self sendBinaryData:data type:type identifier:identifier toUID:uid];
        }
        
        [transfers removeObjectAtIndex:0];
        
        if (![transfers count])
        {
            [self.pendingBinaryTransfers removeObjectForKey:identifier];
        }
        
        if (![self.pendingBinaryTransfers count])
        {
            self.pendingBinaryTransfers = nil;
        }
    }
    else
    {
        if (![self.activeBinaryTransfers count])
        {
            self.activeBinaryTransfers = nil;
        }
    }
}

@end

//##OBJCLEAN_ENDSKIP##
