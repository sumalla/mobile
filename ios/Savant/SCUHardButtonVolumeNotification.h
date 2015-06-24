//
//  SCUHardButtonVolumeNotification.h
//  SavantController
//
//  Created by Cameron Pulsford on 1/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;
@import Extensions;

typedef NS_ENUM(NSUInteger, SCUHardButtonVolumeNotificationStyle)
{
    SCUHardButtonVolumeNotificationStyleDiscrete,
    SCUHardButtonVolumeNotificationStyleRelative
};

@interface SCUHardButtonVolumeNotification : UIView

- (void)interact;

- (void)setRoomName:(NSString *)name;

- (void)setNumberOfRooms:(NSInteger)rooms;

- (void)updatePercentage:(NSInteger)percentage;

- (void)showVolumeUp;

- (void)showVolumeDown;

- (void)hide;

@property (nonatomic) SCUHardButtonVolumeNotificationStyle notificationStyle;

@end
