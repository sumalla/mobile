//
//  SCUNotifications.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNotificationManager.h"
#import "SCUBackgroundHandler.h"
#import "SCUInterface.h"
#import "SCUMainViewController.h"
#import "SCUAppDelegate.h"
#import "SCUClimateServiceViewController.h"
#import "SCUBannerView.h"
#import "SCUTabBarController.h"
#import "SCUNotificationBannerManager.h"
#import "SCUTemperatureViewController.h"

#import <SavantControl/SavantControlPrivate.h>

static NSString *const SCUNotificationManagerHasRegistered = @"SCUNotificationManagerHasRegistered";

static NSString *const SAVNotificationPayloadDataKey = @"data";
static NSString *const SAVNotificationPayloadMessageKey = @"message";
static NSString *const SAVNotificationPayloadRoomKey = @"room";
static NSString *const SAVNotificationPayloadZoneKey = @"zone";
static NSString *const SAVNotificationPayloadTimeKey = @"time";
static NSString *const SAVNotificationPayloadServiceKey = @"service";
static NSString *const SAVNotificationPayloadServiceAliasKey = @"serviceAlias";
static NSString *const SAVNotificationPayloadHomeIDKey = @"homeId";
static NSString *const SAVNotificationPayloadTypeKey = @"type";
static NSString *const SAVNotificationPayloadStateKey = @"state";

static NSString *const SAVNotificationPayloadEntertainment = @"entertainment";
static NSString *const SAVNotificationPayloadLighting      = @"lighting";
static NSString *const SAVNotificationPayloadTemperature   = @"temperature";
static NSString *const SAVNotificationPayloadHumidity      = @"humidity";

@interface SCUNotificationManager () <DiscoveryDelegate, SCUBackgroundHandlerDelegate>

@property (nonatomic, getter = isRunning) BOOL running;
@property (nonatomic, getter = isRegistered) BOOL registered;
@property (nonatomic) NSData *purgatoryPushNotificationID;
@property (nonatomic) NSArray *allSystems;
@property (nonatomic) NSDictionary *heldData;
@property (nonatomic) NSString *heldActionIdentifier;
@property (nonatomic) SCUNotificationBannerManager *bannerManager;

@end

@implementation SCUNotificationManager

+ (instancetype)sharedInstance
{
    static SCUNotificationManager *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCUNotificationManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.bannerManager = [[SCUNotificationBannerManager alloc] init];
        [[SCUBackgroundHandler sharedInstance] addDelegate:self];
    }
    
    return self;
}

- (BOOL)areNotificationsAllowed
{
    return NO;
}

- (void)start:(BOOL)force
{
    if (self.isRunning)
    {
        return;
    }

    BOOL registerNotifications = NO;

    if (force)
    {
        registerNotifications = YES;

        [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
            [defaults setBool:YES forKey:SCUNotificationManagerHasRegistered];
        }];
    }
    else
    {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SCUNotificationManagerHasRegistered])
        {
            registerNotifications = YES;
        }
    }

    if (registerNotifications)
    {
        self.running = YES;

        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
        
        [self registerClientIfNecessary];
    }
}

- (void)registerClientIfNecessary
{
    SAVWeakSelf;
    [[SavantControl sharedControl].notificationManager registerClientIfNecessary:^(BOOL success, BOOL wasNecessary) {
        
        SAVStrongWeakSelf;
        sSelf.registered = success;
        
        if (success && wasNecessary && [[SavantControl sharedControl] cloudUser])
        {
            //-------------------------------------------------------------------
            // Login to post the new notification id. This is hacky and should be
            // changed.
            //-------------------------------------------------------------------
            [[SavantControl sharedControl] loginAsCloudUser:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                ;
            }];
        }
        
        if (success && sSelf.purgatoryPushNotificationID)
        {
            [[SavantControl sharedControl].notificationManager startWithToken:self.purgatoryPushNotificationID];
            self.purgatoryPushNotificationID = nil;
        }
    }];
}

- (void)updatePushNotificationToken:(NSData *)tokenData
{
    if ([tokenData length])
    {
        if (self.isRegistered)
        {
            [[SavantControl sharedControl].notificationManager startWithToken:tokenData];
        }
        else
        {
            self.purgatoryPushNotificationID = tokenData;
        }
    }
}

#pragma mark - DiscoveryDelegate methods

- (void)discoveryDidUpdateSystemList:(SAVDiscovery *)discovery
{
    NSDictionary *systemList = [SavantControl sharedControl].systemList;
    
    NSMutableArray *combinedSystems = [NSMutableArray array];
    
    NSArray *cloudSystems = systemList[SAVDiscoveryCloudSystemsKey];
    
    if ([cloudSystems count])
    {
        [combinedSystems addObjectsFromArray:cloudSystems];
    }
    
    NSArray *localSystems =  systemList[SAVDiscoveryLocalSystemsKey];
    
    if ([localSystems count])
    {
        [combinedSystems addObjectsFromArray:localSystems];
    }
    
    self.allSystems = [combinedSystems copy];
}

#pragma mark - SCUBackgroundHandler methods

- (void)backgroundHandlerEnterBackground
{

}

- (void)backgroundHandlerEnterForeground
{
    if (!self.isRegistered)
    {
        self.running = NO;
        [self start:YES];
    }
}

#pragma mark - notification handling

- (void)handleRemoteNotification:(NSDictionary *)notification withActionIdentifier:(NSString *)identifier
{
    NSDictionary *data = notification[SAVNotificationPayloadDataKey];
    
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive))
    {
        [self presentBannerWithData:data];
    }
    else
    {
        [self actOnNotificationWithPayload:data actionIdentifer:identifier immediately:NO];
    }
}

