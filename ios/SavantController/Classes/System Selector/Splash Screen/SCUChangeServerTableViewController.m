//
//  SCUChangeServerTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUChangeServerTableViewController.h"
#import "SCUChangeServerTableViewControllerModel.h"
#import "SCUProgressTableViewCell.h"

@interface SCUChangeServerTableViewController () <SCUChangeServerTableViewControllerModelDelegate>

@property (nonatomic) SCUChangeServerTableViewControllerModel *model;

@end

@implementation SCUChangeServerTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [[SCUChangeServerTableViewControllerModel alloc] init];
    self.model.delegate = self;
    self.title = NSLocalizedString(@"Cloud Servers", nil);
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUProgressTableViewCell class] forCellType:0];
}

#pragma mark - SCUChangeServerTableViewControllerModelDelegate methods

- (void)reloadData
{
    [self.tableView reloadData];
}

@end
