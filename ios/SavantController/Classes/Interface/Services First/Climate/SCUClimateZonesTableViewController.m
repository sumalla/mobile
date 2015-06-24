//
//  SCUClimateZonesTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesZoneCell.h"
#import "SCUClimateZonesTableViewController.h"

@interface SCUClimateZonesTableViewController () <SCUClimateZonesTableDelegate>

@property (nonatomic) SCUClimateZonesModel *model;

@end

@implementation SCUClimateZonesTableViewController

- (instancetype)initWithModel:(SCUClimateZonesModel *)model
{
    self = [super init];
    
    if (self)
    {
        self.model = model;
        self.model.tableDelegate = self;
    }
    
    return self;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUScenesZoneCell class] forCellType:0];
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delaysContentTouches = NO;
    
    if ([UIDevice isPad])
    {
        self.tableView.backgroundColor = [[SCUColors shared] color03];
    }
    
    self.tableView.rowHeight = 150;
}

- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath
{
    SCUScenesZoneCell *cell = (SCUScenesZoneCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setImagesFromArray:images];
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice isPhone])
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}

@end
