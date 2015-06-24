//
//  SCUServicesFirstLightingMainController.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstLightingMainController.h"
#import "SCULightingRoomsTableViewController.h"
#import "SCULightingTableViewController.h"
#import "SCUInterface.h"
#import "SCUPassthroughViewController.h"
#import "SCUShadesModel.h"

@interface SCUServicesFirstLightingMainController () <SCULightingRoomsModel>

@property (nonatomic) SCULightingRoomsModel *roomsModel;
@property (nonatomic) SCULightingRoomsTableViewController *roomsTableViewController;
@property (nonatomic) UIView *roomsContainer;
@property (nonatomic) UIViewController *lightingContainer;;
@property (nonatomic) SCUServiceViewController *currentLightingController;
@property (nonatomic) BOOL loadedFirstController;
@property (nonatomic) NSString *currentRoom;

@end

@implementation SCUServicesFirstLightingMainController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Rooms", nil);

    SCULightingRoomsModel *roomsModel = [[SCULightingRoomsModel alloc] initWithService:self.model.service];
    roomsModel.delegate = self;
    self.roomsModel = roomsModel;

    SCULightingRoomsTableViewController *roomsViewController = [[SCULightingRoomsTableViewController alloc] initWithModel:roomsModel];
    self.roomsTableViewController = roomsViewController;

    [self addChildViewController:roomsViewController];

    if ([UIDevice isPhone])
    {
        [self.view addSubview:roomsViewController.view];
        [self.view sav_addFlushConstraintsForView:roomsViewController.view];
    }
    else
    {
        self.roomsContainer = [UIView sav_viewWithColor:[UIColor blackColor]];
        [self.view addSubview:self.roomsContainer];

        [self.view sav_pinView:self.roomsContainer withOptions:SAVViewPinningOptionsVertically];
        [self.view sav_pinView:self.roomsContainer withOptions:SAVViewPinningOptionsToLeft];
        [self.view sav_setWidth:.4 forView:self.roomsContainer isRelative:YES];

        [self.roomsContainer addSubview:self.roomsTableViewController.view];
        [self.roomsContainer sav_addConstraintsForView:self.roomsTableViewController.view withEdgeInsets:UIEdgeInsetsMake(0, 20, 20, 20)];

        self.lightingContainer = [[UIViewController alloc] init];
        [self sav_addChildViewController:self.lightingContainer];
        [self.view sav_pinView:self.lightingContainer.view withOptions:SAVViewPinningOptionsToRight ofView:roomsViewController.view withSpace:20];
        [self.view sav_pinView:self.lightingContainer.view withOptions:SAVViewPinningOptionsToRight | SAVViewPinningOptionsVertically];
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
                [self showLightingControlsForRoom:self.model.service.zoneName
                                        indexPath:[self.roomsModel indexPathForRoom:self.model.service.zoneName]
                                         animated:YES];
            }
            else
            {
                [self showLightingControlsForRoom:[self.roomsModel firstRoom] indexPath:indexPath animated:YES];
            }
        }
    }

    if ([UIDevice isPad] && !self.loadedFirstController)
    {
        self.loadedFirstController = YES;
    }
}

#pragma mark - SCULightingRoomsModel

- (void)showLightingControlsForRoom:(NSString *)room indexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    SAVService *service = [[SAVService alloc] initWithZone:room component:nil logicalComponent:nil variantId:nil serviceId:self.model.service.serviceId];
    self.currentRoom = room;

    SCULightingModel *model = nil;

    if ([self.model.service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
    {
        model = [[SCUShadesModel alloc] initWithService:service];
    }
    else
    {
        model = [[SCULightingModel alloc] initWithService:service];
    }

    SCULightingTableViewController *lightingTableViewController = [[SCULightingTableViewController alloc] initWithModel:model];
    lightingTableViewController.roomImageAlwaysInTable = YES;
    lightingTableViewController.title = room;
    SCUServiceViewController *serviceViewController = [[SCUServiceViewController alloc] initWithService:service];
    [serviceViewController sav_addChildViewController:lightingTableViewController];
    [serviceViewController.view sav_addFlushConstraintsForView:lightingTableViewController.view];

    if ([UIDevice isPhone])
    {
        serviceViewController.servicesFirst = YES;
        SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:serviceViewController];
        [self.navigationController pushViewController:passthrough animated:animated];
        serviceViewController.title = room;
    }
    else
    {
        if (self.currentLightingController)
        {
            [self.currentLightingController sav_removeFromParentViewController];
        }

        self.currentLightingController = serviceViewController;
        [self.lightingContainer sav_addChildViewController:serviceViewController];
        [self.lightingContainer.view sav_addConstraintsForView:serviceViewController.view withEdgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
        lightingTableViewController.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];

        if (![[self.roomsTableViewController.tableView indexPathsForSelectedRows] containsObject:indexPath])
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.roomsTableViewController.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            });
        }
    }
}

- (void)reloadData
{
    [self.roomsTableViewController.tableView reloadData];
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

- (SCUMainNavbarItems)mainNavbarItems
{
    if ([UIDevice isPad])
    {
        return SCUMainNavbarItemsEntertainment | SCUMainNavbarItemsRightButtons;
    }
    else
    {
        return SCUMainNavbarItemsEntertainment;
    }
}

- (void)powerOff:(UIBarButtonItem *)sender
{
    SAVServiceRequest *request = [[SAVServiceRequest alloc] init];
    request.serviceId = @"SVC_ENV_LIGHTING";
    request.zoneName = self.currentRoom;
    request.request = @"__RoomLightsOff";
    [[SavantControl sharedControl] sendMessage:request];
}

@end
