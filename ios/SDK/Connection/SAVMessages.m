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

#import "SAVMessages.h"
#import "SAVService.h"
@import Extensions;

@import UIKit;

@interface SAVMessage ()

@property NSString *command;

@end

@implementation SAVMessage

+ (instancetype)messageWithDictionary:(NSDictionary *)dict
{
    return [[[self class] alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];

    return self;
}

- (NSString *)sessionURI
{
    return [NSString stringWithFormat:@"%@/%@", SAVMESSAGE_SESSION_TARGET, self.command];
}

- (NSString *)serviceURI
{
    return [NSString stringWithFormat:@"%@/%@", SAVMESSAGE_SERVICE_TARGET, self.command];
}

- (NSString *)stateURI
{
    return [NSString stringWithFormat:@"%@/%@", SAVMESSAGE_STATE_TARGET, self.command];
}

- (NSString *)disURIForApp:(NSString *)disApp
{
    NSParameterAssert([disApp length]);

    return [NSString stringWithFormat:@"%@/%@/%@", SAVMESSAGE_DIS_TARGET, disApp, self.command];
}

- (NSString *)mediaURIForApp:(NSString *)mediaApp
{
    NSParameterAssert([mediaApp length]);

    return [NSString stringWithFormat:@"%@/%@/%@", SAVMESSAGE_MEDIA_TARGET, mediaApp, self.command];
}

- (NSString *)statusURI
{
    return [NSString stringWithFormat:@"%@/%@", SAVMESSAGE_STATUS_TARGET, self.command];
}

- (NSString *)logURI
{
    return [NSString stringWithFormat:@"%@/%@", SAVMESSAGE_LOG_TARGET, self.command];
}

- (NSString *)logUploadURI
{
    return SAVMESSAGE_LOG_UPLOAD_TARGET;
}

- (NSString *)homeMonitorUriForId:(NSString *)identifier {
    return [NSString stringWithFormat:@"%@/%@/%@", SAVMESSAGE_HOMEMONITOR_TARGET, identifier, self.command];
}

- (NSDictionary *)dictionaryRepresentation
{
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"%@ : %@", [super description], [self dictionaryRepresentation]];
}

- (NSString *)uri
{
    return [self sessionURI];
}

- (BOOL)requiresAuthentication
{
    return YES;
}

- (BOOL)requiresBinaryTransfer
{
    return NO;
}

#pragma mark - NSCopying methods

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithDictionary:[self dictionaryRepresentation]];
}

@end

@implementation SAVDevicePresentMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.UID = dict[SAVMESSAGE_UID_KEY];
        self.OS = dict[SAVMESSAGE_OS_KEY];
        self.app = dict[SAVMESSAGE_APP_KEY];
        self.model = dict[SAVMESSAGE_MODEL_KEY];
        self.configurationID = dict[SAVMESSAGE_CONFIG_ID_KEY];
        self.version = dict[SAVMESSAGE_VERSION_KEY];
        self.type = dict[SAVMESSAGE_TYPE_KEY];
        self.name = dict[SAVMESSAGE_NAME_KEY];
        self.make = dict[SAVMESSAGE_MAKE_KEY];
        self.homeID = dict[SAVMESSAGE_HOST_UID_KEY];
        self.cloudToken = dict[SAVMESSAGE_CLOUDTOKEN_KEY];
        self.hostToken = dict[SAVMESSAGE_HOSTTOKEN_KEY];
    }
    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_DEVICE_PRESENT_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   SAVMESSAGE_VERSION_KEY: SAVMESSAGE_VERSION,
                                   SAVMESSAGE_DEVICE_KEY: @{}
                                   }];

    if (self.configurationID)
        dict[SAVMESSAGE_CONFIG_ID_KEY] = self.configurationID;
    if (self.homeID)
        dict[SAVMESSAGE_HOME_ID_KEY] = self.homeID;
    if (self.cloudToken)
        dict[SAVMESSAGE_CLOUDTOKEN_KEY] = self.cloudToken;
    if (self.hostToken)
        dict[SAVMESSAGE_HOSTTOKEN_KEY] = self.hostToken;

    NSMutableDictionary *deviceDict = [NSMutableDictionary dictionary];

    if (self.UID)
        deviceDict[SAVMESSAGE_UID_KEY] = self.UID;
    if (self.OS)
        deviceDict[SAVMESSAGE_OS_KEY] = self.OS;
    if (self.app)
        deviceDict[SAVMESSAGE_APP_KEY] = self.app;
    if (self.model)
        deviceDict[SAVMESSAGE_MODEL_KEY] = self.model;
    if (self.type)
        deviceDict[SAVMESSAGE_TYPE_KEY] = self.type;
    if (self.name)
        deviceDict[SAVMESSAGE_NAME_KEY] = self.name;
    if (self.make)
        deviceDict[SAVMESSAGE_MAKE_KEY] = self.make;

    if ([deviceDict count])
        dict[SAVMESSAGE_DEVICE_KEY] = [NSDictionary dictionaryWithDictionary:deviceDict];

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (BOOL)requiresAuthentication
{
    return NO;
}

