//
//  SCUHardButtonVolumeNotification.m
//  SavantController
//
//  Created by Cameron Pulsford on 1/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUHardButtonVolumeNotification.h"
#import "SCUSlider.h"

@interface SCUHardButtonVolumeNotification ()

@property (nonatomic) BOOL allowVolumePercentageUpdates;
@property (nonatomic) UILabel *roomLabel;
@property (nonatomic) UILabel *percentage;
@property (nonatomic) UILabel *deltaLabel;
@property (nonatomic) UIImageView *relativeIconView;
@property (nonatomic) SCUSlider *slider;
@property (nonatomic, weak) NSTimer *fadeOutTimer;
@property (nonatomic) CGRect startFrame;
@property (nonatomic) CGPoint startCenter;

@end

@implementation SCUHardButtonVolumeNotification

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.roomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.roomLabel.textAlignment = NSTextAlignmentCenter;
        self.roomLabel.textColor = [[SCUColors shared] color03];
        self.roomLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];

        [self addSubview:self.roomLabel];

        self.percentage = [[UILabel alloc] initWithFrame:CGRectZero];
        self.percentage.textAlignment = NSTextAlignmentRight;
        self.percentage.textColor = [[SCUColors shared] color01];
        [self addSubview:self.percentage];

        self.slider = [[SCUSlider alloc] initWithStyle:SCUSliderStyleVolumePopup frame:CGRectZero];
        self.slider.fillColor = [[SCUColors shared] color01];
        [self addSubview:self.slider];
        
        self.relativeIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.relativeIconView.hidden = YES;
        [self addSubview:self.relativeIconView];

        self.alpha = 0;
        self.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:0.9];
        self.cornerRadius = 6;
        self.userInteractionEnabled = NO;
        
        self.startFrame = CGRectZero;
        self.startCenter = CGPointZero;
    }

    return self;
}

- (void)interact
{
	[self.superview bringSubviewToFront:self];
    self.allowVolumePercentageUpdates = YES;

    if (self.alpha == 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            self.alpha = .95;
        } completion:^(BOOL finished) {
            [self scheduleHide];
        }];
    }
    else
    {
        [self scheduleHide];
    }
}

- (CGSize)intrinsicContentSize
{
    switch (self.notificationStyle)
    {
        case SCUHardButtonVolumeNotificationStyleDiscrete:
            return CGSizeMake(200, 70);
        case SCUHardButtonVolumeNotificationStyleRelative:
            return CGSizeMake(180, 80);
    }
    
    return CGSizeZero;
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    [self sav_pinView:self.percentage withOptions:SAVViewPinningOptionsToLeft withSpace:12];
    [self sav_pinView:self.percentage withOptions:SAVViewPinningOptionsToBottom withSpace:12];
    [self sav_pinView:self.slider withOptions:SAVViewPinningOptionsToRight ofView:self.percentage withSpace:8];
    [self sav_pinView:self.slider withOptions:SAVViewPinningOptionsToRight withSpace:12];
    [self sav_pinView:self.slider withOptions:SAVViewPinningOptionsCenterY ofView:self.percentage withSpace:0];
    [self sav_pinView:self.roomLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:8];
    [self sav_pinView:self.roomLabel withOptions:SAVViewPinningOptionsToTop withSpace:12];
    
    [self sav_pinView:self.relativeIconView withOptions:SAVViewPinningOptionsCenterX];
    [self sav_pinView:self.relativeIconView withOptions:SAVViewPinningOptionsToBottom withSpace:12];
    
    [self sav_setHeight:12 forView:self.slider isRelative:NO];
    [self sav_setWidth:0.24 forView:self.percentage isRelative:YES];
}

