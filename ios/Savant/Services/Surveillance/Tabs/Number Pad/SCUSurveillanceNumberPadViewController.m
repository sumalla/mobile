//
//  SCUSurveillanceNumberPadViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSurveillanceNumberPadViewController.h"
#import "SCUSurveillanceNavigationViewControllerPrivate.h"

@interface SCUSurveillanceNumberPadViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *container;
@property (nonatomic) UIView *handle;
@property (nonatomic) SCUSurveillanceNumberPadViewState currentState;

@end

@implementation SCUSurveillanceNumberPadViewController

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
    
    [self.view addSubview:self.numberPad.view];
    [self.view addSubview:self.transportContainer.view];
    
    UIImageView *handle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grabber"]];
    handle.userInteractionEnabled = NO;
    
    [self.numberPad.view addSubview:handle];
    [self.numberPad.view sav_pinView:handle withOptions:SAVViewPinningOptionsCenterX];
    [self.numberPad.view sav_pinView:handle withOptions:SAVViewPinningOptionsToTop withSpace:5];
    [self.numberPad.view sav_setSize:CGSizeMake(44, 44) forView:handle isRelative:NO];
    
    self.handle = handle;
    
    CGFloat width = (CGRectGetWidth([UIScreen mainScreen].bounds) - 10) / 3;
    CGFloat transportHeight = (width * self.transportContainer.numberOfRows);
    CGFloat numberPadHeight = (width * self.numberPad.numberOfRows);
    
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
    self.scrollView.delaysContentTouches = NO;
    
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
    CGFloat height = CGRectGetHeight(self.transportContainer.view.frame) + CGRectGetHeight(self.numberPad.view.frame);
    
    return height;
}

#pragma mark - UIScrollViewDelegate

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gesture
{
    if (gesture.numberOfTouches)
    {
        if (([gesture locationOfTouch:0 inView:self.handle].y > 0) && [gesture locationOfTouch:0 inView:self.handle].y < CGRectGetHeight(self.handle.frame))
        {
            if (gesture.direction == UISwipeGestureRecognizerDirectionUp)
            {
                [self snapScrollViewtoState:SCUSurveillanceNumberPadViewStateNumberpad];
            }
            else if (gesture.direction == UISwipeGestureRecognizerDirectionDown)
            {
                [self snapScrollViewtoState:SCUSurveillanceNumberPadViewStateTransport];
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)snapScrollViewtoState:(SCUSurveillanceNumberPadViewState)state
{
    switch (state)
    {
        case SCUSurveillanceNumberPadViewStateTransport:
        {
            self.numberPad.collectionViewController.collectionView.scrollEnabled = NO;
            [self.numberPad.collectionViewController.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:15 options:0 animations:^{
                [self.scrollView setContentOffset:CGPointMake(0, 0)];
            } completion:nil];
        }
            break;
        case SCUSurveillanceNumberPadViewStateNumberpad:
        {
            CGFloat contentOffset = self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.frame);
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:15 options:0 animations:^{
                [self.scrollView setContentOffset:CGPointMake(0, contentOffset)];
            } completion:^ (BOOL finished) {
                
                self.numberPad.collectionViewController.collectionView.scrollEnabled = YES;
                self.numberPad.collectionViewController.collectionView.scrollEnabled = NO;
                self.numberPad.collectionViewController.collectionView.scrollEnabled = YES;
                
            }];
            
        }
            break;
    }
}

@end
