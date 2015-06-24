//
//  SCUServicesFirstContainerViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstContainerViewController.h"
#import "SCUServicesFirstCollectionViewController.h"
#import "SCUServicesFirstDataModel.h"
#import "SCUGradientView.h"

@interface SCUServicesFirstContainerViewController ()

@property (nonatomic) SCUServicesFirstCollectionViewController *rootViewController;

@end

@implementation SCUServicesFirstContainerViewController

#pragma mark - SCUMainNavbarManager methods

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsNavigation | SCUMainNavbarItemsEntertainment;
}

#pragma mark - SCUMainToolbarManager methods

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

#pragma mark - Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.rootViewController = [[SCUServicesFirstCollectionViewController alloc] initWithModel:[[SCUServicesFirstDataModel alloc] initWithService:nil]];
    [self sav_addChildViewController:self.rootViewController];
    [self.view sav_addFlushConstraintsForView:self.rootViewController.view];
}

#pragma mark - Overrides

- (UINavigationItem *)navigationItem
{
    return self.rootViewController.navigationItem;
}

- (NSString *)title
{
    return self.rootViewController.title;
}

@end
