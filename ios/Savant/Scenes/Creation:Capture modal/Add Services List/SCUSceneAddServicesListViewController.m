//
//  SCUSceneServicesListViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneAddServicesListViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneAddServiceModel.h"

@import SDK;

@interface SCUSceneAddServicesListViewController () <SCUSceneAddServiceDelegate>

@property SCUSceneAddServiceModel *model;

@end

@implementation SCUSceneAddServicesListViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSceneAddServiceModel alloc] initWithScene:scene andService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Services", nil);
    self.tableView.rowHeight = 60;
}

- (void)selectedServiceGroup:(SAVServiceGroup *)service
{
    if ([service.serviceId hasPrefix:@"SVC_ENV"])
    {
        self.creationVC.editingService = [service.services lastObject];
    }
    else
    {
        self.creationVC.editingServiceGroup = service;
    }

    if ([service.serviceId hasPrefix:@"SVC_ENV_HVAC"])
    {
        self.creationVC.activeState = SCUSceneCreationState_ZonesList;
    }
    else if ([service.serviceId hasPrefix:@"SVC_ENV"])
    {
        self.creationVC.activeState = SCUSceneCreationState_RoomsList;
    }
    else if (!service)
    {
        self.creationVC.activeState = SCUSceneCreationState_PowerOff;
    }
    else
    {
        self.creationVC.activeState = SCUSceneCreationState_Service;
    }
}

@end
