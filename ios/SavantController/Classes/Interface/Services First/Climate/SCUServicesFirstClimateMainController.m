//
//  SCUServicesFirstClimateMainController.m
//  SavantController
//
//  Created by Stephen Silber on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateZonesModel.h"
#import "SCUServicesFirstClimateMainController.h"
#import "SCUClimateHistoryWeekViewController.h"
#import "SCUClimateHistoryDayViewController.h"
#import "SCUClimateZonesTableViewController.h"
#import "SCUClimateServiceViewController.h"
#import "SCUTemperatureServiceModel.h"
#import "SCUScenesZoneCell.h"
#import "SCUInterface.h"
#import <SavantControl/SavantControl.h>
#import "SCUPassthroughViewController.h"

@interface SCUServicesFirstClimateMainController () <SCUClimateZonesModel>

@property (nonatomic) SCUClimateZonesModel *zonesModel;
@property (nonatomic) SCUClimateZonesTableViewController *zonesTableViewController;
@property (nonatomic) SCUClimateServiceViewController *currentClimateController;

@property (nonatomic) UIView *zonesContainer;
@property (nonatomic) UIViewController *climateContainer;
@property (nonatomic) BOOL loadedFirstController;

@end

@implementation SCUServicesFirstClimateMainController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Zones", nil);
    
    SCUClimateZonesModel *zonesModel = [[SCUClimateZonesModel alloc] init];
    zonesModel.delegate = self;
    self.zonesModel = zonesModel;
    
    SCUClimateZonesTableViewController *zonesViewController = [[SCUClimateZonesTableViewController alloc] initWithModel:zonesModel];

    self.zonesTableViewController = zonesViewController;
    self.zonesTableViewController.tableView.rowHeight = 150.0;
    
    [self addChildViewController:zonesViewController];
    
    if ([UIDevice isPhone])
    {
        [self.view addSubview:zonesViewController.view];
        [self.view sav_addFlushConstraintsForView:zonesViewController.view];
    }
    else
    {
        self.zonesContainer = [UIView sav_viewWithColor:[UIColor blackColor]];
        [self.view addSubview:self.zonesContainer];
        
        [self.view sav_pinView:self.zonesContainer withOptions:SAVViewPinningOptionsVertically];
        [self.view sav_pinView:self.zonesContainer withOptions:SAVViewPinningOptionsToLeft];
        [self.view sav_setWidth:.4 forView:self.zonesContainer isRelative:YES];
        
        [self.zonesContainer addSubview:self.zonesTableViewController.view];
        [self.zonesContainer sav_addConstraintsForView:self.zonesTableViewController.view withEdgeInsets:UIEdgeInsetsMake(0, 20, 20, 20)];
        
        self.climateContainer = [[UIViewController alloc] init];
        [self sav_addChildViewController:self.climateContainer];
        [self.view sav_pinView:self.climateContainer.view withOptions:SAVViewPinningOptionsToRight ofView:zonesViewController.view withSpace:20];
        [self.view sav_pinView:self.climateContainer.view withOptions:SAVViewPinningOptionsToRight | SAVViewPinningOptionsVertically];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.loadedFirstController)
    {
        self.loadedFirstController = YES;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

        if ([UIDevice isPad])
        {
            if (self.model.service.zoneName)
            {
                [self showClimateControlsForZone:self.model.service.zoneName indexPath:indexPath animated:YES];
            }
            else
            {
                [self showClimateControlsForZone:[self.zonesModel firstZone] indexPath:indexPath animated:YES];
            }
        }
        else
        {
            if (self.model.service.zoneName)
            {
                [self showClimateControlsForZone:self.model.service.zoneName indexPath:indexPath animated:NO];
            }
        }
    }
    
    if ([UIDevice isPad] && !self.loadedFirstController)
    {
        self.loadedFirstController = YES;
    }
}

- (void)showClimateControlsForZone:(NSString *)zone indexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    SAVService *service = [[SAVService alloc] initWithZone:zone
                                                 component:nil
                                          logicalComponent:nil
                                                 variantId:nil
                                                 serviceId:@"SVC_ENV_HVAC"];

    SCUClimateServiceViewController *climateViewController = [[SCUClimateServiceViewController alloc] initWithService:service];
    climateViewController.servicesFirst = YES;
    climateViewController.title = zone;
    
    if ([UIDevice isPhone])
    {
        climateViewController.servicesFirst = YES;
        SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:climateViewController];
        [self.navigationController pushViewController:passthrough animated:animated];
    }
    else
    {
        if (self.currentClimateController)
        {
            [self.currentClimateController sav_removeFromParentViewController];
        }

        SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:climateViewController];

        self.currentClimateController = climateViewController;
        [self.climateContainer sav_addChildViewController:passthrough];
        [self.climateContainer.view sav_addFlushConstraintsForView:passthrough.view];
        
        if (![[self.zonesTableViewController.tableView indexPathsForSelectedRows] containsObject:indexPath])
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.zonesTableViewController.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            });
        }
    }
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsEntertainment;
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.zonesTableViewController.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)updateImages:(NSArray *)images forRow:(NSInteger)row
{
    SCUScenesZoneCell *cell = (SCUScenesZoneCell *)[self.zonesTableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
    [cell setImagesFromArray:images];
    [cell setNeedsLayout];
}

@end
