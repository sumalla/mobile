//
//  SCUHumidityServiceModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateServiceModelPrivate.h"
#import "SCUHumidityServiceModel.h"

@interface SCUHumidityServiceModel ()

@property (nonatomic) NSMutableDictionary *hummityModesOn;

@end

@implementation SCUHumidityServiceModel

- (void)setupAvailableModesAndStates
{
    //-------------------------------------------------------------------
    // Keep the current temperature registered for the tab bar, even when
    // the view goes off screen
    //-------------------------------------------------------------------
    self.hummityModesOn = [[NSMutableDictionary alloc] init];
    self.isAlwayOn = NO;
    
    if (self.entity)
    {
        [[SavantControl sharedControl] registerForStates:@[[self.entity stateFromType:SAVEntityState_CurrentHumidity]] forObserver:self];
    }

    if (!self.settingsModel.modesAvailableArray)
    {
        if ([self.settingsIndexDictionary count] > 0)
        {
            [self.settingsIndexDictionary removeAllObjects];
        }
        self.settingsModel.settingsGroup = [NSMutableArray array];
        self.settingsModel.selectedModesArray = [NSMutableArray array];
        self.settingsModel.modesAvailableArray = [NSMutableArray array];
        [self setupButtonForModes:[self humidityModesAvailable] settingsIndex:0 settingsButtonTitle:@"MODE" popoverHeader:@""];
    }
    
    self.settingsModel.modesDictionary = [NSMutableDictionary dictionary];
    
    if ([self climateContainsCommand:@"SetHVACModeDehumidify"] && self.entity.dehumidifySetPoint)
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeDecrease)] = @(SAVEntityState_ModeDehumidify);
    }
    if ([self climateContainsCommand:@"SetACDehumidifyPoint"])
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeDecrease)] = @(SAVEntityState_ModeACDehumidify);
    }
    if ([self climateContainsCommand:@"SetHVACModeHumidify"] && self.entity.humidifySetPoint)
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeIncrease)] = @(SAVEntityState_ModeHumidify);
    }
    if ([self climateContainsCommand:@"SetHumiditySetPoint"])
    {
        if ([self.settingsModel.modesDictionary count] < 1 && [self climateContainsCommand:@"SetHumidityModeOn"])
        {
            (self.settingsModel.modesDictionary)[@(SCUClimateModeAutoSingleSetPoint)] = @(SAVEntityState_ModeHumidity);//SAVEntityState_HumidityModeOn
        }
        else if (self.entity.humidifySetPoint)
        {
            (self.settingsModel.modesDictionary)[@(SCUClimateModeAuto)] = @(SAVEntityState_ModeHumidity);
        }
    }
    if ([self climateContainsCommand:@"SetHumidityModeOff"])
    {
        (self.settingsModel.modesDictionary)[@(SCUClimateModeOff)] = @(SAVEntityState_HumidityModeOff);
    }
    
    if ([[self humidityModesAvailable] count] < 1 && self.entity.humiditySPCount > 0)
    {
        SAVEntityState pseudoState = SAVEntityState_ModeHumidify;
        if ([self climateContainsCommand:@"SetHumidifyPoint"] && self.entity.humidifySetPoint)
        {
            pseudoState = SAVEntityState_ModeHumidify;
            (self.settingsModel.modesDictionary)[@(SCUClimateModeIncrease)] = @(pseudoState);
        }
        else if ([self climateContainsCommand:@"SetDehumidifyPoint"] && self.entity.dehumidifySetPoint)
        {
            pseudoState = SAVEntityState_ModeDehumidify;
            (self.settingsModel.modesDictionary)[@(SCUClimateModeDecrease)] = @(pseudoState);
        }
        
        self.hummityModesOn[@(pseudoState)] = @(YES);
        self.isAlwayOn = YES;
    }
}

- (BOOL)sliderIsTappableOnly
{
    BOOL enableSlider = (([self climateContainsCommand:@"SetHumiditySetPoint"]) ||
                        ([self climateContainsCommand:@"SetDehumidifyPoint"] && self.entity.dehumidifySetPoint) ||
                        ([self climateContainsCommand:@"SetHumidifyPoint"] && self.entity.humidifySetPoint));
    return !enableSlider;
}