- (void)presentBannerWithData:(NSDictionary *)data
{
    SAVWeakSelf;
    [self.bannerManager presentBannerWithInfo:data interactionHandler:^{
        [wSelf bannerButtonPressedWithData:data];
    }];
}

- (void)bannerButtonPressedWithData:(NSDictionary *)data
{
    [self actOnNotificationWithPayload:data actionIdentifer:nil immediately:YES];
}

- (void)actOnNotificationWithPayload:(NSDictionary *)data actionIdentifer:(NSString *)identifier immediately:(BOOL)immediately
{
    NSString *homeID = data[SAVNotificationPayloadHomeIDKey];
    
    if ((![SavantControl sharedControl].credentialManager.cloudEmail) || (!homeID))
    {
        return;
    }
    
    if ([homeID isEqualToString:[SavantControl sharedControl].currentSystem.homeID])
    {
        [self navigateWithNotificationData:data immediately:immediately];
    }
    else
    {
        void (^connectBlock)(SAVSystem *system) = ^(SAVSystem *system) {
            [[SCUMainViewController sharedInstance] presentLoadingScreenWithName:system.name];
            [[SCUInterface sharedInstance] teardownInstance];
            [[SavantControl sharedControl] disconnect];
            [[SavantControl sharedControl] connectToSystem:system];
            dispatch_async_main(^{
                [self navigateWithNotificationData:data immediately:NO];
            });
        };

        SAVSystem *system = nil;

        for (SAVSystem *savedSystem in [[SavantControl sharedControl] savedSystems])
        {
            if ([savedSystem.homeID isEqualToString:homeID])
            {
                system = savedSystem;
                break;
            }
        }

        if (system)
        {
            connectBlock(system);
            return;
        }

        [[SavantControl sharedControl] cloudHomesWithCompletionHandler:^(BOOL success, NSArray *systems, NSError *error) {
            if (success && [systems count])
            {
                NSString *homeID = data[SAVNotificationPayloadHomeIDKey];

                NSArray *matchingSystem = [systems arrayByMappingBlock:^id(SAVSystem *system) {

                    if ([system.homeID isEqualToString:homeID])
                    {
                        return system;
                    }

                    return nil;
                }];

                if ([matchingSystem count])
                {
                    SAVSystem *match = [matchingSystem firstObject];
                    connectBlock(match);
                }
                else
                {
                    //display error message?
                    [[SCUInterface sharedInstance] teardownInstance];
                    [[SavantControl sharedControl] disconnect];
                    [[SCUMainViewController sharedInstance] presentSplashScreen];
                }
            }
        }];
    }
}

- (void)navigateWithNotificationData:(NSDictionary *)data immediately:(BOOL)immediately
{
    NSString *type = [NSNull nilOrIdentityFromObject:data[SAVNotificationPayloadTypeKey]];
    
    if ([type isEqualToString:SAVNotificationPayloadLighting])
    {
        [self navigateToLighting:data immediately:immediately];
    }
    else if ([type isEqualToString:SAVNotificationPayloadTemperature])
    {
        [self navigateToClimateTemp:data immediately:immediately];
    }
    else if ([type isEqualToString:SAVNotificationPayloadHumidity])
    {
        [self navigateToClimateHumidity:data immediately:immediately];
    }
    else if ([type isEqualToString:SAVNotificationPayloadEntertainment])
    {
        [self navigateToEntertainmentService:data immediately:immediately];
    }
}

- (void)navigateToLighting:(NSDictionary *)data immediately:(BOOL)immediately
{
    NSString *serviceString = [NSNull nilOrIdentityFromObject:data[SAVNotificationPayloadServiceKey]];
    SAVService *service = [[SAVService alloc] initWithString:serviceString queryService:NO];
    [self presentService:service immediately:immediately];
}

- (void)navigateToClimateTemp:(NSDictionary *)data immediately:(BOOL)immediately
{
    NSString *serviceString = [NSNull nilOrIdentityFromObject:data[SAVNotificationPayloadServiceKey]];
    SAVService *service = [[SAVService alloc] initWithString:serviceString queryService:NO];
    
    [SCUInterface sharedInstance].notificationClimateServiceType = data[SAVNotificationPayloadTypeKey];
    
    [self presentService:service immediately:immediately];
}

- (void)navigateToClimateHumidity:(NSDictionary *)data immediately:(BOOL)immediately
{
    NSString *serviceString = [NSNull nilOrIdentityFromObject:data[SAVNotificationPayloadServiceKey]];
    SAVService *service = [[SAVService alloc] initWithString:serviceString queryService:NO];
    
    [SCUInterface sharedInstance].notificationClimateServiceType = data[SAVNotificationPayloadTypeKey];
    
    [self presentService:service immediately:immediately];
}

- (void)navigateToEntertainmentService:(NSDictionary *)data immediately:(BOOL)immediately
{
    NSString *serviceString = [NSNull nilOrIdentityFromObject:data[SAVNotificationPayloadServiceKey]];
    SAVService *service = [[SAVService alloc] initWithString:serviceString queryService:NO];
    
    if ([data[SAVNotificationPayloadStateKey] isEqualToString:@"on"])
    {
        [self presentService:service immediately:immediately];
    }
}

- (void)presentService:(SAVService *)service immediately:(BOOL)immediately
{
    [SCUInterface sharedInstance].currentServiceFromNotification = service;

    if (immediately)
    {
        [[SCUInterface sharedInstance] presentNotificationService];
    }
}

@end
