//
//  SCUSceneFavoritesTableViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneFavoritesTableViewController.h"
#import "SCUSceneFavoritesDataSource.h"

@interface SCUSceneFavoritesTableViewController ()

@property (weak) SCUSceneFavoritesDataSource *model;

@end

@implementation SCUSceneFavoritesTableViewController

- (instancetype)initWithModel:(SCUSceneFavoritesDataSource *)model
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];
    headerLabel.textColor = [[SCUColors shared] color03shade07];
    headerLabel.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];

    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:headerLabel];
    [headerView sav_addConstraintsForView:headerLabel withEdgeInsets:UIEdgeInsetsMake(0, 15, -15, 0)];

    return headerView;
}

@end
