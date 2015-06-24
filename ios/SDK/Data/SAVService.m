//
//  SAVService.m
//  SavantControl
//
//  Created by Ian Mortimer on 12/4/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

#import "SAVServicePrivate.h"
@import Extensions;
#import "SAVControl.h"
#import "SAVRequestCache.h"
#import "SAVMutableService.h"
#import "Savant.h"

@interface SAVService ()

@property (nonatomic, nonnull) NSString *internalDisplayName;
@property (nonatomic) BOOL hashIsDirty;
@property (nonatomic) NSUInteger cachedHash;

@end

@implementation SAVService

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.hashIsDirty = YES;
    }

    return self;
}

- (instancetype)initWithZone:(NSString *)zone
                   component:(NSString *)component
            logicalComponent:(NSString *)logicalComponent
                   variantId:(NSString *)variantId
                   serviceId:(NSString *)serviceId
                       alias:(NSString *)alias
                serviceAlias:(NSString *)serviceAlias
                 connectorId:(NSString *)connectorId
                capabilities:(NSArray *)capabilities
                    avioType:(SAVServiceAVIOType)avioType
                  outputType:(SAVServiceOutputType)outputType
              discreteVolume:(BOOL)discreteVolume
                      hidden:(BOOL)hidden
{
    self = [self init];

    if (self)
    {
        self.zoneName = zone;
        self.component = component;
        self.logicalComponent = logicalComponent;
        self.variantId = variantId;
        self.serviceId = serviceId;
        self.alias = alias;
        self.serviceAlias = serviceAlias;
        self.connectorId = connectorId;
        self.capabilities = capabilities;
        self.avioType = avioType;
        self.outputType = outputType;
        self.discreteVolume = discreteVolume;
        self.hidden = hidden;
    }

    return self;
}

- (instancetype)initWithZone:(NSString *)zone
                   component:(NSString *)component
            logicalComponent:(NSString *)logicalComponent
                   variantId:(NSString *)variantId
                   serviceId:(NSString *)serviceId
{
    self = [self initWithZone:zone
                    component:component
             logicalComponent:logicalComponent
                    variantId:variantId
                    serviceId:serviceId
                        alias:nil
                 serviceAlias:nil
                  connectorId:nil
                 capabilities:nil
                     avioType:SAVServiceAVIOTypeUnknown
                   outputType:SAVServiceOutputTypeNone
               discreteVolume:NO
                       hidden:NO];

    return self;
}

- (instancetype)initWithString:(NSString *)serviceString
{
    return [self initWithString:serviceString queryService:YES];
}

- (id)initWithString:(NSString *)serviceString queryService:(BOOL)query
{
    self = [self init];

    if (self)
    {
        NSArray *serviceComponents = [serviceString componentsSeparatedByString:@"-"];

        if ([serviceComponents count] == 5)
        {
            self.zoneName = serviceComponents[0];
            self.component = serviceComponents[1];
            self.logicalComponent = serviceComponents[2];
            self.variantId = serviceComponents[3];
            self.serviceId = serviceComponents[4];

            //-------------------------------------------------------------------
            // Attempt to query the full service
            //-------------------------------------------------------------------
            if (query && [self.component length] && [self.logicalComponent length] && [self.serviceId length] && ![self.serviceId hasPrefix:@"SVC_ENV"])
            {
                return [[[Savant data] servicesFilteredByService:self] lastObject];
            }
        }
    }
    
    return self;
}

