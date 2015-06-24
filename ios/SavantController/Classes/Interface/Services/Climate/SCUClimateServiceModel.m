//
//  SCUClimateServiceModel.m
//  SavantController
//
//  Created by David Fairweather on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateServiceModelPrivate.h"

@implementation SCUClimateServiceModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.isCelsiusUserSettingsKey = [NSString stringWithFormat:@"%@.%@.isCelsius", service.component, service.logicalComponent];

        _isCelsius = [[[SAVSettings globalSettings] objectForKey:self.isCelsiusUserSettingsKey] boolValue];

        self.settingsModel = [[SCUSettingsConainerViewModel alloc] init];
        self.settingsModel.commandDelegate = self;
        self.settingsIndexDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        self.lowerValueSetUnitstoFahrenheit = 40;
        self.higherValueSetUnitstoFahrenheit = 180;
        
        self.lowerValueSetUnitstoCelsius = 2;
        self.higherValueSetUnitstoCelsius = 32;
        
        NSString *roomId = [SCUInterface sharedInstance].currentRoom.roomId;

        self.hvacPickerModel = [[SCUHVACPickerModel alloc] initWithHVACArray:[self HVACEntitiesForRoomID:roomId andService:service] serviceType:[self climateServiceType]];
        self.hvacPickerModel.delegate = self;
        
        NSObject *newEntity = [self.hvacPickerModel currentHVACEntity];
        
        if (!newEntity)
        {
            NSMutableArray *otherKeys = [[NSMutableArray alloc] initWithCapacity:2];
            if (service.zoneName)
            {
                [otherKeys addObject:service.zoneName];
            }
            if (service.component)
            {
                [otherKeys addObject:service.component];
            }
    
            newEntity = [self.hvacPickerModel findFirstHVACEntityWithPosibleZoneNames:otherKeys];
        }
        if ([newEntity isKindOfClass:[SAVHVACEntity class]])
        {
            _entity = (SAVHVACEntity *)newEntity;
        }
        _valueInterval = 1;
        self.minimumDeadband = 4;
        
        self.minSetPoint = NSNotFound;
        self.maxSetPoint = NSNotFound;
        self.desiredPoint = NSNotFound;
        self.currentClimatePoint = NSNotFound;
        
        [self setupAvailableModesAndStates];
        [self setupSetPointAdjustmentTypes];
    }
    return self;
}

- (NSArray *)HVACEntitiesForRoomID:(NSString *)roomID andService:(SAVService *)service
{
    NSArray *entities = nil;

    SAVMutableService *dummyService = [[SAVMutableService alloc] init]; // redmine Bug #7984 Lighting controller used as HVAC controller showing up twice
    dummyService.zoneName = roomID;
    dummyService.serviceId = @"SVC_ENV_HVAC";

    if (roomID)
    {
        entities = [[[SavantControl sharedControl] data] HVACEntities:roomID
                                                                 zone:nil
                                                              service:dummyService];
    }
    else if (service.zoneName)
    {
        entities = [[[SavantControl sharedControl] data] HVACEntities:nil
                                                                 zone:service.zoneName
                                                              service:dummyService];
    }

    return entities;
}

- (void)internalSetNewCurrentEntity:(NSObject *)hvacEntity
{
    if (hvacEntity != self.entity && ([hvacEntity isKindOfClass:[SAVHVACEntity class]]))
    {
        [self unregisterStates];
        if (self.settingsModel)
        {
            self.settingsModel.commandDelegate = nil;
            self.settingsModel = nil;
        }
        self.settingsModel = [[SCUSettingsConainerViewModel alloc] init];
        self.settingsModel.commandDelegate = self;

        self.minSetPoint = NSNotFound;
        self.maxSetPoint = NSNotFound;
        self.desiredPoint = NSNotFound;
        self.currentClimatePoint = NSNotFound;

        self.entity = (SAVHVACEntity *)hvacEntity;
        
        self.isCelsiusUserSettingsKey = [NSString stringWithFormat:@"%@.%@.isCelsius", self.entity.service.component, self.entity.service.logicalComponent];
        
        BOOL isCurrentlyInC = self.isCelsius;
        BOOL isCelsius = [[[SAVSettings globalSettings] objectForKey:self.isCelsiusUserSettingsKey] boolValue];
        if (isCurrentlyInC != isCelsius)
        {
            [self setIsCelsius:isCelsius];
        }
        
        [self setupAvailableModesAndStates];
        [self setupSetPointAdjustmentTypes];
        
        [self.delegate changeService];

        [self registerStates];
    }
}

