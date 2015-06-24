//
//  SCUVolumeModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"
@class SAVRoom, SAVServiceGroup, SCUSlingshot;

@protocol SCUVolumeModelDelegate;

@interface SCUVolumeModel : SCUServiceViewModel

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)serviceGroup;

@property (nonatomic) SAVServiceGroup *serviceGroup;
@property (nonatomic) SAVService *service;
@property (nonatomic, getter = isGlobalVolume) BOOL globalVolume;
@property (nonatomic, readonly, getter = isDiscrete) BOOL discrete;

@property NSInteger currentVolume;

@property (weak, nonatomic) id <SCUVolumeModelDelegate> delegate;

- (void)decreaseVolume;
- (void)increaseVolume;
- (void)muteOff;
- (void)muteOn;
- (void)mute;
- (void)setVolume:(NSNumber *)volume;
- (void)sendCommandFromSlingshot:(SCUSlingshot *)slingshot withValue:(NSInteger)value;
- (void)sendReleaseCommandFromSlingshot:(SCUSlingshot *)slingshot;

@end

@protocol SCUVolumeModelDelegate <NSObject>

- (void)didUpdateVolume:(NSInteger)volume;
- (void)didUpdateMuteStatus:(BOOL)muted;
- (void)didUpdateDiscreteVolumeStatus:(BOOL)discreteVolumeAvailable;
- (BOOL)isTracking;
- (void)updateGlobalVolume;
- (BOOL)showRoomVolume;
- (void)showGlobalRoomVolume;
- (void)hideGlobalRoomVolume;

@end
