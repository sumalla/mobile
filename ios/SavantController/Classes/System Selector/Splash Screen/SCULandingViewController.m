//
//  SCULandingViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULandingViewController.h"
#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>
#import "SCUButton.h"
#import "SCUAlertView.h"
#import "SCUCloudSignUpViewController.h"
#import "SCUCloudSignInViewController.h"
#import "SCUMainViewController.h"
#import "SCUChangeServerTableViewController.h"
#import "SCUGradientView.h"
#import "SCULandingPageViewController.h"

NSString *const SCUSignInIsSkippedKey = @"SCUSignInIsSkippedKey";

@interface SCULandingViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>

@property (nonatomic) SCUButton *signInButton;
@property (nonatomic) SCUButton *signUpButton;
@property (nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) NSArray *controllers;
@property (nonatomic) SCULandingPageViewController *currentPageViewController;

@end

@implementation SCULandingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[SavantControl sharedControl] signOut];
    [[SavantControl sharedControl] disconnect];

    [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
        [defaults setBool:NO forKey:SCUSignInIsSkippedKey];
    }];

    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    SCUButton *signInButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"SIGN IN", nil)];
    signInButton.releaseAction = @selector(handleSignIn:);
    self.signInButton = signInButton;

    SCUButton *signUpButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"SIGN UP", nil)];
    signUpButton.releaseAction = @selector(handleSignUp:);
    self.signUpButton = signUpButton;

    for (SCUButton *button in @[signUpButton, signInButton])
    {
        button.target = self;
        button.roundedCorners = YES;
        button.color = [[SCUColors shared] color01];
        button.backgroundColor = [UIColor clearColor];
    }

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 0;
    configuration.distributeEvenly = YES;
    configuration.separatorSize = [UIScreen screenPixel];
    configuration.separatorBlock = ^UIView *{
        return [UIView sav_viewWithColor:[[SCUColors shared] color03shade04]];
    };

    UIView *buttonView = [UIView sav_viewWithEvenlyDistributedViews:@[self.signInButton, self.signUpButton]
                                                  withConfiguration:configuration];

    buttonView.cornerRadius = 2;
    buttonView.borderWidth = [UIScreen screenPixel];
    buttonView.borderColor = [[SCUColors shared] color03shade04];

    [self.view addSubview:buttonView];

    [self.view sav_pinView:buttonView withOptions:SAVViewPinningOptionsToLeft | SAVViewPinningOptionsToRight withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_pinView:buttonView withOptions:SAVViewPinningOptionsToBottom withSpace:20];
    [self.view sav_setHeight:60 forView:buttonView isRelative:NO];

    SCULandingPageViewController *controller1 = [[SCULandingPageViewController alloc] initWithImageName:@"FrontPageSingleApp"
                                                                                               mainText:NSLocalizedString(@"A SINGLE APP HOME", nil)
                                                                                             detailText:NSLocalizedString(@"Your whole home in one touch.", nil)];

    SCULandingPageViewController *controller2 = [[SCULandingPageViewController alloc] initWithImageName:@"FrontPageLighting"
                                                                                               mainText:NSLocalizedString(@"LOVE YOUR LIGHTING", nil)
                                                                                             detailText:NSLocalizedString(@"Create a lighting scheme that's all your own, indoors and out.", nil)];

    SCULandingPageViewController *controller3 = [[SCULandingPageViewController alloc] initWithImageName:@"FrontPageEnergy"
                                                                                               mainText:NSLocalizedString(@"SAVE YOUR ENERGY", nil)
                                                                                             detailText:NSLocalizedString(@"Savant can coordinate your thermostats and window shades to improve energy efficiency.", nil)];

    SCULandingPageViewController *controller4 = [[SCULandingPageViewController alloc] initWithImageName:@"FrontPageEntertain"
                                                                                               mainText:NSLocalizedString(@"ENTERTAIN ANYTIME", nil)
                                                                                             detailText:NSLocalizedString(@"When your guests arrive, Savant can dim the lights and mix the music just as you planned.", nil)];

    SCULandingPageViewController *controller5 = [[SCULandingPageViewController alloc] initWithImageName:@"FrontPageSecurity"
                                                                                               mainText:NSLocalizedString(@"FEEL SAFE", nil)
                                                                                             detailText:NSLocalizedString(@"Lock the front door from miles away—your home is always within reach.", nil)];

    self.currentPageViewController = controller1;

    self.controllers = @[controller1, controller2, controller3, controller4, controller5];

    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];

    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;

    [self.pageViewController setViewControllers:@[controller1] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];

    [self sav_addChildViewController:self.pageViewController];
    [self.view sav_pinView:self.pageViewController.view withOptions:SAVViewPinningOptionsToTop | SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:self.pageViewController.view withOptions:SAVViewPinningOptionsToTop ofView:buttonView withSpace:20];

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
    self.pageControl.numberOfPages = [self.controllers count];
    [self.view addSubview:self.pageControl];
    [self.view sav_pinView:self.pageControl withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:self.pageControl withOptions:SAVViewPinningOptionsToTop ofView:buttonView withSpace:20];

    for (UIScrollView *view in [self.pageViewController.view sav_allSubviews])
    {
        if ([view isKindOfClass:[UIScrollView class]])
        {
            view.delegate = self;
        }
    }

