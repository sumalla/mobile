//
//  SCULoadingIndicatorViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULoadingIndicatorViewController.h"
@import Extensions;

@interface SCULoadingIndicatorViewController ()

@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) NSTimer *timer;

@end

@implementation SCULoadingIndicatorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidden = YES;
    [self.view addSubview:self.spinner];
    [self.view sav_addCenteredConstraintsForView:self.spinner];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.viewController)
    {
        SAVWeakSelf;
        self.timer = [NSTimer sav_scheduledBlockWithDelay:.5 block:^{
            SAVStrongWeakSelf;
            sSelf.spinner.hidden = NO;
            [sSelf.spinner startAnimating];
        }];
    }
}

- (void)loadViewController:(UIViewController *)viewController
{
    [self.timer invalidate];
    [self.spinner stopAnimating];
    self.spinner.hidden = YES;

    if (!self.viewController)
    {
        self.viewController = viewController;
        [self sav_addChildViewController:viewController];
        [self.view sav_addFlushConstraintsForView:viewController.view];
    }
}

@end
