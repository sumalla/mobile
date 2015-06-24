//
//  SCUInterface.m
//  SavantController
//
//  Created by Nathan Trapp on 4/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUInterface.h"
#import "SCUContentViewController.h"
#import "SCUMoreActionsViewController.h"
#import "SCUGlobalNowPlayingViewController.h"
#import "SCUServiceViewController.h"
#import "SCUButton.h"
#import "SCUPopoverController.h"
#import "SCURootViewController.h"
#import "SCUSceneServiceViewController.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUPassthroughViewController.h"
#import "SCURoomDistributionViewController.h"
#import "SCUServicesFirstLightingMainController.h"
#import "SCUServicesFirstClimateMainController.h"
#import "SCUAnalytics.h"
#import "SCUVolumeListener.h"
#import "SCUVolumeModel.h"
#import "SCUBackgroundHandler.h"
#import "SCUHardButtonVolumeNotification.h"
#import "SCUNotificationsTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUHomeCollectionViewController.h"
#import "SCUHomePageCollectionViewController.h"
#import "SCUTemperatureViewController.h"

#import <SavantControl/SavantControl.h>

@interface SCUInterface () <UIPopoverControllerDelegate, ActiveServiceObserver, SCURootViewControllerDelegate, SCUVolumeListenerDelegate, SCUBackgroundHandlerDelegate, SCUVolumeModelDelegate>

@property (nonatomic) SCUContentViewController *contentViewController;
@property (nonatomic) SCUPopoverController *popoverController;
@property (getter = isInterfaceLoaded) BOOL interfaceLoaded;
@property BOOL shouldRestoreService;
@property BOOL shouldRestoreServicesFirstService;
@property BOOL currentServiceActivated;
@property (nonatomic) SCUVolumeListener *volumeListener;
@property (nonatomic) SCUVolumeModel *volumeModel;
@property (nonatomic) SAVService *currentVolumeModelService;
@property (nonatomic) SCUHardButtonVolumeNotification *volumeNotification;

@end

@implementation SCUInterface

+ (instancetype)sharedInstance
{
    static SCUInterface *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCUInterface alloc] init];
    });
    return sharedInstance;
}

#pragma mark - View Management

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [[SCUBackgroundHandler sharedInstance] addDelegate:self];
        self.volumeListener = [[SCUVolumeListener alloc] init];
        self.volumeListener.delegate = self;
    }

    return self;
}

- (void)loadInstance
{
    [self teardownInstance];

    NSString *previousRoomID = [[SAVSettings localSettings] objectForKey:@"CurrentRoom"];

    SAVRoom *currentRoom = nil;

    if (previousRoomID)
    {
        currentRoom = [[SavantControl sharedControl].data roomForRoomID:previousRoomID];
    }

    self.currentRoom = currentRoom;

    NSString *previousServiceString = [[SAVSettings localSettings] objectForKey:@"CurrentService"];

    SAVMutableService *currentService = nil;

    if (previousServiceString)
    {
        currentService = [[SAVMutableService alloc] initWithString:previousServiceString queryService:NO];

        currentService.connectorId = [[SAVSettings localSettings] objectForKey:@"CurrentServiceConnector"];
    }

    self.currentService = [currentService copy];

    self.interfaceLoaded = YES;
    self.contentViewController = [[SCUContentViewController alloc] init];
    self.currentRootViewController.delegate = self;

    [[SavantControl sharedControl].stateManager addActiveServiceObserver:self];
}

- (void)teardownInstance
{
    self.currentVolumeModelService = nil;
    self.interfaceLoaded = NO;
    [self.popoverController dismissPopoverAnimated:YES];
    self.popoverController = nil;

    [[SavantControl sharedControl].stateManager removeActiveServiceObserver:self];

    [self.contentViewController dismissViewControllerAnimated:YES completion:NULL];

    [self.contentViewController sav_removeFromParentViewController];
    self.contentViewController = nil;
}

