//
//  SCUDVDNowPlayingModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingModel.h"

@protocol SCUAVNowPlayingModelDelegate;

@interface SCUAVNowPlayingModel : SCUNowPlayingModel

@property (nonatomic, weak) id<SCUAVNowPlayingModelDelegate, SCUNowPlayingModelDelegate> delegate;

@end

@protocol SCUAVNowPlayingModelDelegate <SCUNowPlayingModelDelegate>

@optional

- (void)diskNumberDidUpdateWithValue:(NSString *)value;

- (void)chapterDidUpdateWithValue:(NSString *)value;

- (void)titleDidUpdateWithValue:(NSString *)value;

- (void)textDidUpdateWithValue:(NSString *)value;

- (void)currentMajorChannelDidUpdateWithValue:(NSString *)value;
- (void)currentMinorChannelDidUpdateWithValue:(NSString *)value;
- (void)currentTunerFrequencyDidUpdateWithValue:(NSString *)value;
- (void)currentStationDidUpdateWithValue:(NSString *)value;

- (void)favoritesDidUpdate:(NSArray *)favorites;

@end
