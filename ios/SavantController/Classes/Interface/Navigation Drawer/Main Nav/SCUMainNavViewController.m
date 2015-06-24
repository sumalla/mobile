//
//  SCUMainNavViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainNavViewController.h"
#import "SCUMainNavViewModel.h"
#import "SCUMainNavCell.h"

@interface SCUMainNavViewController () <SCUMainNavDelegate>

@property (nonatomic) SCUMainNavViewModel *model;

@end

@implementation SCUMainNavViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [[SCUMainNavViewModel alloc] init];
    self.model.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = [UIDevice isShortPhone] ? 50 : 80;
    self.tableView.scrollEnabled = NO;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
}

- (void)selectedViewDidChange
{
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.model.selectedView inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUMainNavCell class] forCellType:0];
}

@end