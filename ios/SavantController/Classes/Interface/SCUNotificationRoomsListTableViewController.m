//
//  SCUNotificationRoomsListTableViewController.m
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationTableViewControllerPrivate.h"
#import "SCUNotificationRoomsListTableViewController.h"
#import "SCUNotificationRoomsListViewModel.h"
#import "SCUScenesRoomCell.h"

@interface SCUNotificationRoomsListTableViewController ()

@property SCUNotificationRoomsListViewModel *model;
@property SAVNotification *editingNotification;
@property BOOL add;

@end

@implementation SCUNotificationRoomsListTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        self.editingNotification = notification;
        self.model = [[SCUNotificationRoomsListViewModel alloc] initWithNotification:[notification copy]];
        self.model.delegate = self;
    
        [self.tableView setTableHeaderView:[self tableHeaderViewForType:notification.serviceType]];
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
    
    [self setTitle:NSLocalizedString(@"Add Rooms", nil)];
    
    [super viewDidLoad];
    
    self.tableView.rowHeight = 101.0f;
    self.tableView.allowsMultipleSelection = YES;
    
    [self.tableView setContentInset:UIEdgeInsetsZero];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:self.add ? NSLocalizedString(@"Add", nil) : NSLocalizedString(@"Done", nil)
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(doneTapped:)];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17.0f],
                                 NSForegroundColorAttributeName: [[SCUColors shared] color01]};
    
    [rightButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:rightButton];
    
    self.add = YES;
    
    if (self.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self updateAddButtonState];
}

- (void)doneTapped:(UIBarButtonItem *)button
{
    [self.model doneEditing];
    
    [self.editingNotification applySettings:[self.model.notification dictionaryRepresentation]];
    
    [self popViewController];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUScenesRoomCell class] forCellType:1];
}

- (UIView *)tableHeaderViewForType:(SAVNotificationServiceType)type
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    textLabel.textColor = [[SCUColors shared] color03shade07];
    textLabel.text = @"Rooms";
    textLabel.numberOfLines = 0;
    
    [header addSubview:textLabel];
    return header;
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    return type == 1 ? 101 : self.tableView.rowHeight;
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUScenesRoomCell *cell = (SCUScenesRoomCell *)c;
    cell.roomImage.image = [self.model imageForIndexPath:indexPath];
    cell.imageButton.hidden = YES;
    if ([self.model indexPathIsSelected:indexPath])
    {
        [self updateAddButtonState];
    }
    
    [self listenToTap:cell.imageButton forIndexPath:indexPath];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ;
    if (![self.model parentForAbsoluteIndexPath:indexPath])
    {
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
}

- (void)listenToTap:(UIButton *)button forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [button sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([self.model respondsToSelector:@selector(selectItemAtIndexPath:)])
        {
            [self.model selectItemAtIndexPath:indexPath];
        }
        
        if ([wSelf.model indexPathIsSelected:indexPath])
        {
            [wSelf deselectedIndexPath:indexPath];
        }
        else
        {
            [wSelf selectedIndexPath:indexPath];
        }
    }];
}

- (void)updateAddButtonState
{
//    if (self.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = [self.model hasSelectedRows];
    }
}

- (void)deselectedIndexPath:(NSIndexPath *)indexPath
{    
    [self.model removeRoom:[self.model roomForIndexPath:indexPath]];
    
    [self updateAddButtonState];
    
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)selectedIndexPath:(NSIndexPath *)indexPath
{
    if (![self.model indexPathIsSelected:indexPath])
    {
        [self.model addRoom:[self.model roomForIndexPath:indexPath]];
        
        [self updateAddButtonState];
        
        SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
    }
}

- (void)updateImage:(UIImage *)image forRow:(NSInteger)row
{
    SCUScenesRoomCell *cell = (SCUScenesRoomCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    if ([cell isKindOfClass:[SCUScenesRoomCell class]])
    {
        cell.roomImage.image = image;
        [cell setNeedsLayout];
    }
}

@end
