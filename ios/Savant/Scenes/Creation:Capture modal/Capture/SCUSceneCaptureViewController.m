//
//  SCUSceneCaptureViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCaptureViewController.h"
#import "SCUSceneCaptureModel.h"
#import "SCUSceneRoomsListViewControllerPrivate.h"
#import "SCUSceneChildCell.h"
#import "SCUCaptureRoomCell.h"

@interface SCUSceneCaptureViewController () <SCUSceneCaptureModelDelegate>

@property SCUSceneCaptureModel *model;

@end

@implementation SCUSceneCaptureViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        self.model = [[SCUSceneCaptureModel alloc] initWithScene:scene andService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Capture", nil);

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(dismissViewController)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
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

- (void)deselectedIndexPath:(NSIndexPath *)indexPath
{
    [self.model removeRoom:[self.model roomForIndexPath:indexPath]];
    
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)selectedIndexPath:(NSIndexPath *)indexPath
{

    if (![self.model indexPathIsSelected:indexPath])
    {     
        [self.model addRoom:[self.model roomForIndexPath:indexPath]];
        
        SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
        
        if ([self.model.expandedIndexPaths containsObject:indexPath])
        {
            [self reloadChildrenBelowIndexPath:indexPath animated:NO];
        }
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSceneChildCell class] forCellType:0];
    [self.tableView sav_registerClass:[SCUCaptureRoomCell class] forCellType:1];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    if (type == 0)
    {
        return 60.0f;
    }
    
    return [super heightForCellWithType:type];
}

- (void)updateImage:(UIImage *)image forRow:(NSInteger)row
{
    SCUCaptureRoomCell *cell = (SCUCaptureRoomCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    if ([cell isKindOfClass:[SCUCaptureRoomCell class]])
    {
        cell.roomImage.image = image;
        [cell setNeedsLayout];
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUCaptureRoomCell *cell = (SCUCaptureRoomCell *)c;
    cell.roomImage.image = [self.model imageForIndexPath:indexPath];
    cell.roomImage.userInteractionEnabled = NO;
    cell.imageButton.hidden = YES;
    [self listenToTap:cell.chevronButton forIndexPath:indexPath];
}

- (void)listenToTap:(UIButton *)button forIndexPath:(NSIndexPath *)indexPath
{
    [button sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([self.model respondsToSelector:@selector(selectItemAtIndexPath:)])
        {
            [self.model selectItemAtIndexPath:indexPath];
        }
        [self toggleIndex:indexPath];
    }];
}

- (void)toggleIndex:(NSIndexPath *)indexPath
{
    [self toggleIndex:indexPath animated:YES];
    [self reconfigureIndexPath:indexPath];
}

- (void)reloadIndex:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
