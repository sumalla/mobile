//
//  SCUPassthroughViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPassthroughViewController.h"
#import "SCUMainToolbarManager.h"
#import "SCUMainNavbarManager.h"
#import "SCUGradientView.h"
#import "SCUPassthroughSupplementaryViewControllerPrivate.h"

@import Extensions;

#define TOOLBAR_HEIGHT 42

@interface SCUPassthroughViewController () <SCUPassthroughSupplementaryViewControllerVisibilityDelegate>

@property (nonatomic) UIViewController *originalRootViewController;
@property (nonatomic, weak) SCUToolbar *toolbar;
@property (nonatomic) NSArray *toolbarConstraints;
@property (nonatomic) BOOL viewHasLoaded;
@property (nonatomic) SCUPassthroughSupplementaryViewController *supplementaryViewController;
@property (nonatomic) SAVViewPinningOptions supplementaryPinningOptions;
@property (nonatomic) CGFloat supplementarySize;

@end

@interface SCUPassthroughView : UIView

@property (nonatomic, weak) SCUPassthroughViewController *delegate;

- (instancetype)initWithDelegate:(SCUPassthroughViewController *)delegate;

@end

@implementation SCUPassthroughView

- (instancetype)initWithDelegate:(SCUPassthroughViewController *)delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self.delegate.rootViewController respondsToSelector:@selector(userInteractionDetected:)])
    {
        [self.delegate.rootViewController userInteractionDetected:point];
    }

    return [super hitTest:point withEvent:event];
}

@end

@implementation SCUPassthroughViewController

- (void)loadView
{
    if (self.detectUserInteraction)
    {
        self.view = [[SCUPassthroughView alloc] initWithDelegate:self];
    }
    else
    {
        [super loadView];
    }
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];

    if (self)
    {
        self.rootViewController = rootViewController;
    }

    return self;
}

- (void)setSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController withPinningOptions:(SAVViewPinningOptions)options size:(CGFloat)size
{
    [self.supplementaryViewController sav_removeFromParentViewController];

    viewController.visibilityDelegate = self;
    self.supplementaryViewController = viewController;
    self.supplementaryPinningOptions = options;
    self.supplementarySize = size;

    if (self.isViewLoaded)
    {
        [self sav_addChildViewController:self.supplementaryViewController];
        [self configureToolbar];
    }
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    if (_rootViewController != rootViewController)
    {
        [_rootViewController sav_removeFromParentViewController];
        _rootViewController = rootViewController;

        if (self.isViewLoaded)
        {
            [self sav_addChildViewController:rootViewController];
            [self configureToolbar];
        }
    }

    if (!self.originalRootViewController)
    {
        self.originalRootViewController = rootViewController;
    }

    self.originalRootViewController.navigationItem.title = rootViewController.title;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.rootViewController)
    {
        [self sav_addChildViewController:self.rootViewController];
    }

    if (self.supplementaryViewController)
    {
        [self sav_addChildViewController:self.supplementaryViewController];
    }

    SCUToolbar *toolbar = [[SCUToolbar alloc] initWithFrame:CGRectZero];
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;

    self.view.backgroundColor = self.backgroundColor;

    self.viewHasLoaded = YES;

    [self configureToolbar];
}

