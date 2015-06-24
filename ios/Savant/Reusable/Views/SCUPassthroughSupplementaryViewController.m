//
//  SCUPassthroughSupplementaryViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPassthroughSupplementaryViewController.h"
#import "SCUPassthroughSupplementaryViewControllerPrivate.h"

@interface SCUPassthroughSupplementaryViewController ()

@end

@implementation SCUPassthroughSupplementaryViewController

- (void)setVisible:(BOOL)visible
{
    if (_visible != visible)
    {
        _visible = visible;

        if (visible)
        {
            [self.visibilityDelegate showSupplementaryViewController:self];
        }
        else
        {
            [self.visibilityDelegate hideSupplementaryViewController:self];
        }
    }
}

@end