@end

@implementation SAVDeviceResponseMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.authorized = [dict[SAVMESSAGE_AUTHORIZED_KEY] boolValue];
        self.authentication = [dict[SAVMESSAGE_AUTHENTICATION_KEY] boolValue];
        self.update = [dict[SAVMESSAGE_UPDATE_KEY] boolValue];
        self.remote = [dict[SAVMESSAGE_REMOTE_KEY] boolValue];
        self.hostID = dict[SAVMESSAGE_HOST_UID_KEY];
        self.homeID = dict[SAVMESSAGE_HOME_ID_KEY];
        self.hostName = dict[SAVMESSAGE_HOST_NAME_KEY];
        self.users = dict[SAVMESSAGE_USERS_KEY];
        self.protocolVersion = [dict[SAVMESSAGE_PROTOCOLVERSION_KEY] unsignedIntValue];
    }
    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_DEVICE_RESPONSE_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:
                                 @{
                                   SAVMESSAGE_AUTHENTICATION_KEY: @(self.authentication),
                                   SAVMESSAGE_AUTHORIZED_KEY: @(self.authorized),
                                   SAVMESSAGE_UPDATE_KEY: @(self.update),
                                   SAVMESSAGE_REMOTE_KEY: @(self.remote),
                                   SAVMESSAGE_PROTOCOLVERSION_KEY: @(self.protocolVersion),
                                   }];

    if (self.hostID)
        dict[SAVMESSAGE_HOST_UID_KEY] = self.hostID;
    if (self.homeID)
        dict[SAVMESSAGE_HOME_ID_KEY] = self.homeID;
    if (self.hostName)
        dict[SAVMESSAGE_HOST_NAME_KEY] = self.hostName;
    if (self.users)
        dict[SAVMESSAGE_USERS_KEY] = self.users;

    return [NSDictionary dictionaryWithDictionary: dict];
}

@end

@implementation SAVAuthRequestMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.user = dict[SAVMESSAGE_USER_KEY];
        self.password = dict[SAVMESSAGE_PASSWORD_KEY];
        self.token = dict[SAVMESSAGE_TOKEN_KEY];
    }
    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_AUTH_REQUEST_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if (self.user)
        dict[SAVMESSAGE_USER_KEY] = self.user;
    if (self.password)
        dict[SAVMESSAGE_PASSWORD_KEY] = self.password;
    if (self.token)
        dict[SAVMESSAGE_TOKEN_KEY] = self.token;

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (BOOL)requiresAuthentication
{
    return NO;
}

@end

@implementation SAVAuthResponseMessage

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.authorized = [dict[SAVMESSAGE_AUTHORIZED_KEY] boolValue];
        self.remoteAccessInfo = dict[SAVMESSAGE_REMOTE_ACCESS_INFO_KEY];
        self.hostToken = dict[SAVMESSAGE_HOSTTOKEN_KEY];
        self.errorCode = [dict[SAVMESSAGE_ERRORCODE_KEY] unsignedIntegerValue];
        self.permissions = dict[SAVMESSAGE_PERMISSIONS_KEY];
    }
    return self;
}

- (NSString *)remoteAccessHostName
{
    return self.remoteAccessInfo[SAVMESSAGE_REMOTE_ACCESS_NAME_KEY];
}

- (NSNumber *)remoteAccessHostPort
{
    return self.remoteAccessInfo[SAVMESSAGE_REMOTE_ACCESS_PORT_KEY];
}

- (NSString *)remoteAccessFailoverHostName
{
    return self.remoteAccessInfo[SAVMESSAGE_REMOTE_ACCESS_FAILOVER_NAME_KEY];
}

