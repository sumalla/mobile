//
//  SCUServiceTabBarController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceTabBarController.h"
#import "SCUServiceViewController.h"
#import "SCUServiceViewModel.h"
#import "SCUTabBarControllerPrivate.h"
#import "SCUPassthroughViewController.h"
#import "SCUButton.h"

@import SDK;

@interface SCUServiceTabBarController ()

@property BOOL viewHasLoaded;

@property (nonatomic) UIView *fakeNavBarView;

@end

@implementation SCUServiceTabBarController

@synthesize panGesture=_panGesture, dismissalCompletionBlock=_dismissalCompletionBlock;

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUServiceViewModel alloc] initWithService:service];
    }
    return self;
}

- (NSString *)savedKey
{
    if ([self.model.service.serviceId hasPrefix:@"SVC_ENV"])
    {
        return self.model.service.serviceId;
    }
    else
    {
        return self.model.stateScope;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.model.service)
    {
        if ([self.model.service.serviceId hasPrefix:@"SVC_ENV"])
        {
            self.title = [self.model.service.displayName uppercaseString];
        }
        else
        {
            self.title = [self.model.service.alias uppercaseString];
        }
    }

    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04],
                                                                      NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:13]}];

    self.viewHasLoaded = YES;

    if ([self.model.service.serviceId hasPrefix:@"SVC_AV"] || [self.model.service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        SCUButton *powerOff = [[SCUButton alloc] initWithStyle:SCUButtonStyleAccent image:[UIImage imageNamed:@"Power"]];
        powerOff.frame = CGRectMake(0, 0, 70, 44);
        powerOff.target = self;
        powerOff.releaseAction = @selector(powerOff:);
        powerOff.buttonInsets = UIEdgeInsetsMake(0, 0, 0, 20);

        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:powerOff];
        self.navigationItem.rightBarButtonItem = button;
    }

    if (self.model.service)
    {
        SCUButton *dismiss = [[SCUButton alloc] initWithStyle:SCUButtonStyleLight image:[UIImage imageNamed:@"chevron-down"]];
        dismiss.frame = CGRectMake(0, 0, 70, 44);
        dismiss.target = self;
        dismiss.releaseAction = @selector(dismissService);
        dismiss.buttonInsets = UIEdgeInsetsMake(0, 20, 0, 0);

        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:dismiss];
        self.navigationItem.leftBarButtonItem = button;
    }
}

- (SCUServiceViewController *)activeTab
{
    SCUServiceViewController *activeTab = (SCUServiceViewController *)self.activeVC;
    return activeTab;
}

- (void)dismissService
{
    if (self.dismissalCompletionBlock)
    {
        self.dismissalCompletionBlock();
    }
}

- (void)powerOff:(UIBarButtonItem *)sender
{
    [(SCUServiceViewController *)self.activeVC powerOff:sender];
}

- (void)setActiveVC:(UIViewController *)activeVC
{
    [super setActiveVC:activeVC];

    if ([self.activeVC isKindOfClass:[SCUServiceViewController class]] && self.viewHasLoaded)
    {
        SCUServiceViewController *serviceVC = (SCUServiceViewController *)self.activeVC;

        serviceVC.dismissalCompletionBlock = self.dismissalCompletionBlock;
        serviceVC.panGesture = self.panGesture;
        
        [serviceVC setupConstraintsForOrientation:[UIDevice interfaceOrientation]];
    }
}

#pragma mark - Passthrough

- (SAVService *)service
{
    return self.isServicesFirst ? self.model.serviceGroup.wildCardedService : self.model.service;
}

- (SAVServiceGroup *)serviceGroup
{
    return self.model.serviceGroup;
}

- (void)dismiss
{
    if (self.dismissalCompletionBlock)
    {
        self.dismissalCompletionBlock();
    }
}

@end
