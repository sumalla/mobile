//
//  SCUVolumeListener.h
//  SavantController
//
//  Created by Cameron Pulsford on 1/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;

@class SCUVolumeListener;

@protocol SCUVolumeListenerDelegate <NSObject>

- (void)volumeListenerDidIncrement:(SCUVolumeListener *)listener;

- (void)volumeListenerDidDecrement:(SCUVolumeListener *)listener;

@end

@interface SCUVolumeListener : NSObject

@property (nonatomic, weak) id<SCUVolumeListenerDelegate> delegate;

@property (nonatomic, getter = isListening) BOOL listening;

@property (nonatomic, readonly, getter = isEnabled) BOOL enabled;

@end
