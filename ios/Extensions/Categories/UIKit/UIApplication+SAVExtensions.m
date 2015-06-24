//
//  UIApplication+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 4/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIApplication+SAVExtensions.h"
#import "SAVUtils.h"

@implementation UIApplication (SAVExtensions)

+ (CGFloat)sav_statusBarHeight
{
    CGRect frame = [[UIApplication sav_sharedApplicationOrException] statusBarFrame];
    return MIN(CGRectGetHeight(frame), CGRectGetWidth(frame));
}


+ (UIApplication *)sav_sharedApplicationOrException
{
    UIApplication *application = nil;

    if ([UIApplication respondsToSelector:@selector(sharedApplication)])
    {
        SAVFunctionForSelector(sharedApplication, [UIApplication class], @selector(sharedApplication), UIApplication *);
        application = sharedApplication([UIApplication class], @selector(sharedApplication));
    }
    else
    {
        [NSException raise:NSInternalInconsistencyException format:@""];
    }

    return application;
}

@end
