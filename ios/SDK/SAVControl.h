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
#import "SAVData.h"
#import "SAVSystem.h"
#import "SAVProvisioningManager.h"
#import "SAVMessages.h"
#import "SAVUser.h"
#import "SAVCloudUser.h"
#import "SAVServiceRequest.h"
#import "SAVConnectionState.h"
#import "SAVSystem.h"
#import "SavantProtocols.h"
#import "SAVCloudBlockTypes.h"
#import "SAVDiscovery.h"
#import "SAVCameraEntity.h"

@class CBPPromise;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SCSResponseErrorDomain;

typedef NS_ENUM(NSInteger, SCSResponseError)
{
    SCSResponseErrorConnectionError         = -1,
    SCSResponseErrorEmailExists             = 103,
    SCSResponseErrorHasAlreadyBeenOnboarded = 203,
    SCSResponseErrorInvalidAdminPermissions = 207,
    SCSResponseErrorInvalidPassword         = 110,
    SCSResponseErrorUnknownEmail            = 102
};

/**
 *  @p SAVControlModes specify some of the default behavior that the SavantControl object will perform automatically. Typically, apps will want to use @p SAVControlModeFull, but stripped down apps, such as widgets, might want to pair some of these features down.
 */
typedef NS_OPTIONS(NSUInteger, SAVControlMode) {
    /**
     *  SavantControl will not try to register any states or do any configuration downloading on your behalf. You must do everything yourself.
     */
    SAVControlModeCustom = 0,
    /**
     *  SavantControl will keep volume, summary, and active service states registered for you.
     */
    SAVControlModeGlobalStates = 1 << 0,
    /**
     *  SavantControl will keep image states registered for you.
     */
    SAVControlModeImageStates = 1 << 1,
    /**
     *  SavantControl will keep settings states registered for you. These include channel favorites, room ordering, scene ordering, etc,.
     */
    SAVControlModeSettingsStates = 1 << 2,
    /**
     *  SavantControl will always download the latest config, if necessary, before calling its @p connectionIsReady callbacks. Unlike other modes, this mode can not be handled manually, so if an up to date configuration is necessary for you, always have this set.
     */
    SAVControlModeConfigurationDownloads = 1 << 3,
    /**
     *  SavantControl will initialize a SAVData object for you. Unlike other modes, this mode can not be handled manually.
     */
    SAVControlModeDatabase = 1 << 4,
    /**
     *  A combination of all of the @p SAVControlModes.
     */
    SAVControlModeFull = SAVControlModeGlobalStates | SAVControlModeImageStates | SAVControlModeSettingsStates | SAVControlModeDatabase | SAVControlModeConfigurationDownloads
};

@interface SAVControl : NSObject

#pragma mark - Required setup

/**
 *  Set the UID of this device. This property is required for connectivity to work. When calling @p -connectToSystem: an exception will be thrown if this is not set to a non-zero length string.
 */
@property (nonatomic) NSString *deviceUID;

/**
 *  Set the control mode. See the @p SAVControlMode definition for more information. This property will default to @p SAVControlModeFull.
 */
@property (nonatomic) SAVControlMode controlMode;

#pragma mark - Optional (but recommended) setup

/**
 *  Use these optional properties to set device specific information.
 */
@property (nonatomic) NSString *deviceFormFactor;
@property (nonatomic) NSString *deviceManufacturer;
@property (nonatomic) NSString *deviceModel;
@property (nonatomic) NSString *deviceModelVersion;
@property (nonatomic) NSString *deviceOperatingSystem;
@property (nonatomic) NSString *deviceOperatingSystemVersion;
@property (nonatomic) NSString *deviceName;

/**
 *  Use these optional properties to set app specific information.
 */
@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appVersion;

@property (nonatomic,readonly) NSPointerArray *homeMonitorObservers;

#pragma mark - Current system information

/**
 *  The current @p SAVSystem object, or nil.
 */
@property (nonatomic, readonly, nullable) SAVSystem *currentSystem;

/**
 *  The current connection state of the system.
 */
@property (nonatomic, readonly) SAVConnectionState connectionState;

/**
 *  @p YES if @p SavantControl is currently connected to a system; otherwise, @p NO.
 */
@property (nonatomic, readonly, getter = isConnectedToSystem) BOOL connectedToSystem;

/**
 *  @p YES if @p SavantControl is currently connected remotely; otherwise, @p NO. The value of this property is undefined when @p SavantControl is not connected to a system.
 */
@property (nonatomic, readonly, getter = isConnectedRemotely) BOOL connectedRemotely;

/**
 *  @p YES if @p SavantControl is currently in demonstration mode; otherwise, @p NO.
 */
@property (nonatomic, readonly, getter = isDemoSystem) BOOL demoSystem;

/**
 *  @p YES if @p SavantControl is currently connected to a 'cloud system'; otherwise, @p NO.
 */
@property (nonatomic, readonly, getter = isConnectedToACloudSystem) BOOL connectedToACloudSystem;

/**
 *  @p YES if the current connected user is an admin; otherwise, @p NO. The value of this property is undefined when @p isConnectedToACloudSystem is @p NO.
 */
