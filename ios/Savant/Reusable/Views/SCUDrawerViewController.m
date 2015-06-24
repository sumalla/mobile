//
//  SCUDrawerViewController.m
//  SCUDrawerViewController
//
//  Created by Cameron Pulsford on 4/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDrawerViewController.h"
@import Extensions;

#define DRAWER_ANIMATION_SCALE 1

@interface SCUDrawerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, getter = isOpen) BOOL open;
@property (nonatomic) UIViewController *rootViewController;
@property (nonatomic) UIViewController *leftViewController;
@property (nonatomic) SCUDrawerLevel leftViewControllerLevel;
@property (nonatomic) UIViewController *rightViewController;
@property (nonatomic) SCUDrawerLevel rightViewControllerLevel;
@property (nonatomic) CGRect currentFrame;
@property (nonatomic) SCUDrawerLevel currentLevel;
@property (nonatomic) UIView *slidingView;
@property (nonatomic) SCUDrawerSide currentSwipeSide;
@property (nonatomic) UIView *drawerView;
@property (nonatomic) CGFloat xMinBoundary;
@property (nonatomic) CGFloat xMaxBoundary;
@property (nonatomic) CGFloat xSlidingBoudary;
@property (nonatomic, getter = isSwiping) BOOL swiping;
@property (nonatomic) SCUDrawerSide openSide;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *rootPanGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *leftPanGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *rightPanGestureRecognizer;
@property (nonatomic) UIView *overlayView;
@property (nonatomic) UIView *overlayParentView;
@property (nonatomic) BOOL rootViewControllerIsNavController;
@property (nonatomic) UINavigationController *rootNavController;
@property (nonatomic) SCUDrawerSide beginSide;

@end

@implementation SCUDrawerViewController

@dynamic open;

- (BOOL)isOpen
{
    return self.openSide != SCUDrawerSideNone;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super init];

    if (self)
    {
        if ([rootViewController isKindOfClass:[UINavigationController class]])
        {
            self.rootViewControllerIsNavController = YES;
            self.rootNavController = (UINavigationController *)rootViewController;
        }

        self.rootViewController = rootViewController;
        self.openWidthPercentage = 0.85;
        self.maximumDrawerOpenWidth = CGFLOAT_MAX;
        self.dragOpenVelocityThreshold = 300;
        self.dragOpenThreshold = 1.0 / 5.0;
        self.minimumAnimationDuration = 0.1;
        self.maximumAnimationDuration = 0.4;
        self.edgeDraggingThreshold = 0.15;
        self.parallaxIntensity = 8;
        self.showOverlay = YES;
        self.showShadow = YES;
    }

    return self;
}

- (void)setViewController:(UIViewController *)viewController forSide:(SCUDrawerSide)drawerSide level:(SCUDrawerLevel)level
{
    NSParameterAssert(drawerSide != SCUDrawerSideNone);
    NSParameterAssert(viewController);

    switch (drawerSide)
    {
        case SCUDrawerSideLeft:
            self.leftViewController = viewController;
            self.leftViewControllerLevel = level;
            self.leftPanGestureRecognizer = [self addPanGestureRecognizerToView:viewController.view];
            break;
        case SCUDrawerSideRight:
            self.rightViewController = viewController;
            self.rightViewControllerLevel = level;
            self.rightPanGestureRecognizer = [self addPanGestureRecognizerToView:viewController.view];
            break;
        case SCUDrawerSideNone:
            break;
    }
}

- (void)setupGestureRecognizerCompatibility:(NSArray *)gestureRecognizers compatibilityMode:(SCUDrawerGestureCompatibilityMode)compatibilityMode
{
    for (UIGestureRecognizer *recognizer in gestureRecognizers)
    {
        if (self.rootPanGestureRecognizer)
        {
            [self setupGestureCompatibilityForInternalRecognizer:self.rootPanGestureRecognizer otherRecognizer:recognizer compatibilityMode:compatibilityMode];
        }

        if (self.leftPanGestureRecognizer)
        {
            [self setupGestureCompatibilityForInternalRecognizer:self.leftPanGestureRecognizer otherRecognizer:recognizer compatibilityMode:compatibilityMode];
        }

        if (self.rightPanGestureRecognizer)
        {
            [self setupGestureCompatibilityForInternalRecognizer:self.rightPanGestureRecognizer otherRecognizer:recognizer compatibilityMode:compatibilityMode];
        }
    }
}