- (void)viewDidLoad
{
    //-------------------------------------------------------------------
    // Restore previous service screen
    //-------------------------------------------------------------------
    if (self.currentService)
    {
        if ([self.currentService.serviceId hasPrefix:@"SVC_AV"])
        {
            if (self.currentRootViewController.activeVC == self.currentRootViewController.viewControllers[SCURootViewActiveTabServices])
            {
                self.shouldRestoreServicesFirstService = YES;
            }
            else
            {
                self.shouldRestoreService = YES;
            }
        }
        else
        {
            if ([self.currentService.serviceId hasPrefix:@"SVC_ENV"])
            {
                if (self.currentRootViewController.activeVC == self.currentRootViewController.viewControllers[SCURootViewActiveTabServices])
                {
                    [self presentServicesFirstService:self.currentService animated:NO];
                }
                else
                {
                    [self presentService:self.currentService animated:NO];
                }
            }
            else
            {
                [self presentService:self.currentService animated:NO];
            }
        }

        for (NSString *room in [[SavantControl sharedControl].data allRoomIds])
        {
            [self room:room didUpdateActiveService:[[SavantControl sharedControl].stateManager activeServiceForRoom:room]];
        }
    }
}

- (SCUContentViewController *)currentContentViewController
{
    return self.contentViewController;
}

- (SCUDrawerViewController *)currentDrawerViewController
{
    return [[self currentContentViewController] currentDrawerViewController];
}

- (SCURootViewController *)currentRootViewController
{
    return self.currentContentViewController.currentRootviewController;
}

- (SCUServiceViewController *)currentServiceViewController
{
    return self.currentContentViewController.currentServiceViewController;
}

#pragma mark - Navigation Bar Items

- (void)presentNotificationService
{
    if (self.currentServiceFromNotification)
    {
        if (self.currentServiceFromNotification.serviceId == nil)
        {
            return;
        }
        else
        {
            SAVService *service = self.currentServiceFromNotification;
            
            SAVService *fullService = [[SAVService alloc] initWithString:[service serviceString] queryService:YES];
            
            if (fullService)
            {
                service = fullService;
            }
            
            self.currentServiceFromNotification = nil;
            
            [[SAVSettings localSettings] setObject:@(0) forKey:[NSString stringWithFormat:@"%@.%@", SCUSavedTabsPrefix, @"rootView"]];
            [[SAVSettings localSettings] synchronize];
            
            if (self.notificationClimateServiceType)
            {
                NSInteger climateServiceVCActiveVCIdx = 0;

                if ([self.notificationClimateServiceType isEqualToString:@"humidity"])
                {
                    SCUClimateViewController *temperatureVC = [[DeviceClassFromClass([SCUTemperatureViewController class]) alloc] initWithService:service];
                    
                    if (temperatureVC.hasHVACService)
                    {
                        climateServiceVCActiveVCIdx = 1;
                    }
                }
                
                [[SAVSettings localSettings] setObject:@(climateServiceVCActiveVCIdx) forKey:[NSString stringWithFormat:@"%@.%@", SCUSavedTabsPrefix, @"SVC_ENV_HVAC"]];
                [[SAVSettings localSettings] synchronize];
                
                self.notificationClimateServiceType = nil;
            }

            BOOL presentedRooms = NO;

            if (self.currentRootViewController.activeVC != self.currentRootViewController.viewControllers[SCURootViewActiveTabRooms])
            {
                presentedRooms = YES;
                [self presentRooms];
            }

            __block NSTimeInterval delay = presentedRooms ? .35 : 0;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                BOOL presentedRoom = NO;

                if (![self.currentRoom.roomId isEqualToString:service.zoneName])
                {
                    self.currentRoom = [[SavantControl sharedControl].data roomForRoomID:service.zoneName];

                    SCUHomeCollectionViewController *homeViewController = (SCUHomeCollectionViewController *)self.currentRootViewController.activeVC;

                    if ([homeViewController isKindOfClass:[SCUHomeCollectionViewController class]])
                    {
                        SCUHomePageCollectionViewController *homePage = [[SCUHomePageCollectionViewController alloc] initWithRoom:self.currentRoom
                                                                                                                         delegate:(id<SCUHomeCollectionViewControllerDelegate>)homeViewController.model
                                                                                                                            model:(SCUHomeCollectionViewModel *)homeViewController.model];

                        [self.contentViewController presentViewController:homePage animated:YES];
                        presentedRoom = YES;
                    }
                }

                delay = presentedRoom ? .35 : 0;

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self presentService:service];
                });
            });
        }
    }
}

