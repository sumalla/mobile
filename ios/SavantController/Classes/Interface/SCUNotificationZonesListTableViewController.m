//
//  SCUNotificationZonesListTableViewController.m
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationZonesListTableViewController.h"
#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationZonesListViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUScenesZoneCell.h"

@interface SCUNotificationZonesListTableViewController ()

@property SCUNotificationZonesListViewModel *model;
@property SAVNotification *editingNotification;

@end

@implementation SCUNotificationZonesListTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        self.editingNotification = notification;
        self.model = [[SCUNotificationZonesListViewModel alloc] initWithNotification:[notification copy]];
        self.model.delegate = self;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.rowHeight = 150.0f;
    
    [self.tableView setContentInset:UIEdgeInsetsZero];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(doneEditing)];
    
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self updateAddButtonState];
}

- (void)doneEditing
{
    [self.model doneEditing];
    
    [self.editingNotification applySettings:[self.model.notification dictionaryRepresentation]];
    
    [self popViewController];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUScenesZoneCell class] forCellType:1];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    return type == 1 ? 150 : self.tableView.rowHeight;
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUScenesZoneCell *cell = (SCUScenesZoneCell *)c;
    
    if ([self.model indexPathIsSelected:indexPath])
    {
        cell.imageButtonEnabled = YES;
        [self updateAddButtonState];
    }
    else
    {
        cell.imageButtonEnabled = NO;
    }
    
    [self listenToTap:cell.imageButton forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    NSIndexPath *relativeIndex = [self.model relativeIndexPathForAbsoluteIndexPath:indexPath];
    
    if ([self.model indexPathIsSelected:relativeIndex])
    {
        [self deselectedIndexPath:relativeIndex];
    }
    else
    {
        [self selectedIndexPath:relativeIndex];
    }
}

- (void)listenToTap:(UIButton *)button forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [button sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        NSIndexPath *relativeIndex = [self.model relativeIndexPathForAbsoluteIndexPath:indexPath];
        
        if ([self.model respondsToSelector:@selector(selectItemAtIndexPath:)])
        {
            [self.model selectItemAtIndexPath:relativeIndex];
        }
        
        if ([wSelf.model indexPathIsSelected:relativeIndex])
        {
            [wSelf deselectedIndexPath:relativeIndex];
        }
        else
        {
            [wSelf selectedIndexPath:relativeIndex];
        }
    }];
}

- (void)updateAddButtonState
{
    self.navigationItem.rightBarButtonItem.enabled = [self.model hasSelectedRows];
}

- (void)deselectedIndexPath:(NSIndexPath *)indexPath
{
    [self collapseIndex:indexPath animated:YES];
    
    [self.model removeZone:[self.model zoneForIndexPath:indexPath]];
    
    [self updateAddButtonState];
    
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)selectedIndexPath:(NSIndexPath *)indexPath
{
    if (![self.model indexPathIsSelected:indexPath])
    {
        [self.model addZone:[self.model zoneForIndexPath:indexPath]];
        
        [self updateAddButtonState];
        
        SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
    }
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath
{
    SCUScenesZoneCell *cell = (SCUScenesZoneCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setImagesFromArray:images];
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