+ (NSString *)iconNameForServiceID:(NSString *)serviceID
{
    return [[[self class] displayNameForServiceID:serviceID] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

+ (NSString *)displayNameForServiceID:(NSString *)serviceId
{
    NSString *displayName = nil;

    if ([[self class] serviceID:serviceId
              matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY"]
           includeAudioVariants:YES])
    {
        displayName = @"Squeezebox";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_AJA"]
                includeAudioVariants:YES])
    {
        displayName = @"Aja";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_APPLEREMOTEMEDIASERVER",
                                       @"SVC_AV_LIVEMEDIAQUERY_DAAP"]
                includeAudioVariants:YES])
    {
        displayName = @"Apple TV";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_GENERALAUDIO"]
                includeAudioVariants:NO])
    {
        displayName = @"Audio";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_ENHANCEDDVD"]
                includeAudioVariants:YES])
    {
        displayName = @"Bluray";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_TV"]
                includeAudioVariants:YES])
    {
        displayName = @"Cable TV";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_CD"]
                includeAudioVariants:NO])
    {
        displayName = @"CD";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_HVAC"]
                includeAudioVariants:NO])
    {
        displayName = @"Climate";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_CCTV"]
                includeAudioVariants:NO])
    {
        displayName = @"Closed Circuit TV";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_DVD"]
                includeAudioVariants:YES])
    {
        displayName = @"DVD";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_ENERGYMONITOR"]
                includeAudioVariants:NO])
    {
        displayName = @"Energy Monitor";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_GAME"]
                includeAudioVariants:YES])
    {
        displayName = @"Game";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_HDMI"]
                includeAudioVariants:YES])
    {
        displayName = @"HDMI";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_DVI"]
                includeAudioVariants:YES])
    {
        displayName = @"DVI";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_COMM_TELEPHONY_INTERCOM"]
                includeAudioVariants:NO])
    {
        displayName = @"Intercom";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_IPOD",
                                       @"SVC_AV_LIVEMEDIAQUERY_IPOD",
                                       @"SVC_AV_SAVANTIPODDOCK"]
                includeAudioVariants:YES])
    {
        displayName = @"iPod";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_DIGITALAUDIO"]
                includeAudioVariants:NO])
    {
        displayName = @"iTunes";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_KSCAPEMETADATAAUDIOMEDIASERVER",
                                       @"SVC_AV_LIVEMEDIAQUERY_KSCAPE"]
                includeAudioVariants:YES])
    {
        displayName = @"KScape";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_LASTFM"]
                includeAudioVariants:NO])
    {
        displayName = @"LastFM";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_LIGHTING"]
                includeAudioVariants:NO])
    {
        displayName = @"Lighting";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_HOMEMONITOR"]
                includeAudioVariants:NO])
    {
        displayName = @"Monitor";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_PANDORA"]
                includeAudioVariants:NO])
    {
        displayName = @"Pandora";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_POOLANDSPA"]
                includeAudioVariants:NO])
    {
        displayName = @"Pool And Spa";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_AMRADIO",
                                       @"SVC_AV_FMRADIO",
                                       @"SVC_AV_MULTIBANDRADIO",
                                       @"SVC_AV_SATELLITERADIO"]
                includeAudioVariants:NO])
    {
        displayName = @"Radio";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_RHAPSODY"]
                includeAudioVariants:NO])
    {
        displayName = @"Rhapsody";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_SACD"]
                includeAudioVariants:NO])
    {
        displayName = @"SACD";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_SATELLITETV"]
                includeAudioVariants:YES])
    {
        displayName = @"Satellite TV";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIA",
                                       @"SVC_AV_LIVEMEDIAQUERY_VIDEOPLAYER"]
                includeAudioVariants:YES])
    {
        displayName = @"Savant Media Server";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_SECURITYSYSTEM",
                                       @"SVC_ENV_USERLOGIN_SECURITYSYSTEM"]
                includeAudioVariants:NO])
    {
        displayName = @"Security";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_SECURITYCAMERA"]
                includeAudioVariants:NO])
    {
        displayName = @"Security Camera";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_SURVEILLANCESYSTEM"]
                includeAudioVariants:NO])
    {
        displayName = @"Security DVR";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_SHADE"]
                includeAudioVariants:NO])
    {
        displayName = @"Shades";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SIRIUS"]
                includeAudioVariants:NO])
    {
        displayName = @"SiriusXM";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SLACKER"]
                includeAudioVariants:NO])
    {
        displayName = @"Slacker";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SPOTIFY"]
                includeAudioVariants:NO])
    {
        displayName = @"Spotify";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_SETTINGS_STEREO"]
                includeAudioVariants:NO])
    {
        displayName = @"Stereo Sound";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_SETTINGS_SURROUNDSOUND"]
                includeAudioVariants:NO])
    {
        displayName = @"Surround Sound";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_COMM_TELEPHONY_PHONE"]
                includeAudioVariants:NO])
    {
        displayName = @"Telephony";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_TIDAL"]
                includeAudioVariants:NO])
    {
        displayName = @"Tidal";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_TUNEIN"]
                includeAudioVariants:NO])
    {
        displayName = @"TuneIn";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_VGA"]
                includeAudioVariants:YES])
    {
        displayName = @"VGA";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_VCR"]
                includeAudioVariants:YES])
    {
        displayName = @"VHS";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_GENERALVIDEO"]
                includeAudioVariants:NO])
    {
        displayName = @"Video";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_COMM_CONFERENCE"]
                includeAudioVariants:NO])
    {
        displayName = @"Video Conference";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_SETTINGS_VIDEO"]
                includeAudioVariants:NO])
    {
        displayName = @"Video Settings";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_INFO_SMARTVIEWTILING"]
                includeAudioVariants:NO])
    {
        displayName = @"Video Tiling";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_WEATHER"]
                includeAudioVariants:NO])
    {
        displayName = @"Weather";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_WEBACTIVEAUDIOSERVER",
                                       @"SVC_AV_WEBACTIVEVIDEOSERVER"]
                includeAudioVariants:NO])
    {
        displayName = @"Web View";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_LIVEMEDIAQUERY_XBMC"]
                includeAudioVariants:YES])
    {
        displayName = @"XBMC";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_EXTERNALMEDIASERVER"]
                includeAudioVariants:YES])
    {
        displayName = @"Generic Media";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_ENV_GENERALTRIGGERCONTROLLEDDEVICE", @"SVC_ENV_GENERALRELAYCONTROLLEDDEVICE"]
                includeAudioVariants:NO])
    {
        displayName = @"Trigger";
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_GEN_GENERIC"]
                includeAudioVariants:NO])
    {
        displayName = @"Commands";
    }

    if (!displayName)
    {
        displayName = @"";
    }

    return displayName;
}

