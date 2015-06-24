//
//  SCULightingRoomsTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingRoomsTableViewController.h"
#import "SCUDefaultTableViewCell.h"

@interface SCULightingRoomsTableViewController ()

@property (nonatomic) SCULightingRoomsModel *model;

@end

@implementation SCULightingRoomsTableViewController

- (instancetype)initWithModel:(SCULightingRoomsModel *)model
{
    self = [super init];

    if (self)
    {
        self.model = model;
    }

    return self;
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

    self.tableView.rowHeight = 60;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:0];
}

@end