@property (nonatomic, readonly, getter = isAdmin) BOOL admin;

/**
 *  The presentable name of the current user on the system, or nil.
 */
@property (nonatomic, readonly, nullable) NSString *currentUserName;

#pragma mark - System interaction

/**
 *  Set a 'pin code' delegate. This allows a separate level of authentication in your app, outside of the normal login flow. For example, maybe you want to use this delegate as an opportunity to show a TouchID alert before allowing normal authentication to continue.
 */
@property (nonatomic, weak, nullable) id<UserLevelSecurityDelegate> pinCodeDelegate;

#pragma mark - Logs

/**
 *  Provides a dictionary containing a data entry for each log file
 *
 *  @return dictionary of log file data keyed to logname
 */
- (NSDictionary *)logData;

#pragma mark - Connection management

/**
 *  Add a system status observer.
 *
 *  @param observer The system status observer.
 */
- (void)addSystemStatusObserver:(id<SystemStatusDelegate>)observer;

/**
 *  Remove a system status observer.
 *
 *  @param observer The system status observer.
 */
- (void)removeSystemStatusObserver:(id<SystemStatusDelegate>)observer;

/**
 *  Connect to a system.
 *
 *  @param system The system to connect to.
 */
- (void)connectToSystem:(SAVSystem *)system;

/**
 *  Connect to the demo system.
 */
- (void)connectToDemoSystem;

/**
 *  Load the previously loaded system and handle authentication automatically.
 *
 *  @return YES if there was a previous system to load; otherwise, NO.
 */
- (BOOL)loadPreviousConnection;

/**
 *  Disconnect the current connection.
 */
- (void)disconnect;

/**
 *  Suspend the current conneciton.
 */
- (void)suspend;

/**
 *  Resume the current connection.
 */
- (void)resume;

#pragma mark - General messaging

/**
 *  Send a message to the system.
 *
 *  @param message The message.
 */
- (void)sendMessage:(SAVMessage *)message;

/**
 *  Send a group of messages to the system.
 *
 *  @param messages The messages.
 */
- (void)sendMessages:(NSArray *)messages;

#pragma mark - Media messaging

/**
 *  Send a media request.
 *
 *  @param request The reqeust.
 *
 *  @return A promise on which to set a completionHandler.
 */
- (CBPPromise *)sendMediaRequest:(SAVMediaRequest *)request;

/**
 *  Cancel a media request for the given promise.
 *
 *  @param promise The promise corresponding to the outstanding media request.
 */
- (void)cancelMediaRequest:(CBPPromise *)promise;

#pragma mark - Observing cameras

/**
 *  Add a camera observer.
 *
 *  @param observer The observer.
 */
- (void)addCameraObserver:(id<CameraFetchDelegate>)observer;

/**
 *  Remove a camera observer.
 *
 *  @param observer The observer.
 */
- (void)removeCameraObserver:(id<CameraFetchDelegate>)observer;

#pragma mark - DIS results (different than DIS feedback)

/**
 *  Add a DIS result observer for an app.
 *
 *  @param observer The observer.
 *  @param app      The app.
 */
- (void)addDISResultObserver:(id <DISResultDelegate>)observer forApp:(NSString *)app;

/**
 *  Remove a DIS result ovserver for an app.
 *
 *  @param observer The observer.
 *  @param app      The app.
 */
- (void)removeDISResultObserver:(id <DISResultDelegate>)observer forApp:(NSString *)app;

#pragma mark - Observing binary transfers

/**
 *  Add a binary transfer observer.
 *
 *  @param observer The observer.
 */
- (void)addBinaryTransferObserver:(id<ConnectionBinaryTransferDelegate>)observer;

/**
 *  Remove a binary transfer observer.
 *
 *  @param observer The observer.
 */
- (void)removeBinaryTransferObserver:(id<ConnectionBinaryTransferDelegate>)observer;

#pragma mark - Local user management

/**
 *  Returns a list of SAVLocalUsers for the current system in alphabetical order.
 *
 *  @return A list of SAVLocalUsers for the current system in alphabetical order.
 */
- (NSArray *)localUsers;

/**
 *  Use this method to check if there is a saved password for a user.
 *
 *  @param user The user.
 *
 *  @return YES if the users password is saved or does not require a password; otherwise, NO.
 */
- (BOOL)hasSavedPasswordForUser:(NSString *)user;

/**
 *  Use this method to check if a user requires authentication.
 *
 *  @param user The user.
 *
 *  @return YES if the user requires authentication; otherwise, NO.
 */
- (BOOL)userRequiresAuthentication:(NSString *)user;

/**
 *  Attempt to login as a local user with a password.
 *
 *  @param user     The local user.
 *  @param password The password.
 */
- (void)loginToLocalUser:(NSString *)user password:(NSString *)password;

/**
 *  Attempt to login as a local user with its saved password.
 *
 *  @param user The local user.
 */
- (void)loginToLocalUserWithSavedPassword:(NSString *)user;

/**
 *  Sign out of all local/cloud accounts.
 */
- (void)signOut;

#pragma mark - Host Services

- (SCSCancelBlock)fetchEndpointForCamera:(SAVCameraEntity*)camera completionHandler:(SCSResponseBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
