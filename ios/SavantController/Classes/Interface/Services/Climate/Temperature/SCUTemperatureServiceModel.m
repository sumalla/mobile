//
//  SCUTemperatureServiceModel.m
//  SavantController
//
//  Created by David Fairweather on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateServiceModelPrivate.h"
#import "SCUTemperatureServiceModel.h"

@interface SCUTemperatureServiceModel ()

@property (nonatomic) BOOL isHeatingStageOne;
@property (nonatomic) BOOL isHeatingStageTwo;
@property (nonatomic) BOOL isHeatingStageThree;

@property (nonatomic) BOOL isCoolingStageOne;
@property (nonatomic) BOOL isCoolingStageTwo;

@end

@implementation SCUTemperatureServiceModel
//@synthesize modesAvailableArray = _modesAvailableArray;

- (void)setupAvailableModesAndStates
{
    self.isHeatingStageOne = NO;
    self.isHeatingStageTwo = NO;
    self.isHeatingStageThree = NO;
    
    self.isCoolingStageOne = NO;
    self.isCoolingStageTwo = NO;
    
    //-------------------------------------------------------------------
    // Keep the current temperature registered for the tab bar, even when
    // the view goes off screen
    //-------------------------------------------------------------------
    if (self.entity)
    {
        [[SavantControl sharedControl] registerForStates:@[[self.entity stateFromType:SAVEntityState_CurrentTemp]] forObserver:self];
    }

    if (!self.settingsModel.modesAvailableArray)
    {
        if ([self.settingsIndexDictionary count] > 0)
        {
            [self.settingsIndexDictionary removeAllObjects];
        }
        self.settingsModel.settingsGroup = [[NSMutableArray alloc] init];
        self.settingsModel.selectedModesArray = [[NSMutableArray alloc] init];
        self.settingsModel.headerTiltesForSettingsCommandPopovers = [[NSMutableArray alloc] init];
        self.settingsModel.modesAvailableArray = [@[] mutableCopy];
        NSMutableArray *modes;
        NSInteger modeIndex = 0;
        modes = [self heatAndCoolModesAvailable];
        modeIndex = [self setupButtonForModes:modes settingsIndex:modeIndex settingsButtonTitle:@"MODE" popoverHeader:@""];

        modes = [self fanModesAvailable];
        if (modes)
        {
            modeIndex = [self setupButtonForModes:modes settingsIndex:modeIndex settingsButtonTitle:@"FAN" popoverHeader:@""] - 1;
            modes = [self fanSpeedsAvailable];
            if (modes)
            {
                modeIndex = [self setupButtonForModes:modes settingsIndex:modeIndex settingsButtonTitle:nil popoverHeader:@"FAN SPEED"] - 1;
            }
            modeIndex++;
        }
        else
        {
            [self setupButtonForModes:[self fanSpeedsAvailable] settingsIndex:modeIndex settingsButtonTitle:@"FAN SPEED" popoverHeader:@""];
        }
    }
    self.settingsModel.modesDictionary = [@{} mutableCopy];
    if ([self climateContainsCommand:@"SetHVACModeCool"] && self.entity.coolSetPoint)
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeDecrease)] = @(SAVEntityState_ModeCool);
    }
    if ([self climateContainsCommand:@"SetHVACModeHeat"] && self.entity.heatSetPoint)
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeIncrease)] = @(SAVEntityState_ModeHeat);
    }
    if ([self climateContainsCommand:@"SetHVACModeAuto"] && self.entity.autoMode)
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeAuto)] = @(SAVEntityState_ModeAuto);
    }
    if ([self climateContainsCommand:@"SetHVACModeOff"])
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeOff)] = @(SAVEntityState_ModeOff);
    }
}

- (BOOL)sliderIsTappableOnly
{
    BOOL enableSlider = (([self climateContainsCommand:@"SetTemperature"]) ||
                         ([self climateContainsCommand:@"SetHeatPointTemperature"] && self.entity.heatSetPoint) ||
                         ([self climateContainsCommand:@"SetCoolPointTemperature"] && self.entity.coolSetPoint));
    return !enableSlider;
}

- (BOOL)canShowSetPointPicker
{
    return (
            ([self sliderIsTappableOnly] && (self.entity.tempSPCount > 0))
            &&
            (
             ([self climateContainsCommand:@"IncreaseHeatPointTemperature"] &&
              [self climateContainsCommand:@"DecreaseHeatPointTemperature"] &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:NO])
             ||
             (
              (
               (
                [self climateContainsCommand:@"IncreaseTemperature"] &&
                [self climateContainsCommand:@"DecreaseTemperature"]
                )
               ||
               ([self climateContainsCommand:@"IncreaseHeatPointTemperature"] &&
                [self climateContainsCommand:@"DecreaseHeatPointTemperature"])
               )
              &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
             ||
             ([self climateContainsCommand:@"IncreaseCoolPointTemperature"] &&
              [self climateContainsCommand:@"DecreaseCoolPointTemperature"] &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:NO])
             )
            );
}