- (NSNumber *)remoteAccessFailoverHostPort
{
    return self.remoteAccessInfo[SAVMESSAGE_REMOTE_ACCESS_FAILOVER_PORT_KEY];
}

- (BOOL)isAdmin
{
    return [self.permissions[SAVMESSAGE_ADMIN_KEY] boolValue];
}

- (BOOL)canManageNotifications
{
    return [self.permissions[SAVMESSAGE_NOTIFICATIONS_KEY] boolValue];
}

- (BOOL)hasRemoteAccess
{
    return [self.permissions[SAVMESSAGE_REMOTE_KEY] boolValue];
}

- (NSSet *)serviceBlacklist
{
    NSArray *serviceBlacklist = self.permissions[SAVMESSAGE_SERVICEBLACKLIST_KEY];

    if ([serviceBlacklist count])
    {
        return [NSSet setWithArray:serviceBlacklist];
    }
    else
    {
        return [NSSet set];
    }
}

- (NSSet *)zoneBlacklist
{
    NSArray *zoneBlacklist = self.permissions[SAVMESSAGE_ZONEBLACKLIST_KEY];

    if ([zoneBlacklist count])
    {
        return [NSSet setWithArray:zoneBlacklist];
    }
    else
    {
        return [NSSet set];
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:@(self.authorized)
                                                                   forKey:SAVMESSAGE_AUTHORIZED_KEY];

    if (self.remoteAccessInfo)
    {
        dict[SAVMESSAGE_REMOTE_ACCESS_INFO_KEY] = self.remoteAccessInfo;
    }

    if (self.hostToken)
    {
        dict[SAVMESSAGE_HOSTTOKEN_KEY] = self.hostToken;
    }

    if (self.errorCode)
    {
        dict[SAVMESSAGE_ERRORCODE_KEY] = @(self.errorCode);
    }

    if (self.permissions)
    {
        dict[SAVMESSAGE_PERMISSIONS_KEY] = self.permissions;
    }

    return dict;
}

- (NSString *)command
{
    return SAVMESSAGE_AUTH_RESPONSE_COMMAND;
}

@end

@implementation SAVFileRequest

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.filePath = dict[SAVMESSAGE_FILE_PATH_KEY];
        self.fileType = dict[SAVMESSAGE_FILE_TYPE_KEY];
        self.fileURI = dict[SAVMESSAGE_FILE_URI_KEY];
        self.payload = dict[SAVMESSAGE_FILE_PAYLOAD_KEY];
    }
    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_FILE_REQUEST_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.filePath)
    {
        [dictionary setObject:self.filePath forKey:SAVMESSAGE_FILE_PATH_KEY];
    }

    if (self.fileType)
    {
        [dictionary setObject:self.fileType forKey:SAVMESSAGE_FILE_TYPE_KEY];
    }

    if (self.fileURI)
    {
        [dictionary setObject:self.fileURI forKey:SAVMESSAGE_FILE_URI_KEY];
    }

    if (self.payload)
    {
        [dictionary setObject:self.payload forKey:SAVMESSAGE_FILE_PAYLOAD_KEY];
    }

    return [dictionary copy];
}

@end

@implementation SAVConfigRequest

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.filePath = SAVMESSAGE_CONFIG_PATH;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.filePath = SAVMESSAGE_CONFIG_PATH;
    }
    return self;
}

@end

@implementation SAVStateRegister

+ (instancetype)messageWithState:(NSString *)state
{
    return [[[self class] alloc] initWithState:state];
}