- (BOOL)canShowSetPointPicker
{
    return (
            ([self sliderIsTappableOnly] && (self.entity.humiditySPCount > 0))
            &&
            (
             ([self climateContainsCommand:@"IncreaseHumidifyPoint"] &&
              [self climateContainsCommand:@"DecreaseHumidifyPoint"] &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:NO])
             ||
             ([self climateContainsCommand:@"IncreaseHumiditySetPoint"] &&
              [self climateContainsCommand:@"DecreaseHumiditySetPoint"] &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
             ||
             ([self climateContainsCommand:@"IncreaseDehumidifyPoint"] &&
              [self climateContainsCommand:@"DecreaseDehumidifyPoint"] &&
              self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:NO])
             )
            );
}

- (NSInteger)sliderMinimumValue
{
    [super setSliderMinimumValue:20];
    return [super sliderMinimumValue];
}

- (NSInteger)sliderMaximumValue
{
    [super setSliderMaximumValue:80];
    return [super sliderMaximumValue];
}

- (NSMutableArray *)humidityModesAvailable
{
    NSMutableArray *modesAvailable = [@[
              ] mutableCopy];
    
    if ([self climateContainsCommand:@"SetHVACModeDehumidify"] && self.entity.dehumidifySetPoint)
    {
        [modesAvailable addObject:@(SAVEntityState_ModeDehumidify)];
    }
    if ([self climateContainsCommand:@"SetACDehumidifyPoint"])
    {
        [modesAvailable addObject:@(SAVEntityState_ModeACDehumidify)];
    }
    if ([self climateContainsCommand:@"SetHVACModeHumidify"] && self.entity.humidifySetPoint)
    {
        [modesAvailable addObject:@(SAVEntityState_ModeHumidify)];
    }
    if ([self climateContainsCommand:@"SetHumiditySetPoint"])
    {
        //if ([modesAvailable count] < 1 && [self climateContainsCommand:@"SetHumidityModeOn"])
        {
        //    [modesAvailable addObject:@(SAVEntityState_HumidityModeOn)];
        }
       // else
        {
            [modesAvailable addObject:@(SAVEntityState_ModeHumidity)];
        }
    }
    if ([self climateContainsCommand:@"SetHumidityModeOff"])
    {
        [modesAvailable addObject:@(SAVEntityState_HumidityModeOff)];
    }
    //if ([self climateContainsCommand:@""])
    {
       // [modesAvailable addObject:@(SAVEntityState_ModeOff)];
    }
    return modesAvailable;
}

- (void)unregisterForStates
{
    if (self.entity)
    {
        [[SavantControl sharedControl] unregisterForStates:@[[self.entity stateFromType:SAVEntityState_CurrentHumidity]] forObserver:self];
    }
}

