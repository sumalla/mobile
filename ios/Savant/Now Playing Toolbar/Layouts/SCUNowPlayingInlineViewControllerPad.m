//
//  SCUNowPlayingInlineViewControllerPad.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingInlineViewControllerPad.h"
#import "SCUNowPlayingViewControllerPrivate.h"

@interface SCUNowPlayingInlineViewControllerPad ()

@property (nonatomic) UIView *separatorView;
@property (nonatomic) UIView *transportContainer;
@property (nonatomic) SCUButton *play;
@property (nonatomic) SCUButton *previous;
@property (nonatomic) SCUButton *next;

@end

@implementation SCUNowPlayingInlineViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[SCUColors shared] color03];
    self.separatorView = [UIView sav_viewWithColor:[[SCUColors shared] color03shade05]];
    self.progressSlider.thumbColor = [UIColor clearColor];

    self.play = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePlay];
    self.previous = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypePrevious];
    self.next = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeNext];

    UIFont *font = [UIFont fontWithName:@"Gotham-Light" size:14];
    self.elapsedTimeLabel.font = font;
    self.remainingTimeLabel.font = font;

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 15;
    configuration.fixedWidth = 30;
    configuration.fixedHeight = 30;

    self.transportContainer = [UIView sav_viewWithEvenlyDistributedViews:@[self.shuffleButton, self.repeatButton, self.previous, self.play, self.next]
                                                       withConfiguration:configuration];

    [self.transportContainer addSubview:self.thumbsUp];
    [self.transportContainer addSubview:self.thumbsDown];

    [self.view addSubview:self.separatorView];
    [self.view addSubview:self.artwork];
    [self.view addSubview:self.elapsedTimeLabel];
    [self.view addSubview:self.remainingTimeLabel];
    [self.view addSubview:self.progressSlider];
    [self.view addSubview:self.label];
    [self.view addSubview:self.transportContainer];

    [self.view bringSubviewToFront:self.separatorView];

    NSDictionary *metrics = @{@"pixel": @([UIScreen screenPixel]),
                              @"padding": @12};

    NSDictionary *views = @{@"separator": self.separatorView,
                            @"artwork": self.artwork,
                            @"elapsed": self.elapsedTimeLabel,
                            @"remaining": self.remainingTimeLabel,
                            @"progress": self.progressSlider,
                            @"label": self.label,
                            @"transport": self.transportContainer};

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                       views:views
                                                                     formats:@[@"|-[separator]-|",
                                                                               @"V:|[separator(pixel)]",
                                                                               @"|-padding-[artwork]",
                                                                               @"V:|-padding-[artwork]-padding-|",
                                                                               @"artwork.width = artwork.height",
//                                                                               @"V:|-15-[label]-4-[elapsed(==label)]-15-|",
                                                                               @"label.bottom = super.centerY",
                                                                               @"elapsed.top = super.centerY",
                                                                               @"[artwork]-10-[label]",
                                                                               @"label.width = super.width / 2",
                                                                               @"[artwork]-[elapsed]",
                                                                               @"elapsed.width = 60",
                                                                               @"[artwork]-[elapsed][progress]-[remaining(==elapsed)]",
                                                                               @"remaining.height = elapsed.height",
                                                                               @"progress.height = elapsed.height",
                                                                               @"remaining.right = label.right",
                                                                               @"progress.centerY = elapsed.centerY",
                                                                               @"remaining.centerY = elapsed.centerY",
                                                                               @"transport.centerY = super.centerY",
                                                                               @"[transport]-|"]]];
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

- (BOOL)matchThumbsToShuffleAndRepeat
{
    return YES;
}

@end
