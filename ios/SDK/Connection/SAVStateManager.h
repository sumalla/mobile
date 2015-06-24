//
//  SAVStateManager.h
//  SavantControl
//
//  Created by Art Jacobson on 2/6/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
#import "SavantProtocols.h"

@class
SAVService,
SAVNowPlayingManager;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kSAVActiveServiceState;
extern NSString *const kSAVActiveServicesState;
extern NSString *const kSAVLastActiveServiceState;
extern NSString *const kSAVLightsAreOnState;
extern NSString *const kSAVCurrentTemperatureState;
extern NSString *const kSAVSecurityStatusState;
extern NSString *const kSAVCurrentVolumeState;
extern NSString *const kSAVIsMutedState;
extern NSString *const kSAVRelativeVolumeOnlyState;
extern NSString *const kSAVRoomLightsAreOn;
extern NSString *const kSAVRoomFansAreOn;
extern NSString *const kSAVRoomCurrentTemperature;

@protocol ActiveServiceObserver <NSObject>

@optional
- (void)room:(NSString *)roomId didUpdateActiveService:(nullable SAVService *)service;
- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services;

@end

@protocol EnvironmentalObserver <NSObject>

@optional
- (void)room:(NSString *)roomId didUpdateLighting:(BOOL)lightsAreOn;
- (void)room:(NSString *)roomId didUpdateTemperature:(NSNumber *)temperature;
- (void)room:(NSString *)roomId didUpdateSecurityStatus:(NSNumber *)status;

@end

@protocol VolumeObserver <NSObject>

@optional
- (void)room:(NSString *)roomId didUpdateVolume:(NSNumber *)volume;
- (void)room:(NSString *)roomId didUpdateMuteStatus:(BOOL)muted;
- (void)room:(NSString *)roomId didUpdateDiscreteVolumeStatus:(BOOL)discreteVolumeAvailable;

@end

@interface SAVStateManager : NSObject <StateDelegate>

@property (nonatomic, nonnull) SAVNowPlayingManager *nowPlaying;

#pragma mark - State registration

/**
 *  Register an observer for states.
 *
 *  @param states   The states.
 *  @param observer The observer.
 */
- (void)registerForStates:(NSArray *)states forObserver:(id<StateDelegate>)observer;

/**
 *  Unregister an observer for states.
 *
 *  @param states   The states.
 *  @param observer The observer.
 */
- (void)unregisterForStates:(NSArray *)states forObserver:(id<StateDelegate>)observer;

/**
 *  Register an observer for active service updates.
 *
 *  @param observer The observer.
 */
- (void)addActiveServiceObserver:(id<ActiveServiceObserver>)observer;

/**
 *  Unregister an observer for active service updates.
 *
 *  @param observer The observer.
 */
- (void)removeActiveServiceObserver:(id<ActiveServiceObserver>)observer;

/**
 *  Register an observer for volume updates.
 *
 *  @param observer The observer.
 */
- (void)addVolumeObserver:(id<VolumeObserver>)observer;

/**
 *  Unregister an observer for volume updates.
 *
 *  @param observer The observer.
 */
- (void)removeVolumeObserver:(id<VolumeObserver>)observer;

#pragma mark - Service accessors

/**
 *  Returns the current active service for the given room.
 *
 *  @param roomId The room.
 *
 *  @return The current active service for the given room.
 */
- (SAVService * __nullable)activeServiceForRoom:(NSString *)roomId;

/**
 *  Returns an array of the current active services for the given room.
 *
 *  @param roomId The room.
 *
 *  @return An array of the current active services for the given room.
 */
- (NSArray *)activeServiceListForRoom:(NSString *)roomId;

/**
 *  Returns the last active service for the given room.
 *
 *  @param roomId The room.
 *
 *  @return The last active service for the given room.
 */
- (SAVService * __nullable)lastActiveServiceForRoom:(NSString *)roomId;

/**
 *  Returns an array of all currently active services in all rooms.
 *
 *  @return An array of all currently active services in all rooms.
 */
- (NSArray * __nullable)activeServices;

#pragma mark - Volume accessors

/**
 *  Returns the current volume for the given room, or nil.
 *
 *  @param roomId The room.
 *
 *  @return The current volume for the given room, or nil.
 */
- (NSNumber *)volumeForRoom:(NSString *)roomId;

/**
 *  Returns the current mute status for the given room, or nil.
 *
 *  @param roomId The room.
 *
 *  @return The current mute status for the given room, or nil.
 */
- (BOOL)muteStatusForRoom:(NSString *)roomId;

/**
 *  Returns the current discrete vole status for the given room, or nil.
 *
 *  @param roomId The room.
 *
 *  @return The current discrete vole status for the given room, or nil.
 */
- (BOOL)discreteVolumeStatusForRoom:(NSString *)roomId;

@end

NS_ASSUME_NONNULL_END
