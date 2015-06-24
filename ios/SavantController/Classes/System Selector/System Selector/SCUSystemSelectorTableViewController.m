//
//  SCUSystemSelectorTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorTableViewController.h"
#import "SCUSystemSelectorTableViewModel.h"
#import "SCUPlaceholderTableViewCell.h"
#import "SCUProgressTableViewCell.h"
#import "SCUMainViewController.h"
#import "SCUActionSheet.h"
#import "SCUAlertView.h"

#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>

@interface SCUSystemSelectorTableViewController () <SCUSystemSelectorViewModelDelegate, SCUActionSheetDelegate>

@property (nonatomic) SCUSystemSelectorTableViewModel *model;
@property (nonatomic) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, weak) NSTimer *loadingSpinnerTimer;
@property (nonatomic, getter = isInitialAppearance) BOOL initialAppearance;

@end

@implementation SCUSystemSelectorTableViewController

#pragma mark - View life cycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];  

    self.initialAppearance = YES;
    self.model = [[SCUSystemSelectorTableViewModel alloc] init];
    self.model.delegate = self;

    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(updateSystemList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    self.tableView.rowHeight = 60;
    self.tableView.contentInset = UIEdgeInsetsMake(-15, 0, 0, 0);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.isInitialAppearance)
    {
        self.initialAppearance = NO;

        SAVWeakSelf;
        self.loadingSpinnerTimer = [NSTimer sav_scheduledBlockWithDelay:.5 block:^{
            SAVStrongWeakSelf;
            sSelf.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            sSelf.loadingSpinner.hidesWhenStopped = YES;
            [sSelf.view addSubview:sSelf.loadingSpinner];
            [sSelf.view sav_addCenteredConstraintsForView:sSelf.loadingSpinner];
            [sSelf.loadingSpinner startAnimating];
        }];
    }
}

#pragma mark - SCUSystemSelectorViewModelDelegate methods

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self invalidateSpinner];

    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
}

- (void)reloadTableAnimated:(BOOL)animated
{
    [self invalidateSpinner];

    if (animated)
    {
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

        for (NSUInteger i = 0; i < (NSUInteger)[self.model numberOfSections]; i++)
        {
            [indexSet addIndex:i];
        }

        [self.tableView beginUpdates];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView reloadData];
    }

    [self.refreshControl endRefreshing];
}

- (void)presentDemoModeDialog
{
    NSString *message = NSLocalizedString(@"Run this application in demonstration mode to preview the Savant experience without being connected to a system.", nil);
    NSString *confirmationTitle = NSLocalizedString(@"Run In Demo Mode", nil);
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);

    if ([UIDevice isPhone])
    {
        SCUActionSheet *actionSheet = [[SCUActionSheet alloc] initWithTitle:message
                                                               buttonTitles:@[confirmationTitle]
                                                                cancelTitle:cancelTitle
                                                           destructiveTitle:nil];
        actionSheet.delegate = self;

        [actionSheet showInView:self.view];
    }
    else
    {
        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:nil message:message buttonTitles:@[cancelTitle, confirmationTitle]];
        alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

        SAVWeakSelf;
        alertView.callback = ^(NSUInteger buttonIndex) {
            if (buttonIndex == 1)
            {
                [wSelf startDemoMode];
            }
        };

        [alertView show];
    }
}

- (void)onboardSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink delegate:(id<SCUOnboardViewControllerDelegate>)delegate
{
    SCUOnboardViewController *viewController = [[SCUOnboardViewController alloc] initWithSystem:system showDoNotLink:showDoNotLink];
    viewController.delegate = delegate;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)systemDidDisconnectWhileTryingToLogin
{
    SCUAlertView *view = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"%@ became disconnected.", nil), [SavantControl sharedControl].currentSystem.name]
                                                buttonTitles:@[NSLocalizedString(@"OK", nil)]];

    SAVWeakSelf;
    view.callback = ^(NSUInteger buttonIndex) {
        [[SCUMainViewController sharedInstance] cleanupFailedLogin];
        [wSelf.model clearCheckMark];
    };

    if (self.presentedViewController)
    {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
            [self.navigationController popToRootViewControllerAnimated:YES];
            [view show];
        }];
    }
    else
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [view show];
    }
}

#pragma mark - Methods to subclass

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUProgressTableViewCell class] forCellType:SCUSystemSelectorViewModelCellTypeSystem];
    [self.tableView sav_registerClass:[SCUPlaceholderTableViewCell class] forCellType:SCUSystemSelectorViewModelCellTypePlaceholder];
}

#pragma mark - SCUActionSheetDelegate/UIAlertViewDelegate methods

- (void)actionSheet:(SCUActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self startDemoMode];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = tableView.rowHeight;

    if ([self.model cellTypeForIndexPath:indexPath] == SCUSystemSelectorViewModelCellTypePlaceholder)
    {
        height = [tableView sav_heightForText:[self.model modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyTitle] font:[UIFont systemFontOfSize:18]];
    }

    return height;
}

- (void)startDemoMode
{
    [[SCUMainViewController sharedInstance].popController dismissPopoverAnimated:YES];
    [self.model startDemoMode];
}

#pragma mark -

- (void)invalidateSpinner
{
    self.initialAppearance = NO;

    if (self.loadingSpinner)
    {
        [self.loadingSpinner removeFromSuperview];
        self.loadingSpinner = nil;
    }

    [self.loadingSpinnerTimer invalidate];
    self.loadingSpinnerTimer = nil;
}

- (void)updateSystemList
{
    if (![[SavantControl sharedControl] updateSystemList])
    {
        [self.refreshControl endRefreshing];
    }
}

@end
