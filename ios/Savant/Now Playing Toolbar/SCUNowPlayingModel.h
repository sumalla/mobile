//
//  SCUNowPlayingModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

typedef NS_ENUM(NSInteger, SCUNowPlayingModelTransportButtonType)
{
    SCUNowPlayingModelTransportButtonTypePrevious,
    SCUNowPlayingModelTransportButtonTypeNext,
    SCUNowPlayingModelTransportButtonTypePlay,
    SCUNowPlayingModelTransportButtonTypePlayStatic,
    SCUNowPlayingModelTransportButtonTypePause,
    SCUNowPlayingModelTransportButtonTypePlayPause,
    SCUNowPlayingModelTransportButtonTypeShuffle,
    SCUNowPlayingModelTransportButtonTypeRepeat,
    SCUNowPlayingModelTransportButtonTypeFastForward,
    SCUNowPlayingModelTransportButtonTypeRewind,
    SCUNowPlayingModelTransportButtonTypeThumbsUp,
    SCUNowPlayingModelTransportButtonTypeThumbsDown
};

@protocol SCUNowPlayingModelDelegate;

@interface SCUNowPlayingModel : SCUServiceViewModel

@property (nonatomic, weak) id<SCUNowPlayingModelDelegate> delegate;

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup delegate:(id<SCUNowPlayingModelDelegate>)delegate;

- (void)sendCommandWithTransportButtonType:(SCUNowPlayingModelTransportButtonType)buttonType forState:(NSInteger)state;

@end

@protocol SCUNowPlayingModelDelegate <NSObject>

@optional

- (void)toolbarShouldHide;

- (void)toolbarShouldShow;

- (void)pauseStatusDidUpdateWithValue:(NSNumber *)value;

- (void)artistDidUpdateWithValue:(NSString *)value;

- (void)songDidUpdateWithValue:(NSString *)value;

- (void)albumDidUpdateWithValue:(NSString *)value;

- (void)repeatDidUpdateWithValue:(NSNumber *)value;

- (void)shuffleDidUpdateWithValue:(NSNumber *)value;

- (void)elapsedTimeDidUpdateWithValue:(NSString *)value;

- (void)progressTimeDidUpdateWithValue:(NSString *)value;

- (void)remainingTimeDidUpdateWithValue:(NSString *)value;

- (void)artworkURLDidUpdate:(NSString *)value;

- (void)playTypeDidUpdateWithValue:(NSNumber *)value;

- (NSArray *)stateNamesEffectingVisibility;

- (NSArray *)states;

@end
