//
//  SCUAVSettingsVideoModel.h
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUServiceViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUActionSheet.h"

@class SCUAVSettingsVideoSelectModel, SCUCenteredSlider, SCUSlider, SCUButton;

typedef NS_ENUM(NSUInteger, SCUAVSettingsVideoCellType)
{
    SCUAVSettingsVideoCellTypeRightInfo,
    SCUAVSettingsVideoCellTypeMenuSelect,
    SCUAVSettingsVideoCellTypeSlider
};

@protocol SCUAVSettingsVideoModelDelegate;

extern NSString *const SCUAVSettingsModelKeyType;
extern NSString *const SCUAVSettingsVideoActionSheetArray;
extern NSString *const SCUAVSettingsVideoActionSheetCommand;
extern NSString *const SCUAVSettingsVideoActionSheetTitle;
extern NSString *const SCUAVSettingsModelState;
extern NSString *const SCUAVSettingsModelValueKey;

@interface SCUAVSettingsVideoModel : SCUServiceViewModel <SCUDataSourceModel>

@property (nonatomic, weak) id<SCUAVSettingsVideoModelDelegate> delegate;
@property (readonly, nonatomic) NSDictionary *statesToIndexPath;

- (instancetype)initWithServices:(NSArray *)services;

- (void)listenToAddButton:(SCUButton *)addButton minusButton:(SCUButton *)minusButton slider:(SCUSlider *)slider centerSlider:(SCUCenteredSlider *)centerSlider atIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathFromStateName:(NSString *)stateName;

@end

@protocol SCUAVSettingsVideoModelDelegate <NSObject>

- (void)presentActionSheetFromIndexPath:(NSIndexPath *)indexPath withTitles:(NSArray *)titles callback:(SCUActionSheetCallback)callback;
- (void)reloadIndexPath:(NSIndexPath *)indexPath;
- (void)updateSliderValueLabel:(float)value atIndexPath:(NSIndexPath *)indexPath;

@optional

- (void)currentBrightnessDidUpdateWithValue:(NSString *)value;
- (void)currentContrastDidUpdateWithValue:(NSString *)value;
- (void)currentSaturationDidUpdateWithValue:(NSString *)value;
- (void)currentHueDidUpdateWithValue:(NSString *)value;
- (void)currentDetailEnhancementDidUpdateWithValue:(NSString *)value;
- (void)currentNoiseReductionDidUpdateWithValue:(NSString *)value;
- (void)currentInputVideoFormatDidUpdateWithValue:(NSString *)value;
- (void)currentOutputVideoFormatDidUpdateWithValue:(NSString *)value;
- (void)currentAspectRatioDidUpdateWithValue:(NSString *)value;
- (void)current3dSettingsDidUpdateWithValue:(NSString *)value;

@end
