//
//  SCUInterface.h
//  SavantController
//
//  Created by Nathan Trapp on 4/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

#import "SCUContentViewController.h"
#import "SCUDrawerViewController.h"

@class SAVService, SAVServiceGroup, SAVRoom, SCUButton, SCUSceneServiceViewController, SAVScene;

@interface SCUInterface : NSObject

@property (nonatomic) SAVRoom *currentRoom;
@property (nonatomic) SAVService *currentService;
@property (nonatomic) SAVService *currentServiceFromNotification;
//-------------------------------------------------------------------
// This string is an ugly way to communicate this data
//-------------------------------------------------------------------
@property (nonatomic) NSString *notificationClimateServiceType;

@property (readonly, getter = isInterfaceLoaded) BOOL interfaceLoaded;

+ (instancetype)sharedInstance;

- (void)loadInstance;
- (void)teardownInstance;

@property (nonatomic, readonly, strong) SCUContentViewController *currentContentViewController;
@property (nonatomic, readonly, strong) SCUDrawerViewController *currentDrawerViewController;
@property (nonatomic, readonly, strong) SCURootViewController *currentRootViewController;
@property (nonatomic, readonly, strong) SCUServiceViewController *currentServiceViewController;

- (void)presentNavigation:(SCUButton *)sender;
- (void)presentHomeOverview:(SCUButton *)sender;
- (void)presentEntertainment:(SCUButton *)sender;

- (void)presentService:(SAVService *)service;
- (void)presentService:(SAVService *)service animated:(BOOL)animated;
- (BOOL)hasViewControllerForSerivce:(SAVService *)service;

- (void)presentNotificationService;

- (void)presentServicesFirstServiceGroup:(SAVServiceGroup *)service animated:(BOOL)animated;
- (void)presentServicesFirstService:(SAVService *)service animated:(BOOL)animated;
- (void)presentRoomsDistributionForServiceGroup:(SAVServiceGroup *)service;

- (void)presentRooms;
- (void)presentScenes;
- (void)presentServices;
- (void)presentSettings;
- (void)presentNotifications;

- (UIColor *)colorForService:(SAVService *)service;
- (UIColor *)colorForServiceId:(NSString *)serviceId;

- (SCUServiceViewController *)serviceViewControllerForService:(SAVService *)service;
- (SCUSceneServiceViewController *)sceneServiceViewControllerForServiceGroup:(SAVServiceGroup *)serviceGroup scene:(SAVScene *)scene;
- (SCUSceneServiceViewController *)sceneServiceViewControllerForService:(SAVService *)service scene:(SAVScene *)scene;

@end
