//
//  SCUUserSettingsTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserSettingsTableViewController.h"
#import "SCUUserSettingsTableViewControllerModel.h"
#import <SavantExtensions/SavantExtensions.h>
#import "SCUUserModifyTableViewController.h"

@interface SCUUserSettingsTableViewController () <SCUUserSettingsTableViewControllerModelDelegate>

@property (nonatomic) SCUUserSettingsTableViewControllerModel *model;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) NSTimer *spinnerTimer;
@property (nonatomic) BOOL hasLoadedInitialData;

@end

@implementation SCUUserSettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Users", nil);
    self.model = [[SCUUserSettingsTableViewControllerModel alloc] init];
    self.model.delegate = self;
    self.tableView.rowHeight = 60;

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self.model action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(createUser)];
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.hasLoadedInitialData)
    {
        return;
    }

    SAVWeakSelf;
    self.spinnerTimer = [NSTimer sav_scheduledBlockWithDelay:0 block:^{
        SAVStrongWeakSelf;
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.hidesWhenStopped = YES;
        [sSelf.view addSubview:spinner];
        [spinner startAnimating];
        [self.view sav_addCenteredConstraintsForView:spinner];
        sSelf.spinner = spinner;
    }];
}

#pragma mark - SCUUserSettingsTableViewControllerModelDelegate methods

- (void)reloadData
{
    self.hasLoadedInitialData = YES;
    [self.spinnerTimer invalidate];
    self.spinnerTimer = nil;
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
    self.spinner = nil;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)presentSettingsForUser:(SAVCloudUser *)user
{
    SCUUserModifyTableViewController *createInviteController = [[SCUUserModifyTableViewController alloc] initWithCloudUser:user];
    [self.navigationController pushViewController:createInviteController animated:YES];
}

#pragma mark - Actions

- (void)createUser
{
    [self presentSettingsForUser:nil];
}

@end
