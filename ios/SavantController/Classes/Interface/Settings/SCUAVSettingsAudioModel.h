//
//  SCUAVAudioSettingsModel.h
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUServiceViewModel.h"
#import "SCUActionSheet.h"
#import <SavantControl/SavantControl.h>

@class SCUCenteredSlider, SCUStepper, SCUSlider, SCUButton;

typedef NS_ENUM(NSUInteger, SCUAVSettingsAudioCellType)
{
    SCUAVSettingsAudioCellTypeSlider,
    SCUAVSettingsAudioCellTypeButtonSelect,
    SCUAVSettingsAudioCellTypeStepper,
    SCUAVSettingsAudioCellTypeBalance
};

@protocol SCUAVSettingsAudioModelDelegate;

@interface SCUAVSettingsAudioModel : SCUServiceViewModel <SCUDataSourceModel>

@property (nonatomic, weak) id<SCUAVSettingsAudioModelDelegate> delegate;
@property (readonly, nonatomic) NSDictionary *statesToIndexPath;

- (instancetype)initWithStereoServices:(NSArray *)stereoServices surroundServices:(NSArray *)surroundServices;

- (void)listenToStepper:(SCUStepper *)stepper atIndexPath:(NSIndexPath *)indexPath;

- (void)listenToAddButton:(SCUButton *)addButton minusButton:(SCUButton *)minusButton slider:(SCUSlider *)slider centerSlider:(SCUCenteredSlider *)centerSlider atIndexPath:(NSIndexPath *)indexPath;

- (void)listenToDefaultButton:(SCUButton *)defaultButton atIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathFromStateName:(NSString *)stateName;

@property (nonatomic, readonly) SAVRoom *room;
@property (nonatomic, readonly) NSMutableDictionary *currentStates;

@end

@protocol SCUAVSettingsAudioModelDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;
- (void)updateSliderValueLabel:(float)value atIndexPath:(NSIndexPath *)indexPath;
- (void)presentActionSheetFromIndexPath:(NSIndexPath *)indexPath withTitles:(NSArray *)titles callback:(SCUActionSheetCallback)callback;

@optional

- (void)currentVolumeDidUpdateWithValue:(NSString *)value;
- (void)currentBassDidUpdateWithValue:(NSString *)value;
- (void)currentTrebleDidUpdateWithValue:(NSString *)value;
- (void)currentBalanceDidUpdateWithValue:(NSString *)value;
- (void)currentAudioEffectsLevelDidUpdateWithValue:(NSString *)value;
- (void)isMutedDidUpdateWithValue:(NSString *)value;

@end