- (void)presentNavigation:(SCUButton *)sender
{
    if (self.currentDrawerViewController.isOpen)
    {
        dispatch_block_t completionHandler = NULL;

        if (self.currentDrawerViewController.openSide == SCUDrawerSideRight)
        {
            completionHandler = ^{
                [self.currentDrawerViewController openDrawerFromSide:SCUDrawerSideLeft animated:YES completion:NULL];
            };
        }

        [self.currentDrawerViewController closeDrawerAnimated:YES completion:completionHandler];
    }
    else
    {
        [self.currentDrawerViewController openDrawerFromSide:SCUDrawerSideLeft animated:YES completion:NULL];
    }
}

- (void)presentHomeOverview:(SCUButton *)sender
{
    [self.currentDrawerViewController closeDrawerAnimated:YES completion:NULL];
}

- (void)presentEntertainment:(SCUButton *)sender
{
    SCUGlobalNowPlayingViewController *nowPlaying = [[DeviceClassFromClass([SCUGlobalNowPlayingViewController class]) alloc] init];
    SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:nowPlaying];
    passthrough.detectUserInteraction = YES;
    passthrough.backgroundColor = [[SCUColors shared] color03shade01];

    UINavigationController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:passthrough];

    [self.contentViewController presentViewController:navController animated:YES completion:NULL];
}

- (void)presentService:(SAVService *)service
{
    [self presentService:service animated:YES];
}

