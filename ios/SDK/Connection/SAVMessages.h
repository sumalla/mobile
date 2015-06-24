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

#import "SavantProtocols.h"

@class SAVService;

@interface SAVMessage : NSObject <NSCopying>

#define SAVMESSAGE_SESSION_TARGET      @"session"
#define SAVMESSAGE_SERVICE_TARGET      @"service"
#define SAVMESSAGE_STATE_TARGET        @"state"
#define SAVMESSAGE_DIS_TARGET          @"dis"
#define SAVMESSAGE_STATUS_TARGET       @"status"
#define SAVMESSAGE_MEDIA_TARGET        @"media"
#define SAVMESSAGE_LOG_TARGET          @"log"
#define SAVMESSAGE_HOMEMONITOR_TARGET  @"homemonitor"
#define SAVMESSAGE_OSD_TARGET          @"osd"
#define SAVMESSAGE_LOG_UPLOAD_TARGET   @"logUpload"

@property (readonly) NSString *command;

+ (instancetype)messageWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;
- (NSString *)sessionURI;
- (NSString *)serviceURI;
- (NSString *)stateURI;
- (NSString *)disURIForApp:(NSString *)disApp;
- (NSString *)mediaURIForApp:(NSString *)mediaApp;
- (NSString *)statusURI;
- (NSString *)logURI;
- (NSString *)uri;
- (BOOL)requiresAuthentication; /* defaults to YES */
- (BOOL)requiresBinaryTransfer; /* defaults to NO */

@end

@interface SAVDevicePresentMessage : SAVMessage

#define SAVMESSAGE_DEVICE_PRESENT_COMMAND @"devicePresent"
#define SAVMESSAGE_DEVICE_KEY     @"device"
#define SAVMESSAGE_UID_KEY        @"UID"
#define SAVMESSAGE_OS_KEY         @"OS"
#define SAVMESSAGE_APP_KEY        @"app"
#define SAVMESSAGE_MODEL_KEY      @"model"
#define SAVMESSAGE_MAKE_KEY       @"make"
#define SAVMESSAGE_TYPE_KEY       @"type"
#define SAVMESSAGE_NAME_KEY       @"name"
#define SAVMESSAGE_CONFIG_ID_KEY  @"configurationID"
#define SAVMESSAGE_VERSION_KEY    @"protocolVersion"
#define SAVMESSAGE_VERSION        @"2"
#define SAVMESSAGE_CLOUDTOKEN_KEY @"cloudToken"
#define SAVMESSAGE_HOSTTOKEN_KEY  @"hostToken"

@property NSString *UID;
@property NSString *OS;
@property NSString *app;
@property NSString *model;
@property NSString *configurationID;
@property NSString *version;
@property NSString *type;
@property NSString *name;
@property NSString *make;
@property NSString *homeID;
@property NSString *cloudToken;
@property NSString *hostToken;

@end

@interface SAVDeviceResponseMessage : SAVMessage

#define SAVMESSAGE_DEVICE_RESPONSE_COMMAND @"deviceRecognized"
#define SAVMESSAGE_AUTHORIZED_KEY        @"authorized"
#define SAVMESSAGE_AUTHENTICATION_KEY    @"authentication"
#define SAVMESSAGE_UPDATE_KEY            @"update"
#define SAVMESSAGE_REMOTE_KEY            @"remote"
#define SAVMESSAGE_HOST_UID_KEY          @"hostUID"
#define SAVMESSAGE_HOME_ID_KEY           @"homeId"
#define SAVMESSAGE_HOST_NAME_KEY         @"hostName"
#define SAVMESSAGE_USERS_KEY             @"users"
#define SAVMESSAGE_PROTOCOLVERSION_KEY   @"protocolVersion"

@property BOOL authorized;
@property BOOL authentication;
@property BOOL update;
@property BOOL remote;
@property NSArray *users;
@property NSString *hostName;
@property NSString *hostID;
@property NSString *homeID;
@property uint32_t protocolVersion;

@end

@interface SAVAuthRequestMessage : SAVMessage

#define SAVMESSAGE_AUTH_REQUEST_COMMAND @"authenticationRequest"
#define SAVMESSAGE_USER_KEY          @"user"
#define SAVMESSAGE_PASSWORD_KEY      @"password"
#define SAVMESSAGE_TOKEN_KEY         @"hostToken"

@property NSString *user;
@property NSString *password;
@property NSString *token;

@end

