//
//  SCUClimateHistoryDataFilterViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryDataFilterViewController.h"
#import "SCUClimateHistoryDataFilterModel.h"
#import "SCUClimateHistoryDataFilterCell.h"

@interface SCUClimateHistoryDataFilterViewController ()

@property SCUClimateHistoryDataFilterModel *model;

@end

@implementation SCUClimateHistoryDataFilterViewController

- (instancetype)initWithDelegate:(id <SCUClimateHistoryDataFilterDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUClimateHistoryDataFilterModel alloc] init];
        self.model.delegate = delegate;
    }
    return self;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUClimateHistoryDataFilterCell class] forCellType:0];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUClimateHistoryDataFilterCell *dataFilterCell = (SCUClimateHistoryDataFilterCell *)cell;

    [self.model listenToSwitch:dataFilterCell.toggleSwitch forIndexPath:indexPath];
}

@end
