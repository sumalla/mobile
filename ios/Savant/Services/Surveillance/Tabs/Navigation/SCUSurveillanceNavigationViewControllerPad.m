//
//  SCUSurveillanceNavigationViewControllerPad.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSurveillanceNavigationViewControllerPad.h"
#import "SCUSurveillanceNavigationViewControllerPrivate.h"

@interface SCUSurveillanceNavigationViewControllerPad () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *buttonContainer;

@property (nonatomic) NSArray *landscapeScrollviewConstraints;
@property (nonatomic) NSArray *portraitScrollviewConstraints;

@end

@implementation SCUSurveillanceNavigationViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    CGFloat width = CGRectGetWidth(screen) > CGRectGetHeight(screen) ? CGRectGetWidth(screen) / 3 : CGRectGetHeight(screen) / 3;
    
    CGFloat transportHeight = ((width / 3) * self.transportContainer.numberOfRows);
    CGFloat numberPadHeight = ((width / 3) * self.numberPad.numberOfRows);
    
    self.transportContainer.collectionViewController.collectionView.scrollEnabled = NO;
    self.numberPad.collectionViewController.collectionView.scrollEnabled = NO;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.backgroundColor = [[SCUColors shared] color03];
    self.scrollView.bounces = NO;
    self.scrollView.delegate = self;
    self.scrollView.delaysContentTouches = NO;
    
    
    [self.contentView addSubview:self.directionalSwipeView];
    [self.contentView addSubview:self.scrollView];
    
    [self.scrollView addSubview:self.numberPad.view];
    [self.scrollView addSubview:self.transportContainer.view];
    
    self.transportContainer.view.translatesAutoresizingMaskIntoConstraints  = NO;
    self.numberPad.view.translatesAutoresizingMaskIntoConstraints           = NO;
    
    [self.directionalSwipeView sav_pinView:self.exitButton withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToRight withSpace:5.0];
    [self.directionalSwipeView sav_setSize:CGSizeMake(60, 120) forView:self.exitButton isRelative:NO];
    
    //-------------------------------------------------------------------
    // Setup the common metrics/views dictionaries.
    //-------------------------------------------------------------------
    NSDictionary *metrics = @{@"spacer": @4,
                              @"padding": @5,
                              @"transportHeight": @(transportHeight),
                              @"numpadHeight": @(numberPadHeight),
                              @"landscapeNumPadWidth": @(width),
                              @"portraitNumPadWidth": @(width),
                              @"channelBarHeight": @(62)};
    
    NSDictionary *views = @{@"transport": self.transportContainer.view,
                            @"numberPad": self.numberPad.view,
                            @"navigation": self.directionalSwipeView,
                            @"scrollView" : self.scrollView,
                            @"view" : self.contentView};
    
    self.landscapeScrollviewConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                 metrics:@{@"transportHeight" : @(transportHeight),
                                                                                           @"numberPadHeight" : @(numberPadHeight)}
                                                                                   views:@{@"numberPad" : self.numberPad.view,
                                                                                           @"transport" : self.transportContainer.view}
                                                                                 formats:@[@"V:|[transport(transportHeight)][numberPad(numberPadHeight)]|",
                                                                                           @"H:|[transport]|",
                                                                                           @"H:|[numberPad]|",
                                                                                           @"transport.width = super.width",
                                                                                           @"numberPad.width = super.width"]];
    
    self.portraitScrollviewConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:@{@"height" : @(400)}
                                                                                  views:@{@"numberPad" : self.numberPad.view,
                                                                                          @"transport" : self.transportContainer.view}
                                                                                formats:@[@"V:|[transport(height)]|",
                                                                                          @"V:|[numberPad(height)]|",
                                                                                          @"H:|[numberPad][transport]|",
                                                                                          @"transport.width = super.width / 2",
                                                                                          @"numberPad.width = transport.width"]];
    
    
    self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                       metrics:metrics
                                                                         views:views
                                                                       formats:@[@"H:|[scrollView][navigation]|",
                                                                                 @"V:|[navigation]|",
                                                                                 @"V:|[scrollView]|",
                                                                                 @"scrollView.width = super.width / 3",
                                                                                 @"scrollView.top = navigation.top",
                                                                                 @"scrollView.bottom = navigation.bottom"
                                                                                 ]];
    
    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:metrics
                                                                        views:views
                                                                      formats:@[@"|[scrollView]|",
                                                                                @"|[navigation]|",
                                                                                @"V:|[scrollView(400)]-(spacer)-[navigation]|",
                                                                                @"transport.width = numberPad.width"
                                                                                ]];
    
    //-------------------------------------------------------------------
    // Setup the initial layout for the current orientation.
    //-------------------------------------------------------------------
    [self setupConstraintsForOrientation:[UIDevice interfaceOrientation]];
    
    
}

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        [self.scrollView removeConstraints:self.landscapeScrollviewConstraints];
        [self.scrollView addConstraints:self.portraitScrollviewConstraints];
        
        self.numberPad.squareCells = NO;
        self.transportContainer.squareCells = NO;
        self.transportContainer.maxNumberOfRows = 4;
        self.transportContainer.minNumberOfRows = 4;
        self.transportContainer.collectionViewController.collectionView.scrollEnabled = NO;
        self.scrollView.scrollEnabled = NO;
        
    }
    else
    {
        [self.scrollView removeConstraints:self.portraitScrollviewConstraints];
        [self.scrollView addConstraints:self.landscapeScrollviewConstraints];
        
        self.numberPad.squareCells = YES;
        self.transportContainer.squareCells = YES;
        self.transportContainer.minNumberOfRows = 1;
        self.transportContainer.maxNumberOfRows = 4;
        self.transportContainer.numberOfColumns = 3;
        self.transportContainer.collectionViewController.collectionView.scrollEnabled = YES;
        self.scrollView.scrollEnabled = YES;
    }
    
    [super setupConstraintsForOrientation:orientation];
    
    [self.transportContainer.collectionViewController.collectionView reloadData];
}

@end