- (void)setupGestureCompatibilityForInternalRecognizer:(UIGestureRecognizer *)internalRecognizer otherRecognizer:(UIGestureRecognizer *)otherRecognizer compatibilityMode:(SCUDrawerGestureCompatibilityMode)compatibilityMode
{
    switch (compatibilityMode)
    {
        case SCUDrawerGestureCompatibilityModePreferClient:
            [internalRecognizer requireGestureRecognizerToFail:otherRecognizer];
            break;
        case SCUDrawerGestureCompatibilityModePreferDrawer:
            [otherRecognizer requireGestureRecognizerToFail:internalRecognizer];
            break;
    }
}

- (BOOL)openDrawerFromSide:(SCUDrawerSide)drawerSide animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    BOOL couldOpen = NO;

    if (!self.isOpen && drawerSide != SCUDrawerSideNone)
    {
        couldOpen = YES;

        SAVWeakSelf;
        [self setDrawerOpen:YES animated:animated withSide:drawerSide newSide:drawerSide completion:^{

            [wSelf addTapGestureRecognizer];
            [wSelf setNavControllerPopGestureEnabled:NO];

            if (completion)
            {
                completion();
            }

        }];
    }

    return couldOpen;
}

- (BOOL)openDrawerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    SCUDrawerSide side = SCUDrawerSideNone;

    if (self.leftViewController && self.rightViewController)
    {
        //-------------------------------------------------------------------
        // This is ambiguous so do nothing.
        //-------------------------------------------------------------------
    }
    else if (self.leftViewController)
    {
        side = SCUDrawerSideLeft;
    }
    else if (self.rightViewController)
    {
        side = SCUDrawerSideRight;
    }

    return [self openDrawerFromSide:side animated:animated completion:completion];
}

- (BOOL)closeDrawerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    BOOL couldClose = NO;

    if (self.isOpen)
    {
        couldClose = YES;

        SAVWeakSelf;
        [self setDrawerOpen:NO animated:animated withSide:self.openSide newSide:SCUDrawerSideNone completion:^{

            [wSelf setNavControllerPopGestureEnabled:YES];

            if (completion)
            {
                completion();
            }

        }];
    }

    return couldClose;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.rootPanGestureRecognizer = [self addPanGestureRecognizerToView:self.rootViewController.view];
    [self sav_addChildViewController:self.rootViewController];

    self.overlayView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (self.isSwiping)
    {
        return;
    }

    [self layoutSubviews];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = YES;

    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [recognizer velocityInView:self.rootViewController.view.superview];

        if (fabs(velocity.y) > fabs(velocity.x))
        {
            shouldBegin = NO;
        }
        else
        {
            SCUDrawerSide side = self.openSide;

            if (side == SCUDrawerSideNone)
            {
                side = [self sideFromPoint:velocity];
            }

            if (side == SCUDrawerSideNone)
            {
                shouldBegin = NO;
            }

            if (shouldBegin && !self.isOpen && self.edgeDraggingThreshold < 1)
            {
                CGFloat width = CGRectGetWidth(self.rootViewController.view.bounds);
                CGPoint point = [recognizer locationInView:self.rootViewController.view.superview];

                if (velocity.x >= 0 && point.x >= (width * self.edgeDraggingThreshold))
                {
                    shouldBegin = NO;
                }
                else if (velocity.x <= 0 && point.x <= (width * (1 - self.edgeDraggingThreshold)))
                {
                    shouldBegin = NO;
                }
            }

            if (shouldBegin)
            {
                if ([self.delegate respondsToSelector:@selector(shouldDrawer:beginDraggingFromSide:)])
                {
                    shouldBegin = [self.delegate shouldDrawer:self beginDraggingFromSide:[self sideFromPoint:velocity]];
                }
            }

            if (shouldBegin)
            {
                if ((side == SCUDrawerSideNone && !self.leftViewController) || (side == SCUDrawerSideRight && !self.rightViewController))
                {
                    shouldBegin = NO;
                }
                else
                {
                    self.beginSide = side;
                }
            }
        }
    }

    return shouldBegin;
}

#pragma mark - Private

