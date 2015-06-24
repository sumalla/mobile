//
//  SCUSecurityServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityServiceViewController.h"
#import "SCUSecurityChartViewController.h"
#import "SCUSecurityPanelViewController.h"
#import "SCUSecurityCamerasViewController.h"
#import "SCUSecurityModel.h"

#import <SavantControl/SavantControl.h>

@implementation SCUSecurityServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Security", nil);

    NSMutableArray *viewControllers = [NSMutableArray array];
    
    NSArray *cameraServices = [[SavantControl sharedControl].data servicesFilteredByServiceID:@"SVC_ENV_SECURITYCAMERA"];
    NSArray *securityServices = [[SavantControl sharedControl].data servicesFilteredByServiceIDs:@[@"SVC_ENV_SECURITYSYSTEM", @"SVC_ENV_USERLOGIN_SECURITYSYSTEM"]];

    if ([securityServices count])
    {
        SCUServiceViewController *panelVC = [[DeviceClassFromClass([SCUSecurityPanelViewController class]) alloc] initWithService:self.model.service];
        SCUServiceViewController *chartVC = [[DeviceClassFromClass([SCUSecurityChartViewController class]) alloc] initWithService:self.model.service];

        [viewControllers addObjectsFromArray:@[panelVC, chartVC]];
    }

    if ([cameraServices count])
    {
        SCUServiceViewController *cameraVC = [[DeviceClassFromClass([SCUSecurityCamerasViewController class]) alloc] initWithService:self.model.service];

        [viewControllers addObject:cameraVC];
    }

    self.viewControllers = viewControllers;

    if ([self.viewControllers count] == 1)
    {
        self.toolbarHeight = 0;
    }
}

@end