+ (SAVServiceTypeForDynamicCommandOrder)SAVServiceTypeForServiceID:(NSString *)serviceId
{
    SAVServiceTypeForDynamicCommandOrder serviceType = SAVServiceTypeForDynamicCommandOrderUnknown;

    if ([[self class] serviceID:serviceId
              matchesServiceIDs:@[@"SVC_AV_ENHANCEDDVD",
                                  @"SVC_AV_DVD",
                                  @"SVC_AV_CD",
                                  @"SVC_AV_SACD",
                                  @"SVC_AV_VCR"]
           includeAudioVariants:YES])
    {
        serviceType = SAVServiceTypeForDynamicCommandOrderDVDMedia;
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_TV",
                                       @"SVC_AV_SATELLITETV"]
                includeAudioVariants:YES])
    {
        serviceType = SAVServiceTypeForDynamicCommandOrderTV;
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_CCTV",
                                       @"SVC_ENV_SECURITYSYSTEM",
                                       @"SVC_ENV_USERLOGIN_SECURITYSYSTEM",
                                       @"SVC_ENV_SECURITYCAMERA",
                                       @"SVC_AV_SURVEILLANCESYSTEM"]
                includeAudioVariants:YES])
    {
        serviceType = SAVServiceTypeForDynamicCommandOrderSecurity;
    }
    else if ([[self class] serviceID:serviceId
                   matchesServiceIDs:@[@"SVC_AV_APPLEREMOTEMEDIASERVER",
                                       @"SVC_AV_LIVEMEDIAQUERY_DAAP",
                                       @"SVC_AV_GENERALAUDIO",
                                       @"SVC_AV_IPOD",
                                       @"SVC_AV_LIVEMEDIAQUERY_IPOD",
                                       @"SVC_AV_SAVANTIPODDOCK",
                                       @"SVC_AV_DIGITALAUDIO",
                                       @"SVC_AV_KSCAPEMETADATAAUDIOMEDIASERVER",

                                       @"SVC_AV_AMRADIO",
                                       @"SVC_AV_FMRADIO",
                                       @"SVC_AV_MULTIBANDRADIO",
                                       @"SVC_AV_SATELLITERADIO",

                                       @"SVC_AV_LIVEMEDIAQUERY",
                                       @"SVC_AV_LIVEMEDIAQUERY_AJA",
                                       @"SVC_AV_LIVEMEDIAQUERY_KSCAPE",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_LASTFM",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_PANDORA",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_RHAPSODY",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIA",
                                       @"SVC_AV_LIVEMEDIAQUERY_VIDEOPLAYER",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SIRIUS",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SLACKER",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SPOTIFY",
                                       @"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_TUNEIN",
                                       @"SVC_AV_LIVEMEDIAQUERY_XBMC",

                                       @"SVC_AV_WEBACTIVEAUDIOSERVER",
                                       @"SVC_AV_WEBACTIVEVIDEOSERVER",
                                       @"SVC_AV_EXTERNALMEDIASERVER",

                                       @"SVC_SETTINGS_STEREO",
                                       @"SVC_SETTINGS_SURROUNDSOUND",

                                       @"SVC_AV_GAME",
                                       @"SVC_AV_HDMI",
                                       @"SVC_AV_VGA",
                                       @"SVC_AV_GENERALVIDEO",
                                       @"SVC_SETTINGS_VIDEO",
                                       @"SVC_INFO_SMARTVIEWTILING"]
                includeAudioVariants:YES])
    {
        serviceType = SAVServiceTypeForDynamicCommandOrderDVDMedia;
    }
    //    else if ([[self class] serviceID:serviceId
    //                   matchesServiceIDs:@[@"SVC_ENV_HVAC",
    //                                       @"SVC_ENV_POOLANDSPA",
    //                                       @"SVC_ENV_WEATHER",
    //                                       @"SVC_ENV_GENERALTRIGGERCONTROLLEDDEVICE", @"SVC_ENV_GENERALRELAYCONTROLLEDDEVICE",
    //                                       @"SVC_ENV_ENERGYMONITOR",
    //                                       @"SVC_COMM_TELEPHONY_INTERCOM",
    //                                       @"SVC_ENV_LIGHTING",
    //                                       @"SVC_ENV_SHADE",
    //                                       @"SVC_COMM_TELEPHONY_PHONE",
    //                                       @"SVC_COMM_CONFERENCE"
    //                                       ]
    //                includeAudioVariants:YES])
    //    {
    //        serviceType = SAVServiceTypeForDynamicCommandOrderUnknown;
    //    }
    //    else
    //    {
    //        serviceType = SAVServiceTypeForDynamicCommandOrderUnknown;
    //    }

    return serviceType;
}