- (void)setDrawerOpen:(BOOL)open animated:(BOOL)animated withSide:(SCUDrawerSide)drawerSide newSide:(SCUDrawerSide)newSide completion:(dispatch_block_t)completion
{
    if (open)
    {
        [self setupInitialStatesForSide:drawerSide];
    }

    UIViewController *viewController = nil;
    CGRect frame = CGRectZero;

    if (self.currentLevel == SCUDrawerLevelBelow)
    {
        viewController = self.rootViewController;
        frame = [self frameForDrawerSide:drawerSide open:open level:self.currentLevel isMainView:YES];
    }
    else
    {
        viewController = [self viewControllerForDrawerSide:drawerSide];
        frame = [self frameForDrawerSide:drawerSide open:open level:self.currentLevel isMainView:NO];
    }

    [self addOverlayIfNecessary];

    if (viewController)
    {
        [self setFrameAnimated:frame forView:viewController.view withVelocity:animated ? 500 : 0 newSide:newSide completion:completion];
    }
}

- (void)layoutSubviews
{
    self.rootViewController.view.frame = [self frameForDrawerSide:self.currentSwipeSide open:self.isOpen level:self.currentLevel isMainView:YES];

    UIViewController *viewController = [self viewControllerForDrawerSide:self.currentSwipeSide];
    CGRect frame = [self frameForDrawerSide:self.currentSwipeSide open:self.isOpen level:self.currentLevel isMainView:NO];
    viewController.view.frame = frame;
    self.overlayView.frame = [self overlayFrameForDrawerSide:self.currentSwipeSide forSlidingFrame:frame];
    self.currentFrame = self.slidingView.frame;
}

#pragma mark - Swiping

- (UIPanGestureRecognizer *)addPanGestureRecognizerToView:(UIView *)view
{
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    recognizer.delegate = self;
    recognizer.maximumNumberOfTouches = 1;
    [view addGestureRecognizer:recognizer];
    return recognizer;
}

- (SCUDrawerSide)sideFromPoint:(CGPoint)point
{
    CGFloat x = point.x;

    if (self.isOpen)
    {
        x *= -1;
    }

    SCUDrawerSide side = SCUDrawerSideRight;

    if (x > 0)
    {
        side = SCUDrawerSideLeft;
    }

    if (side == SCUDrawerSideLeft && !self.leftViewController)
    {
        side = SCUDrawerSideNone;
    }
    else if (side == SCUDrawerSideRight && !self.rightViewController)
    {
        side = SCUDrawerSideNone;
    }

    return side;
}

