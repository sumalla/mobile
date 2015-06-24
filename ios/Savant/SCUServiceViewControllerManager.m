//
//  SCUServiceViewControllerManager.m
//  Prototype
//
//  Created by Nathan Trapp on 3/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUServiceViewControllerManager.h"
#import "SCUServiceViewController.h"
#import "SCUSceneServiceViewController.h"
@import SDK;

@implementation SCUServiceViewControllerManager

+ (SCUServiceViewController *)viewControllerForService:(SAVService *)service
{
    SCUServiceViewController *serviceVC = nil;

    if (![service.serviceId isEqualToString:@"SVC_INFO_SMARTVIEWTILING"])
    {
        serviceVC = [[[[self class] serviceViewControllerForService:service formatString:@""] alloc] initWithService:service];
    }

    return serviceVC;
}

+ (SCUSceneServiceViewController *)sceneServiceViewControllerForServiceGroup:(SAVServiceGroup *)serviceGroup scene:(SAVScene *)scene
{
    return [[self class] sceneServiceViewControllerForService:[serviceGroup.services firstObject] scene:scene];
}

+ (SCUSceneServiceViewController *)sceneServiceViewControllerForService:(SAVService *)service scene:(SAVScene *)scene
{
    return [[[[self class] serviceViewControllerForService:service formatString:@"Scene"] alloc] initWithScene:scene
                                                                                               service:service
                                                                                          sceneService:[scene sceneServiceForService:service]];
}

+ (BOOL)hasViewControllerForSerivce:(SAVService *)service
{
    return [self serviceViewControllerForService:service formatString:@""] ? YES : NO;
}

+ (Class)serviceViewControllerForService:(SAVService *)service formatString:(NSString *)formatPrefix
{
    NSString *className = [NSString stringWithFormat:@"SCU%@%@ServiceViewController", formatPrefix, [[self class] serviceTypeForService:service]];
    if (!NSClassFromString(className)) {
        className = [NSString stringWithFormat:@"Savant.%@%@ServiceViewController", formatPrefix, [[self class] serviceTypeForService:service]];
    }
    
    return DeviceClassFromClass(NSClassFromString(className));
}

+ (NSString *)serviceTypeForService:(SAVService *)service
{
    NSString *serviceType = [service.displayName stringByReplacingOccurrencesOfString:@" " withString:@""];

    // Overrides
    if ([service.serviceId isEqualToString:@"SVC_AV_LIVEMEDIAQUERY"])
    {
        serviceType = nil;
    }
    else if ([service.serviceId containsString:@"SVC_AV_LIVEMEDIAQUERY_XBMC"] ||
             [service.serviceId isEqualToString:@"SVC_AV_LIVEMEDIAQUERY_KSCAPE"])
    {
        serviceType = @"GenericMedia";
    }
    else if ([service.serviceId containsString:@"SVC_AV_LIVEMEDIAQUERY"] ||
             [service.serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"])
    {
        serviceType = @"Media";
    }
    else if ([service.serviceId containsString:@"SVC_AV_ENHANCEDDVD"])
    {
        serviceType = @"DVD";
    }
    else if ([service.serviceId containsString:@"SVC_AV_TV"] ||
             [service.serviceId containsString:@"SVC_AV_SATELLITETV"])
    {
        serviceType = @"TV";
    }
    else if ([service.serviceId containsString:@"SVC_AV_SACD"])
    {
        serviceType = @"CD";
    }
    else if ([service.serviceId isEqualToString:@"SVC_AV_SATELLITERADIO"])
    {
        serviceType = @"SatelliteRadio";
    }
    else if ([service.serviceId containsString:@"SVC_ENV_SHADE"])
    {
        serviceType = @"Lighting";
    }
    else if ([service.serviceId containsString:@"SVC_ENV_SECURITYCAMERA"])
    {
        serviceType = @"Security";
    }
    else if ([serviceType isEqualToString:@"VideoTiling"])
    {
        serviceType = @"Tiling";
    }
    else if ([serviceType isEqualToString:@"WebView"])
    {
        serviceType = @"Web";
    }
    else if ([service.serviceId containsString:@"SVC_AV_SURVEILLANCESYSTEM"])
    {
        serviceType = @"Surveillance";
    }
    else if ([service.serviceId containsString:@"SVC_ENV_POOLANDSPA"])
    {
        serviceType = @"Pool";
    }
    else if ([service.serviceId containsString:@"SVC_ENV_HOMEMONITOR"]) {
        serviceType = @"HomeMonitor";
    }

    return serviceType;
}

@end
