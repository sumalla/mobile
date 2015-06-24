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


#import "SAVSystem.h"

NSString *const kSAVSystemUIDKey = @"UID";
NSString *const kSAVSystemNameKey = @"name";
NSString *const kSAVSystemSchemeKey = @"scheme";
NSString *const kSAVSystemPortKey = @"port";
NSString *const kSAVSystemTypeKey = @"type";
NSString *const kSAVSystemAddressKey = @"ip";
NSString *const kSAVSystemIsRemoteKey = @"remote";
NSString *const kSAVSystemVersionKey = @"version";
NSString *const kSAVSystemIsCloudAccount = @"cloudAccount";
NSString *const kSAVSystemHasRemoteInfoKey = @"remoteEnabled";
NSString *const kSAVSystemOnboardKey = @"onboardKey";
NSString *const kSAVSystemHomeIDKey = @"homeId";
NSString *const kSAVSystemCellURLKey = @"cellUrl";
NSString *const kSAVSystemLastURLKey = @"kSAVSystemLastURLKey";
NSString *const kSAVSystemCloudOnlineKey = @"online";
NSString *const kSAVSystemNotificationsEnabledKey = @"notificationsEnabled";
NSString *const kSAVSystemNotificationsDisabledReasonKey = @"notificationsDisabledReason";
NSString *const kSAVSystemSSIDKey = @"kSAVSystemSSIDKey";

@implementation SAVSystem

@dynamic cellScheme, cellAddress, cellPort;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        self.type = -1;
    }
    
    return self;
}

- (instancetype)initWithSystemInfo:(NSDictionary *)systemInfo
{
    self = [super init];
    
    if (self)
    {
        self.hostID = systemInfo[kSAVSystemUIDKey];
        self.homeID = systemInfo[kSAVSystemHomeIDKey];
        self.name = systemInfo[kSAVSystemNameKey];
        self.localScheme = systemInfo[kSAVSystemSchemeKey];
        self.localPort = [systemInfo[kSAVSystemPortKey] integerValue];
        self.type = (systemInfo[kSAVSystemTypeKey]) ? [systemInfo[kSAVSystemTypeKey] intValue] : -1;
        self.localAddress = systemInfo[kSAVSystemAddressKey];
        self.version = [systemInfo[kSAVSystemVersionKey] unsignedIntegerValue];
        self.cloudSystem = [systemInfo[kSAVSystemIsCloudAccount] boolValue];
        self.hasRemoteAccess = [systemInfo[kSAVSystemHasRemoteInfoKey] boolValue];
        self.onboardKey = systemInfo[kSAVSystemOnboardKey];
        self.cloudOnline = [systemInfo[kSAVSystemCloudOnlineKey] boolValue];
        self.notificationsEnabled = [systemInfo[kSAVSystemNotificationsEnabledKey] boolValue];
        self.notificationsDisabledReason = systemInfo[kSAVSystemNotificationsDisabledReasonKey];
        self.SSID = systemInfo[kSAVSystemSSIDKey];
        
        NSString *cellURL = systemInfo[kSAVSystemCellURLKey];
        
        if (cellURL)
        {
            self.cellURL = [NSURL URLWithString:cellURL];
        }
        
        NSString *lastURL = systemInfo[kSAVSystemLastURLKey];
        
        if (lastURL)
        {
            self.lastURL = [NSURL URLWithString:lastURL];
        }
    }
    
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.hostID)
        dict[kSAVSystemUIDKey] = self.hostID;
    if (self.name)
        dict[kSAVSystemNameKey] = self.name;
    if (self.localScheme)
        dict[kSAVSystemSchemeKey] = self.localScheme;
    if (self.localPort != 0)
        dict[kSAVSystemPortKey] = @(self.localPort);
    if (self.type >= 0)
        dict[kSAVSystemTypeKey] = @(self.type);
    if (self.localAddress)
        dict[kSAVSystemAddressKey] = self.localAddress;
    if (self.hasRemoteAccess)
        dict[kSAVSystemHasRemoteInfoKey] = @(self.hasRemoteAccess);
    if (self.isCloudSystem)
        dict[kSAVSystemIsCloudAccount] = @(self.isCloudSystem);
    if (self.areNotificationsEnabled)
        dict[kSAVSystemNotificationsEnabledKey] = @(self.areNotificationsEnabled);
    if (self.notificationsDisabledReason)
        dict[kSAVSystemNotificationsDisabledReasonKey] = self.notificationsDisabledReason;
    if (self.homeID)
        dict[kSAVSystemHomeIDKey] = self.homeID;
    if (self.onboardKey)
        dict[kSAVSystemOnboardKey] = self.onboardKey;
    if (self.cellURL)
        dict[kSAVSystemCellURLKey] = [self.cellURL absoluteString];
    if (self.lastURL)
        dict[kSAVSystemLastURLKey] = [self.lastURL absoluteString];
    if (self.SSID)
        dict[kSAVSystemSSIDKey] = self.SSID;
    dict[kSAVSystemVersionKey] = @(self.version);
    
    return [dict copy];
}

- (NSString *)description
{
    return [[self dictionaryRepresentation] description];
}

- (void)setLocalURL:(NSURL *)localURL
{
    self.localScheme = [localURL scheme];
    self.localAddress = [localURL host];
    self.localPort = [[localURL port] integerValue];
}

- (NSURL *)localURL
{
    NSString *urlString = nil;
    
    if (self.localAddress)
    {
        urlString = [NSString stringWithFormat:@"%@://%@:%ld", self.localScheme ? self.localScheme : @"ws", self.localAddress, (long)self.localPort];
    }
    
    return [NSURL URLWithString:urlString];
}

- (NSString *)cellScheme
{
    return self.cellURL.scheme;
}

- (NSString *)cellAddress
{
    return self.cellURL.host;
}

- (NSInteger)cellPort
{
    return [self.cellURL.port integerValue];
}

@end
