//
//  SCUTablePopoverController.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPopoverController.h"

@import Extensions;

@interface SCUPopoverController () <SAVNavigationControllerDelegate>

@end

@implementation SCUPopoverController

- (instancetype)initWithContentViewController:(UIViewController *)viewController
{
    //TODO: Fix magic
//    IMP originalImp = SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return @"com.apple.iBooks";
//    });
//
//    self = [super initWithContentViewController:viewController];
//
//    SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return originalImp([NSBundle mainBundle], @selector(bundleIdentifier));
//    });

    if (self)
    {
        viewController.view.backgroundColor = [UIColor clearColor];

        if ([viewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navCon = (UINavigationController *)viewController;
            [navCon addDelegate:self];
        }
    }

    return self;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    CGSize contentSize = viewController.preferredContentSize;
    contentSize.height += 44;

    self.popoverContentSize = contentSize;
}

- (void)presentPopoverFromButton:(UIButton *)button permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    [self presentPopoverFromRect:button.frame inView:button.superview permittedArrowDirections:arrowDirections animated:animated];
}

//-------------------------------------------------------------------
// Some magic to enable popovers on iOS 8 for iPhone
//-------------------------------------------------------------------
//TODO: Fix this magic
//- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
//{
//    IMP originalImp = SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return @"com.apple.iBooks";
//    });
//
//    [super presentPopoverFromRect:rect inView:view permittedArrowDirections:arrowDirections animated:animated];
//
//    SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return originalImp([NSBundle mainBundle], @selector(bundleIdentifier));
//    });
//}
//
//- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
//{
//    IMP originalImp = SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return @"com.apple.iBooks";
//    });
//
//    [super presentPopoverFromBarButtonItem:item permittedArrowDirections:arrowDirections animated:animated];
//
//    SAVReplaceMethodOnClassWithBlock([NSBundle class], @selector(bundleIdentifier), ^{
//        return originalImp([NSBundle mainBundle], @selector(bundleIdentifier));
//    });
//}

@end
