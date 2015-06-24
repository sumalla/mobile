//
//  SCUNowPlayingFullScreenViewControllerPad.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingFullScreenViewControllerPad.h"
#import "SCUNowPlayingViewControllerPrivate.h"

@interface SCUNowPlayingFullScreenViewControllerPad ()

@property (nonatomic) UIView *transportContainer;
@property (nonatomic) SCUButton *play;
@property (nonatomic) SCUButton *previous;
@property (nonatomic) SCUButton *next;
@property (nonatomic) NSArray *lastConstraints;
@property (nonatomic) SCUMarqueeLabel *songLabel;

@end

@implementation SCUNowPlayingFullScreenViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.label.backgroundColor = self.view.backgroundColor;

    self.progressSlider.thumbColor = [[SCUColors shared] color01];
    self.progressSlider.trackColor = [[SCUColors shared] color03shade05];
    self.progressSlider.fillColor = [[SCUColors shared] color03shade05];

    self.songLabel = [[SCUMarqueeLabel alloc] initWithFrame:CGRectZero];
    self.songLabel.textColor = [[SCUColors shared] color04];
    self.songLabel.textAlignment = NSTextAlignmentCenter;
    self.songLabel.font = [UIFont boldSystemFontOfSize:20];

    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.backgroundColor = [UIColor clearColor];

    self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlay];
    self.previous = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePrevious];
    self.next = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeNext];

    [self.artwork addSubview:self.thumbsDown];
    [self.artwork addSubview:self.thumbsUp];

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 20;
    configuration.fixedWidth = 40;

    self.transportContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.previous, self.play, self.next]
                                                       withConfiguration:configuration];

    [self.view addSubview:self.artwork];
    [self.view addSubview:self.elapsedTimeLabel];
    [self.view addSubview:self.remainingTimeLabel];
    [self.view addSubview:self.progressSlider];
    [self.view addSubview:self.label];
    [self.view addSubview:self.songLabel];
    [self.view addSubview:self.transportContainer];
    [self updateLayoutWithInterfaceOrientation:[UIDevice interfaceOrientation]];
}

- (void)updateLayoutWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([self.lastConstraints count])
    {
        [self.view removeConstraints:self.lastConstraints];
    }

    NSDictionary *metrics = @{@"padding": @20,
                              @"labelSpace": @0,
                              @"progressSpace": @30,
                              @"transportSpace": @60,
                              @"artworkPadding": @80};

    NSDictionary *views = @{@"songLabel": self.songLabel,
                            @"artwork": self.artwork,
                            @"elapsed": self.elapsedTimeLabel,
                            @"remaining": self.remainingTimeLabel,
                            @"progress": self.progressSlider,
                            @"label": self.label,
                            @"transport": self.transportContainer};

    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        self.lastConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                        views:views
                                                                      formats:@[@"|-artworkPadding-[artwork]-artworkPadding-|",
                                                                                @"V:|-padding-[artwork]",
                                                                                @"artwork.height = artwork.width",
                                                                                @"|-artworkPadding-[elapsed]-[progress]-[remaining(==elapsed)]-artworkPadding-|",
                                                                                @"progress.height = elapsed.height",
                                                                                @"remaining.height = elapsed.height",
                                                                                @"elapsed.bottom = super.bottom - 50",
                                                                                @"progress.centerY = elapsed.centerY",
                                                                                @"remaining.centerY = elapsed.centerY",
                                                                                @"|-[label]-|",
                                                                                @"|-[songLabel]-|",
                                                                                @"transport.centerX = super.centerX",
                                                                                @"V:[artwork]-transportSpace-[transport]-padding-[songLabel]-[label]"
                                                                                ]];
    }
    else
    {
        self.lastConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                        views:views
                                                                      formats:@[@"|-[artwork]",
                                                                                @"V:|-padding-[artwork]-padding-|",
                                                                                @"artwork.width = artwork.height",
                                                                                @"[artwork]-[label]-|",
                                                                                @"label.centerY = super.centerY",
                                                                                @"songLabel.bottom = label.top - labelSpace",
                                                                                @"songLabel.width = label.width",
                                                                                @"songLabel.centerX = label.centerX",
                                                                                @"transport.centerX = label.centerX",
                                                                                @"transport.bottom = label.top - transportSpace",
                                                                                @"elapsed.top = label.bottom + progressSpace",
                                                                                @"[artwork]-[elapsed]-[progress]-[remaining(==elapsed)]-|",
                                                                                @"progress.height = elapsed.height",
                                                                                @"progress.centerY = elapsed.centerY",
                                                                                @"remaining.height = elapsed.height",
                                                                                @"remaining.centerY = elapsed.centerY"
                                                                                ]];
    }

    if ([self.lastConstraints count])
    {
        [self.view addConstraints:self.lastConstraints];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self updateLayoutWithInterfaceOrientation:orientation];
    }];

    dispatch_async_main(^{
        [self calculateArtworkDimensions];
        self.artwork.image = self.artwork.image;
    });
}

- (void)toggleHidden:(BOOL)hidden
{
    //-------------------------------------------------------------------
    // This is overriden because we always want to stay open.
    //-------------------------------------------------------------------
}

- (void)songDidUpdateWithValue:(NSString *)value
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.songLabel.text = value;
    });
}

- (void)pauseStatusDidUpdateWithValue:(NSNumber *)value
{
    [super pauseStatusDidUpdateWithValue:value];

    if ([value boolValue])
    {
        self.play.image = [UIImage sav_imageNamed:@"Play" tintColor:[[SCUColors shared] color04]];
    }
    else
    {
        self.play.image = [UIImage sav_imageNamed:@"Pause" tintColor:[[SCUColors shared] color04]];
    }
}

- (BOOL)wantsSongInLabel
{
    return NO;
}

- (UIFont *)labelFont
{
    return [UIFont systemFontOfSize:18];
}

- (BOOL)wantsArtworkBorderAndGradient
{
    return YES;
}

- (BOOL)wantsShuffleAndRepeatInArtwork
{
    return YES;
}

- (BOOL)matchThumbsToShuffleAndRepeat
{
    return YES;
}

- (BOOL)wantsNowPlayingButton
{
    return YES;
}

- (SCUSliderStyle)sliderStyle
{
    return SCUSliderStyleiTunes;
}

@end
