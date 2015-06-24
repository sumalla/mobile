//
//  SCURadioNavigationViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

typedef NS_ENUM(NSUInteger, SCURadioType)
{
    SCURadioTypeNone,
    SCURadioTypeAM,
    SCURadioTypeFM,
    SCURadioTypeSat
};

@protocol SCURadioModelDelegate <NSObject>

- (void)didReceiveCurrentFrequency:(CGFloat)frequency;

@end

@interface SCURadioNavigationViewModel : SCUServiceViewModel

@property (nonatomic, weak) id<SCURadioModelDelegate>delegate;

@property (nonatomic) CGFloat amSignificance;
@property (nonatomic) CGFloat fmSignificance;

@property (nonatomic) BOOL isMultiBand;

@property (nonatomic) SCURadioType currentBand;

@property (nonatomic) CGFloat CurrentTunerFrequency;

@property (nonatomic) BOOL isScanning;

- (CGFloat)maxFrequency;
- (CGFloat)minFrequency;

- (void)tuneUpFrequency;

- (void)tuneDownFrequency;

- (void)changeBandTo:(SCURadioType)radioType;

- (void)seekUp;

- (void)seekDown;

- (void)scanTP;

- (void)finishScan;

- (void)selectPreset:(NSInteger)presetNumber;

- (void)selectDirectFrequency:(CGFloat)frequency;

- (void)setFrequency:(CGFloat)frequency;

@property (nonatomic, readonly, copy) NSString *serviceId;

- (BOOL)radioContainsCommand:(NSString *)command;

@end
