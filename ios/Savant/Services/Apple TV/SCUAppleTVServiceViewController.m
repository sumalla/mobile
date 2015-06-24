//
//  SCUAppleTVServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAppleTVServiceViewController.h"
#import "SCUSwipeView.h"
#import "SCUButton.h"

@import Extensions;

@interface SCUAppleTVServiceViewController () <SCUSwipeViewDelegate>

@property (nonatomic) SCUSwipeView *swipeView;
@property (nonatomic) SCUButton *menuButton;
@property (nonatomic) SCUButton *playPauseButton;

@end

@implementation SCUAppleTVServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.swipeView = [[SCUSwipeView alloc] initWithFrame:CGRectZero configuration:SCUSwipeViewConfigurationAll];
    self.swipeView.delegate = self;

    [self.contentView addSubview:self.swipeView];
    [self.contentView sav_addFlushConstraintsForView:self.swipeView];

    self.menuButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleAVStandardGrouped title:NSLocalizedString(@"Menu", nil)];
    self.menuButton.holdTime = .2;
    self.menuButton.target = self;
    self.menuButton.pressAction = @selector(menu:);
    self.menuButton.holdAction = @selector(menu:);
    self.menuButton.releaseAction = @selector(release:);
    [self.contentView addSubview:self.menuButton];

    self.playPauseButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleAVStandardGrouped image:[UIImage sav_imageNamed:@"PlayPause" tintColor:[[SCUColors shared] color04]]];
    self.playPauseButton.tintImage = NO;
    self.playPauseButton.holdTime = .2;
    self.playPauseButton.target = self;
    self.playPauseButton.pressAction = @selector(playPause:);
    self.playPauseButton.holdAction = @selector(playPause:);
    self.playPauseButton.releaseAction = @selector(release:);
    [self.contentView addSubview:self.playPauseButton];

    CGFloat padding = 11;

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.distributeEvenly = YES;
    configuration.interSpace = [UIScreen screenPixel];

    UIView *containerView = [UIView sav_viewWithEvenlyDistributedViews:@[self.menuButton, self.playPauseButton] withConfiguration:configuration];
    containerView.borderWidth = [UIScreen screenPixel];
    containerView.borderColor = [[SCUColors shared] color03shade04];
    containerView.backgroundColor = [[SCUColors shared] color03shade04];
    [self.contentView addSubview:containerView];

    [self.contentView sav_pinView:containerView
                      withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsToBottom
                        withSpace:padding];

    [self.contentView sav_setHeight:60 forView:containerView isRelative:NO];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.swipeView.frame = self.contentView.bounds;
}

#pragma mark - SCUSwipeViewDelegate

- (void)swipeView:(SCUSwipeView *)swipeView didReceiveInteraction:(SCUSwipeViewDirection)interaction isHold:(BOOL)isHold
{
    NSString *command = nil;

    switch (interaction)
    {
        case SCUSwipeViewDirectionUp:
            command = @"OSDCursorUp";
            break;
        case SCUSwipeViewDirectionDown:
            command = @"OSDCursorDown";
            break;
        case SCUSwipeViewDirectionLeft:
            command = @"OSDCursorLeft";
            break;
        case SCUSwipeViewDirectionRight:
            command = @"OSDCursorRight";
            break;
        case SCUSwipeViewDirectionCenter:
            command = @"OSDSelect";
            break;
    }

    if (command)
    {
        if (isHold)
        {
            [self.model sendHoldCommand:command withInterval:SCUServiceModelDefaultHoldInterval];
        }
        else
        {
            [self.model sendCommand:command];
            [self releaseCommand];
        }
    }
}

- (void)swipeView:(SCUSwipeView *)swipeView holdInteractionDidEnd:(SCUSwipeViewDirection)interaction
{
    [self releaseCommand];
}

#pragma mark - Actions

- (void)menu:(SCUButton *)button
{
    [self.model sendCommand:@"Menu"];
}

- (void)playPause:(SCUButton *)playPause
{
    [self.model sendCommand:@"Play"];
}

- (void)release:(SCUButton *)button
{
    [self releaseCommand];
}

- (void)releaseCommand
{
    [self.model endHoldCommandWithCommand:@"StopRepeat"];
}

@end