- (instancetype)initWithState:(NSString *)state
{
    self = [super init];
    if (self)
    {
        self.state = state;
    }
    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_STATE_REGISTER_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if (self.state)
    {
        dict[SAVMESSAGE_STATE_KEY] = self.state;
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSString *)uri
{
    return [self stateURI];
}

@end

@implementation SAVStateUnregister

- (NSString *)command
{
    return SAVMESSAGE_STATE_UNREGISTER_COMMAND;
}

@end

@implementation SAVStateUpdate

+ (instancetype)messageWithState:(NSString *)state value:(id)value
{
    return [[[self class] alloc] initWithState:state value:value];
}

- (instancetype)initWithState:(NSString *)state value:(id)value
{
    self = [super init];
    if (self)
    {
        self.state = state;
        self.value = value;
    }
    return self;
}

- (NSString *)scope
{
    NSArray *stateComponents = [self.state componentsSeparatedByString:@"."];

    if ([stateComponents count])
    {
        NSArray *scopeComponents = [stateComponents subarrayWithRange:NSMakeRange(0, stateComponents.count - 1)];
        return [scopeComponents componentsJoinedByString:@"."];
    }

    return nil;
}

- (NSString *)command
{
    return SAVMESSAGE_STATE_UPDATE_COMMAND;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if (self.state)
        dict[SAVMESSAGE_STATE_KEY] = self.state;
    if (self.value)
        dict[SAVMESSAGE_STATE_VALUE_KEY] = self.value;

    return [NSDictionary dictionaryWithDictionary: dict];
}

- (NSString *)uri
{
    return [self sessionURI];
}

- (NSString *)stateName
{
    NSArray *stateComponents = [self.state componentsSeparatedByString:@"."];
    return [stateComponents lastObject];
}

@end

@implementation SAVHomeMonitorRequest

- (instancetype)initWithDictionary:(NSDictionary *)dict command:(NSString *)command homeMonitorId:(NSString *)homeMonitorId {
    if ((self = [super initWithDictionary:dict])) {
        self.dict = dict;
        self.commandString = command;
        self.homeMonitorId = homeMonitorId;
    }
    return self;
}

- (NSString *)command {
    return self.commandString;
}

- (NSString *)uri {
    return [self homeMonitorUriForId:self.homeMonitorId];
}

- (NSDictionary*)dictionaryRepresentation {
    return self.dict;
}

@end

@interface SAVMediaRequest ()

@property NSString *serviceName;
@property NSString *title;
@property NSString *version;

@end

@implementation SAVMediaRequest

@synthesize arguments = _arguments;

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        self.query = dict[SAVMESSAGE_MEDIAREQUEST_KEY_QUERY];
        self.title = dict[SAVMESSAGE_MEDIAREQUEST_KEY_TITLE];

        self.arguments = dict[SAVMESSAGE_MEDIAREQUEST_KEY_QUERYARGUMENTS];
        self.componentIdentifier = dict[SAVMESSAGE_MEDIAREQUEST_KEY_COMPONENTIDENTIFIER];
        self.logicalComponent = dict[SAVMESSAGE_MEDIAREQUEST_KEY_LOGICALCOMPONENT];
        self.serviceName = dict[SAVMESSAGE_MEDIAREQUEST_KEY_REQUESTINGSERVICE];
        self.version = dict[SAVMESSAGE_MEDIAREQUEST_KEY_VERSION];
    }
    return self;
}

- (NSString *)command
{
    return self.query;
}

- (NSString *)uri
{
    return [self mediaURIForApp:self.componentIdentifier];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    [arguments setValue:self.componentIdentifier forKey:SAVMESSAGE_MEDIAREQUEST_KEY_COMPONENTIDENTIFIER];
    [arguments setValue:self.logicalComponent forKey:SAVMESSAGE_MEDIAREQUEST_KEY_LOGICALCOMPONENT];
    [arguments setValue:self.arguments forKey:SAVMESSAGE_MEDIAREQUEST_KEY_QUERYARGUMENTS];
    [arguments setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKeyPath:SAVMESSAGE_MEDIAREQUEST_KEY_REQUESTINGUID];
    [arguments setValue:@"1" forKey:SAVMESSAGE_MEDIAREQUEST_KEY_VERSION];
    [arguments setValue:self.query forKey:SAVMESSAGE_MEDIAREQUEST_KEY_QUERY];
    return [arguments copy];
}

@end

#define SAVMESSAGE_MEDIAREQUEST_QUERY_ROOT       @"getRoot"
#define SAVMESSAGE_MEDIAREQUEST_QUERY_NOWPLAYING @"nowPlaying"
#define SAVMESSAGE_MEDIAREQUEST_QUERY_SUBMENU    @"submenu"

@interface SAVMediaRequestGenerator ()

@property NSString *componentIdentifier;
@property NSString *logicalComponent;
@property NSString *serviceName;

@end

@implementation SAVMediaRequestGenerator

+ (instancetype)mediaRequestGeneratorFromService:(SAVService *)service
{
    SAVMediaRequestGenerator *generator = [[SAVMediaRequestGenerator alloc] init];
    generator.componentIdentifier = service.component;
    generator.logicalComponent = service.logicalComponent;
    generator.serviceName = service.serviceId;
    return generator;
}