- (void)setupInitialStatesForSide:(SCUDrawerSide)side
{
    self.currentSwipeSide = side;
    UIViewController *drawerController = nil;

    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat openWidth = [self drawerWidth];
    CGFloat threshold = openWidth * self.dragOpenThreshold;

    switch (side)
    {
        case SCUDrawerSideNone:
            break;
        case SCUDrawerSideLeft:
            drawerController = self.leftViewController;
            self.currentLevel = self.leftViewControllerLevel;
            [self addChildViewController:self.leftViewController];

            if (self.currentLevel == SCUDrawerLevelBelow)
            {
                self.xMinBoundary = 0;
                self.xMaxBoundary = openWidth;
                self.xSlidingBoudary = threshold;
                self.overlayParentView = self.view;
            }
            else
            {
                self.xMinBoundary = -openWidth;
                self.xMaxBoundary = 0;
                self.xSlidingBoudary = -(width - threshold);
                self.overlayParentView = self.rootViewController.view;
            }

            break;
        case SCUDrawerSideRight:
            drawerController = self.rightViewController;
            self.currentLevel = self.rightViewControllerLevel;
            [self addChildViewController:self.rightViewController];

            if (self.currentLevel == SCUDrawerLevelBelow)
            {
                self.xMinBoundary = -openWidth;
                self.xMaxBoundary = 0;
                self.xSlidingBoudary = -threshold;
                self.overlayParentView = self.rightViewController.view;
            }
            else
            {
                self.xMinBoundary = width - openWidth;
                self.xMaxBoundary = width;
                self.xSlidingBoudary = (width - threshold);
                self.overlayParentView = self.rootViewController.view;
            }

            break;
    }

    if (drawerController)
    {
        self.slidingView = drawerController.view;
        self.drawerView = drawerController.view;

        if (self.currentLevel == SCUDrawerLevelBelow)
        {
            self.slidingView = self.rootViewController.view;
        }

        [self.view addSubview:drawerController.view];

        if (self.currentLevel == SCUDrawerLevelAbove)
        {
            self.overlayView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.5];
            [self.view bringSubviewToFront:drawerController.view];
        }
        else
        {
            self.overlayView.backgroundColor = [[SCUColors shared] color03];
            [self.view sendSubviewToBack:drawerController.view];
        }

        [self layoutSubviews];

        if (self.showShadow)
        {
            self.slidingView.layer.shadowColor = [[SCUColors shared] color03].CGColor;
            self.slidingView.layer.shadowRadius = 10;
            self.slidingView.layer.shadowOpacity = .5;

            if (self.currentLevel == SCUDrawerLevelAbove)
            {
                if (self.currentSwipeSide == SCUDrawerSideLeft)
                {
                    self.slidingView.layer.shadowOffset = CGSizeMake(5, 0);
                }
                else if (self.currentSwipeSide == SCUDrawerSideRight)
                {
                    self.slidingView.layer.shadowOffset = CGSizeMake(-5, 0);
                }
            }
            else
            {
                if (self.currentSwipeSide == SCUDrawerSideLeft)
                {
                    self.slidingView.layer.shadowOffset = CGSizeMake(-5, 0);
                }
                else if (self.currentSwipeSide == SCUDrawerSideRight)
                {
                    self.slidingView.layer.shadowOffset = CGSizeMake(5, 0);
                }
            }

            self.slidingView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.slidingView.bounds].CGPath;
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGFloat velocity = [recognizer velocityInView:self.rootViewController.view.superview].x;
    CGFloat absoluteVelocity = fabs(velocity);
    CGPoint translation = [recognizer translationInView:self.rootViewController.view.superview];

    switch (recognizer.state)
    {
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateBegan:
            [self setupInitialStatesForSide:self.beginSide];
            [self addTapGestureRecognizer];
            [self addOverlayIfNecessary];
            self.swiping = YES;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat x = CGRectGetMinX(self.currentFrame) + translation.x;

            if (x < self.xMinBoundary)
            {
                x = self.xMinBoundary;
            }
            else if (x > self.xMaxBoundary)
            {
                x = self.xMaxBoundary;
            }

            if (self.currentLevel == SCUDrawerLevelBelow)
            {
                if (self.currentSwipeSide == SCUDrawerSideLeft)
                {
                    CGFloat percentage = x / self.xMaxBoundary;
                    CGRect leftFrame = self.leftViewController.view.frame;
                    leftFrame.origin.x = (-[self drawerWidth] / self.parallaxIntensity) + (([self drawerWidth] / self.parallaxIntensity) * percentage);
                    self.leftViewController.view.frame = leftFrame;
                    
                    if ([self.parallaxDelegate respondsToSelector:@selector(addParallaxEffectsForDrawer:)])
                    {
                        UIView *parallaxView = [self.parallaxDelegate addParallaxEffectsForDrawer:self];
                        CGRect frame = parallaxView.frame;
                        CGFloat translation = -percentage * CGRectGetWidth(frame) / 2;
                        frame.origin.x = translation;
                        parallaxView.frame = frame;
                    }
                }
                else if (self.currentSwipeSide == SCUDrawerSideRight)
                {
                    CGFloat percentage = x / self.xMinBoundary;
                    CGRect rightFrame = self.rightViewController.view.frame;
                    rightFrame.origin.x = ([self drawerWidth] / self.parallaxIntensity) - (([self drawerWidth] / self.parallaxIntensity) * percentage);
                    self.rightViewController.view.frame = rightFrame;
                    
                    if ([self.parallaxDelegate respondsToSelector:@selector(addParallaxEffectsForDrawer:)])
                    {
                        UIView *parallaxView = [self.parallaxDelegate addParallaxEffectsForDrawer:self];
                        CGRect frame = parallaxView.frame;
                        CGFloat translation = percentage * CGRectGetWidth(frame) / 2;
                        frame.origin.x = translation;
                        parallaxView.frame = frame;
                    }
                }
            }

            CGRect frame = self.currentFrame;
            frame.origin.x = x;
            self.slidingView.frame = frame;

            if (self.showOverlay)
            {
                CGFloat currentX = fabs(x);
                CGFloat width = CGRectGetWidth(self.slidingView.bounds);
                CGFloat alpha = 0;

                if (self.currentLevel == SCUDrawerLevelAbove)
                {
                    if (self.currentSwipeSide == SCUDrawerSideRight)
                    {
                        alpha = ((CGRectGetWidth(self.view.bounds) - currentX) / width);
                    }
                    else if (self.currentSwipeSide == SCUDrawerSideLeft)
                    {
                        alpha = (width - currentX) / width;
                    }

                    self.overlayView.frame = [self overlayFrameForDrawerSide:self.currentSwipeSide forSlidingFrame:self.slidingView.frame];
                }
                else
                {
                    if (self.currentSwipeSide == SCUDrawerSideRight)
                    {
                        alpha = 1 - ABS(currentX) / ABS(self.xMinBoundary);
                    }
                    else if (self.currentSwipeSide == SCUDrawerSideLeft)
                    {
                        alpha = 1 - (currentX / self.xMaxBoundary);
                    }
                }

                self.overlayView.alpha = alpha;

                if ([self.delegate respondsToSelector:@selector(drawer:isAnimatingSide:percentOpen:)])
                {
                    [self.delegate drawer:self isAnimatingSide:self.currentSwipeSide percentOpen:self.currentLevel == SCUDrawerLevelAbove ? alpha : 1 - alpha];
                }
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            self.swiping = NO;

            CGFloat currentX = CGRectGetMinX(self.slidingView.frame);

            BOOL open = NO;

            if (self.currentSwipeSide == SCUDrawerSideLeft)
            {
                if (((currentX > self.xSlidingBoudary || absoluteVelocity > self.dragOpenVelocityThreshold) && velocity > 0) || (self.isOpen && velocity > 0))
                {
                    open = YES;
                }
            }
            else if (self.currentSwipeSide == SCUDrawerSideRight)
            {
                if (((currentX < self.xSlidingBoudary || absoluteVelocity > self.dragOpenVelocityThreshold) && velocity < 0) || (self.isOpen && velocity < 0))
                {
                    open = YES;
                }
            }

            CGRect frame = [self frameForDrawerSide:self.currentSwipeSide open:open level:self.currentLevel isMainView:self.slidingView == self.rootViewController.view];

            SCUDrawerSide newSide = self.currentSwipeSide;

            if (!open)
            {
                newSide = SCUDrawerSideNone;
            }

            SAVWeakSelf;
            [self setFrameAnimated:frame forView:self.slidingView withVelocity:absoluteVelocity newSide:newSide completion:^{
                if (open)
                {
                    [wSelf setNavControllerPopGestureEnabled:NO];
                }
                else
                {
                    [wSelf setNavControllerPopGestureEnabled:YES];
                }
            }];
            
            if ([self.parallaxDelegate respondsToSelector:@selector(addParallaxEffectsForDrawer:)])
            {
                UIView *parallaxView = [self.parallaxDelegate addParallaxEffectsForDrawer:self];
                CGRect frame = parallaxView.frame;
                frame.origin.x = 0;
                [self setFrameAnimated:frame forView:parallaxView withVelocity:absoluteVelocity newSide:newSide completion:nil];
            }

            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (UIViewController *)viewControllerForDrawerSide:(SCUDrawerSide)side
{
    UIViewController *viewController = nil;

    if (side == SCUDrawerSideLeft)
    {
        viewController = self.leftViewController;
    }
    else if (side == SCUDrawerSideRight)
    {
        viewController = self.rightViewController;
    }

    return viewController;
}

#pragma mark - Tapping

- (void)addTapGestureRecognizer
{
    if (self.tapGestureRecognizer)
    {
        [self.rootViewController.view removeGestureRecognizer:self.tapGestureRecognizer];
    }

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.rootViewController.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    [self closeDrawerAnimated:YES completion:NULL];
}

#pragma mark - Frame helpers

- (CGFloat)drawerWidth
{
    CGFloat width = CGRectGetWidth(self.rootViewController.view.bounds) * self.openWidthPercentage;

    if (width > self.maximumDrawerOpenWidth)
    {
        width = self.maximumDrawerOpenWidth;
    }

    return width;
}

- (CGRect)frameWithX:(CGFloat)x shrinkWidthToFit:(BOOL)shrinkWidth drawerSide:(SCUDrawerSide)drawerSide
{
    UIViewController *frameViewController = nil;

    if (shrinkWidth)
    {
        if (drawerSide == SCUDrawerSideLeft)
        {
            frameViewController = self.leftViewController;
        }
        else if (drawerSide == SCUDrawerSideRight)
        {
            frameViewController = self.rightViewController;
        }
    }
    else
    {
        frameViewController = self.rootViewController;
    }

    CGRect bounds = self.rootViewController.view.bounds;
    CGRect frame = frameViewController.view.frame;

    CGFloat width = CGRectGetWidth(bounds);

    if (shrinkWidth)
    {
        width = [self drawerWidth];
    }

    return CGRectMake(x, CGRectGetMinY(frame), width, CGRectGetHeight(frame));
}

- (CGRect)frameForDrawerSide:(SCUDrawerSide)drawerSide open:(BOOL)open level:(SCUDrawerLevel)level isMainView:(BOOL)isMainView
{
    CGRect frame = CGRectZero;

    if (isMainView)
    {
        if (level == SCUDrawerLevelAbove || !open)
        {
            frame = [self frameWithX:0 shrinkWidthToFit:NO drawerSide:drawerSide];
        }
        else
        {
            if (drawerSide == SCUDrawerSideLeft)
            {
                frame = [self frameWithX:[self drawerWidth] shrinkWidthToFit:NO drawerSide:drawerSide];
            }
            else if (drawerSide ==  SCUDrawerSideRight)
            {
                frame = [self frameWithX:-[self drawerWidth] shrinkWidthToFit:NO drawerSide:drawerSide];
            }
        }
    }
    else
    {
        if (drawerSide == SCUDrawerSideLeft)
        {
            if (level == SCUDrawerLevelBelow)
            {
                if (open)
                {
                    frame = [self frameWithX:0 shrinkWidthToFit:YES drawerSide:drawerSide];
                }
                else
                {
                    frame = [self frameWithX:(-[self drawerWidth] / 8.0) shrinkWidthToFit:YES drawerSide:drawerSide];
                }
            }
            else
            {
                if (open)
                {
                    frame = [self frameWithX:0 shrinkWidthToFit:YES drawerSide:drawerSide];
                }
                else
                {
                    frame = [self frameWithX:-[self drawerWidth] shrinkWidthToFit:YES drawerSide:drawerSide];
                }
            }
        }
        else
        {
            CGFloat width = CGRectGetWidth(self.rootViewController.view.bounds);

            if (level == SCUDrawerLevelBelow)
            {
                if (open)
                {
                    frame = [self frameWithX:(width - [self drawerWidth]) shrinkWidthToFit:YES drawerSide:drawerSide];
                }
                else
                {
                    frame = [self frameWithX:(width - ([self drawerWidth] * (7.0 / 8.0))) shrinkWidthToFit:YES drawerSide:drawerSide];
                }
            }
            else
            {
                if (open)
                {
                    frame = [self frameWithX:(width - [self drawerWidth]) shrinkWidthToFit:YES drawerSide:drawerSide];
                }
                else
                {
                    frame = [self frameWithX:CGRectGetMaxX(self.rootViewController.view.bounds) shrinkWidthToFit:YES drawerSide:drawerSide];
                }
            }
        }
    }

    frame.size.height = CGRectGetHeight(self.view.bounds);

    if (self.currentLevel == SCUDrawerLevelAbove && self.positionAboveDrawerBelowNavBar && !isMainView)
    {
        frame.origin.y = CGRectGetMaxY(self.rootNavController.navigationBar.frame);
        frame.size.height -= frame.origin.y;
    }

    if (self.currentLevel != SCUDrawerLevelAbove)
    {
        frame.origin.y = 0;
    }

    return frame;
}

- (CGRect)overlayFrameForDrawerSide:(SCUDrawerSide)drawerSide forSlidingFrame:(CGRect)slidingFrame
{
    CGRect overlayFrame = slidingFrame;

    if (self.currentLevel == SCUDrawerLevelBelow)
    {
        overlayFrame = self.view.bounds;
    }
    else
    {
        if (drawerSide == SCUDrawerSideRight)
        {
            overlayFrame.origin.x = 0;
            overlayFrame.size.width = CGRectGetMinX(slidingFrame);
        }
        else if (drawerSide == SCUDrawerSideLeft)
        {
            overlayFrame.origin.x = CGRectGetMaxX(slidingFrame);
            overlayFrame.size.width = CGRectGetWidth(self.view.bounds) - CGRectGetMaxX(slidingFrame);
        }
    }

    return overlayFrame;
}

- (void)setFrameAnimated:(CGRect)frame forView:(UIView *)view withVelocity:(CGFloat)velocity newSide:(SCUDrawerSide)newSide completion:(dispatch_block_t)completion
{
    NSTimeInterval duration = fabs(CGRectGetMinX(view.frame) - CGRectGetMinX(frame)) / velocity;

    if (duration > self.maximumAnimationDuration)
    {
        duration = self.maximumAnimationDuration;
    }

    if (duration < self.minimumAnimationDuration)
    {
        duration = self.minimumAnimationDuration;
    }

    SCUDrawerSide originalSide = self.openSide;

    [UIView animateWithDuration:DRAWER_ANIMATION_SCALE * duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{

                         if (self.showOverlay)
                         {
                             if (self.currentLevel == SCUDrawerLevelAbove)
                             {
                                 if (newSide == SCUDrawerSideNone)
                                 {
                                     self.overlayView.alpha = 0;
                                 }
                                 else
                                 {
                                     self.overlayView.alpha = 1;
                                 }
                             }
                             else if (self.currentLevel == SCUDrawerLevelBelow)
                             {
                                 UIViewController *viewController = [self viewControllerForDrawerSide:self.currentSwipeSide];
                                 CGRect frame = [self frameForDrawerSide:self.currentSwipeSide open:newSide == SCUDrawerSideNone ? NO : YES level:self.currentLevel isMainView:NO];
                                 viewController.view.frame = frame;

                                 if (newSide == SCUDrawerSideNone)
                                 {
                                     self.overlayView.alpha = 1;
                                 }
                                 else
                                 {
                                     self.overlayView.alpha = 0;
                                 }
                             }

                             self.overlayView.frame = [self overlayFrameForDrawerSide:self.currentSwipeSide forSlidingFrame:frame];

                             if ([self.delegate respondsToSelector:@selector(drawer:isAnimatingSide:percentOpen:)])
                             {
                                 [self.delegate drawer:self isAnimatingSide:self.currentSwipeSide percentOpen:newSide == SCUDrawerSideNone ? 0 : 1];
                             }
                         }

                         view.frame = frame;
                         self.openSide = newSide;
                     }
                     completion:^(BOOL finished) {
                         if (finished)
                         {
                             if (newSide == SCUDrawerSideNone)
                             {
                                 [self.leftViewController.view removeFromSuperview];
                                 [self.rightViewController.view removeFromSuperview];

                                 [self.rootViewController.view removeGestureRecognizer:self.tapGestureRecognizer];
                                 self.tapGestureRecognizer = nil;

                                 [self removeOverlay];
                             }

                             if (completion)
                             {
                                 completion();
                             }
                         }

                         if (newSide != originalSide)
                         {
                             if (newSide == SCUDrawerSideNone)
                             {
                                 if ([self.delegate respondsToSelector:@selector(drawer:didCloseFromSide:)])
                                 {
                                     [self.delegate drawer:self didCloseFromSide:originalSide];
                                     [self.rightViewController removeFromParentViewController];
                                     [self.leftViewController removeFromParentViewController];
                                 }
                             }
                             else
                             {
                                 if ([self.delegate respondsToSelector:@selector(drawer:didOpenFromSide:)])
                                 {
                                     [self.delegate drawer:self didOpenFromSide:newSide];
                                 }
                             }
                         }
                     }];
}

- (void)addOverlayIfNecessary
{
    if (self.showOverlay && !self.overlayView.superview)
    {
        self.overlayView.alpha = self.currentLevel == SCUDrawerLevelBelow ? 1 : 0;
        [self.overlayParentView addSubview:self.overlayView];

        if (self.currentLevel == SCUDrawerLevelBelow)
        {
            self.overlayView.frame = self.view.bounds;
            [self.overlayParentView insertSubview:self.overlayView belowSubview:self.slidingView];
        }
        else
        {
            CGRect frame = self.overlayParentView.bounds;

            if (self.currentLevel == SCUDrawerLevelAbove && self.positionAboveDrawerBelowNavBar)
            {
                frame.origin.y = CGRectGetMaxY(self.rootNavController.navigationBar.frame);
                frame.size.height -= frame.origin.y;
            }

            self.overlayView.frame = frame;
        }
    }
}

- (void)removeOverlay
{
    [self.overlayView removeFromSuperview];
}

- (void)setNavControllerPopGestureEnabled:(BOOL)enabled
{
    if (self.rootViewControllerIsNavController)
    {
        self.rootNavController.interactivePopGestureRecognizer.enabled = enabled;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    dispatch_async_main(^{
        [self layoutSubviews];
    });
}

@end
