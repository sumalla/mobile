//
//  SCULandingPageViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULandingPageViewController.h"
#import "SCUGradientView.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCULandingPageViewController ()

@property (nonatomic) UIImageView *backgroundImage;
@property (nonatomic) UILabel *subLabel;
@property (nonatomic) UILabel *mainLabel;

@end

@implementation SCULandingPageViewController

- (instancetype)initWithImageName:(NSString *)imageName mainText:(NSString *)mainText detailText:(NSString *)detailText
{
    self = [super init];

    if (self)
    {
        UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
        backgroundImage.clipsToBounds = YES;
        [self.view addSubview:backgroundImage];
        self.backgroundImage = backgroundImage;

        SCUGradientView *gradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03] colorWithAlphaComponent:.4], [[[SCUColors shared] color03] colorWithAlphaComponent:.9]]];
        gradient.locations = @[@.4, @1];
        [self.view addSubview:gradient];
        [self.view sav_addFlushConstraintsForView:gradient];

        UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        mainLabel.textAlignment = NSTextAlignmentCenter;
        mainLabel.text = mainText;
        mainLabel.font = [UIFont fontWithName:@"Gotham-Medium" size:[UIDevice isPad] ? 32 : 28];
        mainLabel.textColor = [[SCUColors shared] color04];
        mainLabel.adjustsFontSizeToFitWidth = YES;
        mainLabel.minimumScaleFactor = .8;
        [self.view addSubview:mainLabel];
        self.mainLabel = mainLabel;

        [self.view sav_pinView:mainLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:SAVViewAutoLayoutStandardSpace];
        [self.view sav_pinView:mainLabel withOptions:SAVViewPinningOptionsCenterY];

        UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subLabel.textAlignment = NSTextAlignmentCenter;
        subLabel.numberOfLines = 0;
        subLabel.text = detailText;
        subLabel.textColor = [[SCUColors shared] color04];
        subLabel.lineBreakMode = NSLineBreakByWordWrapping;
        subLabel.font = [UIFont systemFontOfSize:[UIDevice isPad] ? 18 : 15];
        [self.view addSubview:subLabel];
        self.subLabel = subLabel;

        [self layoutSublabelForOrientation:[UIDevice deviceOrientation]];

        self.view.clipsToBounds = YES;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self layoutSublabelForOrientation:[UIDevice deviceOrientation]];
}

- (void)layoutSublabelForOrientation:(UIInterfaceOrientation)orientation
{
    [self.subLabel removeFromSuperview];
    [self.view addSubview:self.subLabel];

    if ([UIDevice isPad] && [self.subLabel.text length] > 70 && UIInterfaceOrientationIsPortrait(orientation))
    {
        [self.view sav_setWidth:.55 forView:self.subLabel isRelative:YES];
        [self.view sav_pinView:self.subLabel withOptions:SAVViewPinningOptionsCenterX];
    }
    else
    {
        [self.view sav_pinView:self.subLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:SAVViewAutoLayoutStandardSpace];
    }

    [self.view sav_pinView:self.subLabel withOptions:SAVViewPinningOptionsToBottom ofView:self.mainLabel withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.backgroundImage.frame = self.view.bounds;
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self layoutSublabelForOrientation:orientation];
    }];
}

@end
