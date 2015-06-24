//
//  SCUNavigationMenuViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNavigationMenuViewController.h"
#import "SCUButton.h"
#import "SCUToolbarButton.h"
#import "SCUNavigationBar.h"
#import "SCUInterface.h"
#import "SCUGradientView.h"
#import "SCUMoreActionsViewController.h"
#import "SCUMainNavViewController.h"
#import "SCUMainViewController.h"

#import <SavantControl/SavantControl.h>

@interface SCUNavigationMenuViewController ()

@property (nonatomic) SCUMoreActionsViewController *moreVC;
@property (nonatomic) SCUButton *homeOverview;
@property (nonatomic) NSInteger lastRowCount;

@end

@implementation SCUNavigationMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.lastRowCount = 0;
    
    SCUGradientView *gradientView = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[SCUColors shared] color03shade01], [[SCUColors shared] color03]]];
    gradientView.startPoint = CGPointMake(0, .5);
    gradientView.endPoint = CGPointMake(1, .5);
    [self.view addSubview:gradientView];
    [self.view sav_addFlushConstraintsForView:gradientView];

    SCUMainNavViewController *mainNav = [[SCUMainNavViewController alloc] init];
    [self sav_addChildViewController:mainNav];

    [self.view sav_pinView:mainNav.view withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:mainNav.view withOptions:SAVViewPinningOptionsToTop withSpace:15];
    [self.view sav_setHeight:250 forView:mainNav.view isRelative:NO];

    SCUToolbarButton *hamburgerButton = [SCUNavigationBar navigationButton];
    hamburgerButton.frame = CGRectMake(0, 0, 22, 42);
    hamburgerButton.tintColor = [[SCUColors shared] color04];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:hamburgerButton];

    SCUGradientView *buttonGradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03shade01] colorWithAlphaComponent:.9], [[[SCUColors shared] color03shade01] colorWithAlphaComponent:.7]]];
    buttonGradient.startPoint = CGPointMake(0, .5);
    buttonGradient.endPoint = CGPointMake(1, .5);

    self.homeOverview = [[SCUButton alloc] initWithCustomView:buttonGradient];
    self.homeOverview.backgroundColor = [UIColor sav_colorWithRGBValue:0x404040];
    self.homeOverview.target = self;
    self.homeOverview.releaseAction = @selector(showSystemSelector);

    UILabel *currentUserLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    currentUserLabel.text = [SavantControl sharedControl].currentUserName;
    currentUserLabel.font = [UIFont boldSystemFontOfSize:18];
    currentUserLabel.textColor = [[SCUColors shared] color04];
    currentUserLabel.adjustsFontSizeToFitWidth = YES;
    currentUserLabel.minimumScaleFactor = .7;
    [self.homeOverview addSubview:currentUserLabel];

    UILabel *currentLocationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    currentLocationLabel.text = [[SavantControl sharedControl].currentSystem.name uppercaseString];
    currentLocationLabel.font = [UIFont fontWithName:@"Gotham-Light" size:14];
    currentLocationLabel.textColor = [[SCUColors shared] color03shade07];
    currentLocationLabel.adjustsFontSizeToFitWidth = YES;
    currentLocationLabel.minimumScaleFactor = .7;
    [self.homeOverview addSubview:currentLocationLabel];

    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
    [self.homeOverview addSubview:separator];
    [self.homeOverview sav_pinView:separator withOptions:SAVViewPinningOptionsCenterY | SAVViewPinningOptionsHorizontally];
    [self.homeOverview sav_setHeight:[UIScreen screenPixel] forView:separator isRelative:NO];

    [self.homeOverview sav_pinView:currentUserLabel withOptions:SAVViewPinningOptionsToTop ofView:separator withSpace:0];
    [self.homeOverview sav_pinView:currentUserLabel withOptions:SAVViewPinningOptionsToLeft withSpace:18];
    [self.homeOverview sav_pinView:currentUserLabel withOptions:SAVViewPinningOptionsToRight withSpace:SAVViewAutoLayoutStandardSpace];

    [self.homeOverview sav_pinView:currentLocationLabel withOptions:SAVViewPinningOptionsToBottom ofView:separator withSpace:0];
    [self.homeOverview sav_pinView:currentLocationLabel withOptions:SAVViewPinningOptionsToLeft withSpace:18];
    [self.homeOverview sav_pinView:currentLocationLabel withOptions:SAVViewPinningOptionsToRight withSpace:SAVViewAutoLayoutStandardSpace];

    [self.view addSubview:self.homeOverview];
    [self.view sav_pinView:self.homeOverview withOptions:SAVViewPinningOptionsToBottom | SAVViewPinningOptionsHorizontally];
    [self.view sav_setHeight:80 forView:self.homeOverview isRelative:NO];

    self.moreVC = [[SCUMoreActionsViewController alloc] init];
    [self sav_addChildViewController:self.moreVC];

    NSInteger numberOfRows = [self.moreVC.tableView.dataSource tableView:self.moreVC.tableView numberOfRowsInSection:0];
    CGFloat tableHeight = numberOfRows * self.moreVC.tableView.rowHeight;

    [self.view sav_pinView:self.moreVC.view withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:self.moreVC .view withOptions:SAVViewPinningOptionsToTop ofView:self.homeOverview withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_setHeight:tableHeight forView:self.moreVC .view isRelative:NO];
}

- (void)showSystemSelector
{
    [[SavantControl sharedControl] disconnect];
    [[SCUMainViewController sharedInstance] presentSystemSelector:SCUSystemSelectorFromLocationInterface];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateMoreActionsTable];
}

- (void)updateMoreActionsTable
{
    NSInteger numberOfRows = [self.moreVC.tableView.dataSource tableView:self.moreVC.tableView numberOfRowsInSection:0];
    
    if (numberOfRows - self.lastRowCount != 0)
    {
        [self.moreVC sav_removeFromParentViewController];
        [self sav_addChildViewController:self.moreVC];
        
        self.moreVC.navMenuVC = self;
        
        CGFloat tableHeight = numberOfRows * self.moreVC.tableView.rowHeight;
        
        [self.view sav_pinView:self.moreVC.view withOptions:SAVViewPinningOptionsHorizontally];
        [self.view sav_pinView:self.moreVC .view withOptions:SAVViewPinningOptionsToTop ofView:self.homeOverview withSpace:SAVViewAutoLayoutStandardSpace];
        [self.view sav_setHeight:tableHeight forView:self.moreVC .view isRelative:NO];
        
        self.lastRowCount = numberOfRows;
    }
}

@end
