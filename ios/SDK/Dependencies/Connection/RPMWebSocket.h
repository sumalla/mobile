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

@import Foundation;
#import "libwebsockets.h"
#import "RPMWebSocketFragment.h"

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/JSON.h>
#endif

#import "RPMCommunicationConstants.h"


#define RPMWEBSOCKET_SOCKET_SENDBUFFER_SIZE (256*1024)

typedef enum
{
    RPMWebSocketStateConnecting   = 0, //The connection has not yet been established.
    RPMWebSocketStateOpen         = 1, //The WebSocket connection is established and communication is possible.
    RPMWebSocketStateClosing      = 2, //The connection is going through the closing handshake.
    RPMWebSocketStateClosed       = 3  //The connection has been closed or could not be opened
} RPMWebSocketState;

struct per_session_data__rpm_protocol;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMWebSocket : NSObject
{
    struct libwebsocket*    _webSocket;
    struct libwebsocket_context* _context;
    BOOL                    _isServer;
    id                      _delegate;
    NSString*               _host;
    int                     _port;
    RPMWebSocketState       _websocketState;
    BOOL                    _readyState;
    BOOL                    _secure;
    BOOL                    _shouldExit;
    BOOL                    _isConnecting;
    RPMWebSocketFragment*   _fragment;
    NSThread*               _delegateThread;
    NSThread*               _backgroundThread;
    NSTimeInterval          _lastPingTime;
    BOOL                    _isRegisteredForWritability;
    BOOL                    _isWritable;
    NSMutableArray*         _messageQueue;
    RPMWebSocket*           _parentWebSocket; // _parentWebSocket is == to self in all cases except for incoming
                                              // websockets created by a server websocket. This ivar is used to
                                              // help with the messageQueue.
    NSMutableArray*         _connectedWebSockets;
    NSMutableArray*         _webSocketsToRemove;
    id                      _userInfo;
    int                     _unackedPings;
    BOOL                    _receivedPong;
    BOOL                    _useLoopback;
    RPMWebSocketClientSSL   _clientSecureLevel;
    struct libwebsocket_protocols *_protocols;
    int                     _consecutiveWriteFailures;

    NSMutableDictionary     *_pendingBinaryTransfers;
    NSMutableArray          *_activeBinaryTransfers;
    NSDictionary            *_invalidateMessage;

    struct per_session_data__rpm_protocol *_psd;
}
#pragma clang diagnostic pop

@property(readwrite,assign) id delegate;
@property(readwrite,assign) NSThread* delegateThread;
@property(nonatomic,assign) int port;
@property(nonatomic,retain) NSString* host;
@property(nonatomic,readonly) BOOL secure;
@property(nonatomic,assign) BOOL isReady;
@property(nonatomic,assign) RPMWebSocketState websocketState;
@property(nonatomic,assign) BOOL isConnecting;
@property(nonatomic,assign) BOOL useLoopback;
@property(nonatomic,retain) id userInfo;
@property(nonatomic,retain) RPMWebSocketFragment* fragment;
@property(readwrite, assign) struct libwebsocket *webSocket;
@property(readonly, assign) int consecutiveWriteFailures;

- (BOOL)createClientWithSSL:(RPMWebSocketClientSSL)securityLevel;
- (BOOL)createServerWithSSL:(BOOL)secure;
- (void)invalidate;
- (void)sendMessage:(id)message;
- (void)startDelayedBinaryTransferOfType:(NSUInteger)type length:(unsigned long long)length identifier:(NSObject*)identifier;
- (void)sendBinaryData:(NSData*)data type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid;
- (void)sendBinaryFile:(NSString*)path type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid;

@end

@protocol RPMWebSocketDelegateProtocol <NSObject>

- (void)onWebSocketConnect: (RPMWebSocket*)webSocket;
- (void)onWebSocketDisconnect: (RPMWebSocket*)webSocket;
- (void)onMessage: (id)message
             from: (RPMWebSocket*)websocket;
@optional
- (void)onBinary: (id)message
            from: (RPMWebSocket*)websocket;

- (void)onBinaryTransferDidCompleteWithUID: (NSString*)uid
                                identifier: (NSObject *)identifier
                                      from: (RPMWebSocket *)websocket;
- (void)onCriticalWriteFailureFrom: (RPMWebSocket *)websocket;
@end

//##OBJCLEAN_ENDSKIP##
