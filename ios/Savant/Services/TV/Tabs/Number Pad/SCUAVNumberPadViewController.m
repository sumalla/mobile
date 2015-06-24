//
//  SCUTVNumberPadViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNumberPadViewController.h"
#import "SCUAVNavigationViewControllerPrivate.h"
#import "SCUAVNumberPadViewControllerPrivate.h"
@import Extensions;

@interface SCUAVNumberPadViewController()

@property (nonatomic) UIPanGestureRecognizer *pan;
@property (nonatomic) CGFloat initialScrollOffset;

@end

@implementation SCUAVNumberPadViewController

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"numberpad"];
}

- (void)loadView
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self setScrollViewSize];
    self.view = self.scrollView;
}

- (void)setScrollViewSize
{
    self.scrollView.contentSize = self.container.frame.size;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.numberPad.hideInfoBox = YES;
    
    [self.view addSubview:self.numberPad.view];
    [self.view addSubview:self.transportContainer.view];
    
    UIView *handle = [[UIView alloc] initWithFrame:CGRectZero];
    handle.backgroundColor = [UIColor clearColor];
    handle.userInteractionEnabled = NO;
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectZero];
    topLine.backgroundColor = [[SCUColors shared] color03];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
    bottomLine.backgroundColor = [[SCUColors shared] color03];
    
    [handle addSubview:topLine];
    [handle addSubview:bottomLine];
    
    [handle sav_pinView:topLine withOptions:SAVViewPinningOptionsCenterX];
    [handle sav_pinView:topLine withOptions:SAVViewPinningOptionsToTop withSpace:25.0];
    [handle sav_setSize:CGSizeMake(44, 4) forView:topLine isRelative:NO];
    
    [handle sav_pinView:bottomLine withOptions:SAVViewPinningOptionsCenterX];
    [handle sav_pinView:bottomLine withOptions:SAVViewPinningOptionsToBottom ofView:topLine withSpace:5.0];
    [handle sav_setSize:CGSizeMake(44, 4) forView:bottomLine isRelative:NO];
    
    [self.numberPad.view addSubview:handle];
    [self.numberPad.view sav_pinView:handle withOptions:SAVViewPinningOptionsCenterX];
    [self.numberPad.view sav_pinView:handle withOptions:SAVViewPinningOptionsToTop withSpace:-10];
    [self.numberPad.view sav_setSize:CGSizeMake(88, 88) forView:handle isRelative:NO];
    
    self.handle = handle;

    CGFloat width = (CGRectGetWidth([UIScreen mainScreen].bounds) - 10) / 3;
    CGFloat transportHeight = (width * self.transportContainer.numberOfRows);
    CGFloat numberPadHeight = (width * self.numberPad.numberOfRows);
    
    if (self.transportContainer.numberOfRows > 3 && [UIDevice isShortPhone])
    {
        transportHeight = (width * 3);
        self.transportContainer.collectionViewController.collectionView.scrollEnabled = YES;
    }
    
    if ([UIDevice isShortPhone])
    {
        numberPadHeight = (width * 3.5);
    }
    
    self.transportContainer.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.numberPad.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"width" : @(width),
                                                                               @"transportHeight" : @(transportHeight),
                                                                               @"numberPadHeight" : @(numberPadHeight)}
                                                                       views:@{@"numberPad" : self.numberPad.view,
                                                                               @"transport" : self.transportContainer.view}
                                                                     formats:@[@"V:|[transport(transportHeight)][numberPad(numberPadHeight)]|",
                                                                               @"H:|[transport]|",
                                                                               @"H:|[numberPad]|"]]];
    
    self.scrollView.backgroundColor = [[SCUColors shared] color03];
    self.scrollView.bounces = NO;
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.delaysContentTouches = NO;
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.pan.delegate = self;
    [self.scrollView addGestureRecognizer:self.pan];
    self.scrollView.panGestureRecognizer.enabled = NO;
    
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(handleGesture:)];
    [self.view sav_setWidth:1 forView:self.transportContainer.view isRelative:YES];
    [self.view sav_setWidth:1 forView:self.numberPad.view isRelative:YES];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGSize contentSize = CGSizeMake(self.container.frame.size.width, [self contentHeight]);
    self.scrollView.contentSize = contentSize;
}

- (CGFloat)contentHeight
{
    return [self transportHeight] + [self numberPadHeight];;
}

- (CGFloat)transportHeight
{
    return CGRectGetHeight(self.transportContainer.view.frame);
}

- (CGFloat)numberPadHeight
{
    return (CGRectGetHeight([[UIScreen mainScreen] bounds]) - 124);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.pan locationInView:self.handle].y < 0 || [self.pan locationInView:self.handle].y > CGRectGetHeight(self.handle.frame))
    {
        return NO;
    }
    
    
    return YES;
}

- (void)handleGesture:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
            self.initialScrollOffset = [gesture locationInView:self.contentView].y;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint offset = self.scrollView.contentOffset;
            offset.y -= [gesture locationInView:self.contentView].y - self.initialScrollOffset;
            
            if (offset.y < 0)
            {
                offset.y = 0;
            }


            if (offset.y > ([self contentHeight] - [self numberPadHeight]))
            {
                offset.y = ([self contentHeight] - [self numberPadHeight]);
            }
            
            self.scrollView.contentOffset = offset;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            if (fabs(self.scrollView.contentOffset.y - self.initialScrollOffset) > self.transportContainer.numberOfRows * 15)
            {
                CGFloat velocity = [gesture velocityInView:self.contentView].y;
                
                SCUAVNumberPadViewState state = velocity > 0 ? SCUAVNumberPadViewStateTransport : SCUAVNumberPadViewStateNumberpad;
                velocity = velocity / 100;
                
                [self snapScrollViewtoState:state withVelocity:fabs(velocity)];
            }
            else
            {
                [self snapScrollViewtoState:self.currentState];
            }
        }
            break;
        default:
            break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)snapScrollViewtoState:(SCUAVNumberPadViewState)state withVelocity:(CGFloat)velocity
{
    self.currentState = state;

    if (velocity < 4)
    {
        velocity = 2;
    }
    else if (velocity > 25)
    {
        velocity = 25;
    }

    CGFloat contentOffset = (state == SCUAVNumberPadViewStateNumberpad) ? [self transportHeight] : 0;
    CGPoint toValue = CGPointMake(0, contentOffset);
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:fabs(velocity) options:0 animations:^{
        self.scrollView.contentOffset = toValue;
    } completion:nil];
}

- (void)snapScrollViewtoState:(SCUAVNumberPadViewState)state
{
    [self snapScrollViewtoState:state withVelocity:1.5];
}

@end