- (NSString *)zoneNameForEntity:(SAVHVACEntity *)entity
{
    return [self.hvacPickerModel zoneNameForEntity:entity];
}

- (SAVService *)service
{
    return self.entity.service;
}

- (NSInteger)setupButtonForModes:(NSArray *)modes settingsIndex:(NSInteger)settingsIndex settingsButtonTitle:(NSString *)buttonTitle popoverHeader:(NSString *)popHeader
{
    if (modes && [modes count] > 0)
    {
        if (buttonTitle)
        {
            [self.settingsModel.titlesForSettingButtons addObject:buttonTitle];
        }
        if (popHeader)
        {
            [self.settingsModel.headerTiltesForSettingsCommandPopovers addObject:popHeader];
        }
        else
        {
            [self.settingsModel.headerTiltesForSettingsCommandPopovers addObject:@""];
        }
        
        [self.settingsModel.modesAvailableArray addObject:modes];
        [self.settingsModel.selectedModesArray addObject:@(SAVEntityState_Unknown)];
        [self.settingsModel.settingsGroup addObject:@(settingsIndex)];
        
        for (NSNumber *entityState in modes)
        {
            [self.settingsIndexDictionary setObject:@(settingsIndex) forKey:[entityState stringValue]];
        }
        modes = nil;
        settingsIndex++;
    }
    return settingsIndex;
}

- (BOOL)sliderIsTappableOnly
{
    return YES; //every is only tappable unless implemented in a subclass
    //    ![self.model climateContainsCommand:@"SetTemperature"] ||
    //    ![self.model climateContainsCommand:@"SetHumiditySetPoint"]
}

- (SCUClimateServiceType)climateServiceType
{
    return SCUClimateServiceTypeNone;
}

- (BOOL)canShowSetPointPicker
{
    return NO;
}

- (BOOL)sliderHasMultipleSetPoints
{
    return YES;
}

- (void)setupSetPointAdjustmentTypes
{
    //implement in subclass
    //example
    /*
    self.changeSetpointCommandDictionary = [@{
                                              @(SCUClimateAdjustmentDecrementMinPoint) : @(SAVEntityEvent_HeatDown),
                                              @(SCUClimateAdjustmentIncrementMinPoint) : @(SAVEntityEvent_HeatUp),
                                              @(SCUClimateAdjustmentDecrementMaxPoint) : @(SAVEntityEvent_CoolDown),
                                              @(SCUClimateAdjustmentIncrementMaxPoint) : @(SAVEntityEvent_CoolUp),
                                              @(SCUClimateAdjustmentIncrementDesiredClimatePoint) : @(SAVEntityEvent_AutoUp),
                                              @(SCUClimateAdjustmentDecrementDesiredClimatePoint) : @(SAVEntityEvent_AutoDown),
                                              @(SCUClimateAdjustmentSetMinPoint) : @(SAVEntityEvent_HeatSet),
                                              @(SCUClimateAdjustmentSetMaxPoint) : @(SAVEntityEvent_CoolSet),
                                              @(SCUClimateAdjustmentSetDesiredClimatePoint) : @(SAVEntityEvent_AutoSet)
                                              } mutableCopy];
     */
    
    //self.changeSetpointCommandDictionary = [@{} mutableCopy]; is in init settings model now, still need to set in subclass
}

- (void)setupAvailableModesAndStates
{
    //implement in subclass
    //    self.modesDictionary = [@{} mutableCopy]; is in init settings model now, still need to set in subclass

}

