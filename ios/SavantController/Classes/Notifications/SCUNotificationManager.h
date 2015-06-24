//
//  SCUNotifications.h
//  SavantController
//
//  Created by Cameron Pulsford on 10/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

extern NSString *const SAVNotificationPayloadHostIdKey;

@interface SCUNotificationManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)areNotificationsAllowed;

/**
 *  Start the notification manager and register for notifications. If you pass NO, the notification manager will not register if it has not already been registered once before.
 *
 *  @param force YES to force the notification manager to register. NO will start the notification manager only if it has been started once previously.
 */
- (void)start:(BOOL)force;

/**
 *  Call this when Apple provides us with a new push notification token.
 *
 *  @param token The new notification token.
 */
- (void)updatePushNotificationToken:(NSData *)token;

- (void)handleRemoteNotification:(NSDictionary *)notification withActionIdentifier:(NSString *)identifier;

@end
