
//
//  SCUTVNavigationViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNavigationViewController.h"
#import "SCUAVNavigationViewControllerPrivate.h"
#import "SCUTransportButtonCollectionViewController.h"
#import "SCUCustomHoldButton.h"
@import Extensions;
#import "SCUCascadingTimer.h"

@interface SCUAVNavigationViewController ()

@property (nonatomic, weak) NSTimer *revertTimer;
@property (nonatomic) BOOL supportsPageCommands;

@property (nonatomic) UILabel *channelLabel;
@property (nonatomic) UILabel *pageLabel;
@property (nonatomic) UILabel *diskLabel;

@end

@implementation SCUAVNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    
    if ([self.model.pageCommands count])
    {
        self.supportsPageCommands = YES;
    }
    else
    {
        self.supportsPageCommands = NO;
    }
    
    SCUTransportButtonCollectionViewController *buttonController = [[SCUTransportButtonCollectionViewController alloc] initWithGenericCommands:self.model.transportGenericCommands backCommands:self.model.transportBackCommands forwardCommands:self.model.transportForwardCommands];
    buttonController.columns = 3;
    
    self.transportContainer = [[SCUButtonViewController alloc] initWithCollectionViewController:buttonController];
    self.transportContainer.delegate = self;
    self.transportContainer.numberOfColumns = 3;
    [self addChildViewController:self.transportContainer];
    
    self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:self.model.numberPadCommands];
    self.numberPad.delegate = self;
    self.numberPad.letterMapping = YES;
    self.numberPad.hideInfoBox = YES;
    self.numberPad.flushConstraints = YES;
    [self addChildViewController:self.numberPad];
    
    self.directionalSwipeView = [[SCUSwipeView alloc] initWithFrame:CGRectZero configuration:SCUSwipeViewConfigurationAll];
    self.directionalSwipeView.delegate = self;
    
    UIImage *channelDownImage = [UIImage imageNamed:@"white_arrow_down"];
    UIImage *channelUpImage = [UIImage imageNamed:@"white_arrow_up"];
    
    self.upButton = [[SCUCustomHoldButton alloc] initWithImage:[channelUpImage scaleToSize:CGSizeMake(15, 15)]];
    self.downButton = [[SCUCustomHoldButton alloc] initWithImage:[channelDownImage scaleToSize:CGSizeMake(15, 15)]];
    self.upButton.backgroundColor = [UIColor clearColor];
    self.downButton.backgroundColor = [UIColor clearColor];
    self.upButton.selectedBackgroundColor = [[SCUColors shared] color01];
    self.downButton.selectedBackgroundColor = [[SCUColors shared] color01];
    
    self.bottomView  = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomView.backgroundColor = [[SCUColors shared] color03];

    self.bottomPagedView = [[SCUPagedViewControl alloc] initWithViews:[self pagedViews]];
    
    [self.bottomView addSubview:self.downButton];
    [self.bottomView addSubview:self.upButton];
    [self.bottomView addSubview:self.bottomPagedView];
    
    [self.bottomView sav_pinView:self.downButton withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToBottom];
    [self.bottomView sav_pinView:self.upButton withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToRight|SAVViewPinningOptionsToBottom];
    [self.bottomView sav_setWidth:0.35 forView:self.downButton isRelative:YES];
    [self.bottomView sav_setWidth:0.35 forView:self.upButton isRelative:YES];

    [self.bottomView sav_pinView:self.bottomPagedView withOptions:SAVViewPinningOptionsToRight ofView:self.downButton withSpace:0];
    [self.bottomView sav_pinView:self.bottomPagedView withOptions:SAVViewPinningOptionsToLeft ofView:self.upButton withSpace:0];
    [self.bottomView sav_pinView:self.bottomPagedView withOptions:SAVViewPinningOptionsVertically];
    
    self.bottomView.hidden = self.hideBottomBar;
    
    self.exitButton  = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Exit", nil)];
    self.lastButton  = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Last", nil)];
    self.dvrButton   = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"DVR", nil)];
    self.guideButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Guide", nil)];
    
    [self.exitButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [self.model sendCommand:@"Exit"];
    }];
    
    [self.lastButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [self.model sendCommand:@"LastChannel"];
    }];
    
    [self.dvrButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([self.model.serviceCommands containsObject:@"MyDVR"])
        {
            [self.model sendCommand:@"MyDVR"];
        }
        else if ([self.model.serviceCommands containsObject:@"List"])
        {
            [self.model sendCommand:@"List"];
        }
    }];
    
    [self.guideButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [self.model sendCommand:@"Guide"];
    }];
    
    self.upButton.holdTime = .6;
    self.upButton.target = self;
    self.upButton.pressAction = @selector(handlePressForUpButton);
    self.upButton.holdAction = @selector(handlePressForUpButton);
    self.upButton.releaseAction = @selector(handleRelease);
    
    self.downButton.holdTime = .6;
    self.downButton.target = self;
    self.downButton.pressAction = @selector(handlePressForDownButton);
    self.downButton.holdAction = @selector(handlePressForDownButton);
    self.downButton.releaseAction = @selector(handleRelease);
    
    self.upButton.color = [[SCUColors shared] color04];
    self.downButton.color = [[SCUColors shared] color04];
    
    self.directionalSwipeView.borderWidth = 0;
    self.directionalSwipeView.arrowViewSize = 200;
    self.directionalSwipeView.arrowSize = CGSizeMake(40, 40);
    self.directionalSwipeView.arrowColor = [[SCUColors shared] color03shade02];
    
    for (SCUButton *button in @[self.exitButton, self.lastButton, self.dvrButton, self.guideButton])
    {
        button.backgroundColor = [[SCUColors shared] color03];
        button.selectedBackgroundColor = [[SCUColors shared] color01];
        button.color = [[SCUColors shared] color04];
        button.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
    }
}

