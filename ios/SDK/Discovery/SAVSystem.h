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
@class ProvisionableDevice;

typedef NS_ENUM(NSUInteger, SAVSystemRemoteAccessDisabledReason)
{
    SAVSystemRemoteAccessDisabledReasonUnknown,
    SAVSystemRemoteAccessDisabledReasonNotGranted,
    SAVSystemRemoteAccessDisabledReasonTrialPeriodExpired,
    SAVSystemRemoteAccessDisabledReasonPastDue
};

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kSAVSystemUIDKey;
extern NSString *const kSAVSystemNameKey;
extern NSString *const kSAVSystemSchemeKey;
extern NSString *const kSAVSystemPortKey;
extern NSString *const kSAVSystemTypeKey;
extern NSString *const kSAVSystemAddressKey;
extern NSString *const kSAVSystemIsRemoteKey;
extern NSString *const kSAVSystemVersionKey;
extern NSString *const kSAVSystemIsCloudAccount;
extern NSString *const kSAVSystemHasRemoteInfoKey;
extern NSString *const kSAVSystemOnboardKey;
extern NSString *const kSAVSystemHomeIDKey;
extern NSString *const kSAVSystemCellURLKey;
extern NSString *const kSAVSystemLastURLKey;
extern NSString *const kSAVSystemCloudOnlineKey;
extern NSString *const kSAVSystemNotificationsEnabledKey;
extern NSString *const kSAVSystemNotificationsDisabledReasonKey;
extern NSString *const kSAVSystemSSIDKey;

@interface SAVSystem : NSObject

/**
 *  The provisionable device, if any, associated with the system.
 */
@property (nonatomic) ProvisionableDevice *provisionableDevice;

/**
 *  The presentable name of the system.
 */
@property (nonatomic) NSString *name;

/**
 *  The mac address of the host.
 */
@property (nonatomic) NSString *hostID;

/**
 *  The general ID of the home.
 */
@property (nonatomic, nullable) NSString *homeID;

/**
 *  The unique key used to onboard, or nil. If this is nil, the system is already onboarded.
 */
@property (nonatomic, nullable) NSString *onboardKey;

/**
 *  The type of system: mac/linux.
 */
@property (nonatomic) NSInteger type;

/**
 *  The SSID associated with the last local connection.
 */
@property (nonatomic, nullable) NSString *SSID;

/**
 *  The local URL.
 */
@property (nonatomic, nullable) NSURL *localURL;

/**
 *  The local scheme.
 */
@property (nonatomic, nullable) NSString *localScheme;

/**
 *  The local address.
 */
@property (nonatomic, nullable) NSString *localAddress;

/**
 *  The local port.
 */
@property (nonatomic) NSInteger localPort;

/**
 *  The cell URL.
 */
@property (nonatomic, nullable) NSURL *cellURL;

/**
 *  The cell scheme.
 */
@property (nonatomic, nullable) NSString *cellScheme;

/**
 *  The cell address.
 */
@property (nonatomic, nullable) NSString *cellAddress;

/**
 *  The cell port.
 */
@property (nonatomic) NSInteger cellPort;

/**
 *  YES if the system's cloud connection is valid; otherwise, NO.
 */
@property (nonatomic, getter = isCloudOnline) BOOL cloudOnline;

/**
 *  YES if the system's configured for notifications; otherwise, NO.
 */
@property (nonatomic, getter = areNotificationsEnabled) BOOL notificationsEnabled;

/**
 *  The reason notifications are not enabled.
 */
@property (nonatomic, nullable) NSString *notificationsDisabledReason;

/**
 *  The protocol version.
 */
@property (nonatomic) NSUInteger version;

/**
 *  Store the last URL you connected to here.
 */
@property (nonatomic, nullable) NSURL *lastURL;

/**
 *  YES if the system is a cloud system; otherwise, NO
 */
@property (nonatomic, getter = isCloudSystem) BOOL cloudSystem;

/**
 *  YES if the system was connected to manually; otherwise, NO.
 */
@property (nonatomic, getter = isManualConnection) BOOL manualConnection;

/**
 *  YES if the system allows remote access; otherwise, NO.
 */
@property (nonatomic) BOOL hasRemoteAccess;

/**
 *  The reason remote access is disabled.
 */
@property (nonatomic) SAVSystemRemoteAccessDisabledReason remoteAccessDisableReason;

/**
 *  YES if your priviledges allow for admine access; otherwise, NO. Check your priviledges often.
 */
@property (nonatomic, getter = isAdmin) BOOL admin;

/**
 *  A set of blacklisted services.
 */
@property (nonatomic, nullable) NSSet *serviceBlacklist;

/**
 *  A set of blacklisted rooms/
 */
@property (nonatomic, nullable) NSSet *zoneBlacklist;


- (instancetype)initWithSystemInfo:(NSDictionary *)systemInfo;

- (NSDictionary *)dictionaryRepresentation;

NS_ASSUME_NONNULL_END

@end

