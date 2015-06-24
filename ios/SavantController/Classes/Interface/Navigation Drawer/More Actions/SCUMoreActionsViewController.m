//
//  SCUMoreActionsViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMoreActionsViewController.h"
#import "SCUMoreActionsViewModel.h"
#import "SCUMoreActionsCell.h"

@interface SCUMoreActionsViewController () <SCUMoreActionsViewModelDelegate>

@property (nonatomic) SCUMoreActionsViewModel *model;

@end

@implementation SCUMoreActionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [[SCUMoreActionsViewModel alloc] init];
    self.model.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    self.tableView.rowHeight = [UIDevice isShortPhone] ? 60 : 80;
    self.tableView.contentInset = UIEdgeInsetsMake(-30, 0, 0, 0);
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.model loadData];
    [super viewDidAppear:animated];
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUMoreActionsCell class] forCellType:0];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - SCUMoreActionsViewModelDelegate methods

- (void)reloadData
{
    [self.tableView reloadData];
    [self.navMenuVC updateMoreActionsTable];
}

@end
