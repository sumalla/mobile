//
//  SAVPoolEntityCommands.h
//  SavantController
//
//  Created by Jason Wolkovitz on 10/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#ifndef SavantController_SAVPoolEntityCommands_h
#define SavantController_SAVPoolEntityCommands_h

//-------------------------------------------------------------------
// Entity Commands
//-------------------------------------------------------------------

// Heat Commands
static NSString *SAVPoolEntityCommandEnablePoolHeater = @"EnablePoolHeater";
static NSString *SAVPoolEntityCommandDisablePoolHeater = @"DisablePoolHeater";
static NSString *SAVPoolEntityCommandTogglePoolHeater = @"TogglePoolHeater";

static NSString *SAVPoolEntityCommandIncrementPoolHeaterSetpoint = @"IncrementPoolHeaterSetpoint";
static NSString *SAVPoolEntityCommandDecrementPoolHeaterSetpoint = @"DecrementPoolHeaterSetpoint";
static NSString *SAVPoolEntityCommandSetPoolHeaterSetpoint  = @"SetPoolHeaterSetpoint";
// action_argument name="PoolHeaterSetpoint" note="Enter the Desired Pool Heater Setpoint (nnn, degrees C or F)"

// Heat Commands secondary
static NSString *SAVPoolEntityCommandDisableSecondaryPoolHeater = @"DisableSecondaryPoolHeater";
static NSString *SAVPoolEntityCommandEnableSecondaryPoolHeater = @"EnableSecondaryPoolHeater";
static NSString *SAVPoolEntityCommandToggleSecondaryPoolHeater = @"ToggleSecondaryPoolHeater";
static NSString *SAVPoolEntityCommandIncrementPoolHeaterSecondarySetpoint = @"IncrementPoolHeaterSecondarySetpoint";
static NSString *SAVPoolEntityCommandDecrementPoolHeaterSecondarySetpoint = @"DecrementPoolHeaterSecondarySetpoint";
static NSString *SAVPoolEntityCommandSetPoolHeaterSecondarySetpoint = @"SetPoolHeaterSecondarySetpoint";
//action_argument name="PoolHeaterSecondarySetpoint" note="Enter the Desired Secondary Pool Heater Setpoint (nnn, degrees C or F). This Value Should be Less than the Primary Heater Setpoint."

//solar Heat Commands
static NSString *SAVPoolEntityCommandDisableSolarHeater = @"DisableSolarHeater";
static NSString *SAVPoolEntityCommandEnableSolarHeater = @"EnableSolarHeater";
static NSString *SAVPoolEntityCommandToggleSolarHeater = @"ToggleSolarHeater";

//spa heater
static NSString *SAVPoolEntityCommandDisableSpaHeater = @"DisableSpaHeater";
static NSString *SAVPoolEntityCommandEnableSpaHeater = @"EnableSpaHeater";
static NSString *SAVPoolEntityCommandToggleSpaHeater = @"ToggleSpaHeater";
static NSString *SAVPoolEntityCommandIncrementSpaHeaterSetpoint = @"IncrementSpaHeaterSetpoint";
static NSString *SAVPoolEntityCommandDecrementSpaHeaterSetpoint = @"DecrementSpaHeaterSetpoint";
static NSString *SAVPoolEntityCommandSetSpaHeaterSetpoint = @"SetSpaHeaterSetpoint";
///name="SpaHeaterSetpoint" note="Enter the Desired Spa Heater Setpoint (nnn, degrees C or F)."

// Pump Commands
static NSString *SAVPoolEntityCommandSetPumpModeOn = @"SetPumpModeOn";
static NSString *SAVPoolEntityCommandSetPumpModeOff = @"SetPumpModeOff";
static NSString *SAVPoolEntityCommandTogglePumpMode = @"TogglePumpMode";
static NSString *SAVPoolEntityCommandSetPumpSpeedHigh = @"SetPumpSpeedHigh";
static NSString *SAVPoolEntityCommandSetPumpSpeedLow = @"SetPumpSpeedLow";
static NSString *SAVPoolEntityCommandTogglePumpSpeed = @"TogglePumpSpeed";