- (void)sendServiceRequestForSAVEntityState:(SAVEntityState)entityModeType
{
    SAVEntityEvent eventRequest = SAVEntityEvent_Unknown;
    switch (entityModeType)
    {
        case SAVEntityState_Unknown:
            return;
        case SAVEntityState_FanmodeAuto:
        {
            eventRequest = SAVEntityEvent_FanAuto;
        }
            break;
        case SAVEntityState_FanmodeOn:
        {
            eventRequest = SAVEntityEvent_FanOn;
        }
            break;
        case SAVEntityState_FanmodeOff:
        {
            eventRequest = SAVEntityEvent_FanOff;
        }
            break;
        case SAVEntityState_FanSpeedHigh:
        {
            eventRequest = SAVEntityEvent_FanSpeedHigh;
        }
            break;
        case SAVEntityState_FanSpeedMediumHigh:
        {
            eventRequest = SAVEntityEvent_FanSpeedMediumHigh;
        }
            break;
        case SAVEntityState_FanSpeedMedium:
        {
            eventRequest = SAVEntityEvent_FanSpeedMedium;
        }
            break;
        case SAVEntityState_FanSpeedMediumLow:
        {
            eventRequest = SAVEntityEvent_FanSpeedMediumLow;
        }
            break;
        case SAVEntityState_FanSpeedLow:
        {
            eventRequest = SAVEntityEvent_FanSpeedLow;
        }
            break;
        case SAVEntityState_ModeAuto:
        {
            eventRequest = SAVEntityEvent_ModeAuto;
        }
            break;
        case SAVEntityState_ModeCool:
        {
            eventRequest = SAVEntityEvent_ModeCool;
        }
            break;
        case SAVEntityState_ModeHeat:
        {
            eventRequest = SAVEntityEvent_ModeHeat;
        }
            break;
        case SAVEntityState_ModeOff:
        {
            eventRequest = SAVEntityEvent_ModeOff;
        }
            break;
        case SAVEntityState_ModeHumidity:
        case SAVEntityState_HumidityModeOn:  //fake state
        {
            eventRequest = SAVEntityEvent_ModeHumidity;
        }
            break;
        case SAVEntityState_HumidityModeOff:
        {
            eventRequest = SAVEntityEvent_ModeHumidityOff; //fake state
        }
            break;
        case SAVEntityState_ModeHumidify:
        {
            eventRequest = SAVEntityEvent_ModeHumidify;
        }
            break;
        case SAVEntityState_ModeDehumidify:
        {
            eventRequest = SAVEntityEvent_ModeDehumidify;
        }         
            break;
        case SAVEntityState_ModeACDehumidify:
        {
            eventRequest = SAVEntityEvent_ModeACDehumidify;
        }
            break;
        default:
            //SAVEntityEvent_ModeHumidityAuto //don't know if this is a command but this would be a dual setpoint system
            //SAVEntityEvent_ModeHumidityOff
            return;
    }
    if (eventRequest != SAVEntityEvent_Unknown)
    {
        [self sendServiceRequest:[self.entity requestForEvent:eventRequest value:nil]];
    }
}

- (SAVEntityState)savEntityStateForSCUClimateModeType:(SCUClimateModeType)climateModeType allowSubstitute:(BOOL)allowSub
{
    NSNumber *stateMode = self.settingsModel.modesDictionary[@(climateModeType)];
    SCUClimateModeType substituteClimateType = SCUClimateModeNone;
    if (!stateMode)
    {
        switch (climateModeType)
        {
            case SCUClimateModeAuto:
                substituteClimateType = SCUClimateModeAutoSingleSetPoint;
                break;
            case SCUClimateModeAutoSingleSetPoint:
                substituteClimateType = SCUClimateModeAuto;
                break;
            case SCUClimateModeIncrease:
            case SCUClimateModeDecrease:
            case SCUClimateModeOff:
            default:
                break;
        }
        if (substituteClimateType != SCUClimateModeNone && allowSub)
        {
            stateMode = self.settingsModel.modesDictionary[@(substituteClimateType)];
        }
    }
    if (stateMode)
    {
        return [stateMode integerValue];
    }
    return SAVEntityState_Unknown;
}

- (void)climatePointAdjustmentType:(SCUClimateAdjustmentType)adjustmentType setValue:(NSNumber *)value
{
    if ((adjustmentType < SCUClimateAdjustmentSetMinPoint || value) && self.entity)
    {
        NSNumber *savEntityEventNumber = self.changeSetpointCommandDictionary[@(adjustmentType)];
        if ([savEntityEventNumber integerValue] != SAVEntityEvent_Unknown)
        {
            SAVEntityEvent savEntityEvent = [savEntityEventNumber integerValue];
            //could check if it is in range of HVAC commands SAVEntityEvent_CoolUp , SAVEntityEvent_AutoSet
            if (adjustmentType < SCUClimateAdjustmentSetMinPoint)
            {
                [self sendServiceRequest:[self.entity requestForEvent:savEntityEvent value:@(self.valueInterval)]];
            }
            else
            {
                [self sendServiceRequest:[self.entity requestForEvent:savEntityEvent value:value]];
            }
        }
    }
}