- (SAVMediaRequest *)mediaRequest
{
    SAVMediaRequest *mediaRequest = [[SAVMediaRequest alloc] init];
    mediaRequest.componentIdentifier = self.componentIdentifier;
    mediaRequest.logicalComponent = self.logicalComponent;
    mediaRequest.serviceName = self.serviceName;
    return mediaRequest;
}

- (SAVMediaRequest *)initialMenu
{
    SAVMediaRequest *mediaRequest = [self mediaRequest];
    mediaRequest.query = SAVMESSAGE_MEDIAREQUEST_QUERY_ROOT;

    if (self.serviceName)
    {
        mediaRequest.arguments = @{SAVMESSAGE_MEDIAREQUEST_KEY_REQUESTINGSERVICE: self.serviceName};
    }

    return mediaRequest;
}

- (SAVMediaRequest *)nowPlayingMenu
{
    SAVMediaRequest *mediaRequest = [self mediaRequest];
    mediaRequest.query = SAVMESSAGE_MEDIAREQUEST_QUERY_NOWPLAYING;
    return mediaRequest;
}

- (SAVMediaRequest *)mediaRequestFromNode:(NSDictionary *)node
{
    SAVMediaRequest *mediaRequest = [self mediaRequest];
    mediaRequest.title = node[SAVMESSAGE_MEDIAREQUEST_KEY_TITLE];
    mediaRequest.query = node[SAVMESSAGE_MEDIAREQUEST_KEY_QUERY];
    mediaRequest.arguments = node[SAVMESSAGE_MEDIAREQUEST_KEY_QUERYARGUMENTS];

    if (self.addSceneKey)
    {
        NSMutableDictionary *arguments = [mediaRequest.arguments mutableCopy];

        if (!arguments)
        {
            arguments = [NSMutableDictionary dictionary];
        }

        arguments[@"isScene"] = @YES;

        mediaRequest.arguments = [arguments copy];
    }

    return mediaRequest;
}

- (SAVMediaRequest *)mediaRequestFromNode:(NSDictionary *)node withSearchTerm:(NSString *)searchTerm
{
    SAVMediaRequest *mediaRequest = [self mediaRequestFromNode:node];

    if ([searchTerm length])
    {
        NSMutableDictionary *args = [mediaRequest.arguments mutableCopy];

        if (!args)
        {
            args = [NSMutableDictionary dictionary];
        }

        [args setObject:searchTerm forKey:@"search"];
        mediaRequest.arguments = [args copy];
    }

    return mediaRequest;
}

- (SAVMediaRequest *)mediaSubmenuRequestFromNode:(NSDictionary *)node
{
    SAVMediaRequest *mediaRequest = [self mediaRequestFromNode:node];
    mediaRequest.query = SAVMESSAGE_MEDIAREQUEST_QUERY_SUBMENU;
    return mediaRequest;
}

- (SAVMediaRequest *)backCommandWithLevel:(NSUInteger)level
{
    SAVMediaRequest *mediaRequest = [self mediaRequest];
    mediaRequest.query = [NSString stringWithFormat:@"Back %lu", (unsigned long)level];
    return mediaRequest;
}

@end

#pragma mark - DIS

@implementation SAVDISRequest

- (instancetype)initWithApp:(NSString *)app request:(NSString *)request arguments:(NSDictionary *)arguments
{
    NSParameterAssert(app);
    NSParameterAssert(request);

    self = [super init];

    if (self)
    {
        self.app = app;
        self.request = request;
        self.arguments = arguments;
    }

    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_DIS_REQUEST_KEY;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [@{SAVMESSAGE_DIS_REQUEST_KEY: self.request} mutableCopy];

    if (self.arguments)
    {
        dictionary[SAVMESSAGE_DIS_REQUESTARGS_KEY] = self.arguments;
    }

    return [dictionary copy];
}

- (NSString *)uri
{
    return [self disURIForApp:self.app];
}

@end

@interface SAVDISRequestGenerator ()

@property NSString *app;

@end

@implementation SAVDISRequestGenerator

- (instancetype)initWithApp:(NSString *)app
{
    self = [super init];

    if (self)
    {
        self.app = app;
    }

    return self;
}