- (NSString *)serviceString
{
    return [NSString stringWithFormat:@"%@-%@-%@-%@-%@",
            self.zoneName ? self.zoneName : @"",
            self.component ? self.component : @"",
            self.logicalComponent ? self.logicalComponent : @"",
            self.variantId ? self.variantId : @"",
            self.serviceId ? self.serviceId : @""];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }

    if (![object isKindOfClass:[SAVService class]])
    {
        return NO;
    }

    return [self isEqualToService:(SAVService *)object];
}

- (BOOL)isEqualToService:(SAVService *)service
{
    if (!service)
    {
        return NO;
    }

    if (!((![self.zoneName length] && ![service.zoneName length]) || [self.zoneName isEqualToString:service.zoneName]))
    {
        return NO;
    }

    if (!((![self.component length] && ![service.component length]) || [self.component isEqualToString:service.component]))
    {
        return NO;
    }

    if (!((![self.logicalComponent length] && ![service.logicalComponent length]) || [self.logicalComponent isEqualToString:service.logicalComponent]))
    {
        return NO;
    }

    if (!((![self.variantId length] && ![service.variantId length]) || [self.variantId isEqualToString:service.variantId]))
    {
        return NO;
    }

    if (!((![self.serviceId length] && ![service.serviceId length]) || [self.serviceId isEqualToString:service.serviceId]))
    {
        return NO;
    }

    if (!((![self.connectorId length] && ![service.connectorId length]) || [self.connectorId isEqualToString:service.connectorId]))
    {
        return NO;
    }

    return YES;
}

- (BOOL)isPartiallyEqualToService:(SAVService *)service
{
    if (!service)
    {
        return NO;
    }

    if (!((![self.component length] && ![service.component length]) || [self.component isEqualToString:service.component]))
    {
        return NO;
    }

    if (!((![self.logicalComponent length] && ![service.logicalComponent length]) || [self.logicalComponent isEqualToString:service.logicalComponent]))
    {
        return NO;
    }

    if (!((![self.serviceId length] && ![service.serviceId length]) || [self.serviceId isEqualToString:service.serviceId]))
    {
        return NO;
    }

    return YES;
}