// water fall
static NSString *SAVPoolEntityCommandSetWaterfallModeOn = @"SetWaterfallModeOn";
static NSString *SAVPoolEntityCommandSetWaterfallModeOff = @"SetWaterfallModeOff";
static NSString *SAVPoolEntityCommandToggleWaterfallMode = @"ToggleWaterfallMode";

// spa modes
static NSString *SAVPoolEntityCommandSetSpaModeOn = @"SetSpaModeOn";
static NSString *SAVPoolEntityCommandSetSpaModeOff = @"SetSpaModeOff";
static NSString *SAVPoolEntityCommandToggleSpaMode = @"ToggleSpaMode";
//action name="UpdatePoolSpaStatus"> not used

//non standard
//cleaning
static NSString *SAVPoolEntityCommandSetCleaningSystemOn = @"SetCleaningSystemOn";
static NSString *SAVPoolEntityCommandSetCleaningSystemOff = @"SetCleaningSystemOff";
static NSString *SAVPoolEntityCommandToggleCleaningSystem = @"ToggleCleaningSystem";
//static NSString *SAVPoolEntityCommand = @"";

//Auxiliary
static NSString *SAVPoolEntityCommandSetAuxiliaryPrefix = @"SetAuxiliary";
static NSString *SAVPoolEntityCommandSetAuxiliaryOnSuffix = @"On";
static NSString *SAVPoolEntityCommandSetAuxiliaryOffSuffix = @"Off";
//SetAuxiliary*On, SetAuxiliary*Off
static NSString *SAVPoolEntityCommandSetAuxiliaryOn = @"SetAuxiliaryOn";
static NSString *SAVPoolEntityCommandSetAuxiliaryOff = @"SetAuxiliaryOff";
static NSString *SAVPoolEntityCommandToggleAuxiliary = @"ToggleAuxiliary";
static NSString *SAVPoolEntityCommandIncreaseAuxiliaryDimmerLevel = @"IncreaseAuxiliaryDimmerLevel";
static NSString *SAVPoolEntityCommandDecreaseAuxiliaryDimmerLevel = @"DecreaseAuxiliaryDimmerLevel";

//Auxiliary action_argument
static NSString *SAVPoolEntityActionArgumentAuxiliaryNumber = @"AuxiliaryNumber"; //ype=string note="Select the Auxiliary to Set (1 - 31)."

//-------------------------------------------------------------------
// Entity State Strings
//-------------------------------------------------------------------
// Heat States
static NSString *SAVPoolEntityStatePoolHeaterMode = @"CurrentPoolHeaterMode";//type="string">Enabled<>Off<>On<
static NSString *SAVPoolEntityStatePoolHeaterSetpoint = @"CurrentPoolHeaterSetpoint";//type="string"
static NSString *SAVPoolEntityStatePoolTemperature = @"CurrentPoolTemperature";//type="string">--<><
static NSString *SAVPoolEntityStateIsPoolHeaterOn = @"IsPoolHeaterOn";//type="boolean">false<>true<

// Heat secondary
static NSString *SAVPoolEntityStateSecondaryPoolHeaterMode = @"CurrentSecondaryPoolHeaterMode";//type="string">Enabled<>Off<>On<
static NSString *SAVPoolEntityStatePoolHeaterSecondarySetpoint = @"CurrentPoolHeaterSecondarySetpoint";//type="string"
static NSString *SAVPoolEntityStateIsSecondaryPoolHeaterMode = @"IsSecondaryPoolHeaterMode";//type="boolean">false<>true<