- (NSArray *)feedbackStringsWithStateNames:(NSArray *)feedbackNames
{
    NSMutableArray *registrations = [NSMutableArray array];

    for (NSString *feedbackName in feedbackNames)
    {
        [registrations addObject:[NSString stringWithFormat:@"dis.%@.%@", self.app, feedbackName]];
    }

    return [registrations copy];
}

- (SAVDISRequest *)request:(NSString *)request withArguments:(NSDictionary *)arguments
{
    return [[SAVDISRequest alloc] initWithApp:self.app request:request arguments:arguments];
}

@end

@interface SAVDISFeedbackRegister ()

@property NSString *app;

@end

@implementation SAVDISFeedbackRegister

- (instancetype)initWithState:(NSString *)state
{
    self = [super init];

    if (self)
    {
        NSArray *components = [state componentsSeparatedByString:@"."];

        NSParameterAssert([components count] >= 3);

        if ([components count] >= 3)
        {
            self.app = components[1];
            self.state = [[components subarrayWithRange:NSMakeRange(2, [components count] - 2)] componentsJoinedByString:@"."];
        }
    }

    return self;
}

- (NSString *)uri
{
    return [self disURIForApp:self.app];
}

@end

@implementation SAVDISFeedbackUnregister

- (NSString *)command
{
    return SAVMESSAGE_STATE_UNREGISTER_COMMAND;
}

@end

@implementation SAVDISFeedback

- (instancetype)initWithApp:(NSString *)app state:(NSString *)state value:(id)value
{
    self = [super init];

    if (self)
    {
        self.app = app;
        self.state = state;
        self.value = value;
    }

    return self;
}

- (NSString *)scope
{
    return [NSString stringWithFormat:@"dis.%@.%@", self.app, self.state];
}

- (NSString *)uri
{
    return [self disURIForApp:self.app];
}

@end

@interface SAVDISResults ()

@property NSString *name;
@property NSString *scope;

@end

@implementation SAVDISResults

- (instancetype)initWithApp:(NSString *)app request:(NSString *)request results:(NSDictionary *)results
{
    self = [super init];

    if (self)
    {
        self.app = app;
        self.request = request;
        self.results = results;
    }

    return self;
}

- (NSString *)command
{
    return SAVMESSAGE_DIS_REQUEST;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if (self.request)
        dict[SAVMESSAGE_DIS_REQUEST_KEY] = self.request;
    if (self.results)
        dict[SAVMESSAGE_DIS_RESULTS_KEY] = self.results;

    return [NSDictionary dictionaryWithDictionary: dict];
}

- (NSString *)uri
{
    return [self disURIForApp:self.app];
}

@end

@implementation SAVCameraStreamRequest

- (void)setAction:(SAVCameraStreamAction)action
{
    _action = action;

    switch (action)
    {
        case SAVCameraStreamAction_StartFetch:
            self.command = @"startFetch";
            break;
        case SAVCameraStreamAction_StopFetch:
            self.command = @"stopFetch";
            break;
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    if (self.action == SAVCameraStreamAction_StartFetch)
    {
        return @{@"frequency": @(self.frequency), @"large": @(self.isLarge)};
    }
    else
    {
        return @{@"frequency": @(self.frequency)};
    }
}

- (NSString *)uri
{
    return [NSString stringWithFormat:@"cameras/%@-%@/%@", self.component, self.logicalComponent, self.command];
}

@end

@implementation SAVLogUploadRequest

- (NSString *)uri {
    return [self logUploadURI];
}

- (NSDictionary *) dictionaryRepresentation {
    return @{};
}

@end

#define SAV_BINARYTRANSFER_KEY_URI @"URI"
#define SAV_BINARYTRANSFER_KEY_PAYLOAD @"payload"

@interface SAVBinaryTransfer ()

@property NSData *data;
@property NSString *internalURI;
@property id payload;

@end

@implementation SAVBinaryTransfer

- (instancetype)initWithData:(NSData *)data uri:(NSString *)uri payload:(id)payload
{
    self = [super init];

    if (self)
    {
        self.data = data;
        self.internalURI = uri;
        self.payload = payload;
    }

    return self;
}

- (NSString *)uri
{
    return self.internalURI;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setValue:self.internalURI forKey:SAV_BINARYTRANSFER_KEY_URI];
    [dictionary setValue:self.payload forKey:SAV_BINARYTRANSFER_KEY_PAYLOAD];
    return [dictionary copy];
}

- (BOOL)requiresBinaryTransfer
{
    return YES;
}

@end
