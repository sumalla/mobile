//
//  SAVNowPlayingManager.h
//  Savant
//
//  Created by Cameron Pulsford on 5/19/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVStateManager.h"
#import "SAVNowPlayingStatus.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SAVNowPlayingManagerDelegate;

@interface SAVNowPlayingManager : NSObject

- (void)addNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer forRoom:(NSString *)room;

- (void)removeNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer forRoom:(NSString *)room;

//- (void)addGlobalNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer;
//
//- (void)removeNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer;

- (nullable SAVNowPlayingStatus *)nowPlayingStatusForRoom:(NSString *)room;

- (NSDictionary *)globalNowPlayingStatus;

@end

@protocol SAVNowPlayingManagerDelegate <NSObject>

- (void)artistDidUpdate:(NSString *)artist inRoom:(NSString *)room;

- (void)albumDidUpdate:(NSString *)album inRoom:(NSString *)room;

- (void)songDidUpdate:(NSString *)song inRoom:(NSString *)room;

//- (void)nowPlayingDidUpdateStatus:(NSArray *)status;

@end

NS_ASSUME_NONNULL_END
