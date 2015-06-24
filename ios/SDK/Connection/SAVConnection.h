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

@import Foundation;
#import "SAVMessages.h"
#import "SavantPrivateProtocols.h"
#import "CBPPromise.h"
#import "RPMCommunicationConstants.h"

@class SAVConnection;

typedef NS_ENUM(NSUInteger, SAVAuthenticationErrorCode)
{
    SAVAuthenticationErrorCodeInvalidPassword = 1,
    SAVAuthenticationErrorCodeInvalidToken = 2,
    SAVAuthenticationErrorCodeInvalidUser = 3
};

@interface SAVConnection : NSObject

@property (weak) id <ConnectionStatusDelegate> statusDelegate;
@property (weak) id <ConnectionStateUpdateDelegate> stateDelegate;
@property (weak) id <ConnectionDISDelegate> disDelegate;
@property (weak) id <ConnectionMessageDelegate> messageDelegate;

@property (readonly) NSString *URI;
@property NSString *configurationGUID;
@property (nonatomic, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, readonly, getter = isUpdateAvailable) BOOL updateAvailable;
@property (nonatomic, readonly, getter = isAuthenticationNeeded) BOOL authenticationNeeded;
@property (nonatomic, readonly, getter = isRemote) BOOL remote;
@property (readonly) NSString *hostID;
@property (readonly) NSString *homeID;
@property (readonly) NSString *hostName;
@property (nonatomic, readonly, copy) NSArray *availableUsers;
@property (readonly) NSString *address;
@property (readonly) NSNumber *port;
@property (readonly) NSString *scheme;

- (instancetype)initWithURL:(NSURL *)url system:(SAVSystem *)system securityLevel:(RPMWebSocketClientSSL)securityLevel;

- (void)connect;

- (void)disconnect;

- (void)attemptAuthenticationWithUser:(NSString *)user andPassword:(NSString *)password;

- (void)attemptAuthenticationWithToken:(NSString *)token;

- (BOOL)userRequiresAuthentication:(NSString *)user;

- (BOOL)sendMessage:(SAVMessage *)message;

- (BOOL)sendMessages:(NSArray *)messages;

- (CBPPromise *)sendMediaRequest:(SAVMediaRequest *)request;

- (void)cancelMediaRequest:(CBPPromise *)promise;

@end
