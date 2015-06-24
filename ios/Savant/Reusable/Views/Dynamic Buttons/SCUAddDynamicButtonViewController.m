//
//  SCUAddDynamicButtonViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddDynamicButtonViewController.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUAddDynamicButtonViewModel.h"

@interface SCUAddDynamicButtonViewController () <SCUAddDynamicButtonViewModelDelegate>

@end

@implementation SCUAddDynamicButtonViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Add Button", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    self.model.delegate = self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    NSString *labelText = cell.textLabel.text;
    labelText = [labelText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    cell.textLabel.text = labelText;
    return cell;
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self.tableView reloadData];

    if ([self.model numberOfItemsInSection:0] < 1)
    {
        [self done];
    }
}

#pragma mark - Actions

- (void)done
{
    if (self.delegate)
    {
        [self.delegate finshedAddingObjects];
    }
    [self dismissViewControllerAnimated:YES completion:^{

    }];
}

#pragma mark - SCUAddDynamicButtonViewModelDelegate

- (void)addButton:(NSDictionary *)button
{
    if ([self.model.dataSource count])
    {
        [self.tableView reloadData];
    }
    else
    {
        [self done];
    }
    
    [self.delegate addButton:button];
}

@end
