//
//  SCUNotificationCreationWhenTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUSwipeCell.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationCreationWhenViewModel.h"
#import "SCUNotificationCreationWhenTableViewController.h"
#import "SCUDatePickerCell.h"
#import "SCUDateCell.h"
#import "SCUDayPickerCell.h"
#import "SCUButton.h"
#import "SCUSceneChildCell.h"
#import "SCUSecondsPickerCell.h"
#import "SCUToggleSwitchTableViewCell.h"

@interface SCUNotificationCreationWhenTableViewController () <SCUNotificationWhenViewDelegate>

@property (nonatomic) SCUNotificationCreationWhenViewModel *model;
@property SAVNotification *editingNotification;

@end

static NSInteger secondsPerHour = 3600;

@implementation SCUNotificationCreationWhenTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        self.editingNotification = notification;
        self.model = [[SCUNotificationCreationWhenViewModel alloc] initWithNotification:[notification copy]];
        self.model.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"When", nil);
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(popViewControllerCanceled)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
}

- (void)doneEditing
{    
    [self.editingNotification applySettings:[self.model.notification dictionaryRepresentation]];

    [self popViewController];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    switch (type)
    {
        case SCUNotificationWhenCellTypeChild:
            return 45;
        case SCUNotificationWhenCellTypeDatePicker:
        case SCUNotificationWhenCellTypeNumericPicker:
            return 162;
        case SCUNotificationWhenCellTypeDayPicker:
        case SCUNotificationWhenCellTypeDefault:
        case SCUNotificationWhenCellTypeDate:
        case SCUNotificationWhenCellTypeToggle:
            return 60;
        default:
            return self.tableView.rowHeight;
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:SCUNotificationWhenCellTypeDefault];
    [self.tableView sav_registerClass:[SCUDatePickerCell class] forCellType:SCUNotificationWhenCellTypeDatePicker];
    [self.tableView sav_registerClass:[SCUDateCell class] forCellType:SCUNotificationWhenCellTypeDate];
    [self.tableView sav_registerClass:[SCUDayPickerCell class] forCellType:SCUNotificationWhenCellTypeDayPicker];
    [self.tableView sav_registerClass:[SCUSceneChildCell class] forCellType:SCUNotificationWhenCellTypeChild];
    [self.tableView sav_registerClass:[SCUSecondsPickerCell class] forCellType:SCUNotificationWhenCellTypeNumericPicker];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUNotificationWhenCellTypeToggle];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t indexPath:(NSIndexPath *)indexPath
{
    SCUNotificationWhenCellType type = t;
    switch (type)
    {
        case SCUNotificationWhenCellTypeToggle:
        {
            SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
            
            [self listenToSwitch:cell.toggleSwitch forIndexPath:indexPath];
            break;
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)t forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUNotificationWhenCellType type = t;
    switch (type)
    {
        case SCUNotificationWhenCellTypeChild:
        {
            SCUSceneChildCell *cell = (SCUSceneChildCell *)c;
            cell.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
            cell.backgroundColor = [[SCUColors shared] color03shade02];
            break;
        }
        case SCUNotificationWhenCellTypeDayPicker:
        {
            SCUSceneChildCell *cell = (SCUSceneChildCell *)c;
            cell.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
            cell.backgroundColor = [[SCUColors shared] color03shade02];
            break;
        }
        case SCUNotificationWhenCellTypeDatePicker:
        {
            SCUSceneChildCell *cell = (SCUSceneChildCell *)c;
            cell.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
            cell.backgroundColor = [[SCUColors shared] color03shade02];
            break;
        }
    }
}

- (void)listenToSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SCUNotificationWhenCellProperty property = [self.model cellPropertyForIndexPath:indexPath];
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on){
        SAVStrongWeakSelf;
        switch (property)
        {
            case SCUNotificationWhenCellPropertyAllDay:
                if (on != sSelf.model.notification.isAllDay)
                {
                    if (on)
                    {
                        // SAVNotification isAllDay checks if time/endTime == -1
                        sSelf.model.notification.time    = -1;
                        sSelf.model.notification.endTime = -1;
                    }
                    else
                    {
                        sSelf.model.notification.time    = secondsPerHour * 8;
                        sSelf.model.notification.endTime = secondsPerHour * 18;
                    }
                    
                    NSIndexPath *startPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
                    NSIndexPath *endPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];

                    if (on)
                    {
                        [self removeParentRowsAtIndexPaths:@[endPath, startPath] withRowAnimation:UITableViewRowAnimationTop updateBlock:^{
                            [sSelf.model prepareData];
                        }];
                    }
                    else
                    {
                        [sSelf.model prepareData];
                        [self addParentRowsAtIndexPaths:@[startPath, endPath] withRowAnimation:UITableViewRowAnimationTop];
                    }
                }
                break;
                
            case SCUNotificationWhenCellPropertyAllYear:
                if (on != sSelf.model.notification.isAllYear)
                {
                    
                    if (on)
                    {
                        sSelf.model.notification.endDate = sSelf.model.notification.startDate;
                    }
                    else
                    {
                        sSelf.model.notification.startDate = [NSDate today];
                        sSelf.model.notification.endDate = [NSDate dateWithTimeInterval:86400 sinceDate:[NSDate today]];
                    }

                    NSIndexPath *startPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
                    NSIndexPath *endPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];

                    if (on)
                    {
                        [self removeParentRowsAtIndexPaths:@[endPath, startPath] withRowAnimation:UITableViewRowAnimationTop updateBlock:^{
                            [sSelf.model prepareData];
                        }];
                    }
                    else
                    {
                        [sSelf.model prepareData];
                        [self addParentRowsAtIndexPaths:@[startPath, endPath] withRowAnimation:UITableViewRowAnimationTop];
                    }
                }
                break;
        }
    };
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[[self.model absoluteIndexPathForRelativeIndexPath:indexPath]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)toggleIndex:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    for (NSIndexPath *expandedPath in self.model.expandedIndexPaths)
    {
        if (![expandedPath isEqual:indexPath])
        {
            [self toggleIndex:expandedPath animated:YES];
        }
    }
    
    [self toggleIndex:indexPath animated:YES];
    [self.tableView endUpdates];
}

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    [self reloadChildrenBelowIndexPath:indexPath animated:NO];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

@end
