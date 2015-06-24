//
//  SCUNowPlayingFullScreenViewControllerPhone.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingFullScreenViewControllerPhone.h"
#import "SCUNowPlayingViewControllerPrivate.h"
@import SDK;

@interface SCUNowPlayingFullScreenViewControllerPhone ()

@property (nonatomic) SCUMarqueeLabel *songLabel;
@property (nonatomic) SCUButton *play;
@property (nonatomic) SCUButton *previous;
@property (nonatomic) SCUButton *next;
@property (nonatomic) UIView *transportContainer;

@end

@implementation SCUNowPlayingFullScreenViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    self.progressSlider.thumbColor = [[SCUColors shared] color01];
    self.progressSlider.trackColor = [[SCUColors shared] color03shade05];
    self.progressSlider.fillColor = [[SCUColors shared] color03shade05];

    [self.artwork addSubview:self.thumbsDown];
    [self.artwork addSubview:self.thumbsUp];

    self.artwork.contentMode = UIViewContentModeScaleAspectFit;
    self.title = self.model.service.alias;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.songLabel = [[SCUMarqueeLabel alloc] initWithFrame:CGRectZero];
    self.songLabel.textColor = [[SCUColors shared] color04];
    self.songLabel.backgroundColor = [UIColor clearColor];
    self.songLabel.textAlignment = NSTextAlignmentCenter;
    self.songLabel.font = [UIFont boldSystemFontOfSize:16];

    self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlay];
    self.previous = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePrevious];
    self.next = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeNext];

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 20;
    configuration.fixedWidth = 40;

    self.transportContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.previous, self.play, self.next]
                                                       withConfiguration:configuration];

    for (UILabel *label in @[self.elapsedTimeLabel, self.remainingTimeLabel])
    {
        label.font = [UIFont systemFontOfSize:14];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = .7;
    }

    [self.view addSubview:self.artwork];
    [self.view addSubview:self.progressSlider];
    [self.view addSubview:self.elapsedTimeLabel];
    [self.view addSubview:self.remainingTimeLabel];
    [self.view addSubview:self.songLabel];
    [self.view addSubview:self.label];
    [self.view addSubview:self.transportContainer];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.elapsedTimeLabel.textAlignment = NSTextAlignmentRight;
    self.remainingTimeLabel.text = NSTextAlignmentLeft;

    UIView *dummyView1 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *dummyView2 = [[UIView alloc] initWithFrame:CGRectZero];

    [self.view addSubview:dummyView1];
    [self.view addSubview:dummyView2];

    NSDictionary *views = @{@"artwork": self.artwork,
                            @"elapsed": self.elapsedTimeLabel,
                            @"progress": self.progressSlider,
                            @"remaining": self.remainingTimeLabel,
                            @"song": self.songLabel,
                            @"artist": self.label,
                            @"transport": self.transportContainer,
                            @"dummy1": dummyView1,
                            @"dummy2": dummyView2};

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                       views:views
                                                                     formats:@[@"|-12-[artwork]-12-|",
                                                                               @"V:|-12-[artwork]",
                                                                               @"artwork.height = super.height / 2",
                                                                               @"|-6-[elapsed][progress][remaining(==elapsed)]-6-|",
                                                                               @"elapsed.width = 60",
                                                                               @"elapsed.height = 40",
                                                                               @"progress.height = 40",
                                                                               @"remaining.height = 40",
                                                                               @"V:[elapsed]-40-|",
                                                                               @"progress.centerY = elapsed.centerY",
                                                                               @"remaining.centerY = elapsed.centerY",
                                                                               @"artist.bottom = progress.top - 20",
                                                                               @"artist.height = 20",
                                                                               @"|-[artist]-|",
                                                                               @"song.bottom = artist.top - 2",
                                                                               @"song.height = 30",
                                                                               @"|-[song]-|",
                                                                               @"transport.centerX = super.centerX",
                                                                               @"|[dummy1]|",
                                                                               @"|[dummy2]|",
                                                                               @"V:[artwork][dummy1][transport(30)][dummy2(==dummy1)][song]"
                                                                               ]]];
}

- (void)toggleHidden:(BOOL)hidden
{
    //-------------------------------------------------------------------
    // This is overrided because we always want to stay open.
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

    if (!self.play)
    {
        self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlay];
    }

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
    return [UIFont systemFontOfSize:15];
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