- (NSString *)serviceId
{
    return self.service.serviceId;
}

- (NSInteger)valueForStateUpdateResponce:(NSString *)updateValueString
{
    NSString *valueString =  [updateValueString stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    NSInteger value;
    if ([valueString length] > 0)
    {
        value = [updateValueString integerValue];
    }
    else
    {
        value = NSNotFound;
    }
    return value;
}

- (NSInteger)setpointValueForAdjustmentType:(SCUClimateAdjustmentType)type
{
    NSInteger value = NSNotFound;
    switch (type)
    {
        case SCUClimateAdjustmentDecrementMinPoint:
        case SCUClimateAdjustmentIncrementMinPoint:
        case SCUClimateAdjustmentSetMinPoint:
        {
            value = self.minSetPoint;
            break;
        }
        case SCUClimateAdjustmentDecrementMaxPoint:
        case SCUClimateAdjustmentIncrementMaxPoint:
        case SCUClimateAdjustmentSetMaxPoint:
        {
            value = self.maxSetPoint;
            break;
        }
        case SCUClimateAdjustmentDecrementDesiredClimatePoint:
        case SCUClimateAdjustmentIncrementDesiredClimatePoint:
        case SCUClimateAdjustmentSetDesiredClimatePoint:
        {
            value = self.desiredPoint;
            break;
        }
        case SCUClimateAdjustmentNone:
            break;
    }
    return value;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    ;
}

- (void)updateSettings:(SAVStateUpdate *)stateUpdate
{   
    SAVEntityState state = [self.entity typeFromState:stateUpdate.stateName];
    
    NSString *indexString = [self.settingsIndexDictionary objectForKey:[NSString stringWithFormat:@"%ld", (long)state]];
    NSInteger index = -1;
    if (indexString)
    {
        index = [indexString integerValue];
    }

    if (index >= 0)
    {
        [self setSelectedMode:state forSettingsIndex:index];
    }
}

- (NSArray *)statesUpdates
{
    return [self.stateUpdatesDict allValues];
}

- (void)dealloc
{
    [self.hvacPickerModel unregisterForStates];
    [self unregisterForStates];
}

- (void)unregisterForStates
{
    //subClass
}

#pragma mark - SCUStateReceiver Protocol

- (NSArray *)statesToRegister
{
    NSMutableSet *stateNames = [NSMutableSet set];
    [stateNames addObjectsFromArray:self.entity.states];
    return [stateNames allObjects];
}

- (BOOL)climateContainsCommand:(NSString *)command
{
    NSArray *commands = self.serviceCommands;
    
    return [commands containsObject:command];
}

- (NSString *)climateValueWithAppendedSuffix:(NSString *)value
{
    //implement in subclass if suffix is needed
    return value;
}

- (void)settingsModeSelectedAtIndexPath:(NSIndexPath *)indexPath forSettingIndex:(NSUInteger)settingIndex
{
    SAVEntityState settingCommandToSend = [self.settingsModel settingsModeSelectedAtIndexPath:indexPath forSettingIndex:settingIndex];
    if (settingCommandToSend != SAVEntityState_Unknown)
    {
        [self sendServiceRequestForSAVEntityState:settingCommandToSend];
    }
}

- (BOOL)isSetPointOutOfRange:(NSInteger)value
{
    return ((value > self.lowerValueSetUnitstoFahrenheit && self.isCelsius) ||
            (value < self.higherValueSetUnitstoCelsius && !self.isCelsius) ||
            (value > self.higherValueSetUnitstoFahrenheit) ||
            (value < 1));
}

//convenience methods and how the states will be updated
- (SAVEntityState)selectedPrimaryMode
{
    _selectedPrimaryMode = [self.settingsModel selectedModeForSettingsIndex:0];
    return _selectedPrimaryMode;
}

- (SAVEntityState)selectedSecondaryMode
{
    _selectedSecondaryMode = [self.settingsModel selectedModeForSettingsIndex:1];
    return _selectedSecondaryMode;
}

- (SAVEntityState)selectedTertiaryMode
{
    _selectedTertiaryMode = [self.settingsModel selectedModeForSettingsIndex:2];
    return _selectedTertiaryMode;
}

- (void)setSelectedMode:(SAVEntityState)mode forSettingsIndex:(NSUInteger)settingsIndex
{
    [self.settingsModel setSelectedMode:mode forSettingsIndex:settingsIndex];

    //-------------------------------------------------------------------
    // Jason W... :-(
    //-------------------------------------------------------------------
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-getter-return-value"
    switch (settingsIndex)
    {
        case 0:
        {
            [self selectedPrimaryMode];
            break;
        }
        case 1:
        {
            [self selectedSecondaryMode];
            break;
        }
        case 2:
        {
            [self selectedTertiaryMode];
            break;
        }
        default:
            break;
    }
#pragma clang diagnostic pop
}

- (BOOL)isDecreasingCurrentClimatePoint
{
    _isDecreasingCurrentClimatePoint = NO;
    return _isDecreasingCurrentClimatePoint;
}

- (BOOL)isIncreasingCurrentClimatePoint
{
    _isIncreasingCurrentClimatePoint = NO;
    return _isIncreasingCurrentClimatePoint;
}

- (BOOL)isSingleSetPoint
{
    BOOL isSingleSetPoint = NO;
    if (self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeAutoSingleSetPoint allowSubstitute:NO])
    {
        isSingleSetPoint = YES;
    }
    else if (self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeDecrease allowSubstitute:NO])
    {
        isSingleSetPoint = YES;
    }
    else if (self.selectedPrimaryMode == [self savEntityStateForSCUClimateModeType:SCUClimateModeIncrease allowSubstitute:NO])
    {
        isSingleSetPoint = YES;
    }
    return isSingleSetPoint;
}