@interface SAVAuthResponseMessage : SAVMessage

#define SAVMESSAGE_AUTH_RESPONSE_COMMAND @"authenticationResponse"
#define SAVMESSAGE_REMOTE_ACCESS_INFO_KEY @"remoteAccessInfo"
#define SAVMESSAGE_REMOTE_ACCESS_NAME_KEY @"remoteAccessHostName"
#define SAVMESSAGE_REMOTE_ACCESS_PORT_KEY @"remoteAccessHostPort"
#define SAVMESSAGE_REMOTE_ACCESS_FAILOVER_NAME_KEY @"remoteAccessFailoverHostName"
#define SAVMESSAGE_REMOTE_ACCESS_FAILOVER_PORT_KEY @"remoteAccessFailoverHostPort"
#define SAVMESSAGE_ERRORCODE_KEY @"errorCode"
#define SAVMESSAGE_PERMISSIONS_KEY @"permissions"
#define SAVMESSAGE_ADMIN_KEY @"admin"
#define SAVMESSAGE_NOTIFICATIONS_KEY @"notifications"
#define SAVMESSAGE_REMOTE_KEY @"remote"
#define SAVMESSAGE_ZONEBLACKLIST_KEY @"zoneBlacklist"
#define SAVMESSAGE_SERVICEBLACKLIST_KEY @"serviceBlacklist"

@property BOOL authorized;
@property NSString *hostToken;
@property NSUInteger errorCode;

@property NSDictionary *permissions;
@property (readonly, getter = isAdmin, atomic) BOOL admin;
@property (readonly, atomic) BOOL canManageNotifications;
@property (readonly, atomic) BOOL hasRemoteAccess;
@property (readonly, atomic) NSSet *serviceBlacklist;
@property (readonly, atomic) NSSet *zoneBlacklist;

@property NSDictionary *remoteAccessInfo;
@property (readonly, atomic) NSString *remoteAccessHostName;
@property (readonly, atomic) NSNumber *remoteAccessHostPort;
@property (readonly, atomic) NSString *remoteAccessFailoverHostName;
@property (readonly, atomic) NSNumber *remoteAccessFailoverHostPort;

@end

@interface SAVFileRequest : SAVMessage

#define SAVMESSAGE_FILE_REQUEST_COMMAND            @"fileDownload"
#define SAVMESSAGE_FILE_PATH_KEY                   @"filePath"
#define SAVMESSAGE_FILE_TYPE_KEY                   @"fileType"
#define SAVMESSAGE_FILE_URI_KEY                    @"URI"
#define SAVMESSAGE_FILE_PAYLOAD_KEY                @"payload"
#define SAVMESSAGE_FILETYPE_NOWPLAYING_ARTWORK     @"nowPlayingArtwork"
#define SAVMESSAGE_FILETYPE_THUMBNAIL_ARTWORK      @"thumbnailArtwork"

@property NSString *filePath;
@property NSString *fileType;
@property NSString *fileURI;
@property id payload;

@end

@interface SAVConfigRequest : SAVFileRequest

#define SAVMESSAGE_CONFIG_PATH @"uiconfig.tar.gz"

@end

@interface SAVStateRegister : SAVMessage

#define SAVMESSAGE_STATE_REGISTER_COMMAND @"register"
#define SAVMESSAGE_STATE_KEY @"state"

@property NSString *state;

+ (instancetype)messageWithState:(NSString *)state;
- (instancetype)initWithState:(NSString *)state;

@end

@interface SAVStateUnregister : SAVStateRegister

#define SAVMESSAGE_STATE_UNREGISTER_COMMAND @"unregister"

@end

@interface SAVStateUpdate : SAVMessage

@property NSString *state;
@property id value;
@property (readonly, atomic) NSString *scope;

#define SAVMESSAGE_STATE_UPDATE_COMMAND @"update"
#define SAVMESSAGE_STATE_VALUE_KEY @"value"

+ (instancetype)messageWithState:(NSString *)state value:(id)value;

/**
 *  Returns the last component of a state.
 *
 *  @return The last component of a state.
 */
- (NSString *)stateName;

@end

@interface SAVHomeMonitorRequest : SAVMessage
@property(nonatomic,strong) NSDictionary *dict;
@property(nonatomic,strong) NSString *commandString;
@property(nonatomic,strong) NSString *homeMonitorId;

- (instancetype)initWithDictionary:(NSDictionary *)dict command:(NSString *)command homeMonitorId:(NSString *)homeMonitorId;

