//
//  SCUSceneZonesListViewController.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneZonesListViewControllerPrivate.h"
#import "SCUScenesZoneCell.h"

@interface SCUSceneZonesListViewController ()

@end

@implementation SCUSceneZonesListViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSceneZonesListModel alloc] initWithScene:scene andService:service];
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
    
    if (self.model.service.logicalComponent)
    {
        self.title = self.model.service.displayName;
    }
    else if (self.model.service)
    {
        self.title = NSLocalizedString(@"Power Off", nil);
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.creationVC.add ? NSLocalizedString(@"Add", nil) : NSLocalizedString(@"Done", nil)
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    
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
    
    [self.model removeZone:[self.model zoneForIndexPath:indexPath]];
    
    [self updateAddButtonState];
    
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)selectedIndexPath:(NSIndexPath *)indexPath
{
    if (self.model.service.logicalComponent)
    {
        self.creationVC.editingService.zoneName = [self.model zoneForIndexPath:indexPath];
        self.creationVC.activeState = SCUSceneCreationState_Service;
    }
    
    if (![self.model indexPathIsSelected:indexPath])
    {
        self.creationVC.envAdd = YES;
        
        [self.model addZone:[self.model zoneForIndexPath:indexPath]];
        
        [self updateAddButtonState];
        
        SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
    }
    else
    {
        self.creationVC.envAdd = NO;
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