- (void)setNotificationStyle:(SCUHardButtonVolumeNotificationStyle)notificationStyle
{
    if (_notificationStyle != notificationStyle)
    {
        _notificationStyle = notificationStyle;
        
        switch (notificationStyle)
        {
            case SCUHardButtonVolumeNotificationStyleDiscrete:
                self.relativeIconView.hidden = YES;
                self.percentage.hidden = NO;
                self.slider.hidden = NO;
                break;
                
            case SCUHardButtonVolumeNotificationStyleRelative:
                self.relativeIconView.hidden = NO;
                self.percentage.hidden = YES;
                self.slider.hidden = YES;
                break;
        }
        
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setNumberOfRooms:(NSInteger)rooms
{
    self.roomLabel.text = [NSString stringWithFormat:@"%ld Rooms", (long)rooms];
}

- (void)setRoomName:(NSString *)name
{
    self.roomLabel.text = name;
}

- (void)updatePercentage:(NSInteger)percentage
{
    if (self.allowVolumePercentageUpdates)
    {
        [self setNotificationStyle:SCUHardButtonVolumeNotificationStyleDiscrete];
        self.percentage.text = [NSString stringWithFormat:@"%ld%%", (long)percentage];
        self.slider.value = (CGFloat)percentage;
    }
}

- (void)showVolumeUp
{
    [self.superview bringSubviewToFront:self];
    self.allowVolumePercentageUpdates = NO;

    [self setNotificationStyle:SCUHardButtonVolumeNotificationStyleRelative];
    
    self.relativeIconView.image = [UIImage sav_imageNamed:@"VolumeToastPlus" tintColor:[[SCUColors shared] color01]];
    
    if (self.alpha == 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            self.alpha = .95;
        } completion:^(BOOL finished) {
            [self scheduleHide];
            self.startFrame = self.relativeIconView.frame;
            self.startCenter = self.relativeIconView.center;
        }];
    }
    else
    {
        [self scheduleHide];
        [self pulseIcon];
    }
}

- (void)showVolumeDown
{
    [self.superview bringSubviewToFront:self];
    self.allowVolumePercentageUpdates = NO;

    [self setNotificationStyle:SCUHardButtonVolumeNotificationStyleRelative];
    
    self.relativeIconView.image = [UIImage sav_imageNamed:@"VolumeToastMinus" tintColor:[[SCUColors shared] color01]];
    
    if (self.alpha == 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            self.alpha = .95;
        } completion:^(BOOL finished) {
            [self scheduleHide];
            self.startFrame = self.relativeIconView.frame;
            self.startCenter = self.relativeIconView.center;
        }];
    }
    else
    {
        [self scheduleHide];
        [self pulseIcon];
    }
}

- (void)hide
{
    self.allowVolumePercentageUpdates = NO;
    
    [self.fadeOutTimer invalidate];

    [UIView animateWithDuration:.3 animations:^{
        self.alpha = 0;
    }];
}

- (void)pulseIcon
{
    __block CGRect startFrame = startFrame = self.startFrame;
    __block CGPoint startCenter = startCenter = self.startCenter;
    __block CGFloat duration = .0667;
    
    [UIView animateWithDuration:duration animations:^{
        self.relativeIconView.frame = CGRectMake(startFrame.origin.x, startFrame.origin.x, startFrame.size.width*.7, startFrame.size.height*.7);
        self.relativeIconView.center = startCenter;
        self.relativeIconView.alpha = .75;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration animations:^{
            self.relativeIconView.frame = CGRectMake(startFrame.origin.x, startFrame.origin.x, startFrame.size.width*1.15, startFrame.size.height*1.15);
            self.relativeIconView.center = startCenter;
            self.relativeIconView.alpha = 1;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:duration animations:^{
                self.relativeIconView.frame = startFrame;
            }];
        }];
    }];}

- (void)scheduleHide
{
    //-------------------------------------------------------------------
    // Cancel the old fadeout timer and make a new one.
    //-------------------------------------------------------------------
    [self.fadeOutTimer invalidate];

    SAVWeakSelf;
    self.fadeOutTimer = [NSTimer sav_scheduledBlockWithDelay:1.5 block:^{
        [wSelf hide];
    }];
}

@end
