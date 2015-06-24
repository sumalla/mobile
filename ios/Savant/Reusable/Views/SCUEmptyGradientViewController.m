//
//  SCUEmptyGradientViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEmptyGradientViewController.h"
#import "SCUGradientView.h"

@import Extensions;

@interface SCUEmptyGradientViewController ()

@property (nonatomic) UIViewController *rootViewController;

@end

@implementation SCUEmptyGradientViewController

- (instancetype)initWithRootViewController:(UIViewController *)viewController
{
    self = [super init];

    if (self)
    {
        self.rootViewController = viewController;
    }

    return self;
}

- (void)loadView
{
    self.view = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:[SCUGradientView standardGradient]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self sav_addChildViewController:self.rootViewController];
    [self.view sav_addFlushConstraintsForView:self.rootViewController.view];
}

#pragma mark - Overrides

- (UINavigationItem *)navigationItem
{
    return self.rootViewController.navigationItem;
}

- (NSString *)title
{
    return self.rootViewController.title;
}

@end