- (void)presentServicesFirstService:(SAVService *)service animated:(BOOL)animated
{
    if (service)
    {
        [SCUAnalytics recordEvent:@"Service Tile Selected" withKey:@"serviceType" value:service.serviceId];

        self.currentRoom = nil;

        if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] || [service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
        {
            SCUServicesFirstLightingMainController *viewController = [[SCUServicesFirstLightingMainController alloc] initWithService:service];
            viewController.servicesFirst = YES;

            [self.contentViewController presentServiceViewController:viewController animated:YES];
        }
        else if ([service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            SCUServicesFirstClimateMainController *viewController = [[SCUServicesFirstClimateMainController alloc] initWithService:service];
            viewController.servicesFirst = YES;

            [self.contentViewController presentServiceViewController:viewController animated:YES];
        }
        else
        {
            SCUServiceViewController *serviceViewController = [self serviceViewControllerForService:service];
            serviceViewController.servicesFirst = YES;

            [self presentServicesAnimated:NO];
            [self.contentViewController presentServiceViewController:serviceViewController animated:animated];

            [self.contentViewController dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

- (void)presentServicesFirstServiceGroup:(SAVServiceGroup *)serviceGroup animated:(BOOL)animated
{
    [self presentServicesFirstService:serviceGroup.wildCardedService animated:animated];
}

- (void)presentService:(SAVService *)service animated:(BOOL)animated
{
    if (service)
    {
        [SCUAnalytics recordEvent:@"Control Screen" withKey:@"serviceType" value:service.serviceId];

        SCUServiceViewController *serviceViewController = [self serviceViewControllerForService:service];

        if (serviceViewController)
        {
            [self.contentViewController presentServiceViewController:serviceViewController animated:animated];
        }
        else
        {
            dispatch_block_t block = ^{
                [self.contentViewController leaveServiceScreenAnimated:animated];
                SCUServiceViewModel *model = [[SCUServiceViewModel alloc] initWithService:service];
                [model viewWillAppear];
            };

            if (self.currentDrawerViewController.isOpen)
            {
                [self.currentDrawerViewController closeDrawerAnimated:YES completion:block];
            }
            else
            {
                block();
            }
        }
    }
}

- (SCUSceneServiceViewController *)sceneServiceViewControllerForServiceGroup:(SAVServiceGroup *)serviceGroup scene:(SAVScene *)scene
{
    return [self sceneServiceViewControllerForService:[serviceGroup.services firstObject] scene:scene];
}

- (SCUSceneServiceViewController *)sceneServiceViewControllerForService:(SAVService *)service scene:(SAVScene *)scene
{
    return [[[self serviceViewControllerForService:service formatString:@"Scene"] alloc] initWithScene:scene
                                                                                               service:service
                                                                                          sceneService:[scene sceneServiceForService:service]];
}

- (SCUServiceViewController *)serviceViewControllerForService:(SAVService *)service
{
    SCUServiceViewController *serviceVC = nil;

    if (![service.serviceId isEqualToString:@"SVC_INFO_SMARTVIEWTILING"])
    {
        serviceVC = [[[self serviceViewControllerForService:service formatString:@""] alloc] initWithService:service];
    }

    return serviceVC;
}

- (BOOL)hasViewControllerForSerivce:(SAVService *)service
{
    return [self serviceViewControllerForService:service formatString:@""] ? YES : NO;
}

- (Class)serviceViewControllerForService:(SAVService *)service formatString:(NSString *)formatPrefix
{
    NSString *className = [NSString stringWithFormat:@"SCU%@%@ServiceViewController", formatPrefix, [self serviceTypeForService:service]];
    return DeviceClassFromClass(NSClassFromString(className));
}

- (NSString *)serviceTypeForService:(SAVService *)service
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

    return serviceType;
}

- (void)presentRoomsDistributionForServiceGroup:(SAVServiceGroup *)service
{
    if (service)
    {
        SCURoomDistributionViewController *distribution = [[SCURoomDistributionViewController alloc] initWithServiceGroup:service];
        SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:distribution];
        passthrough.backgroundColor = [[SCUColors shared] color03shade01];
        SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:passthrough];

        [self.contentViewController presentViewController:navController animated:YES completion:NULL];
    }
}

- (void)presentRooms
{
    [self presentRoomsAnimated:YES];
}

- (void)presentRoomsAnimated:(BOOL)animated
{
    self.currentRootViewController.navigationController.navigationBarHidden = NO;

    if (self.currentRootViewController.activeVC == self.currentRootViewController.viewControllers[SCURootViewActiveTabRooms])
    {
        [self.currentContentViewController.navigationController popToRootViewControllerAnimated:NO];
        [self.currentDrawerViewController closeDrawerAnimated:animated completion:NULL];
    }
    else
    {
        [SCUAnalytics recordEvent:@"Rooms Navigation"];

        [self.currentContentViewController.navigationController popToRootViewControllerAnimated:NO];
        [self.currentDrawerViewController closeDrawerAnimated:animated completion:NULL];
        self.currentRootViewController.activeVC = self.currentRootViewController.viewControllers[SCURootViewActiveTabRooms];
    }
}

- (void)presentScenes
{
    self.currentRootViewController.navigationController.navigationBarHidden = NO;

    [SCUAnalytics recordEvent:@"Scenes Navigation"];

    [self.currentContentViewController.navigationController popToRootViewControllerAnimated:NO];
    [self.currentDrawerViewController closeDrawerAnimated:YES completion:NULL];
    self.currentRootViewController.activeVC = self.currentRootViewController.viewControllers[SCURootViewActiveTabScenes];
}

- (void)presentServices
{
    [self presentServicesAnimated:YES];
}

- (void)presentServicesAnimated:(BOOL)animated
{
    self.currentRootViewController.navigationController.navigationBarHidden = NO;

    if (self.currentRootViewController.activeVC == self.currentRootViewController.viewControllers[SCURootViewActiveTabServices])
    {
        [self.currentContentViewController.navigationController popToRootViewControllerAnimated:NO];
        [self.currentDrawerViewController closeDrawerAnimated:animated completion:NULL];
    }
    else
    {
        [SCUAnalytics recordEvent:@"Services Navigation"];

        [self.currentContentViewController.navigationController popToRootViewControllerAnimated:NO];
        [self.currentDrawerViewController closeDrawerAnimated:animated completion:NULL];
        self.currentRootViewController.activeVC = self.currentRootViewController.viewControllers[SCURootViewActiveTabServices];
    }
}

- (void)presentSettings
{
    self.currentRootViewController.navigationController.navigationBarHidden = NO;
    
    [SCUAnalytics recordEvent:@"Settings Navigation"];

    [self.currentDrawerViewController closeDrawerAnimated:YES completion:NULL];
    self.currentRootViewController.activeVC = self.currentRootViewController.viewControllers[SCURootViewActiveTabSettings];
    [self.currentContentViewController.navigationController popToRootViewControllerAnimated:YES];
}

- (void)presentNotifications
{
    [SCUAnalytics recordEvent:@"Notifications Navigation"];

    [self.currentDrawerViewController closeDrawerAnimated:YES completion:NULL];
    self.currentRootViewController.navigationController.navigationBarHidden = YES;
    self.currentRootViewController.activeVC = self.currentRootViewController.viewControllers[SCURootViewActiveTabNotifications];
    [self.currentContentViewController.navigationController popToRootViewControllerAnimated:YES];
}

- (UIColor *)colorForService:(SAVService *)service
{
    return [self colorForServiceId:service.serviceId];
}

- (UIColor *)colorForServiceId:(NSString *)serviceId
{
    if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_AJA"])
    {
        // AJA
        return [UIColor sav_colorWithRGBValue:0x009ddc];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_APPLEREMOTEMEDIASERVER"] ||
             [serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_DAAP"])
    {
        // Apple TV
        return [UIColor sav_colorWithRGBValue:0x1b8af9];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_ENHANCEDDVD"])
    {
        // Bluray
        return [UIColor sav_colorWithRGBValue:0x0095d7];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_KSCAPEMETADATAAUDIOMEDIASERVER"] ||
             [serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_KSCAPE"])
    {
        // KScape
        return [UIColor sav_colorWithRGBValue:0x6694b9];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_LASTFM"])
    {
        // LastFM
        return [UIColor sav_colorWithRGBValue:0xd12127];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_PANDORA"])
    {
        // Pandora
        return [UIColor sav_colorWithRGBValue:0x32638f];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_SACD"])
    {
        // SACD
        return [UIColor sav_colorWithRGBValue:0xff7e7a];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SIRIUS"] ||
             [serviceId hasPrefix:@"SVC_AV_SATELLITERADIO"])
    {
        // Siris XM
        return [UIColor sav_colorWithRGBValue:0x005380];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SLACKER"])
    {
        // Slacker
        return [UIColor sav_colorWithRGBValue:0x0098d7];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SPOTIFY"])
    {
        // Spotify
        return [UIColor sav_colorWithRGBValue:0x81b900];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_TUNEIN"])
    {
        // TuneIn
        return [UIColor sav_colorWithRGBValue:0x36b4a7];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_TIDAL"])
    {
        // Tidal
        return [UIColor sav_colorWithRGBValue:0x00ffff];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIA"] ||
             [serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_VIDEOPLAYER"])
    {
        // SMS - Savant Services Default Color
        return [UIColor sav_colorWithRGBValue:0xff5f00];
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY"])
    {
        // Squeezebox
        return [UIColor sav_colorWithRGBValue:0xff2602];
    }
    
    // Non-Savant Default Color
    return [UIColor sav_colorWithRGBValue:0x1a1a1a];
}

- (void)currentServiceDidActivate
{
    self.currentServiceActivated = YES;
}

- (void)setCurrentService:(SAVService *)currentService
{
    if (currentService &&
        (!self.currentRootViewController.activeVC ||
        (self.currentRootViewController.activeVC != self.currentRootViewController.viewControllers[SCURootViewActiveTabScenes])))
    {
        _currentService = currentService;
        self.currentVolumeModelService = currentService;

        //-------------------------------------------------------------------
        // Track if the service we switched to actually activates
        //-------------------------------------------------------------------
        self.currentServiceActivated = [[SavantControl sharedControl].stateManager.activeServices containsObject:currentService];

        //-------------------------------------------------------------------
        // Fail safe if the service fails to power on / was already on
        //-------------------------------------------------------------------
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(currentServiceDidActivate) object:nil];
        [self performSelector:@selector(currentServiceDidActivate) withObject:nil afterDelay:5];

        [[SAVSettings localSettings] setObject:currentService.serviceString forKey:@"CurrentService"];

        if (currentService.connectorId)
        {
            [[SAVSettings localSettings] setObject:currentService.connectorId forKey:@"CurrentServiceConnector"];
        }
        else
        {
            [[SAVSettings localSettings] removeObjectForKey:@"CurrentServiceConnector"];
        }

        //-------------------------------------------------------------------
        // Reconfigure the toolbar to properly display volume for this service
        //-------------------------------------------------------------------
        SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.currentContentViewController.navigationController.topViewController;

        if ([passthrough isKindOfClass:[SCUPassthroughViewController class]])
        {
            [passthrough configureToolbar];
        }
    }
    else
    {
        _currentService = nil;
        self.currentVolumeModelService = nil;

        self.currentRoom = self.currentRoom; /* currentVolumeModelService hacks */

        [[SAVSettings localSettings] removeObjectForKey:@"CurrentService"];
    }

    [[SAVSettings localSettings] synchronize];
}

- (void)setCurrentRoom:(SAVRoom *)currentRoom
{
    if (currentRoom)
    {
        self.currentVolumeModelService = [[SavantControl sharedControl].stateManager activeServiceForRoom:currentRoom.roomId];
        [self.volumeNotification setRoomName:currentRoom.roomId];
    }
    else
    {
        self.currentVolumeModelService = nil;
    }

    if ([currentRoom isEqual:_currentRoom])
    {
        return;
    }

    _currentRoom = currentRoom;

    if (currentRoom)
    {
        [[SAVSettings localSettings] setObject:currentRoom.roomId forKey:@"CurrentRoom"];
    }
    else
    {
        [[SAVSettings localSettings] removeObjectForKey:@"CurrentRoom"];
    }

    [[SAVSettings localSettings] synchronize];
}

#pragma mark - State Delegate

- (void)room:(NSString *)roomId didUpdateActiveService:(SAVService *)service
{
    if ([roomId isEqualToString:self.currentRoom.roomId] && self.currentRoom)
    {
        self.currentVolumeModelService = service;
        self.volumeModel.service = self.currentVolumeModelService;

        if (self.currentServiceActivated)
        {
            if ([[self currentServiceViewController].model.service.serviceId hasPrefix:@"SVC_AV"] &&
                ![[self currentServiceViewController].model.service.serviceString isEqualToString:service.serviceString])
            {
                if (service)
                {
                    [self presentService:service];
                }
                else
                {
                    [[self currentContentViewController] leaveServiceScreenAnimated:YES];
                }
            }
        }
        else
        {
            if ([service isEqual:self.currentService])
            {
                self.currentServiceActivated = YES;
            }
        }

        //-------------------------------------------------------------------
        // Restore previous AV service screen
        //-------------------------------------------------------------------
        if (self.shouldRestoreService)
        {
            [self presentService:service animated:NO];

            self.shouldRestoreService = NO;
        }
    }
    else if (self.currentService && service && self.shouldRestoreServicesFirstService)
    {
        if ([service matchesWildcardedService:self.currentService])
        {
            [self presentServicesFirstService:self.currentService animated:NO];

            self.shouldRestoreServicesFirstService = NO;
        }
    }
}

#pragma mark - Volume methods

- (void)setCurrentVolumeModelService:(SAVService *)currentVolumeModelService
{
    _currentVolumeModelService = currentVolumeModelService;

    [self stopStealingVolume];

    if (currentVolumeModelService)
    {
        [self startStealingVolume];
    }
}

- (void)startStealingVolume
{
    if (!self.volumeNotification)
    {
        UIView *window = [UIView sav_topView];
        self.volumeNotification = [[SCUHardButtonVolumeNotification alloc] initWithFrame:CGRectZero];
        [self.volumeNotification setRoomName:self.currentRoom.roomId];
        [window addSubview:self.volumeNotification];
        [window sav_addCenteredConstraintsForView:self.volumeNotification];
    }

    self.volumeListener.listening = YES;
    self.volumeModel = [[SCUVolumeModel alloc] initWithService:self.currentVolumeModelService];
    self.volumeModel.delegate = self;
}

- (void)stopStealingVolume
{
    self.volumeListener.listening = NO;
    self.volumeModel.delegate = nil;
    self.volumeModel = nil;
    [self.volumeNotification hide];
}

- (void)volumeListenerDidIncrement:(SCUVolumeListener *)listener
{
    if (![self isPresentedViewControllerGlobalNowPlaying])
    {
        [self.volumeModel increaseVolume];
        [self updateVolumeNotification:self.volumeModel.currentVolume + 1 fromOldVolume:self.volumeModel.currentVolume];
    }
}

- (void)volumeListenerDidDecrement:(SCUVolumeListener *)listener
{
    if (![self isPresentedViewControllerGlobalNowPlaying])
    {
        [self.volumeModel decreaseVolume];
        [self updateVolumeNotification:self.volumeModel.currentVolume - 1 fromOldVolume:self.volumeModel.currentVolume];
    }
}

- (BOOL)isPresentedViewControllerGlobalNowPlaying
{
    if (!self.contentViewController.presentedViewController)
    {
        return NO;
    }
    else
    {
        UINavigationController *navigationController = (UINavigationController *)self.contentViewController.presentedViewController;
        
        if ([navigationController isKindOfClass:[UINavigationController class]])
        {
            SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)[navigationController.viewControllers firstObject];
            
            if ([passthrough isKindOfClass:[SCUPassthroughViewController class]])
            {
                if ([[passthrough rootViewController] isKindOfClass:[SCUGlobalNowPlayingViewController class]])
                {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (void)updateVolumeNotification:(NSInteger)newVolume fromOldVolume:(NSInteger)oldVolume
{
    if (self.volumeModel.isDiscrete && [self.volumeModel.serviceGroup.activeServices count] == 1)
    {
        if (newVolume < 0)
        {
            newVolume = 0;
        }
        else if (newVolume > 50)
        {
            newVolume = 50;
        }

        SAVService *currentService = self.volumeModel.serviceGroup.activeServices.firstObject;

        [self.volumeNotification interact];
        [self.volumeNotification setRoomName:currentService.zoneName];
        
        return;
    }
    
    if (self.volumeModel.serviceGroup.activeServices.count > 1)
    {
        [self.volumeNotification setNumberOfRooms:self.volumeModel.serviceGroup.activeServices.count];
    }
    else if (self.volumeModel.serviceGroup.activeServices.count == 1)
    {
        SAVService *currentService = self.volumeModel.serviceGroup.activeServices.firstObject;
        
        [self.volumeNotification setRoomName:currentService.zoneName];
    }
    
    if ((newVolume - oldVolume) > 0)
    {
        [self.volumeNotification showVolumeUp];
    }
    else
    {
        [self.volumeNotification showVolumeDown];
    }
    
}

#pragma mark - SCUBackgroundHandlerDelegate

- (void)backgroundHandlerEnterBackground
{
    [self stopStealingVolume];
}

- (void)backgroundHandlerEnterForeground
{
    self.currentVolumeModelService = self.currentVolumeModelService;
}

- (void)backgroundHandlerWillResignActive
{
    [self stopStealingVolume];
}

- (void)backgroundHandlerDidActivate
{
    self.currentVolumeModelService = self.currentVolumeModelService;
}

#pragma mark - SCUVolumeModelDelegate methods

- (void)didUpdateVolume:(NSInteger)volume
{
    [self.volumeNotification updatePercentage:volume * 2];
}

- (void)didUpdateMuteStatus:(BOOL)muted
{

}

- (void)didUpdateDiscreteVolumeStatus:(BOOL)discreteVolumeAvailable
{

}

- (BOOL)isTracking
{
    return NO;
}

- (void)updateGlobalVolume
{

}

- (BOOL)showRoomVolume
{
    return NO;
}

- (void)showGlobalRoomVolume
{

}

- (void)hideGlobalRoomVolume
{
    
}

@end