- (void)setIsCelsius:(BOOL)isCelsius
{
    [super setIsCelsius:isCelsius];
    if ([self isSetPointOutOfRange:self.minSetPoint])
    {
        [super setMinSetPoint:NSNotFound];
    }
    if ([self isSetPointOutOfRange:self.maxSetPoint])
    {
        [super setMaxSetPoint:NSNotFound];
    }
    if ([self isSetPointOutOfRange:self.desiredPoint])
    {
        [super setDesiredPoint:NSNotFound];
    }
    if ([self isSetPointOutOfRange:self.currentClimatePoint])
    {
        [super setCurrentClimatePoint:NSNotFound];
    }
    [self.delegate updateScale];
    [[SAVSettings globalSettings] setObject:@(isCelsius) forKey:self.isCelsiusUserSettingsKey];
    [[SAVSettings globalSettings] synchronize];
}

- (NSInteger)sliderMinimumValue
{
    NSInteger minPoint = self.isCelsius ? 5 : 45;
    [super setSliderMinimumValue:minPoint];
    return [super sliderMinimumValue];
}

- (NSInteger)sliderMaximumValue
{
    NSInteger maxPoint = self.isCelsius ? 35 : 95;
    [super setSliderMaximumValue:maxPoint];
    return [super sliderMaximumValue];
}

- (NSInteger)minimumDeadband
{
    [super setMinimumDeadband:(self.isCelsius ? 2 : 3)];
    return [super minimumDeadband];
}

- (void)setupSetPointAdjustmentTypes
{
    if (!self.changeSetpointCommandDictionary)
    {
        self.changeSetpointCommandDictionary = [@{
                                                  @(SCUClimateAdjustmentDecrementMinPoint) : @(SAVEntityEvent_HeatDown),
                                                  @(SCUClimateAdjustmentIncrementMinPoint) : @(SAVEntityEvent_HeatUp),
                                                  @(SCUClimateAdjustmentDecrementMaxPoint) : @(SAVEntityEvent_CoolDown),
                                                  @(SCUClimateAdjustmentIncrementMaxPoint) : @(SAVEntityEvent_CoolUp),
                                                  @(SCUClimateAdjustmentDecrementDesiredClimatePoint) : @(SAVEntityEvent_AutoDown),
                                                  @(SCUClimateAdjustmentIncrementDesiredClimatePoint) : @(SAVEntityEvent_AutoUp),
                                                  @(SCUClimateAdjustmentSetMinPoint) : @(SAVEntityEvent_HeatSet),
                                                  @(SCUClimateAdjustmentSetMaxPoint) : @(SAVEntityEvent_CoolSet),
                                                  @(SCUClimateAdjustmentSetDesiredClimatePoint) : @(SAVEntityEvent_AutoSet)
                                                  } mutableCopy];
    }
}

- (NSMutableArray *)heatAndCoolModesAvailable
{
    NSMutableArray *modesAvailable = [@[] mutableCopy];
    
    if ([self climateContainsCommand:@"SetHVACModeAuto"] && self.entity.autoMode)
    {
        [modesAvailable addObject:@(SAVEntityState_ModeAuto)];
    }
    if ([self climateContainsCommand:@"SetHVACModeHeat"] && self.entity.heatSetPoint)
    {
        [modesAvailable addObject:@(SAVEntityState_ModeHeat)];
    }
    if ([self climateContainsCommand:@"SetHVACModeCool"] && self.entity.coolSetPoint)
    {
        [modesAvailable addObject:@(SAVEntityState_ModeCool)];
    }
    if ([self climateContainsCommand:@"SetHVACModeOff"])
    {
        [modesAvailable addObject:@(SAVEntityState_ModeOff)];
    }

    return modesAvailable;
}

- (NSMutableArray *)fanModesAvailable
{
    NSMutableArray *modesAvailable = [@[] mutableCopy];
    
    if ([self climateContainsCommand:@"SetFanModeOn"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanmodeOn)];
    }
    if ([self climateContainsCommand:@"SetFanModeAuto"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanmodeAuto)];
    }
//    if ([self climateContainsCommand:@"SetFanModeOff"])
//    {
//        [modesAvailable addObject:@(SAVEntityState_FanmodeOff)];
//    }
    
    return modesAvailable;
}

- (NSMutableArray *)fanSpeedsAvailable
{
    NSMutableArray *modesAvailable = [@[] mutableCopy];
    
    if ([self climateContainsCommand:@"SetFanSpeedHigh"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanSpeedHigh)];
    }
    if ([self climateContainsCommand:@"SetFanSpeedMidHigh"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanSpeedMediumHigh)];
    }
    if ([self climateContainsCommand:@"SetFanSpeedMid"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanSpeedMedium)];
    }
    if ([self climateContainsCommand:@"SetFanSpeedMidLow"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanSpeedMediumLow)];
    }
    if ([self climateContainsCommand:@"SetFanSpeedLow"])
    {
        [modesAvailable addObject:@(SAVEntityState_FanSpeedLow)];
    }
    
    return modesAvailable;
}