- (BOOL)matchesWildcardedService:(SAVService *)service
{
    return service &&
    (([service.zoneName isEqualToString:self.zoneName] || ![service.zoneName length]) &&
     ([service.component isEqualToString:self.component] || ![service.component length]) &&
     ([service.logicalComponent isEqualToString:self.logicalComponent] || ![service.logicalComponent length]) &&
     ([service.variantId isEqualToString:self.variantId] || ![service.variantId length]) &&
     ([service.serviceId isEqualToString:self.serviceId] || ![service.serviceId length]) &&
     ([service.connectorId isEqualToString:self.connectorId] || ![service.connectorId length]) &&
     (service.outputType == self.outputType || service.outputType == SAVServiceOutputTypeNone));
}

+ (NSArray *)services:(NSArray *)services filteredByService:(SAVService *)service
{
    return [services filteredArrayUsingBlock:^BOOL(SAVService *object) {
        return [object matchesWildcardedService:service];
    }];
}

- (void)setZoneName:(NSString *)zoneName
{
    self.hashIsDirty = YES;
    _zoneName = zoneName;
}

- (void)setComponent:(NSString *)component
{
    self.hashIsDirty = YES;
    _component = component;
}

- (void)setLogicalComponent:(NSString *)logicalComponent
{
    self.hashIsDirty = YES;
    _logicalComponent = logicalComponent;
}

- (void)setVariantId:(NSString *)variantId
{
    self.hashIsDirty = YES;
    _variantId = variantId;
}

- (void)setServiceId:(NSString *)serviceId
{
    self.hashIsDirty = YES;
    _serviceId = serviceId;
}

- (NSUInteger)hash
{
    if (self.hashIsDirty)
    {
        self.cachedHash = [self.zoneName hash] ^ [self.component hash] ^ [self.logicalComponent hash] ^ [self.variantId hash] ^ [self.serviceId hash];
        self.hashIsDirty = NO;
    }

    return self.cachedHash;
}

- (NSString *)description
{
    return [self serviceString];
}

- (NSString *)iconName
{
    return [[self class] iconNameForServiceID:self.serviceId];
}

- (NSString *)displayName
{
    if (!self.internalDisplayName)
    {
        self.internalDisplayName = [SAVService displayNameForServiceID:self.serviceId];
    }

    return self.internalDisplayName;
}

- (NSString *)uniquePresentableName
{
    NSString *uniquePresentableName = self.alias ? self.alias : self.component;

    if (!uniquePresentableName)
    {
        uniquePresentableName = @"";
    }

    return uniquePresentableName;
}

+ (BOOL)serviceID:(NSString *)serviceID matchesServiceIDs:(NSArray *)serviceIDs includeAudioVariants:(BOOL)audio
{
    BOOL match = NO;

    for (NSString *sid in serviceIDs)
    {
        if ([sid isEqualToString:serviceID])
        {
            match = YES;
            break;
        }

        if (audio)
        {
            if ([serviceID isEqualToString:[sid stringByAppendingString:@"AUDIO"]])
            {
                match = YES;
                break;
            }
        }
    }

    return match;
}

#pragma mark - Properties

- (NSArray *)commands
{
    return [[SAVRequestCache sharedInstance] commandsForService:self];
}

- (NSArray *)customCommands
{
    return [[SAVRequestCache sharedInstance] customCommandsForService:self];
}

- (NSArray *)channelCommands
{
    return [[SAVRequestCache sharedInstance] channelCommandsForService:self];
}

- (NSArray *)pageCommands
{
    return [[SAVRequestCache sharedInstance] pageCommandsForService:self];
}

- (NSArray *)numberPadCommands
{
    return [[SAVRequestCache sharedInstance] numberPadCommandsForService:self];
}

- (NSArray *)navigationCommands
{
    return [[SAVRequestCache sharedInstance] navigationCommandsForService:self];
}

- (NSArray *)dynamicCommands
{
    return [[SAVRequestCache sharedInstance] dynamicCommandsForService:self];
}

- (NSArray *)volumeCommands
{
    return [[SAVRequestCache sharedInstance] volumeCommandsForService:self];
}

