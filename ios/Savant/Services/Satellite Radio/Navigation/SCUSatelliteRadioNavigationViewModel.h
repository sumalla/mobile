//
//  SCUSatelliteRadioNavigationViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

@protocol SCUSatelliteRadioNavigationViewModelDelegate;
@class SCUButton;

@interface SCUSatelliteRadioNavigationViewModel : SCUServiceViewModel

@property (nonatomic, weak) id <SCUSatelliteRadioNavigationViewModelDelegate> delegate;

- (void)toggleScan:(SCUButton *)sender;

@end

@protocol SCUSatelliteRadioNavigationViewModelDelegate <NSObject>

- (void)categoryChanged:(NSString *)category;
- (void)channelChanged:(NSString *)channel;
- (void)albumChanged:(NSString *)album;
- (void)artistChanged:(NSString *)artist;
- (void)songChanged:(NSString *)song;

@end
