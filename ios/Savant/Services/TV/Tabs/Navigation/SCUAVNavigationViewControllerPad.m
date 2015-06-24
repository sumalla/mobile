//
//  SCUTVNavigationViewControllerPad.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNumberPadViewController.h"
#import "SCUAVNavigationViewControllerPad.h"
#import "SCUAVNavigationViewControllerPrivate.h"

@interface SCUAVNavigationViewControllerPad ()

@property (nonatomic) UIView *handle;

@end

@implementation SCUAVNavigationViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect screen = [[UIScreen mainScreen] bounds];
    
    CGFloat width = CGRectGetWidth(screen) > CGRectGetHeight(screen) ? CGRectGetWidth(screen) / 3 : CGRectGetHeight(screen) / 3;

    CGFloat transportHeight = ((width / 3) * self.transportContainer.numberOfRows);
    CGFloat numberPadHeight = ((width / 3) * self.numberPad.numberOfRows);
    
    self.bottomLabel.text = @"CHANNEL";

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.backgroundColor = [[SCUColors shared] color03];
    self.scrollView.bounces = NO;
    self.scrollView.delegate = self;
    self.scrollView.delaysContentTouches = NO;
    
    self.buttonContainer = [self containerViewForPossibleButtons];
    
    UIView *invisibleBottomBox = [[UIView alloc] initWithFrame:CGRectZero];
    invisibleBottomBox.userInteractionEnabled = YES;
    invisibleBottomBox.backgroundColor = [UIColor clearColor];
    
    UIView *invisibleSideBox = [[UIView alloc] initWithFrame:CGRectZero];
    invisibleSideBox.userInteractionEnabled = YES;
    invisibleSideBox.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.directionalSwipeView];
    [self.contentView addSubview:invisibleBottomBox];
    [self.contentView addSubview:invisibleSideBox];
    [self.contentView addSubview:self.bottomView];
    [self.contentView addSubview:self.buttonContainer];
    [self.contentView addSubview:self.scrollView];
    
    [self.scrollView addSubview:self.numberPad.view];
    [self.scrollView addSubview:self.transportContainer.view];
    
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
    
    self.transportContainer.view.translatesAutoresizingMaskIntoConstraints  = NO;
    self.numberPad.view.translatesAutoresizingMaskIntoConstraints           = NO;
    
    CGFloat bottomBarHeight = self.hideBottomBar ? 0 : 62.0f;
    //-------------------------------------------------------------------
    // Setup the common metrics/views dictionaries.
    //-------------------------------------------------------------------
    NSDictionary *metrics = @{@"spacer": @4,
                              @"padding": @5,
                              @"transportHeight": @(transportHeight),
                              @"numpadHeight": @(numberPadHeight),
                              @"landscapeNumPadWidth": @(width),
                              @"portraitNumPadWidth": @(width),
                              @"bottomBarHeight": @(bottomBarHeight)};

    NSDictionary *views = @{@"transport": self.transportContainer.view,
                            @"numberPad": self.numberPad.view,
                            @"navigation": self.directionalSwipeView,
                            @"bottomView": self.bottomView,
                            @"navigationButtons" : self.buttonContainer,
                            @"scrollView" : self.scrollView,
                            @"view" : self.contentView,
                            @"invisibleBottom" : invisibleBottomBox,
                            @"invisibleSide" : invisibleSideBox};

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
                                                                                 @"scrollView.bottom = navigation.bottom",
                                                                                 @"bottomView.bottom = navigation.bottom - padding",
                                                                                 @"bottomView.height = bottomBarHeight",
                                                                                 @"bottomView.width = super.width / 2",
                                                                                 @"bottomView.right = navigation.right - padding",
                                                                                 @"invisibleBottom.bottom = navigation.bottom",
                                                                                 @"invisibleBottom.right = navigation.right",
                                                                                 @"invisibleBottom.left = navigation.left",
                                                                                 @"invisibleBottom.top = bottomView.top",
                                                                                 @"invisibleSide.top = navigationButtons.top",
                                                                                 @"invisibleSide.right = navigation.right",
                                                                                 @"invisibleSide.bottom = bottomView.top",
                                                                                 @"invisibleSide.width = navigationButtons.width + padding",
                                                                                 @"navigationButtons.right = navigation.right - padding",
                                                                                 @"navigationButtons.bottom = bottomView.top - padding"
                                                                                 ]];
    
    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:metrics
                                                                        views:views
                                                                      formats:@[@"|[scrollView]|",
                                                                                @"|[navigation]|",
                                                                                @"V:|[scrollView(400)]-(spacer)-[navigation]|",
                                                                                @"transport.width = numberPad.width",
                                                                                @"bottomView.left = navigation.left + padding",
                                                                                @"bottomView.right = navigation.right - padding",
                                                                                @"bottomView.bottom = navigation.bottom - padding",
                                                                                @"bottomView.height = bottomBarHeight",
                                                                                @"invisibleBottom.bottom = navigation.bottom",
                                                                                @"invisibleBottom.right = navigation.right",
                                                                                @"invisibleBottom.left = navigation.left",
                                                                                @"invisibleBottom.top = bottomView.top",
                                                                                @"invisibleSide.top = navigationButtons.top",
                                                                                @"invisibleSide.right = navigation.right",
                                                                                @"invisibleSide.bottom = bottomView.top",
                                                                                @"invisibleSide.width = navigationButtons.width + padding",
                                                                                @"navigationButtons.right = navigation.right - padding",
                                                                                @"navigationButtons.bottom = bottomView.top - padding"
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
        self.scrollView.scrollEnabled = NO;
        self.handle.hidden = YES;
        
    }
    else
    {
        [self.scrollView removeConstraints:self.portraitScrollviewConstraints];
        [self.scrollView addConstraints:self.landscapeScrollviewConstraints];
        
        self.numberPad.squareCells = YES;
        self.transportContainer.squareCells = YES;
        self.transportContainer.minNumberOfRows = 1;
        self.transportContainer.maxNumberOfRows = 4;
        self.scrollView.scrollEnabled = YES;
        self.handle.hidden = NO;
    }
    
    [super setupConstraintsForOrientation:orientation];

    [self.transportContainer.collectionViewController.collectionView reloadData];
}

