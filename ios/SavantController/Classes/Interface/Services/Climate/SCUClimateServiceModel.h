//
//  SCUClimateServiceModel.h
//  SavantController
//
//  Created by David Fairweather on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUSettingsConainerViewModel.h"
#import "SCUHVACPickerModel.h"

typedef NS_ENUM(NSUInteger, SCUClimateAdjustmentType)
{
    SCUClimateAdjustmentNone,
    SCUClimateAdjustmentDecrementMinPoint,
    SCUClimateAdjustmentIncrementMinPoint,
    SCUClimateAdjustmentDecrementMaxPoint,
    SCUClimateAdjustmentIncrementMaxPoint,
    SCUClimateAdjustmentIncrementDesiredClimatePoint,
    SCUClimateAdjustmentDecrementDesiredClimatePoint,
    SCUClimateAdjustmentSetMinPoint,
    SCUClimateAdjustmentSetMaxPoint,
    SCUClimateAdjustmentSetDesiredClimatePoint
};

typedef NS_ENUM(NSUInteger, SCUClimateModeType)
{
    SCUClimateModeIncrease,
    SCUClimateModeDecrease,
    SCUClimateModeAuto,
    SCUClimateModeAutoSingleSetPoint,
    SCUClimateModeOff,
    SCUClimateModeNone
};

@protocol SCUClimateServiceModelDelegate <NSObject>

- (void)changeService;

@optional

- (void)updateScale;

- (void)receivedCurrentClimatePoint:(NSNumber *)value;
- (void)receivedClimateSetPoint:(NSNumber *)value setPointType:(SCUClimateAdjustmentType)setPointType;

- (void)actionToChangeCurrentClimatePoint;
- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode;

- (void)setDesiredSetPointValue:(NSInteger)value;

@end

@interface SCUClimateServiceModel : SCUServiceViewModel  <SCUHVACPickerModelDelegate>

@property (nonatomic, strong) NSString *isCelsiusUserSettingsKey;

@property (nonatomic) BOOL isCelsius;

@property (nonatomic, weak) id<SCUClimateServiceModelDelegate>delegate;
@property (nonatomic, readonly) NSArray *statesUpdates;

@property (nonatomic, strong) NSMutableDictionary *changeSetpointCommandDictionary;
@property (nonatomic, strong) NSMutableDictionary *settingsIndexDictionary;

@property (nonatomic) BOOL isDecreasingCurrentClimatePoint;
@property (nonatomic) BOOL isIncreasingCurrentClimatePoint;

@property (nonatomic) SAVEntityState selectedPrimaryMode;
@property (nonatomic) SAVEntityState selectedSecondaryMode;
@property (nonatomic) SAVEntityState selectedTertiaryMode;

@property (nonatomic) NSInteger higherValueSetUnitstoFahrenheit;
@property (nonatomic) NSInteger lowerValueSetUnitstoFahrenheit;
@property (nonatomic) NSInteger higherValueSetUnitstoCelsius;
@property (nonatomic) NSInteger lowerValueSetUnitstoCelsius;

@property (nonatomic) NSInteger minSetPoint;
@property (nonatomic) NSInteger maxSetPoint;
@property (nonatomic) NSInteger desiredPoint;
@property (nonatomic) NSInteger currentClimatePoint;

@property (nonatomic) NSInteger minimumDeadband;
@property (nonatomic) NSInteger sliderMaximumValue;
@property (nonatomic) NSInteger sliderMinimumValue;

@property (nonatomic, readonly) BOOL sliderIsTappableOnly;
@property (nonatomic, readonly) BOOL sliderHasMultipleSetPoints;
@property (nonatomic, readonly, strong) SCUSettingsConainerViewModel *settingsModel;
@property (nonatomic, strong) SCUHVACPickerModel *hvacPickerModel;

@property (nonatomic) SAVHVACEntity *entity;

- (SAVEntityState)savEntityStateForSCUClimateModeType:(SCUClimateModeType)climateModeType allowSubstitute:(BOOL)allowSub;

//- (NSArray *)HVACEntitiesForRoomID:(NSString *)roomID andService:(SAVService *)service;

- (void)setupAvailableModesAndStates;

- (void)setupSetPointAdjustmentTypes;

- (void)sendServiceRequestForSAVEntityState:(SAVEntityState)entityModeType;

- (void)climatePointAdjustmentType:(SCUClimateAdjustmentType)adjustmentType setValue:(NSNumber *)value;

- (BOOL)climateContainsCommand:(NSString *)command;

- (NSString *)climateValueWithAppendedSuffix:(NSString *)value;

- (BOOL)isSingleSetPoint;

//- (NSArray *)HVACEntitiesZoneNames;

//- (NSString *)zoneNameForEntity:(SAVHVACEntity *)entity;

- (void)unregisterForStates;

- (NSInteger)setupButtonForModes:(NSArray *)modes settingsIndex:(NSInteger)settingsIndex settingsButtonTitle:(NSString *)buttonTitle popoverHeader:(NSString *)popHeader;

- (void)updateSettings:(SAVStateUpdate *)stateUpdate;

- (NSInteger)valueForStateUpdateResponce:(NSString *)updateValueString;

- (BOOL)isSetPointOutOfRange:(NSInteger)value;

- (BOOL)canShowSetPointPicker;

- (SAVEntityState)selectedPrimaryMode;

- (SCUClimateServiceType)climateServiceType;

@end