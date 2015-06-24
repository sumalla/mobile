//
//  SCUScenesRoomsListViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneRoomsListViewControllerPrivate.h"
#import "SCUScenesRoomCell.h"

@implementation SCUSceneRoomsListViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSceneRoomsListModel alloc] initWithScene:scene andService:service];
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

    self.tableView.rowHeight = 101.0f;
    self.tableView.allowsMultipleSelection = YES;

    if (self.model.service.logicalComponent)
    {
        self.title = self.model.service.displayName;
    }
    else if (self.model.service)
    {
        self.title = NSLocalizedString(@"Power Off", nil);
    }
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:self.creationVC.add ? NSLocalizedString(@"Add", nil) : NSLocalizedString(@"Done", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(doneEditing)];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17.0f],
                                 NSForegroundColorAttributeName: [[SCUColors shared] color01]};
    
    [rightButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:rightButton];

    if (self.creationVC.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }

    [self updateAddButtonState];
}

- (void)doneEditing
{
    [self.model doneEditing];

    [self popToRootViewController];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUScenesRoomCell class] forCellType:1];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    return type == 1 ? 101 : self.tableView.rowHeight;
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUScenesRoomCell *cell = (SCUScenesRoomCell *)c;
    cell.roomImage.image = [self.model imageForIndexPath:indexPath];

    if ([self.model indexPathIsSelected:indexPath])
    {
        [self updateAddButtonState];
    }

    [self listenToTap:cell.imageButton forIndexPath:indexPath];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.model parentForAbsoluteIndexPath:indexPath])
    {
        NSIndexPath *relativeIndex = [self.model relativeIndexPathForAbsoluteIndexPath:indexPath];

        if ((!self.model.service.logicalComponent && self.model.service) &&
            [self.model indexPathIsSelected:relativeIndex])
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
        if ([wSelf.model indexPathIsSelected:indexPath])
        {
            [wSelf deselectedIndexPath:indexPath];
        }
        else if ([self.model respondsToSelector:@selector(selectItemAtIndexPath:)])
        {
            [self.model selectItemAtIndexPath:indexPath];
        }
        else
        {
            [wSelf selectedIndexPath:indexPath];
        }
    }];
}

- (void)next
{
    self.creationVC.activeState = SCUSceneCreationState_Service;
}

- (void)updateAddButtonState
{
    if (self.creationVC.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = [self.model hasSelectedRows];
    }
}

- (void)deselectedIndexPath:(NSIndexPath *)indexPath
{
    [self collapseIndex:indexPath animated:YES];
    
    self.creationVC.editingService.zoneName = nil;

    [self.model removeRoom:[self.model roomForIndexPath:indexPath]];

    [self updateAddButtonState];

    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)selectedIndexPath:(NSIndexPath *)indexPath
{
    if (self.model.service.logicalComponent)
    {
        self.creationVC.editingService.zoneName = [self.model roomForIndexPath:indexPath];
        self.creationVC.activeState = SCUSceneCreationState_Service;
    }

    if (![self.model indexPathIsSelected:indexPath])
    {
        self.creationVC.envAdd = YES;

        [self.model addRoom:[self.model roomForIndexPath:indexPath]];

        [self updateAddButtonState];

        SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
    }
    else
    {
        self.creationVC.envAdd = NO;
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