- (UIView *)containerViewForPossibleButtons
{
    NSMutableArray *buttons = [NSMutableArray arrayWithObjects:self.exitButton, self.lastButton, self.dvrButton, self.guideButton, nil];
    if (![self.model.serviceCommands containsObject:@"Exit"])
    {
        if ([self.model.serviceCommands containsObject:@"Return"])
        {
            self.exitButton.title = NSLocalizedString(@"Return", nil);
            [self.exitButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
                [self.model sendCommand:@"Return"];
            }];
        }
        else
        {
            [buttons removeObject:self.exitButton];
        }
    }
    
    if (![self.model.serviceCommands containsObject:@"LastChannel"])
    {
        [buttons removeObject:self.lastButton];
    }
    
    if (![self.model.serviceCommands containsObject:@"MyDVR"] && [self.model.serviceCommands containsObject:@"List"])
    {
        self.dvrButton.title = NSLocalizedString(@"List", nil);
    }
    else if (![self.model.serviceCommands containsObject:@"MyDVR"])
    {
        [buttons removeObject:self.dvrButton];
    }
    
    if (![self.model.serviceCommands containsObject:@"Guide"])
    {
        [buttons removeObject:self.guideButton];
    }
    
    if (buttons.count)
    {
        SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
        configuration.interSpace = 4;
        configuration.fixedWidth = 60;
        configuration.fixedHeight = 90;
        configuration.distributeEvenly = YES;
        configuration.vertical = YES;
        
        UIView *buttonContainer = [UIView sav_viewWithEvenlyDistributedViews:buttons withConfiguration:configuration];
        return buttonContainer;
    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

@end