@end

@interface SAVMediaRequest : SAVMessage

#define SAVMESSAGE_MEDIAREQUEST_KEY_TITLE               @"Title"
#define SAVMESSAGE_MEDIAREQUEST_KEY_QUERY               @"Query"
#define SAVMESSAGE_MEDIAREQUEST_KEY_QUERYARGUMENTS      @"Query arguments"
#define SAVMESSAGE_MEDIAREQUEST_KEY_COMPONENTIDENTIFIER @"Component Identifier"
#define SAVMESSAGE_MEDIAREQUEST_KEY_LOGICALCOMPONENT    @"Logical Component"
#define SAVMESSAGE_MEDIAREQUEST_KEY_REQUESTINGSERVICE   @"requestingService"
#define SAVMESSAGE_MEDIAREQUEST_KEY_COMMAND             @"command"
#define SAVMESSAGE_MEDIAREQUEST_KEY_ARGUMENTS           @"arguments"
#define SAVMESSAGE_MEDIAREQUEST_KEY_REQUESTINGUID       @"RequestingUID"
#define SAVMESSAGE_MEDIAREQUEST_KEY_VERSION             @"version"

@property NSString *query;
@property NSDictionary *arguments;
@property (readonly) NSString *title;
@property NSString *componentIdentifier;
@property NSString *logicalComponent;

@end

@interface SAVMediaRequestGenerator : NSObject

@property (nonatomic) BOOL addSceneKey;

+ (instancetype)mediaRequestGeneratorFromService:(SAVService *)service;

- (SAVMediaRequest *)mediaRequest;
- (SAVMediaRequest *)initialMenu;
- (SAVMediaRequest *)nowPlayingMenu;
- (SAVMediaRequest *)mediaRequestFromNode:(NSDictionary *)node;
- (SAVMediaRequest *)mediaRequestFromNode:(NSDictionary *)node withSearchTerm:(NSString *)searchTerm;
- (SAVMediaRequest *)mediaSubmenuRequestFromNode:(NSDictionary *)node;
- (SAVMediaRequest *)backCommandWithLevel:(NSUInteger)level;

@end

#pragma mark - DIS

@interface SAVDISRequest : SAVMessage

@property (nonatomic) NSString *app;
@property (nonatomic) NSString *request;
@property (nonatomic) NSDictionary *arguments;

- (instancetype)initWithApp:(NSString *)app request:(NSString *)request arguments:(NSDictionary *)arguments;

@end

@interface SAVDISRequestGenerator : NSObject

- (instancetype)initWithApp:(NSString *)app;

@property (readonly) NSString *app;

- (NSArray *)feedbackStringsWithStateNames:(NSArray *)feedbackNames;

- (SAVDISRequest *)request:(NSString *)request withArguments:(NSDictionary *)arguments;

@end

@interface SAVDISFeedbackRegister : SAVStateRegister

@end

@interface SAVDISFeedbackUnregister : SAVDISFeedbackRegister

@end

#define SAVMESSAGE_DIS_REQUEST @"request"
#define SAVMESSAGE_DIS_REQUEST_KEY @"request"
#define SAVMESSAGE_DIS_REQUESTARGS_KEY @"requestArgs"
#define SAVMESSAGE_DIS_RESULTS_KEY @"results"

@interface SAVDISFeedback : SAVStateUpdate

@property NSString *app;

- (instancetype)initWithApp:(NSString *)app state:(NSString *)state value:(id)value;

@end

@interface SAVDISResults : SAVMessage

@property NSString *app;
@property NSString *request;
@property id results;

- (instancetype)initWithApp:(NSString *)app request:(NSString *)request results:(NSDictionary *)results;

@end

@interface SAVCameraStreamRequest : SAVMessage

typedef NS_ENUM(NSUInteger, SAVCameraStreamAction)
{
    SAVCameraStreamAction_StartFetch,
    SAVCameraStreamAction_StopFetch
};

@property (nonatomic) SAVCameraStreamAction action;
@property NSTimeInterval frequency;
@property NSString *component;
@property NSString *logicalComponent;
@property (getter = isLarge) BOOL large;

@end

@interface SAVLogUploadRequest : SAVMessage

@end

@interface SAVBinaryTransfer : SAVMessage

@property (readonly) NSData *data;

- (instancetype)initWithData:(NSData *)data uri:(NSString *)uri payload:(id)payload;

@end
