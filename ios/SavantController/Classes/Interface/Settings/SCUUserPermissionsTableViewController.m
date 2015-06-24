//
//  SCUUserPermissionsTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserPermissionsTableViewController.h"
#import "SCURoomsPermissionsDataModel.h"

@interface SCUUserPermissionsTableViewController () <SCURoomsPermissionsDataModelDelegate, SCUServicesPermissionsDataModelDelegate>

@property (nonatomic) SCUDataSourceModel *model;

@end

@implementation SCUUserPermissionsTableViewController

- (instancetype)initWithRoomsModel:(SCURoomsPermissionsDataModel *)roomsModel
{
    self = [super init];

    if (self)
    {
        roomsModel.delegate = self;
        self.model = roomsModel;
    }

    return self;
}

- (instancetype)initWithServicesModel:(SCUServicesPermissionsDataModel *)servicesModel
{
    self = [super init];

    if (self)
    {
        servicesModel.delegate = self;
        self.model = servicesModel;
    }

    return self;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done)];

    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    self.tableView.rowHeight = 60;
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)done
{
    SAVFunctionForSelector(function, self.model, @selector(commit), void);
    function(self.model, @selector(commit));
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - SCURoomsPermissionsDataModelDelegate methods

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
