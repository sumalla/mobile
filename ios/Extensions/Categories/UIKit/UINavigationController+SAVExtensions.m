//
//  UINavigationController+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UINavigationController+SAVExtensions.h"
#import "SAVUtils.h"

@interface UINavigationController () <UINavigationControllerDelegate>

@property (nonatomic) NSHashTable *sav_delegates;

@end

@implementation UINavigationController (SAVExtensions)

- (void)addDelegate:(id<SAVNavigationControllerDelegate>)delegate
{
    if (!self.sav_delegates)
    {
        self.sav_delegates = [NSHashTable weakObjectsHashTable];
    }

    if (self.delegate && self.delegate != self)
    {
        [self.sav_delegates addObject:self.delegate];
    }

    self.delegate = self;

    [self.sav_delegates addObject:delegate];
}

- (void)removeDelegate:(id<SAVNavigationControllerDelegate>)delegate
{
    [self.sav_delegates removeObject:delegate];
}

#pragma mark - UINavigationControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    for (id<SAVNavigationControllerDelegate> delegate in self.sav_delegates)
    {
        if ([delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
        {
            [delegate navigationController:navigationController willShowViewController:viewController animated:animated];
        }
    }

    NSUInteger newViewControllerCount = [navigationController.viewControllers count];

    if (newViewControllerCount < [self.sav_viewControllersCount unsignedIntegerValue])
    {
        for (id<SAVNavigationControllerDelegate> delegate in self.sav_delegates)
        {
            if ([delegate respondsToSelector:@selector(navigationController:willPopToViewController:)])
            {
                [delegate navigationController:self willPopToViewController:viewController];
            }
        }
    }

    self.sav_viewControllersCount = @(newViewControllerCount);
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    for (id<SAVNavigationControllerDelegate> delegate in self.sav_delegates)
    {
        if ([delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
        {
            [delegate navigationController:navigationController didShowViewController:viewController animated:animated];
        }
    }
}

#pragma mark -

SAVSynthesizeCategoryProperty(sav_delegates, setSav_delegates, NSHashTable *, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

SAVSynthesizeCategoryProperty(sav_viewControllersCount, setSav_viewControllersCount, NSNumber *, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

@end
