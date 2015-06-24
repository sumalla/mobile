//
//  SCUNotificationCreationTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 1/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUNotificationCreationDataSource.h"

@implementation SCUNotificationCreationTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    return [super init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Notifications", nil);
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .01)];

    self.tableView.rowHeight = 60;
    self.tableView.contentInset = UIEdgeInsetsMake(34.5, 0, 0, 0);

    if (!self.creationVC.isLeftView)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelTapped:)];
    }
}

- (void)cancelTapped:(UIBarButtonItem *)button
{
    [self popViewController];
}

- (void)closeIfEmpty
{
//    self.creationVC.editingNotification = [self.creationVC.notification copy];
//    
//    if (self.creationVC.isLeftView)
//    {
//        if ([[self.creationVC.scene services] count] ||
//            [self.creationVC.scene.lightingOff count] ||
//            [self.creationVC.scene.hvacOff count] ||
//            [self.creationVC.scene.avOff count])
//        {
//            [self popViewControllerCanceled];
//        }
//        else
//        {
//            [self dismissViewController];
//        }
//    }
//    else
//    {
//        [self popViewControllerCanceled];
//    }
//    
//    if ([self.model respondsToSelector:@selector(doneEditing)])
//    {
//        [self.model doneEditing];
//    }
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (SCUPassthroughViewController *)passthroughVC
{
    return (SCUPassthroughViewController *)self.parentViewController;
}

- (void)dismissViewController
{
    [self.creationVC dismissViewControllerAnimated:YES completion:NULL];
    
    [self.creationVC.delegate viewControllerDismissedAnimated:YES];
}

- (void)popViewController
{
    if ([UIDevice isPad] && [self.creationVC.states count] == 2)
    {
        [self.creationVC viewControllerDidCancel:self];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)popViewControllerCanceled
{
    if ([UIDevice isPad] && !self.creationVC.isLeftView)
    {
        [self.creationVC viewControllerDidCancel:self];
    }
    else
    {
        [self popViewController];
    }
}

- (void)popToRootViewController
{
    if ([UIDevice isPad] && !self.creationVC.isLeftView)
    {
        [self.creationVC viewControllerDidDismiss:self];
    }
    else
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];
    headerLabel.textColor = [[SCUColors shared] color03shade07];
    headerLabel.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    [headerView addSubview:headerLabel];
    [headerView sav_pinView:headerLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:15];
    [headerView sav_pinView:headerLabel withOptions:SAVViewPinningOptionsToBottom withSpace:8];
    
    return headerView;
}

@end
