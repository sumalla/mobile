//
//  SCUSwingingViewController.m
//  SavantController
//
//  Created by Stephen Silber on 8/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwingingViewController.h"
#import "SCUGradientView.h"
#import "SCUButton.h"

@import Extensions;

@interface SCUSwingingViewController () <SCUSwingingAnimator, UIGestureRecognizerDelegate>

@property (nonatomic, getter = isOpen) BOOL open;
@property (nonatomic) SCUGradientView *shadowMask;

@end

@implementation SCUSwingingViewController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController andSecondaryViewController:(SCUModelTableViewController<SCUSwingingAnimatorDelegate> *)secondaryViewController
{
    NSParameterAssert(rootViewController);
    NSParameterAssert(secondaryViewController);
    NSParameterAssert([secondaryViewController isKindOfClass:[SCUModelTableViewController class]]);
    NSParameterAssert([secondaryViewController conformsToProtocol:@protocol(SCUSwingingAnimatorDelegate)]);
    self = [super init];
    
    if (self)
    {
        self.closeThreshold = [UIDevice isPad] ? .025 : .1;

        if ([UIDevice isPad])
        {
            self.initialSwingPadding = 100;
        }
        else
        {
            self.initialSwingPadding = 60;
        }

        secondaryViewController.swingingDelegate = self;
        [self sav_addChildViewController:secondaryViewController];
        [self.view sav_addFlushConstraintsForView:secondaryViewController.view];
        self.secondaryViewController = secondaryViewController;

        self.shadowMask = [[SCUGradientView alloc] initWithFrame:CGRectZero
                                                       andColors:@[[UIColor clearColor], [[[SCUColors shared] color03] colorWithAlphaComponent:0.50]]];

        self.rootViewController = rootViewController;
        [self sav_addChildViewController:self.rootViewController];
        [self setAnchorPoint:CGPointMake(0.5, 0) forView:self.rootViewController.view];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tap.delegate = self;
        [self.secondaryViewController.view addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[SCUColors shared] color03shade04];
}

- (void)toggleSwinging
{
    if (self.isOpen)
    {
        [self closeSwingWithCompletionHandler:NULL];
    }
    else
    {
        [self openSwingWithCompletionHandler:NULL];
    }
}

- (BOOL)openWithCompletionHandler:(dispatch_block_t)completionHandler
{
    BOOL success = !self.isOpen;

    if (success)
    {
        [self openSwingWithCompletionHandler:completionHandler];
    }

    return success;
}

- (BOOL)closeWithCompletionHandler:(dispatch_block_t)completionHandler
{
    BOOL success = self.isOpen;

    if (success)
    {
        [self closeSwingWithCompletionHandler:completionHandler];
    }

    return success;
}

- (void)openSwingWithCompletionHandler:(dispatch_block_t)completionHandler
{
    self.initialHeight = 165 / (CGRectGetHeight([[UIScreen mainScreen] bounds]));
    self.secondaryViewController.tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.secondaryViewController.view.bounds), 0, 0, 0);
    self.secondaryViewController.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.secondaryViewController.view.bounds));
    [self.view bringSubviewToFront:self.secondaryViewController.view];
    [self.rootViewController.view addSubview:self.shadowMask];
    [self.rootViewController.view sav_addFlushConstraintsForView:self.shadowMask];
    [self.secondaryViewController viewWillAppear:YES];

    [UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:20 options:0 animations:^{

        CGFloat height = CGRectGetHeight(self.secondaryViewController.view.bounds);
        self.secondaryViewController.tableView.contentInset = UIEdgeInsetsMake(height - (height * self.initialHeight), 0, 0, 0);
        self.secondaryViewController.tableView.contentOffset = CGPointMake(0, -(height - (height * self.initialHeight)));
        CGFloat percentage = [self transformRootViewController];
        self.rootViewController.view.alpha = 1 - percentage;

        self.shadowMask.alpha = 1;

    } completion:^(BOOL finished) {
        self.open = YES;
        [self.secondaryViewController viewDidAppear:YES];

        if (completionHandler)
        {
            completionHandler();
        }
    }];
}

- (void)closeSwingWithCompletionHandler:(dispatch_block_t)completionHandler
{
    self.open = NO;
    [self.view bringSubviewToFront:self.rootViewController.view];
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DRotate(transform, 0, 0, 0, 0);

    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.secondaryViewController.tableView.contentOffset = CGPointMake(0, -CGRectGetHeight(self.secondaryViewController.view.bounds));
        self.secondaryViewController.tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.secondaryViewController.view.bounds), 0, 0, 0);
        self.rootViewController.view.layer.transform = transform;
        self.shadowMask.alpha = 0;
        [self.secondaryViewController viewWillDisappear:YES];
        self.rootViewController.view.alpha = 1;
    } completion:^ (BOOL finished) {
        [self.shadowMask removeFromSuperview];
        [self.secondaryViewController viewDidDisappear:YES];

        if (completionHandler)
        {
            completionHandler();
        }

        self.secondaryViewController.tableView.contentInset = UIEdgeInsetsZero;
        self.secondaryViewController.tableView.contentOffset = CGPointZero;
    }];
}

- (CGFloat)transformRootViewController
{
    CGFloat angle = 1 + ((self.secondaryViewController.tableView.contentOffset.y) / (CGRectGetHeight(self.view.bounds) - self.initialSwingPadding));
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 500.0;
    transform = CATransform3DRotate(transform, angle * -M_PI_2, 1, 0, 0);
    self.rootViewController.view.layer.transform = transform;
    return angle;
}

- (void)contentOffsetDidChange:(UIScrollView *)scrollView
{
    if (self.open)
    {
        CGFloat percentage = [self transformRootViewController];
        self.rootViewController.view.alpha = 1 - percentage;

        if (percentage < self.closeThreshold)
        {
            [self closeSwingWithCompletionHandler:NULL];
        }
        
        if (percentage > 0.50)
        {
            [self.shadowMask setColors:@[[UIColor clearColor], [[UIColor blackColor] colorWithAlphaComponent:percentage]]];
            [self.shadowMask setNeedsDisplay];
        }
    }
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#pragma mark - Tap gesture

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self toggleSwinging];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = YES;

    CGPoint location = [gestureRecognizer locationInView:self.secondaryViewController.view];

    if ([self.secondaryViewController.tableView indexPathForRowAtPoint:location])
    {
        shouldBegin = NO;
    }

    return shouldBegin;
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (self.isOpen)
    {
        [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
            [self closeSwingWithCompletionHandler:NULL];
        }];
    }
}

@end
