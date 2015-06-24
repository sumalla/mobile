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
#import "RPMWebSocket.h"
#import "RPMDiscoveryServer.h"
#ifndef GNUSTEP
#import "RPMDiscoveryScanner.h"
#endif

#import "RPMCommunicationConstants.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMAsyncConnection : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    // Server only
    NSMutableArray          *_connectedClients;
    RPMDiscoveryServer      *_savantService;
    NSTimer                 *_publishRetryTimer;
    BOOL                    _cloudEnabled;
    
    // Client only
    NSString                *_host;
    NSNetServiceBrowser     *_bonjourBrowser;
#ifndef GNUSTEP
    RPMDiscoveryScanner     *_savantBrowser;
#endif
    NSTimer                 *_clientConnectRetry;
    NSTimer                 *_clientConnectTimeout;
    
    // Shared
    RPMWebSocket            *_localSocket;
    NSString                *_serviceName;     // Optional
    NSString                *_serviceType;     // Optional
    NSString                *_systemName;      // Optional
    NSString                *_systemUID;       // Optional
    NSNetService            *_bonjourService;
    id                      _delegate;
    NSThread                *_delegateThread;
    int                     _port;
    BOOL                    _useDiscoveryServer;
    BOOL                    _isServer;
    RPMWebSocketClientSSL   _securityLevel;
    BOOL                    _useLoopback;
    NSTimeInterval          _connectionAttemptTimeout;
    
    id                      _userInfo;
    RPMAsyncConnection      *_parent;
}
#pragma clang diagnostic pop

@property (nonatomic,assign) BOOL useDiscoveryServer;
@property (readonly) RPMWebSocketClientSSL securityLevel;
@property (nonatomic,assign) id delegate;
@property (nonatomic,assign) NSThread* delegateThread;
@property (nonatomic,assign) int port;
@property (readonly, retain) NSString *host;
@property (nonatomic, assign) BOOL useLoopback; // Force server to only bind to loopback interface
@property (readonly, atomic) BOOL isReady;
@property (readonly, atomic) RPMWebSocketState websocketState;
@property (readonly, atomic) BOOL isValid; // Returns YES if the socket is connected, or connecting.
@property (readonly) BOOL isServer;
@property (readonly, copy) NSMutableArray* connectedClients;
@property (readwrite, assign) NSTimeInterval connectionAttemptTimeout; // defaults to 5.0
@property (readwrite, retain) id userInfo;
@property (readonly, assign) RPMAsyncConnection *parent;
@property (nonatomic,assign) BOOL cloudEnabled;

- (id)initClientWithServiceName:(NSString *)serviceName
                           type:(NSString *)serviceType
                     systemName:(NSString *)systemName
                       delegate:(id)delegate;

- (id)initClientWithHost:(NSString *)host
                    port:(int)port
                  secure:(RPMWebSocketClientSSL)securityLevel
                delegate:(id)delegate;

- (id)initServerWithServiceName:(NSString *)serviceName
                           type:(NSString *)serviceType
                     systemName:(NSString *)systemName
                         secure:(BOOL)secure
                       delegate:(id)delegate;

- (id)initServerWithSystemName:(NSString *)systemName
                      uniqueID:(NSString *)uid
                        secure:(BOOL)secure
                      delegate:(id)delegate;

- (id)initServerWithPort:(int)port
                  secure:(BOOL)secure
                delegate:(id)delegate;

- (void)startConnection;
- (void)invalidate;

- (void)sendMessage:(id)message;
- (void)startDelayedBinaryTransferOfType:(NSUInteger)type length:(unsigned long long)length identifier:(NSObject*)identifier;
- (void)sendBinaryData:(NSData*)data type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid;
- (void)sendBinaryFile:(NSString*)path type:(NSUInteger)type identifier:(NSObject*)identifier toUID:(NSString *)uid;

- (void)setInterfaceExtractionProgress:(NSNumber *)progress;
- (void)updateCloudProperties;

@end

@protocol RPMAsyncConnectionDelegate <NSObject>

@optional
- (void)onAsyncConnect:(RPMAsyncConnection *)connection;

- (void)onAsyncDisconnect:(RPMAsyncConnection *)connection;

- (void)onMessage:(id)message
        fromAsync:(RPMAsyncConnection*)connection;

- (void)onBinary:(id)message
       fromAsync:(RPMAsyncConnection *)connection;

- (BOOL)onAsyncConnectionAttemptTimeout:(RPMAsyncConnection *)connection; // Returning YES will continue attempts, NO will stop the connection attempt.

- (void)onBinaryTransferDidCompleteWithUID:(NSString *)uid
                                identifier:(id)identifier
                                 fromAsync:(RPMAsyncConnection *)websocket;

- (void)onCriticalWriteFailureFromAsync:(RPMAsyncConnection *)connection;
@end

//##OBJCLEAN_ENDSKIP##
