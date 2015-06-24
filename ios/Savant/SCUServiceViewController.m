//
//  SCUServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewController.h"
#import "SCUServiceViewModel.h"
#import "SCUButton.h"
@import Extensions;
@import SDK;

@implementation UIViewController (Portrait)

//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait;
//}

@end


@interface SCUServiceViewController () <ActiveServiceObserver>

@property (nonatomic) UIView *contentView;
@property (nonatomic) UILabel *titleView;
@property (nonatomic) BOOL statusBarInitialState;

@property (weak, nonatomic) UIPanGestureRecognizer *internalPanGesture;

@end

@implementation SCUServiceViewController

@synthesize dismissalCompletionBlock=_dismissalCompletionBlock;

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUServiceViewModel alloc] initWithService:service];
    }
    return self;
}

- (void)dealloc
{
    [[Savant states] removeActiveServiceObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.statusBarInitialState = [UIApplication sharedApplication].statusBarHidden;

    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:-10 forBarMetrics:UIBarMetricsDefault];
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.contentView];
    CGFloat edgeInset = [self contentViewPadding];
    [self.view sav_addConstraintsForView:self.contentView withEdgeInsets:UIEdgeInsetsMake(edgeInset + 19, edgeInset, edgeInset, edgeInset)];
    
    if (self.model.service)
    {
        if ([self.model.service.serviceId hasPrefix:@"SVC_ENV"])
        {
            self.title = [self.model.service.displayName uppercaseString];
        }
        else
        {
            self.title = [self.model.service.alias uppercaseString];
        }
    }

    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04],
                                                                      NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:13]}];

    if ([self.model.service.serviceId hasPrefix:@"SVC_AV"] || [self.model.service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        SCUButton *powerOff = [[SCUButton alloc] initWithStyle:SCUButtonStyleAccent image:[UIImage imageNamed:@"Power"]];
        powerOff.frame = CGRectMake(0, 0, 70, 44);
        powerOff.target = self;
        powerOff.releaseAction = @selector(powerOff:);
        powerOff.buttonInsets = UIEdgeInsetsMake(0, 0, 0, 20);

        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:powerOff];
        self.navigationItem.rightBarButtonItem = button;
    }

    if (self.model.service)
    {
        SCUButton *dismiss = [[SCUButton alloc] initWithStyle:SCUButtonStyleLight image:[UIImage imageNamed:@"chevron-down"]];
        dismiss.frame = CGRectMake(0, 0, 70, 44);
        dismiss.target = self;
        dismiss.releaseAction = @selector(dismissService);
        dismiss.buttonInsets = UIEdgeInsetsMake(0, 20, 0, 0);

        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithCustomView:dismiss];
        self.navigationItem.leftBarButtonItem = button;
    }

    if (self.panGesture)
    {
        [self.navigationController.navigationBar addGestureRecognizer:self.panGesture];
    }
}

- (void)setPanGesture:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture != self.internalPanGesture)
    {
        [self.navigationController.navigationBar removeGestureRecognizer:self.internalPanGesture];
        [self.navigationController.navigationBar addGestureRecognizer:panGesture];

        self.internalPanGesture = panGesture;
    }
}

- (UIPanGestureRecognizer *)panGesture
{
    return self.internalPanGesture;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.model viewWillAppear];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.panGesture)
    {
        [self.navigationController.navigationBar removeGestureRecognizer:self.panGesture];
        [self.navigationController.navigationBar addGestureRecognizer:self.panGesture];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.model viewWillDisappear];

    if (!self.statusBarInitialState)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (NSInteger)contentViewPadding
{
    if ([self.model.service.serviceId hasPrefix:@"SVC_AV"] && ![UIDevice isShortPhone])
    {
        return [UIDevice isPad] ? 4 : 4;
    }
    else
    {
        return [UIDevice isPad] ? 4 : 0;
    }
}

#pragma mark - Constraints

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self setupConstraintsForOrientation:orientation];
    }];
}

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    if (self.portraitConstraints && self.landscapeConstraints)
    {
        [self.contentView removeConstraints:self.portraitConstraints];
        [self.contentView removeConstraints:self.landscapeConstraints];

        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            [self.contentView addConstraints:self.landscapeConstraints];
        }
        else
        {
            [self.contentView addConstraints:self.portraitConstraints];
        }
    }
}

- (void)powerOff:(UIBarButtonItem *)sender
{
    if ([self.model.service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        [self.model sendCommand:@"__RoomLightsOff"];
    }
    else
    {
        [self.model sendCommand:@"PowerOff"];
    }

    [self dismissService];
}

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    [self updateRooms];
}

- (SAVService *)service
{
    return self.model.service;
}

- (SAVServiceGroup *)serviceGroup
{
    return self.model.serviceGroup;
}

- (void)updateRooms
{
    ;
}

- (void)presentCustomView
{
    ;
}

- (void)dismissService
{
    if (self.dismissalCompletionBlock)
    {
        self.dismissalCompletionBlock();
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([UIDevice isPhone])
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    else
    {
        return UIInterfaceOrientationMaskAll;
    }
}

@end