- (void)configureToolbar
{
    if (self.viewHasLoaded)
    {
        NSDictionary *metrics = @{@"top": @(self.edgeInsets.top),
                                  @"left": @(self.edgeInsets.left),
                                  @"right": @(self.edgeInsets.right),
                                  @"bottom": @(self.edgeInsets.bottom + self.footerHeight),
                                  @"toolbarHeight": @TOOLBAR_HEIGHT,
                                  @"supplementarySize": @(self.supplementarySize)};

        if (self.toolbarConstraints)
        {
            [self.view removeConstraints:self.toolbarConstraints];
        }

        if (self.rootViewController)
        {
            if ([self.rootViewController conformsToProtocol:@protocol(SCUMainToolbarManager)])
            {
                UIViewController <SCUMainToolbarManager> *rvc = (UIViewController  <SCUMainToolbarManager> *)self.rootViewController;

                if (self.toolbar)
                {
                    if ([rvc respondsToSelector:@selector(mainToolbarIsVisible)] && rvc.mainToolbarIsVisible)
                    {
                        [self.view bringSubviewToFront:self.toolbar];
                        self.toolbar.hidden = NO;
                        [self.toolbar configureWithManager:rvc];

                        if (self.supplementaryViewController.isVisible)
                        {
                            self.supplementaryViewController.view.hidden = NO;

                            self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                             metrics:metrics
                                                                                               views:@{@"svcView": rvc.view, @"toolbar": self.toolbar, @"supplementary": self.supplementaryViewController.view}
                                                                                             formats:@[@"|[toolbar]|",
                                                                                                       @"|[supplementary]|",
                                                                                                       @"|-(left)-[svcView]-(right)-|",
                                                                                                       @"V:|[toolbar(toolbarHeight)][supplementary(supplementarySize)]-(top)-[svcView]-(bottom)-|"]];
                        }
                        else
                        {
                            self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                             metrics:metrics
                                                                                               views:@{@"svcView": rvc.view, @"toolbar": self.toolbar}
                                                                                             formats:@[@"|[toolbar]|",
                                                                                                       @"|-(left)-[svcView]-(right)-|",
                                                                                                       @"V:|[toolbar(toolbarHeight)]-(top)-[svcView]-(bottom)-|"]];
                        }
                    }
                    else
                    {
                        self.toolbar.hidden = YES;

                        if (self.supplementaryViewController.isVisible)
                        {
                            self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                               views:@{@"content": rvc.view, @"supplementary": self.supplementaryViewController.view}
                                                                                             formats:@[@"|-left-[content]-right-|",
                                                                                                       @"|[supplementary]|",
                                                                                                       @"V:|[supplementary(supplementarySize)]-top-[content]-bottom-|"]];
                        }
                        else
                        {
                            self.supplementaryViewController.view.hidden = YES;

                            self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                             metrics:metrics
                                                                                               views:@{@"view": rvc.view}
                                                                                             formats:@[@"|-(left)-[view]-(right)-|",
                                                                                                       @"V:|-(top)-[view]-(bottom)-|"]];
                        }
                    }

                    [self.view addConstraints:self.toolbarConstraints];
                }
            }
            else
            {
                self.toolbar.hidden = YES;

                if (self.supplementaryViewController.isVisible)
                {
                    self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                       views:@{@"content": self.rootViewController.view, @"supplementary": self.supplementaryViewController.view}
                                                                                     formats:@[@"|-left-[content]-right-|",
                                                                                               @"|[supplementary]|",
                                                                                               @"V:|[supplementary(supplementarySize)]-top-[content]-bottom-|"]];
                }
                else
                {
                    self.toolbarConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                     metrics:metrics
                                                                                       views:@{@"view": self.rootViewController.view}
                                                                                     formats:@[@"|-(left)-[view]-(right)-|",
                                                                                               @"V:|-(top)-[view]-(bottom)-|"]];
                }
                
                [self.view addConstraints:self.toolbarConstraints];
            }
        }

        if (self.footerView)
        {
            [self.footerView removeFromSuperview];

            [self.view addSubview:self.footerView];
            [self.view sav_pinView:self.footerView withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsHorizontally];
            [self.view sav_setHeight:self.footerHeight forView:self.footerView isRelative:NO];
            
            [self.view bringSubviewToFront:self.footerView];
        }

        [self.toolbar viewWillAppear:NO];
    }

    self.supplementaryViewController.view.hidden = self.supplementaryViewController.isVisible ? NO : YES;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;

    [self configureToolbar];
}

- (void)setFooterHeight:(CGFloat)footerHeight
{
    _footerHeight = footerHeight;

    [self configureToolbar];
}

- (void)setFooterView:(UIView *)footerView
{
    [self.footerView removeFromSuperview];

    _footerView = footerView;

    [self configureToolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.toolbar viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.toolbar viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.toolbar viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.toolbar viewDidDisappear:animated];
}

#pragma mark - Overrides

- (UINavigationItem *)navigationItem
{
    return self.originalRootViewController.navigationItem;
}

- (NSString *)title
{
    return self.rootViewController.title;
}

#pragma mark - SCUPassthroughSupplementaryViewControllerVisibilityDelegate

- (void)showSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController
{
    [self configureToolbar];
}

- (void)hideSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController
{
    [self configureToolbar];
}

- (BOOL)isSupplementaryViewVisible
{
    if (self.supplementaryViewController)
    {
        return self.supplementaryViewController.view.hidden ? NO : YES;
    }
    else
    {
        return NO;
    }

}

@end