- (void)unregisterForStates
{
    if (self.entity)
    {
        [[SavantControl sharedControl] unregisterForStates:@[[self.entity stateFromType:SAVEntityState_CurrentTemp]] forObserver:self];
    }
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    BOOL isOn = [stateUpdate.value boolValue];
    BOOL stageChange = NO;
    SAVEntityState state = [self.entity typeFromState:stateUpdate.stateName];

    switch (state)
    {
        case SAVEntityState_HeatPoint:
            self.minSetPoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
            {
                [self.delegate receivedClimateSetPoint:@(self.minSetPoint) setPointType:SCUClimateAdjustmentSetMinPoint];
            }
            break;
        case SAVEntityState_CoolPoint:
            self.maxSetPoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
            {
                [self.delegate receivedClimateSetPoint:@(self.maxSetPoint) setPointType:SCUClimateAdjustmentSetMaxPoint];
            }
            break;
        case SAVEntityState_CurrentTemp:
            self.currentClimatePoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedCurrentClimatePoint:)])
            {
                [self.delegate receivedCurrentClimatePoint:@(self.currentClimatePoint)];
            }
            break;
        case SAVEntityState_Mode:
            //[self.delegate didReceiveClimateSetPointModeString:(NSString *)stateUpdate.value withIndex:0];
            //make in to SAVEntityState_ModeHeat or SAVEntityState_ModeCool:
            break;
        case SAVEntityState_AutoSetPoint:
            if (1)//check if autoSetPoint is supported?
            {
                self.desiredPoint = [self valueForStateUpdateResponce:stateUpdate.value];

                if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
                {
                    [self.delegate receivedClimateSetPoint:@(self.desiredPoint) setPointType:SCUClimateAdjustmentSetDesiredClimatePoint];
                }
            }
            break;
        case SAVEntityState_Stage1Cooling:
        {
            stageChange = YES;
            self.isCoolingStageOne = [stateUpdate.value boolValue];
            break;
        }
        case SAVEntityState_Stage2Cooling:
        {
            stageChange = YES;
            self.isCoolingStageTwo = [stateUpdate.value boolValue];
            break;
        }
        case SAVEntityState_Stage1Heating:
        {
            stageChange = YES;
            self.isHeatingStageOne = [stateUpdate.value boolValue];
            break;
        }
        case SAVEntityState_Stage2Heating:
        {
            stageChange = YES;
            self.isHeatingStageTwo = [stateUpdate.value boolValue];
            break;
        }
        case SAVEntityState_Stage3Heating:
        {
            stageChange = YES;
            self.isHeatingStageThree = [stateUpdate.value boolValue];
            break;
        }
        case SAVEntityState_Fanmode:
            //state = (NSString *)stateUpdate.value parse it to one of the states below
            break;
        case SAVEntityState_ModeOff:
        case SAVEntityState_ModeHeat:
        case SAVEntityState_ModeCool:
        case SAVEntityState_ModeAuto:
            if (isOn)
            {
                if ([self.delegate respondsToSelector:@selector(didReceiveClimateSetPointMode:)])
                {
                    [self.delegate didReceiveClimateSetPointMode:state];
                }
            }
        case SAVEntityState_FanmodeAuto:
        case SAVEntityState_FanmodeOn:
        case SAVEntityState_FanmodeOff:
            if (isOn)
            {
                [self updateSettings:stateUpdate];
            }
            break;
        case SAVEntityState_FanSpeedHigh:
        case SAVEntityState_FanSpeedMediumHigh:
        case SAVEntityState_FanSpeedMedium:
        case SAVEntityState_FanSpeedMediumLow:
        case SAVEntityState_FanSpeedLow:
            [self updateSettings:stateUpdate];
            break;
        default:
            [super didReceiveStateUpdate:stateUpdate];
            break;
    }
    
    if (stageChange && [self.delegate respondsToSelector:@selector(actionToChangeCurrentClimatePoint)])
    {
        [self.delegate actionToChangeCurrentClimatePoint];
    }
}

#pragma mark - SCUStateReceiver Protocol

- (NSString *)climateValueWithAppendedSuffix:(NSString *)value
{
    return [SAVHVACEntity addDegreeSuffix:value];
}

- (SCUClimateServiceType)climateServiceType
{
    return SCUClimateServiceTypeTemperature;
}

- (BOOL)isDecreasingCurrentClimatePoint
{
    return (self.isCoolingStageOne || self.isCoolingStageTwo);
}

- (BOOL)isIncreasingCurrentClimatePoint
{
    return (self.isHeatingStageOne || self.isHeatingStageTwo || self.isHeatingStageThree);
}

@end
