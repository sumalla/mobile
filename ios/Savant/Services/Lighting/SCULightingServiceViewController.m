//
//  SCULightingServiceViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingServiceViewController.h"
#import "SCULightingModel.h"
#import "SCUShadesModel.h"
#import "SCULightingTableViewController.h"
@import Extensions;

@interface SCULightingServiceViewController () <SCULightingModelRoomImageDelegate>

@property (nonatomic) SCULightingModel *lightingModel;
@property (nonatomic) SCULightingTableViewController *lightingTable;
@property (nonatomic) UIImageView *roomImageView;
@property (nonatomic) UILabel *roomLabel;
@property (nonatomic) NSArray *lastConstraints;

@end

@implementation SCULightingServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.contentView.backgroundColor = [[SCUColors shared] color03shade01];

    if ([self.model.service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
    {
        self.lightingModel = [[SCUShadesModel alloc] initWithService:self.model.service];
    }
    else
    {
        self.lightingModel = [[SCULightingModel alloc] initWithService:self.model.service];
    }

    self.lightingModel.roomImageDelegate = self;
    self.lightingTable = [[SCULightingTableViewController alloc] initWithModel:self.lightingModel];
    [self addChildViewController:self.lightingTable];
    [self.contentView addSubview:self.lightingTable.view];

    if ([UIDevice isPad])
    {
        self.roomImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.roomImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.roomImageView.clipsToBounds = YES;
        self.roomImageView.hidden = YES;
        [self.contentView addSubview:self.roomImageView];
        
        SCUGradientView *gradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03] colorWithAlphaComponent:.8], [[[SCUColors shared] color03] colorWithAlphaComponent:.25]]];
        gradient.locations = @[@(0), @(1)];
        
        [self.roomImageView addSubview:gradient];
        [self.roomImageView sav_addFlushConstraintsForView:gradient];
        
        self.roomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.roomLabel.textColor = [[SCUColors shared] color04];
        self.roomLabel.font = [UIDevice isPad] ? [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h6] : [UIFont fontWithName:@"Gotham-Light" size:[[SCUDimens dimens] regular].h7];
        self.roomLabel.adjustsFontSizeToFitWidth = YES;
        self.roomLabel.minimumScaleFactor = 0.75;
        self.roomLabel.text = self.service.zoneName;
        
        [self.roomImageView addSubview:self.roomLabel];
        [self.roomImageView sav_pinView:self.roomLabel withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToTop|SAVViewPinningOptionsToRight withSpace:27];
        
        [self updateConstraintsForOrientation:[UIDevice interfaceOrientation]];
    }
    else
    {
        [self.contentView sav_addFlushConstraintsForView:self.lightingTable.view];
    }
}

- (void)updateConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    [self.roomImageView removeFromSuperview];
    [self.contentView addSubview:self.roomImageView];
    [self.lightingTable sav_removeFromParentViewController];
    [self addChildViewController:self.lightingTable];
    [self.contentView addSubview:self.lightingTable.view];

    NSDictionary *metrics = @{@"spacing": @20};
    
    NSDictionary *views = @{@"image": self.roomImageView,
                            @"table": self.lightingTable.view};
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        self.roomImageView.hidden = YES;
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                        views:views
                                                                      formats:@[@"|-spacing-[table]-spacing-|",
                                                                                @"V:|[table]|"]]];
    }
    else
    {
        self.roomImageView.hidden = NO;
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                        views:views
                                                                      formats:@[@"|-spacing-[image]-spacing-[table]-spacing-|",
                                                                                @"image.width = super.width * .3",
                                                                                @"V:|-spacing-[image]-spacing-|",
                                                                                @"V:|[table]|"]]];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self updateConstraintsForOrientation:orientation];
    }];
}

#pragma mark - SCULightingModelRoomImageDelegate methods

- (void)roomImageDidUpdate:(UIImage *)image
{
    if ([UIDevice isPad])
    {
        self.roomImageView.image = image;
    }
}

#pragma mark - SCUMainToolbarManager

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

@end
