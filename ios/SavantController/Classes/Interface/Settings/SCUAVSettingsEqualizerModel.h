//
//  SCUAVSettingsEqualizerModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"
#import "SCUCenteredSlider.h"
#import <SavantControl/SavantControl.h>

@class SCUAVSettingsEqualizerSendToModel, SCUAVSettingsEqualizerPresetModel;

@protocol SCUAVSettingsEqualizerModelDelegate;

@interface SCUAVSettingsEqualizerModel : SCUViewModel

@property (nonatomic, weak) id<SCUAVSettingsEqualizerModelDelegate> delegate;

- (instancetype)initWithRoom:(SAVRoom *)room;

@property (nonatomic, readonly) SAVRoom *room;

@property (nonatomic, readonly) NSString *amplitude1;
@property (nonatomic, readonly) NSString *frequency1;
@property (nonatomic, readonly) NSString *amplitude2;
@property (nonatomic, readonly) NSString *frequency2;
@property (nonatomic, readonly) NSString *amplitude3;
@property (nonatomic, readonly) NSString *frequency3;
@property (nonatomic, readonly) NSString *amplitude4;
@property (nonatomic, readonly) NSString *frequency4;
@property (nonatomic, readonly) NSString *amplitude5;
@property (nonatomic, readonly) NSString *frequency5;
@property (nonatomic, readonly) NSString *amplitude6;
@property (nonatomic, readonly) NSString *frequency6;
@property (nonatomic, readonly) NSString *amplitude7;
@property (nonatomic, readonly) NSString *frequency7;
@property (nonatomic, readonly) NSString *presetName;
@property (nonatomic, readonly, getter = isResetEnabled) BOOL resetEnabled;
@property (nonatomic, readonly, getter = isAddPresetEnabled) BOOL addPresetEnabled;
@property (nonatomic, readonly) NSString *currentPresetID;

- (void)registerSlider:(SCUCenteredSlider *)slider withOrder:(NSUInteger)order;

- (void)resetCurrentPreset;

- (void)addPreset;

- (void)pickPreset;

- (void)sendTo;

- (BOOL)isCurrentPresetIDAppliedInRoom:(SAVRoom *)room;

- (NSDictionary *)currentZonesToSendForPresetID:(NSString *)presetID room:(SAVRoom *)room isAddition:(BOOL)isAddition;

@end

@protocol SCUAVSettingsEqualizerModelDelegate <NSObject>

- (void)updateCurrentPreset;

- (void)showPresetPickerWithModel:(SCUAVSettingsEqualizerPresetModel *)model;

- (void)updatePresetPickerModel:(SCUAVSettingsEqualizerPresetModel *)model;

- (void)showSendToWithModel:(SCUAVSettingsEqualizerSendToModel *)model;

- (void)updateSentToModel:(SCUAVSettingsEqualizerSendToModel *)model;

@end
