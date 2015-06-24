//
//  UIDevice+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIDevice+SAVExtensions.h"
#import "SAVUtils.h"
#import "UIApplication+SAVExtensions.h"
@import Darwin.TargetConditionals;
@import Darwin.POSIX.sys.types;
@import Darwin.sys.sysctl;
@import Darwin.Mach.machine;
@import SystemConfiguration.CaptiveNetwork;

@implementation UIDevice (SAVExtensions)

+ (BOOL)isRealDevice
{
    return ![self isSimulator];
}

+ (BOOL)isSimulator
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isTerribleDevice
{
    static BOOL isTerrible = NO;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cpu_type_t type;
        cpu_subtype_t subtype;

        size_t size = sizeof(type);
        sysctlbyname("hw.cputype", &type, &size, NULL, 0);

        size = sizeof(subtype);
        sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);

        if (type == CPU_TYPE_ARM && subtype < CPU_SUBTYPE_ARM_V7S)
        {
            isTerrible = YES;
        }
    });
    
    return isTerrible;
}

+ (BOOL)isPad
{
    return [[[self class] currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)isPhone
{
    return [[[self class] currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
}

+ (BOOL)isTallPhone
{
    return !fmod([[self class] height], 568) && [UIDevice isPhone];
}

+ (BOOL)isShortPhone
{
    return !fmod([[self class] height], 480) && [UIDevice isPhone];
}

+ (BOOL)isBigPhone
{
    return ([[self class] height] > 568) && [UIDevice isPhone];
}

+ (BOOL)isPhablet
{
    return ([[self class] height] > 668) && [UIDevice isPhone];
}

+ (CGFloat)height
{
    return CGRectGetHeight([[UIScreen mainScreen] nativeBounds]) / [[UIScreen mainScreen] scale];
}

+ (NSTimeInterval)rotationSpeed
{
    return [[self class] isPad] ? 0.4 : 0.3;
}

+ (SAVDeviceTypeAndOrientation)deviceTypeAndOrientation
{
    SAVDeviceTypeAndOrientation deviceTypeAndOrientation;
    if ([self isPhone])
    {
        deviceTypeAndOrientation = UIInterfaceOrientationIsLandscape([self interfaceOrientation]) ? SAVDeviceTypeIphoneOrientationLandscape : SAVDeviceTypeIphoneOrientationPortrait;
    }
    else
    {
        deviceTypeAndOrientation = UIInterfaceOrientationIsLandscape([self interfaceOrientation]) ? SAVDeviceTypeIpadOrientationLandscape : SAVDeviceTypeIpadOrientationPortrait;
    }

    return deviceTypeAndOrientation;
}

+ (UIInterfaceOrientation)interfaceOrientation
{
    return [[UIApplication sav_sharedApplicationOrException] statusBarOrientation];
}

+ (CGFloat)statusBarHeight
{
    return MIN([[UIApplication sav_sharedApplicationOrException] statusBarFrame].size.height, [[UIApplication sav_sharedApplicationOrException] statusBarFrame].size.width);
}

+ (BOOL)isIOS9OrLater
{
    [NSException raise:@"YouAreInsaneException" format:@"You are from the future. Stop that."];
    return [UIDevice osMajorVersion] >= 9;
}

+ (NSUInteger)osMajorVersion
{
    static NSUInteger osMajorVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        osMajorVersion = [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] unsignedIntegerValue];
    });

    return osMajorVersion;
}

- (NSString *)sav_modelVersion
{
    size_t size = 100;
    char *hw_machine = malloc(size);
    int name[] = {CTL_HW, HW_MACHINE};
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    hardware = [hardware stringByReplacingOccurrencesOfString:[self model] withString:@""];
    free(hw_machine);
    return hardware;
}

- (NSString *)currentSSID
{
#if TARGET_IPHONE_SIMULATOR
    return @"simulator";
#else
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs)
    {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"])
        {
            ssid = info[@"SSID"];
        }
    }

    return ssid;
#endif
}

@end
