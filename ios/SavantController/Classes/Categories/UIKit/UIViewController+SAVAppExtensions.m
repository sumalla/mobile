//
//  UIViewController+SAVAppExentions.m
//  SavantController
//
//  Created by Alicia Tams on 2/25/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "UIViewController+SAVAppExtensions.h"
#import <SavantExtensions.h>

@implementation UIViewController (SAVAppExtensions)

- (NSUInteger)supportedInterfaceOrientations
{
    if ([UIDevice isPad])
    {
        return UIInterfaceOrientationMaskAll;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
