//
//  SCUSystemSelectorViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorViewController.h"
#import "SCUSystemSelectorTableViewController.h"
#import "SCUGradientView.h"
#import <SavantControl/SavantControl.h>

@interface SCUSystemSelectorViewController () <UINavigationControllerDelegate>

@property (nonatomic) SCUSystemSelectorFromLocation fromLocation;

@end

@implementation SCUSystemSelectorViewController

- (void)dealloc
{
    self.navigationController.delegate = nil;
}

- (instancetype)initWithFromLocation:(SCUSystemSelectorFromLocation)fromLocation
{
    self = [super init];

    if (self)
    {
        self.fromLocation = fromLocation;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.delegate = self;

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"SavantLogo" tintColor:[[SCUColors shared] color03shade06]]];
    logo.contentMode = UIViewContentModeCenter;
    [self.view addSubview:logo];
    [self.view sav_pinView:logo withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsToTop];
    [self.view sav_setHeight:60 forView:logo isRelative:NO];

    SCUSystemSelectorTableViewController *viewController = [[SCUSystemSelectorTableViewController alloc] init];
    [self sav_addChildViewController:viewController];
    [self.view sav_pinView:viewController.view withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsToBottom];
    [self.view sav_pinView:viewController.view withOptions:SAVViewPinningOptionsToBottom ofView:logo withSpace:0];

    if (self.fromLocation == SCUSystemSelectorFromLocationInterface)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:[SavantControl sharedControl]
                                                                                              action:@selector(loadPreviousConnection)];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == self)
    {
        [[SavantControl sharedControl] disconnect];
    }
}

@end
