//
//  SAVNotificationManager.h
//  SavantControl
//
//  Created by Cameron Pulsford on 1/14/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
#import "SAVNotification.h"

typedef void (^SAVNotificationClientRegistrationHandler)(BOOL success, BOOL wasNecessary);

typedef void (^SAVNotificationResponse)(BOOL success, NSError *error);

typedef void (^SAVNotificationPayloadResponse)(BOOL success, NSError *error, NSArray *payload);

@interface SAVNotificationManager : NSObject

/**
 *  Register the client. You must set all the device properties first.
 *
 *  @param completionHandler The completion handler. YES if the client is successfully registered, otherwise, NO.
 */
- (void)registerClientIfNecessary:(SAVNotificationClientRegistrationHandler)completionHandler;

/**
 *  Start the notification manager with push token data from Apple.
 *
 *  @param token Push token data from Apple. This data must have a length greater than 0.
 */
- (void)startWithToken:(NSData *)token;

/**
 *  Register for a new notification.
 *
 *  @param notification      The new notitication to register.
 *  @param completionHandler The completion handler, or nil.
 */
- (void)registerNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler;

/**
 *  Unregister an existing notification.
 *
 *  @param notification      The existing notification to unregister.
 *  @param completionHandler The completion handler, or nil.
 */
- (void)unregisterNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler;
/**
 *  Update rule on an existing notification
 *
 *  @param notification      The existing notification to update.
 *  @param completionHandler The completion handler, or nil.
 */
- (void)updateTriggerForNotification:(SAVNotification *)notification completionHandler:(SAVNotificationResponse)completionHandler;

/**
 *  Enable or disable an existing notification.
 *
 *  @param notification      The existing notification.
 *  @param enabled           YES to enable the notification; NO to disable it.
 *  @param completionHandler The completion handler, or nil.
 */
- (void)setNotification:(SAVNotification *)notification enabled:(BOOL)enabled completionHandler:(SAVNotificationResponse)completionHandler;

/**
 *  Get a list of all registered notifications.
 *
 *  @param completionHandler The completion handler.
 */
- (void)registeredNotificationsWithCompletionHandler:(SAVNotificationPayloadResponse)completionHandler;

@end
