//
//  SCUNowPlayingViewControllerPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingModel.h"
#import "SCUMarqueeLabel.h"
#import "SCUButton.h"
#import "SCUArtworkImageView.h"
#import "SCUSlider.h"
#import "SCUGradientView.h"
@import Extensions;

@interface SCUNowPlayingViewController () <SCUNowPlayingModelDelegate>

@property (nonatomic) SCUNowPlayingModel *model;
@property (nonatomic) UIImageView *albumArtworkView;
@property (nonatomic) UILabel *elapsedTimeLabel;
@property (nonatomic) SCUSlider *progressSlider;
@property (nonatomic) UILabel *remainingTimeLabel;
@property (nonatomic) SCUMarqueeLabel *label;
@property (nonatomic) SCUArtworkImageView *artwork;
@property (nonatomic) SCUButton *shuffleButton;
@property (nonatomic) SCUButton *repeatButton;
@property (nonatomic) SCUButton *servicesFirst;
@property (nonatomic) SCUButton *thumbsUp;
@property (nonatomic) SCUButton *thumbsDown;
@property (nonatomic) SCUGradientView *artworkGradient;

@property (nonatomic) NSArray *visibleConstraints;
@property (nonatomic) NSDictionary *views;

- (SCUButton *)buttonWithTransportButtonType:(SCUNowPlayingModelTransportButtonType)buttonType;

#pragma mark - Methods to subclass

- (void)addSubviews;

@property (nonatomic, readonly, copy) NSArray *layoutViews;

- (void)updateLabel;

@property (nonatomic, readonly) BOOL wantsSongInLabel;

@property (nonatomic, readonly) BOOL wantsArtistInLabel;

@property (nonatomic, readonly) BOOL wantsAlbumInLabel;

@property (nonatomic, readonly) BOOL wantsArtworkBorderAndGradient;

@property (nonatomic, readonly) BOOL wantsShuffleAndRepeatInArtwork;

@property (nonatomic, readonly) BOOL matchThumbsToShuffleAndRepeat;

@property (nonatomic, readonly) BOOL wantsNowPlayingButton;

@property (nonatomic, readonly) SCUSliderStyle sliderStyle;

- (void)toggleHidden:(BOOL)hidden;

@property (nonatomic, readonly, copy) UIFont *labelFont;

- (void)calculateArtworkDimensions;

@end
