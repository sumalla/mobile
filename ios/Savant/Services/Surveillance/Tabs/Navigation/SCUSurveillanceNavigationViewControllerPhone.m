//
//  SCUSurveillanceNavigationViewControllerPhone.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSurveillanceNavigationViewControllerPhone.h"
#import "SCUSurveillanceNavigationViewControllerPrivate.h"

@implementation SCUSurveillanceNavigationViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView addSubview:self.directionalSwipeView];
    [self.contentView sav_addFlushConstraintsForView:self.directionalSwipeView];
    
    [self.directionalSwipeView sav_pinView:self.exitButton withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToLeft withSpace:5.0];
    [self.directionalSwipeView sav_setSize:CGSizeMake(60, 60) forView:self.exitButton isRelative:NO];
}

@end
