//
//  SCUUserSelectorViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserSelectorViewController.h"
#import "SCUUserSelectorViewModel.h"
#import "SCUUserSelectorTableViewCell.h"
#import "SCUPlaceholderTableViewCell.h"

@interface SCUUserSelectorViewController ()

@property (nonatomic) SCUUserSelectorViewModel *model;

@end

@implementation SCUUserSelectorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [[SCUUserSelectorViewModel alloc] init];
    self.tableView.rowHeight = 60;
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUPlaceholderTableViewCell class] forCellType:SCUUserSelectorTableViewCellTypePlaceholder];
    [self.tableView sav_registerClass:[SCUUserSelectorTableViewCell class] forCellType:SCUUserSelectorTableViewCellTypeUser];
}

@end
