//
//  SCUSystemSelectorSwingingContainer.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorSwingingContainer.h"
#import "SCUSystemSelectorViewController.h"
#import "SCUSystemSelectorSettingsTableViewController.h"

@interface SCUSystemSelectorSwingingContainer ()

@property (nonatomic) SCUSystemSelectorViewController *systemSelectorViewController;
@property (nonatomic) SCUThemedNavigationViewController *navController;

@end

@implementation SCUSystemSelectorSwingingContainer

- (instancetype)initWithFromLocation:(SCUSystemSelectorFromLocation)fromLocation
{
    self.systemSelectorViewController = [[SCUSystemSelectorViewController alloc] initWithFromLocation:fromLocation];
    SCUThemedNavigationViewController *navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:self.systemSelectorViewController];
    self.navController = navController;
    SCUSystemSelectorSettingsTableViewController *settingsViewController = [[SCUSystemSelectorSettingsTableViewController alloc] init];
    self = [super initWithRootViewController:navController andSecondaryViewController:settingsViewController];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    self.systemSelectorViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SettingsGear"]
                                                                                                           style:UIBarButtonItemStylePlain
                                                                                                          target:self
                                                                                                          action:@selector(toggleSwinging)];
}

@end