- (void)setMinSetPoint:(NSInteger)minSetPoint
{
    if (minSetPoint != 0)
    {
        _minSetPoint = minSetPoint;
        if (self.selectedPrimaryMode == [(self.settingsModel.modesDictionary)[@(SCUClimateModeIncrease)] integerValue])
        {
            if (minSetPoint > self.lowerValueSetUnitstoFahrenheit && minSetPoint < self.higherValueSetUnitstoFahrenheit && self.isCelsius)
            {
                [self setIsCelsius:NO];
            }
            else if (minSetPoint > self.lowerValueSetUnitstoCelsius && minSetPoint < self.higherValueSetUnitstoCelsius && !self.isCelsius)
            {
                [self setIsCelsius:YES];
            }
        }
    }
}

- (void)setMaxSetPoint:(NSInteger)maxSetPoint
{
    if (maxSetPoint != 0)
    {
        _maxSetPoint = maxSetPoint;
        if (self.selectedPrimaryMode == [(self.settingsModel.modesDictionary)[@(SCUClimateModeDecrease)] integerValue])
        {
            if (maxSetPoint > self.lowerValueSetUnitstoFahrenheit && maxSetPoint < self.higherValueSetUnitstoFahrenheit && self.isCelsius)
            {
                [self setIsCelsius:NO];
            }
            else if (maxSetPoint > self.lowerValueSetUnitstoCelsius && maxSetPoint < self.higherValueSetUnitstoCelsius && !self.isCelsius)
            {
                [self setIsCelsius:YES];
            }
        }
    }
}

- (void)setDesiredPoint:(NSInteger)desiredPoint
{
    _desiredPoint = desiredPoint;
    if (self.selectedPrimaryMode == [(self.settingsModel.modesDictionary)[@(SCUClimateModeAuto)] integerValue])
    {
        if (desiredPoint > self.lowerValueSetUnitstoFahrenheit && desiredPoint < self.higherValueSetUnitstoFahrenheit && self.isCelsius)
        {
            [self setIsCelsius:NO];
        }
        else if (desiredPoint > self.lowerValueSetUnitstoCelsius && desiredPoint < self.higherValueSetUnitstoCelsius && !self.isCelsius)
        {
            [self setIsCelsius:YES];
        }
    }
}

@end
