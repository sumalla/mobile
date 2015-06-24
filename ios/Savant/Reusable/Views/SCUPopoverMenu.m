//
//  SCUPopoverMenu.m
//  SavantController
//
//  Created by Nathan Trapp on 7/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPopoverMenu.h"
#import "SCUPopoverController.h"
@import Extensions;

@interface SCUPopoverMenu () <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>

@property SCUPopoverController *popover;
@property UITableViewController *tableViewController;

@end

@implementation SCUPopoverMenu

- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles
{
    self = [super init];
    if (self)
    {
        self.buttonTitles = buttonTitles;
        self.selectedIndex = -1;
    }
    return self;
}

- (void)showFromToolbar:(UIToolbar *)view
{
    [self showFromView:view animated:YES];
}

- (void)showFromTabBar:(UITabBar *)view
{
    [self showFromView:view animated:YES];
}

- (void)showFromView:(UIView *)view animated:(BOOL)animated
{
    [self showFromRect:view.frame inView:view.superview animated:YES];
}

- (void)showFromButton:(UIButton *)button animated:(BOOL)animated
{
    [self showFromView:button animated:animated];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    self.tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.tableViewController.tableView.backgroundColor = [UIColor clearColor];
    self.tableViewController.tableView.dataSource = self;
    self.tableViewController.tableView.delegate = self;
    self.tableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewController.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .1)];
    self.tableViewController.tableView.sectionFooterHeight = 0;
    self.tableViewController.tableView.sectionHeaderHeight = 0;
    self.tableViewController.tableView.allowsMultipleSelection = NO;
    self.tableViewController.tableView.contentInset = UIEdgeInsetsMake(0, 0, -20, 0);
    [self.tableViewController.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

    self.popover = [[SCUPopoverController alloc] initWithContentViewController:self.tableViewController];

    CGFloat height = 44 * [self.buttonTitles count];

    self.popover.popoverContentSize = CGSizeMake(320, height);
    [self.popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:animated];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;

    if (self.tableViewController)
    {
        [self.tableViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]
                                                        animated:YES
                                                  scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.buttonTitles count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callback)
    {
        self.callback(indexPath.row);
    }

    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    cell.textLabel.text = self.buttonTitles[indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.selectedBackgroundView = [[UIView alloc] init];
    cell.selectedBackgroundView.backgroundColor = [UIColor sav_colorWithRGBValue:0xc4c4c4 alpha:.8];
    cell.textLabel.highlightedTextColor = [[SCUColors shared] color01];
    cell.textLabel.textColor = [[SCUColors shared] color03shade06];
    cell.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];

    if (![tableView indexPathForSelectedRow])
    {
        [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]
                                                        animated:NO
                                                  scrollPosition:UITableViewScrollPositionMiddle];
    }

    return cell;
}

#pragma mark - UIPopoverDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (self.callback)
    {
        self.callback(-1);
    }

    self.popover = nil;
}

@end