- (NSArray *)powerCommands
{
    return [[SAVRequestCache sharedInstance] powerCommandsForService:self];
}

- (NSArray *)transportCommands
{
    return [[SAVRequestCache sharedInstance] transportCommandsForService:self];
}

- (NSArray *)transportBackCommands
{
    return [[SAVRequestCache sharedInstance] transportBackCommandsForService:self];
}

- (NSArray *)transportForwardCommands
{
    return [[SAVRequestCache sharedInstance] transportForwardCommandsForService:self];
}

- (NSArray *)favoriteCommands
{
    return [[SAVRequestCache sharedInstance] favoriteCommandsForService:self];
}

- (NSArray *)transportGenericCommands
{
    return [[SAVRequestCache sharedInstance] transportGenericCommandsForService:self];
}

+ (SAVServiceAVIOType)avioTypeForString:(NSString *)avioType
{
    SAVServiceAVIOType type = SAVServiceAVIOTypeUnknown;

    if ([avioType isEqualToString:@"Internal"])
    {
        type = SAVServiceAVIOTypeInternal;
    }
    else if ([avioType isEqualToString:@"Input"])
    {
        type = SAVServiceAVIOTypeInput;
    }
    if ([avioType isEqualToString:@"Output"])
    {
        type = SAVServiceAVIOTypeOutput;
    }

    return type;
}

+ (SAVServiceOutputType)outputTypeForString:(NSString *)avType
{
    SAVServiceOutputType type = SAVServiceOutputTypeNone;

    if ([avType isEqualToString:@"Audio"])
    {
        type = SAVServiceOutputTypeAudio;
    }
    if ([avType isEqualToString:@"Video"])
    {
        type = SAVServiceOutputTypeAudioVideo;
    }

    return type;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcovered-switch-default"
- (NSString *)identifier
{
    if ([self.serviceId hasPrefix:@"SVC_ENV_"])
    {
        return self.serviceId;
    }

    NSString *genericServiceID = [SAVServiceGroup genericServiceIdForServiceId:self.serviceId];

    NSString *scope = nil;

    switch (self.avioType)
    {
        case SAVServiceAVIOTypeOutput:
            scope = [NSString stringWithFormat:@"%@.%@.%@", self.component, self.logicalComponent, genericServiceID];
            break;
        case SAVServiceAVIOTypeInput:
        case SAVServiceAVIOTypeInternal:
            scope = [NSString stringWithFormat:@"%@.%@.%@", self.component, self.connectorId, genericServiceID];
            break;
        case SAVServiceAVIOTypeUnknown:
        default:
            break;
    }

    return scope;
}
#pragma clang diagnostic pop

- (NSString *)connectorId
{
    NSString *connectorId = nil;

    //-------------------------------------------------------------------
    // Wild card the connector ID as long as the avioType is Output
    //-------------------------------------------------------------------
    if (self.avioType != SAVServiceAVIOTypeOutput)
    {
        connectorId = _connectorId;
    }

    return connectorId;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    if ([self class] == [SAVService class])
    {
        return self;
    }
    else
    {
        return [[SAVService alloc] initWithZone:self.zoneName
                                      component:self.component
                               logicalComponent:self.logicalComponent
                                      variantId:self.variantId
                                      serviceId:self.serviceId
                                          alias:self.alias
                                   serviceAlias:self.serviceAlias
                                    connectorId:self.connectorId
                                   capabilities:self.capabilities
                                       avioType:self.avioType
                                     outputType:self.outputType
                                 discreteVolume:self.discreteVolume
                                         hidden:self.hidden];
    }
}

#pragma mark - NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[SAVMutableService alloc] initWithZone:self.zoneName
                                         component:self.component
                                  logicalComponent:self.logicalComponent
                                         variantId:self.variantId
                                         serviceId:self.serviceId
                                             alias:self.alias
                                      serviceAlias:self.serviceAlias
                                       connectorId:self.connectorId
                                      capabilities:self.capabilities
                                          avioType:self.avioType
                                        outputType:self.outputType
                                    discreteVolume:self.discreteVolume
                                            hidden:self.hidden];
}

+ (BOOL)isLMQService:(NSString *)serviceID
{
    return [serviceID containsString:@"SVC_AV_LIVEMEDIAQUERY"];
}

@end
