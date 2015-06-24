//
//  UIDevice+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, SAVDeviceTypeAndOrientation)
{
    SAVDeviceTypeIphoneOrientationPortrait,
    SAVDeviceTypeIphoneOrientationLandscape,
    SAVDeviceTypeIpadOrientationPortrait,
    SAVDeviceTypeIpadOrientationLandscape,
};

@interface UIDevice (SAVExtensions)

+ (BOOL)isRealDevice;

+ (BOOL)isSimulator;

+ (BOOL)isTerribleDevice;

+ (BOOL)isPad;

+ (BOOL)isPhone;

+ (BOOL)isTallPhone;
+ (BOOL)isShortPhone;
+ (BOOL)isBigPhone;
+ (BOOL)isPhablet;

+ (SAVDeviceTypeAndOrientation)deviceTypeAndOrientation;

+ (NSTimeInterval)rotationSpeed;

+ (UIInterfaceOrientation)interfaceOrientation;

+ (CGFloat)statusBarHeight;

+ (BOOL)isIOS9OrLater;

+ (NSUInteger)osMajorVersion;

- (NSString *)sav_modelVersion;

- (NSString *)currentSSID;

@end
