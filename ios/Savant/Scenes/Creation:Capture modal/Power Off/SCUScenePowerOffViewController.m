//
//  SCUSceneServicesListViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenePowerOffViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUScenePowerOffModel.h"

@import SDK;

@interface SCUScenePowerOffViewController ()

@property SCUScenePowerOffModel *model;
@property NSIndexPath *selectedRow;

@end

@implementation SCUScenePowerOffViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUScenePowerOffModel alloc] initWithScene:scene andService:service];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.selectedRow)
    {
        [self.tableView selectRowAtIndexPath:self.selectedRow animated:NO scrollPosition:0];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsMultipleSelection = NO;

    self.title = NSLocalizedString(@"Power Off", nil);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil)
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(next)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.tableView.rowHeight = 60;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *oldIndex = [self.tableView indexPathForSelectedRow];
    [self.tableView cellForRowAtIndexPath:oldIndex].accessoryType = UITableViewCellAccessoryNone;

    if ([self.selectedRow isEqual:indexPath])
    {
        self.selectedRow = nil;

        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.selectedRow = indexPath;

        self.navigationItem.rightBarButtonItem.enabled = YES;

        [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return indexPath;
}

- (void)next
{
    NSDictionary *modelObject = [self.model modelObjectForIndexPath:[self.tableView indexPathForSelectedRow]];

    SAVMutableService *service = [[SAVMutableService alloc] init];
    service.serviceId = modelObject[SCUDefaultTableViewCellKeyModelObject];
    self.creationVC.editingService = service;
    self.creationVC.activeState = SCUSceneCreationState_RoomsList;
}

@end