- (NSArray *)pagedViews
{
    self.channelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.pageLabel    = [[UILabel alloc] initWithFrame:CGRectZero];
    self.diskLabel    = [[UILabel alloc] initWithFrame:CGRectZero];
    
    self.channelLabel.text = NSLocalizedString(@"Channel", nil).uppercaseString;
    self.pageLabel.text = NSLocalizedString(@"Page", nil).uppercaseString;
    self.diskLabel.text = NSLocalizedString(@"Disk", nil).uppercaseString;

    for (UILabel *label in @[self.channelLabel, self.pageLabel, self.diskLabel])
    {
        label.textColor = [[SCUColors shared] color04];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h12];
    }

    NSMutableArray *views = [NSMutableArray array];
    if ([self.model.channelCommands count])
    {
        [views addObject:self.channelLabel];
    }
    if (self.supportsPageCommands)
    {
        [views addObject:self.pageLabel];
    }
    if ([self.model.navigationCommands containsObject:@"DiskUp"])
    {
        [views addObject:self.diskLabel];
    }

    return views;
}

- (void)handlePressForUpButton
{
    if (self.bottomPagedView.currentView == self.channelLabel)
    {
        [self.model sendCommand:@"ChannelAnalogUp"];
    }
    else if (self.bottomPagedView.currentView == self.pageLabel)
    {
        [self.model sendCommand:@"OSDPageUp"];
    }
    else if (self.bottomPagedView.currentView == self.diskLabel)
    {
        [self.model sendCommand:@"DiskUp"];
    }
}

- (void)handlePressForDownButton
{
    if (self.bottomPagedView.currentView == self.channelLabel)
    {
        [self.model sendCommand:@"ChannelAnalogDown"];
    }
    else if (self.bottomPagedView.currentView == self.pageLabel)
    {
        [self.model sendCommand:@"OSDPageDown"];
    }
    else if (self.bottomPagedView.currentView == self.diskLabel)
    {
        [self.model sendCommand:@"DiskDown"];
    }
}

- (void)handleHoldForUpButton
{
    if (self.bottomPagedView.currentView == self.channelLabel)
    {
        [self.model sendCommand:@"ChannelAnalogUp"];
    }
    else if (self.bottomPagedView.currentView == self.pageLabel)
    {
        [self.model sendCommand:@"OSDPageUp"];
    }
    else if (self.bottomPagedView.currentView == self.diskLabel)
    {
        [self.model sendCommand:@"DiskUp"];
    }
}

