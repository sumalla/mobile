//
//  SCUServiceCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceCollectionViewController.h"
#import "SCUGradientView.h"
#import "SCUToolbarButton.h"
@import SDK;

@implementation SCUServiceCollectionViewController

@synthesize panGesture=_panGesture, dismissalCompletionBlock=_dismissalCompletionBlock;

- (instancetype)initWithService:(SAVService *)service
{
    return [super init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.model.service)
    {
        self.title = self.model.service.displayName;
    }
}

- (void)powerOff:(UIBarButtonItem *)sender
{
    if ([self.model.service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        [self.model sendCommand:@"__RoomLightsOff"];
    }
    else
    {
        [self.model sendCommand:@"PowerOff"];
    }

    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (SAVServiceGroup *)serviceGroup
{
    return self.model.serviceGroup;
}

- (SAVService *)service
{
    return self.isServicesFirst ? self.model.serviceGroup.wildCardedService : self.model.service;
}

@end
