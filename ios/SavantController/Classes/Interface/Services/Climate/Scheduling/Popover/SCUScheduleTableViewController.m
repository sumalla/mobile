//
//  SCUScheduleTableViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScheduleTableViewController.h"
#import "SCUSchedulingModel.h"
#import "SCUClimateScheduleSwitchCell.h"
#import "SCUSchedulingEditor.h"
#import "SCUThemedNavigationViewController.h"
#import <SavantControl/SavantControl.h>

@interface SCUScheduleTableViewController () <SCUClimateSchedulingModelDelegate, SCUSchedulingEditorDelegate>

@property (weak) SCUSchedulingModel *model;
@property SCUScheduleTableType type;

@end

@implementation SCUScheduleTableViewController

- (instancetype)initWithModel:(SCUSchedulingModel *)model andType:(SCUScheduleTableType)type
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        self.model = model;
        self.type = type;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.model addDelegate:self];
    self.model.type = self.type;
    
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.model removeDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor clearColor];

    switch (self.type)
    {
        case SCUScheduleTableType_Active:
            self.title = NSLocalizedString(@"Schedules", nil);
            break;
        case SCUScheduleTableType_AllSchedules:
            self.title = NSLocalizedString(@"All Schedules", nil);
            break;
    }
    
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
    
    if (self.type == SCUScheduleTableType_AllSchedules)
    {
        if (![self.model numberOfItemsInSection:0])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)viewAllSchedules
{
    SCUScheduleTableViewController *allSchedules = [[SCUScheduleTableViewController alloc] initWithModel:self.model andType:SCUScheduleTableType_AllSchedules];
    [self.navigationController pushViewController:allSchedules animated:YES];
}

#pragma mark - Methods to subclass

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.type == SCUScheduleTableType_AllSchedules);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.model removeScheduleAtIndexPath:indexPath];
        [self reloadData];
    }
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUClimateScheduleSwitchCell class] forCellType:SCUScheduleCellType_Toggle];
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUScheduleCellType_Default];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUScheduleCellType type = t;

    switch (type)
    {
        case SCUScheduleCellType_Toggle:
        {
            SCUClimateScheduleSwitchCell *cell = (SCUClimateScheduleSwitchCell *)c;
            [self.model listenToSwitch:cell.toggleSwitch atIndexPath:indexPath];
        }
            break;
        case SCUScheduleCellType_Default:
        {
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
    }
}

- (void)newSchedule:(NSDictionary *)settings
{
    SAVClimateSchedule *schedule = [[SAVClimateSchedule alloc] initWithName:nil];
    [schedule applyGlobalSettings:settings];
    
    SCUSchedulingEditor *schedulingEditor = [[SCUSchedulingEditor alloc] initWithSchedule:schedule];
    schedulingEditor.newSchedule = YES;
    schedulingEditor.modalPresentationStyle = UIModalPresentationFullScreen;
    schedulingEditor.delegate = self;

    SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:schedulingEditor];

    [self presentViewController:navController animated:YES completion:nil];
}

- (void)editSchedule:(SAVClimateSchedule *)schedule
{
    SCUSchedulingEditor *schedulingEditor = [[SCUSchedulingEditor alloc] initWithSchedule:schedule];
    schedulingEditor.modalPresentationStyle = UIModalPresentationFullScreen;
    schedulingEditor.delegate = self;

    SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:schedulingEditor];

    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Scheduling Editor Delegate

- (void)willDismissEditor:(SAVClimateSchedule *)schedule
{
    [self.model saveSchedule:schedule];
    [self reloadData];
}

- (NSDictionary *)schedulerSettings
{
    return self.model.schedulerSettings;
}

@end
