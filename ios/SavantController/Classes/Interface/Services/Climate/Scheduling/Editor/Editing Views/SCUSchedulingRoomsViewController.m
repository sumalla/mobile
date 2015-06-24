//
//  SCUSchedulingRoomsViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingRoomsViewController.h"
#import "SCUSchedulingRoomModel.h"
#import "SCUSchedulingRoomCell.h"
#import <SavantControl/SAVClimateSchedule.h>

@interface SCUSchedulingRoomsViewController ()

@property SCUSchedulingRoomModel *model;

@end

@implementation SCUSchedulingRoomsViewController

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSchedulingRoomModel alloc] initWithSchedule:schedule];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 150;
}

- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath
{
    SCUSchedulingRoomCell *cell = (SCUSchedulingRoomCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setImagesFromArray:images];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.model registerForObservers];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.model invalidateImageReloadTimer];
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSchedulingRoomCell class] forCellType:0];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.model toggleRoomSelectedAtIndexPath:indexPath];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:c withType:type indexPath:indexPath];
}

@end
