//
//  SCUInitialSettingsTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsTableViewController.h"
#import "SCUAVSettingsModel.h"
#import "SCUEmptyGradientViewController.h"
#import "SCUAVSettingsVideoTableViewController.h"
#import "SCUAVSettingsAudioTableViewController.h"
#import "SCUAVEqualizerViewController.h"
#import "SCUAVSettingsVideoTableViewController.h"
#import "SCUAVSettingsAudioTableViewController.h"
#import "SCUUserSettingsTableViewController.h"
#import "SCUMainNavbarManager.h"
#import "SCUUserModifyTableViewController.h"

@interface SCUAVSettingsTableViewController () <SCUAVSettingsModelDelegate>

@property (nonatomic) SCUAVSettingsModel *model;

@end

@implementation SCUAVSettingsTableViewController

- (instancetype)init
{
    self = [self initWithModel:[[SCUAVSettingsModel alloc] init]];
    return self;
}

- (instancetype)initWithModel:(SCUAVSettingsModel *)model
{
    self = [super init];
    
    if (self)
    {
        self.model = model;
        self.model.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    self.title = [self.model title];
    self.tableView.rowHeight = 60;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

#pragma mark - SCUMainNavbarManager

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsNavigation | SCUMainNavbarItemsEntertainment;
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

#pragma mark - SCUAVSettingsModelDelegate methods

- (void)navigateBack
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)presentUserList
{
    SCUUserSettingsTableViewController *userSettings = [[SCUUserSettingsTableViewController alloc] init];
    [self.navigationController pushViewController:userSettings animated:YES];
}

- (void)presentUser:(SAVCloudUser *)user
{
    SCUUserModifyTableViewController *viewController = [[SCUUserModifyTableViewController alloc] initWithCloudUser:user];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)onboardSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink delegate:(id<SCUOnboardViewControllerDelegate>)delegate
{
    SCUOnboardViewController *viewController = [[SCUOnboardViewController alloc] initWithSystem:system showDoNotLink:showDoNotLink];
    viewController.delegate = delegate;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)presentNextAVSettingsViewControllerWithModel:(SCUAVSettingsModel *)model
{
    SCUAVSettingsTableViewController *settingsViewController = [[SCUAVSettingsTableViewController alloc] initWithModel:model];
    SCUEmptyGradientViewController *viewController = [[SCUEmptyGradientViewController alloc] initWithRootViewController:settingsViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)presentEqualizerScreenWithModel:(SCUAVSettingsEqualizerModel *)model
{
    SCUAVEqualizerViewController *equalizer = [[SCUAVEqualizerViewController alloc] initWithModel:model];
    [self presentSettingsViewController:equalizer];
}

- (void)presentVideoSettingsScreenWithModel:(SCUAVSettingsVideoModel *)model
{
    SCUAVSettingsVideoTableViewController *video = [[SCUAVSettingsVideoTableViewController alloc] initWithModel:model];
    [self presentSettingsViewController:video];
}

- (void)presentAudioSettingsScreenWithModel:(SCUAVSettingsAudioModel *)model
{
    SCUAVSettingsAudioTableViewController *audio = [[SCUAVSettingsAudioTableViewController alloc] initWithModel:model];
    [self presentSettingsViewController:audio];
}

- (void)presentSettingsViewController:(UIViewController *)settingsViewController
{
    SCUEmptyGradientViewController *viewController = [[SCUEmptyGradientViewController alloc] initWithRootViewController:settingsViewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