- (void)handleHoldForDownButton
{
    if (self.bottomPagedView.currentView == self.channelLabel)
    {
        [self.model sendCommand:@"ChannelAnalogDown"];
    }
    else if (self.bottomPagedView.currentView == self.pageLabel)
    {
        [self.model sendCommand:@"OSDPageDown"];
    }
    else if (self.bottomPagedView.currentView == self.diskLabel)
    {
        [self.model sendCommand:@"DiskDown"];
    }
}

- (void)handleRelease
{
    [self.model endHoldCommandWithCommand:@"StopRepeat"];
}

- (CGFloat)holdInterval
{
    if ([self.service.serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY"] ||
        [self.service.serviceId hasPrefix:@"SVC_AV_TV"] ||
        [self.service.serviceId hasPrefix:@"SVC_AV_SATELLITETV"] ||
        [self.service.serviceId hasPrefix:@"SVC_AV_KSCAPEMETADATAAUDIOMEDIASERVER"])
    {
        return 0.5;
    }
    
    return 0.2;
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"navigation"];
}

#pragma mark - SCUButtonCollectionViewControllerDelegate methods

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    [self.model sendCommand:command];
}

#pragma mark - SCUSwipeViewDelegate methods

- (void)swipeView:(SCUSwipeView *)swipeView didReceiveInteraction:(SCUSwipeViewDirection)interaction isHold:(BOOL)isHold
{
    NSArray *possibleCommands = nil;
    NSString *cmd = nil;
    
    if (swipeView == self.directionalSwipeView)
    {
        possibleCommands = [self.model.navigationCommands arrayByAddingObjectsFromArray:self.model.pageCommands];
    }
    else
    {
        return;
    }
    
    switch (interaction)
    {
        case SCUSwipeViewDirectionUp:
            cmd = [self commandContainingString:@[@"Up"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionDown:
            cmd = [self commandContainingString:@[@"Down"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionLeft:
            cmd = [self commandContainingString:@[@"Left"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionRight:
            cmd = [self commandContainingString:@[@"Right"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionCenter:
            cmd = [self commandContainingString:@[@"Select", @"Enter"] inArray:possibleCommands];
            break;
    }
    
    if (cmd)
    {
        if (isHold)
        {
            [self.model sendHoldCommand:cmd withInterval:self.holdInterval];
        }
        else
        {
            [self.model sendCommand:cmd];
        }
    }
}

- (void)swipeView:(SCUSwipeView *)swipeView holdInteractionDidEnd:(SCUSwipeViewDirection)interaction
{
    [self.model endHoldCommandWithCommand:nil];
}

#pragma mark - SCUSwipeViewDelegate helper methods

- (NSString *)commandContainingString:(NSArray *)strings inArray:(NSArray *)array
{
    NSArray *commands = [array filteredArrayUsingBlock:^BOOL(NSString *command) {
        BOOL keep = NO;

        for (NSString *string in strings)
        {
            keep = [command containsString:string];

            if (keep)
            {
                break;
            }
        }

        return keep;
    }];

    NSString *commandToUse = nil;

    for (NSString *string in strings)
    {
        for (NSString *command in commands)
        {
            if ([command containsString:string])
            {
                commandToUse = command;

                break;
            }
        }

        if (commandToUse)
        {
            break;
        }
    }

    return commandToUse;
}

#pragma mark - dynamic text

- (void)setSwipeViewCenterText:(NSString *)text animated:(BOOL)animated
{
    SAVWeakSelf;
    if (animated)
    {
        [UIView animateWithDuration:.25 animations:^{
            wSelf.directionalSwipeView.centerLabel.alpha = 0.f;
        } completion:^(BOOL finished) {
            wSelf.directionalSwipeView.centerLabel.text = text;
            [UIView animateWithDuration:.5 animations:^{
                wSelf.directionalSwipeView.centerLabel.alpha = 1.f;
            }];
        }];
    }
    else
    {
        self.directionalSwipeView.centerLabel.text = text;
    }
}

@end