//solar Heat Commands
static NSString *SAVPoolEntityStateSolarHeaterMode = @"CurrentSolarHeaterMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStateSolarHeaterTemperature = @"CurrentSolarHeaterTemperature";//type="string">--<><
static NSString *SAVPoolEntityStateIsSolarHeaterOn = @"IsSolarHeaterOn";//type="boolean">false<>true<
//update state="IsSolarHeaterOn" type="boolean"false
//update state="IsSolarHeaterOn" type="string"false bug?

//spa heater
static NSString *SAVPoolEntityStateSpaHeaterMode = @"CurrentSpaHeaterMode";//type="string">Enabled<>Off<>On<
static NSString *SAVPoolEntityStateSpaHeaterSetpoint = @"CurrentSpaHeaterSetpoint";//type="string"><
static NSString *SAVPoolEntityStateSpaTemperature = @"CurrentSpaTemperature";//type="string">--<><
static NSString *SAVPoolEntityStateIsSpaHeaterOn = @"IsSpaHeaterOn";//type="boolean">false<>true<

// other temp states
static NSString *SAVPoolEntityStateAirTemperature = @"CurrentAirTemperature";//type="string">--<><
static NSString *SAVPoolEntityStateTemperatureUnits = @"CurrentTemperatureUnits";//type="string"><>Celcius<>Farenheit<

//Pump states
static NSString *SAVPoolEntityStatePumpMode = @"CurrentPumpMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStatePumpSpeed = @"CurrentPumpSpeed";//type="string">High<>Low<
static NSString *SAVPoolEntityStateIsPumpModeOn = @"IsPumpModeOn";//type="boolean">false<>true<

// spa modes
static NSString *SAVPoolEntityStateSpaMode = @"CurrentSpaMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStateIsSpaModeOn = @"IsSpaModeOn";//type="boolean">false<>true<

// water fall
static NSString *SAVPoolEntityStateCurentWaterfallMode = @"CurentWaterfallMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStateWaterfallMode = @"CurrentWaterfallMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStateIsWaterfallModeOn = @"IsWaterfallModeOn";//type="boolean">false<>true<

//non standard
//cleaning
static NSString *SAVPoolEntityStateCleaningSystemMode = @"CurrentCleaningSystemMode";//type="string">Off<>On<
static NSString *SAVPoolEntityStateIsCleaningSystemModeOn = @"IsCleaningSystemModeOn";//type="boolean">false<>true<

//non standard
//opmode
static NSString *SAVPoolEntityStateOpmode = @"CurrentOpmode";//type="string">AUTO<>SERVICE<>TIMEOUT<><

//Auxiliary
static NSString *SAVPoolEntityStateAuxiliaryPrefix = @"CurrentAuxiliary";

static NSString *SAVPoolEntityStateCurrentAuxiliaryState = @"CurrentAuxiliaryState";// type="string">OFF<>ON<>Off<>On<
static NSString *SAVPoolEntityStateCurrentAuxiliaryStateSuffix = @"State"; //CurrentAuxiliary*State type="string">Off<>On<
static NSString *SAVPoolEntityStateCurrentExtraAuxiliaryState = @"CurrentExtraAuxiliaryState";//type="string" >Off<>On<

static NSString *SAVPoolEntityStateCurrentAuxiliaryDimmerLevel = @"CurrentAuxiliaryDimmerLevel";//type="string"
static NSString *SAVPoolEntityStateAuxiliaryDimmerLevelSuffix = @"DimmerLevel";//"CurrentAuxiliary*DimmerLevel" type="string"

static NSString *SAVPoolEntityStateAuxiliaryLEDPresetSuffix = @"LEDPreset";//"CurrentAuxiliary*LEDPreset" type="integer"

static NSString *SAVPoolEntityStateIsAuxiliaryOn = @"IsAuxiliaryOn";//type="boolean">false<>true<
static NSString *SAVPoolEntityStateIsAuxiliaryOnPrefix = @"IsAuxiliary";//IsAuxiliary*On type="boolean">false<>true<
static NSString *SAVPoolEntityStateIsAuxiliaryOnSuffix = @"On";


#endif