#ifdef DEBUG
    SCUButton *serverButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Servers", nil)];
    serverButton.target = self;
    serverButton.releaseAction = @selector(changeCloudServerAddress);
    serverButton.color = [[SCUColors shared] color04];
    serverButton.selectedColor = [[SCUColors shared] color01];
    serverButton.backgroundColor = [UIColor clearColor];
    serverButton.selectedBackgroundColor = [UIColor clearColor];

    [self.view addSubview:serverButton];
    [self.view sav_pinView:serverButton withOptions:SAVViewPinningOptionsToLeft withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_pinView:serverButton withOptions:SAVViewPinningOptionsToTop withSpace:30];
#endif

    SCUButton *localButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"search"]];
    localButton.target = self;
    localButton.releaseAction = @selector(handleSkip:);
    localButton.color = [[SCUColors shared] color04];
    localButton.selectedColor = [[SCUColors shared] color01];
    localButton.backgroundColor = [UIColor clearColor];
    localButton.selectedBackgroundColor = [UIColor clearColor];

    [self.view addSubview:localButton];
    [self.view sav_pinView:localButton withOptions:SAVViewPinningOptionsToRight withSpace:SAVViewAutoLayoutStandardSpace];
    [self.view sav_pinView:localButton withOptions:SAVViewPinningOptionsToTop withSpace:30];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIImage sav_clearImageCache];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)handleSignIn:(SCUButton *)sender
{
    SCUCloudSignInViewController *signInViewController = [[SCUCloudSignInViewController alloc] init];
    [self.navigationController pushViewController:signInViewController animated:YES];
    signInViewController.navigationItem.leftBarButtonItem = [self createCancelBarButtonItem];
}

- (void)handleSignUp:(SCUButton *)sender
{
    SCUCloudSignUpViewController *signUpViewController = [[SCUCloudSignUpViewController alloc] init];
    [self.navigationController pushViewController:signUpViewController animated:YES];
    signUpViewController.navigationItem.leftBarButtonItem = [self createCancelBarButtonItem];
}

- (void)handleSkip:(SCUButton *)sender
{
    [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
        [defaults setBool:YES forKey:SCUSignInIsSkippedKey];
    }];

    [[SCUMainViewController sharedInstance] presentSystemSelector:SCUSystemSelectorFromLocationSignIn];
}

- (UIBarButtonItem *)createCancelBarButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                         target:self
                                                         action:@selector(cancel:)];
}

- (void)cancel:(UIBarButtonItem *)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)changeCloudServerAddress
{
    SCUChangeServerTableViewController *changeServer = [[SCUChangeServerTableViewController alloc] init];
    [self.navigationController pushViewController:changeServer animated:YES];
}

#pragma mark - UIPageViewControllerDataSource methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController *vc = nil;
    NSUInteger indexOfViewController = [self.controllers indexOfObjectIdenticalTo:viewController];

    if (indexOfViewController != 0)
    {
        vc = self.controllers[indexOfViewController - 1];
    }

    return vc;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController *vc = nil;
    NSUInteger indexOfViewController = [self.controllers indexOfObjectIdenticalTo:viewController];

    if (indexOfViewController != [self.controllers count] - 1)
    {
        vc = self.controllers[indexOfViewController + 1];
    }

    return vc;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        self.pageControl.currentPage = [self.controllers indexOfObjectIdenticalTo:[pageViewController.viewControllers firstObject]];
        self.currentPageViewController = self.controllers[self.pageControl.currentPage];
    }
}

#pragma mark - Terrible rotation hacks

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        CGRect frame = self.pageViewController.view.frame;
        CGSize newSize = size;
        newSize.height -= 99;
        frame.size = newSize;
        self.pageViewController.view.frame = frame;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        ;
    }];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.currentPageViewController)
    {
        CGFloat pageWidth = CGRectGetWidth(self.currentPageViewController.view.bounds);
        CGFloat currentOffset = scrollView.contentOffset.x;
        CGFloat position = currentOffset - pageWidth;
        CGFloat percentage = position / pageWidth;
        CGFloat translation = percentage * (pageWidth / 2);

        //-------------------------------------------------------------------
        // Move the "main" view.
        //-------------------------------------------------------------------
        self.currentPageViewController.backgroundImage.transform = CGAffineTransformMakeTranslation(percentage * (pageWidth / 2), 0);

        //-------------------------------------------------------------------
        // Move the view that's coming on to screen.
        //-------------------------------------------------------------------
        NSInteger currentIndex = (NSInteger)[self.controllers indexOfObject:self.currentPageViewController];
        SCULandingPageViewController *nextController = nil;
        CGFloat nextTranslation = 0;

        if (percentage > 0)
        {
            if (currentIndex < (NSInteger)([self.controllers count] - 1))
            {
                nextController = self.controllers[currentIndex + 1];
                nextTranslation = -((pageWidth / 2) - translation);
            }
        }
        else
        {
            if ((currentIndex - 1) >= 0)
            {
                nextController = self.controllers[currentIndex - 1];
                nextTranslation = ((pageWidth / 2) + translation);
            }
        }

        if (nextTranslation)
        {
            CGRect frame = nextController.backgroundImage.frame;
            frame.origin.x = nextTranslation;
            nextController.backgroundImage.frame = frame;
        }
    }
}

@end