- (void)setupSetPointAdjustmentTypes
{
    if (!self.changeSetpointCommandDictionary)
    {
        self.changeSetpointCommandDictionary = [@{} mutableCopy];
        
        if ([self climateContainsCommand:@"DecreaseDehumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentDecrementMaxPoint)] = @(SAVEntityEvent_DehumidfyDown);
        }
        if ([self climateContainsCommand:@"IncreaseDehumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentIncrementMaxPoint)] = @(SAVEntityEvent_DehumidfyUp);
        }
        if ([self climateContainsCommand:@"DecreaseHumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentDecrementMinPoint)] = @(SAVEntityEvent_HumidfyDown);
        }
        if ([self climateContainsCommand:@"IncreaseHumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentIncrementMinPoint)] = @(SAVEntityEvent_HumidfyUp);
        }
        if ([self climateContainsCommand:@"DecreaseHumiditySetPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentDecrementDesiredClimatePoint)] = @(SAVEntityEvent_SingleHumidityDown);
        }
        if ([self climateContainsCommand:@"IncreaseHumiditySetPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentIncrementDesiredClimatePoint)] = @(SAVEntityEvent_SingleHumidityUp);
        }
        if ([self climateContainsCommand:@"SetDehumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentSetMaxPoint)] = @(SAVEntityEvent_DehumidfySet);
        }
        if ([self climateContainsCommand:@"SetHumidifyPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentSetMinPoint)] = @(SAVEntityEvent_HumidfySet);
        }
        if ([self climateContainsCommand:@"SetHumiditySetPoint"])
        {
            (self.changeSetpointCommandDictionary)[@(SCUClimateAdjustmentSetDesiredClimatePoint)] = @(SAVEntityEvent_SingleHumiditySet);
        }
    }
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    SAVEntityState state = [self.entity typeFromState:stateUpdate.stateName];
    
    BOOL isOff = NO;

    switch (state)
    {
        case SAVEntityState_CurrentHumidity: //current set point
            self.currentClimatePoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedCurrentClimatePoint:)])
            {
                [self.delegate receivedCurrentClimatePoint:@(self.currentClimatePoint)];
            }
            break;
        case SAVEntityState_HumidifyPoint:
            self.minSetPoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
            {
                [self.delegate receivedClimateSetPoint:@(self.minSetPoint) setPointType:SCUClimateAdjustmentSetMinPoint];
            }
            break;
        case SAVEntityState_DehumidifyPoint:
            self.maxSetPoint = [self valueForStateUpdateResponce:stateUpdate.value];
            if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
            {
                [self.delegate receivedClimateSetPoint:@(self.maxSetPoint) setPointType:SCUClimateAdjustmentSetMaxPoint];
            }
            break;
        case SAVEntityState_HumidityPoint: //desired set point
            self.desiredPoint = [self valueForStateUpdateResponce:stateUpdate.value];;
            if ([self.delegate respondsToSelector:@selector(receivedClimateSetPoint:setPointType:)])
            {
                [self.delegate receivedClimateSetPoint:@(self.desiredPoint) setPointType:SCUClimateAdjustmentSetDesiredClimatePoint];
            }
            break;
        case SAVEntityState_Mode:
            //if ([self.delegate respondsToSelector:@selector(didReceiveClimateSetPointModeString:withIndex:)])
            {
                //[self.delegate didReceiveClimateSetPointModeString:(NSString *)stateUpdate.value withIndex:0];
            }
            break;
        case SAVEntityState_ModeHumidity:
        case SAVEntityState_ModeHumidify:
        case SAVEntityState_ModeACDehumidify:
        case SAVEntityState_ModeDehumidify:
        {
            isOff = ![stateUpdate.value boolValue];

            self.hummityModesOn[@(state)] = @(isOff);
            if ([self.delegate respondsToSelector:@selector(didReceiveClimateSetPointMode:)])
            {
                BOOL allOff = YES;
                for (NSNumber *modeOn in [self.hummityModesOn allKeys])
                {
                    if (![self.hummityModesOn[modeOn] boolValue])
                    {
                        allOff = NO;
                        break;
                    }
                }
                SAVEntityState realState = state;
                if (allOff)
                {
                    realState = SAVEntityState_HumidityModeOff;
                }
                if (allOff || !isOff || (state == SAVEntityState_ModeHumidity))
                {
                    [self.delegate didReceiveClimateSetPointMode:realState];
                    [self setSelectedMode:realState forSettingsIndex:0];
                }
            }
            break;
        }
        case SAVEntityState_CurrentSchedule:
            break;
        default:
            break;
    }
}

- (NSString *)climateValueWithAppendedSuffix:(NSString *)value
{
    return [SAVHVACEntity addPercentSuffix:value];
}

- (SCUClimateServiceType)climateServiceType
{
    return SCUClimateServiceTypeHumidity;
}

- (SAVEntityState)selectedPrimaryMode
{
    SAVEntityState state = SAVEntityState_Unknown;
    NSString *key = nil;
    
    switch ([self.settingsModel.modesDictionary count])
    {
        case 1:
        {
            key = [[self.settingsModel.modesDictionary allKeys] firstObject];
            state = [[self.settingsModel.modesDictionary objectForKey:key] integerValue];
            break;
        }
        case 0:
        {
            state = SAVEntityState_ModeHumidify;
            break;
        }
        default:
        {
            state = [super selectedPrimaryMode];
            break;
        }
    }
    return state;
}

@end
