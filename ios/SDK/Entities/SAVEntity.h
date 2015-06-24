//
//  SAVEntity.h
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
@class SAVService, SAVServiceRequest;

typedef NS_ENUM(NSInteger, SAVEntityClass)
{
    SAVEntityClass_Unknown = -1,
    SAVEntityClass_HVAC,
    SAVEntityClass_Pool,
    SAVEntityClass_Lighting,
    SAVEntityClass_Shades,
    SAVEntityClass_Security,
    SAVEntityClass_Cameras
};

typedef NS_ENUM(NSInteger, SAVEntityAddressScheme)
{
    SAVEntityAddressScheme_ZeroRelative,
    SAVEntityAddressScheme_OneRelative,
    SAVEntityAddressScheme_NoInitial
};

typedef NS_ENUM(NSInteger, SAVEntityState)
{
    SAVEntityState_Unknown = -1,
    //-------------------------------------------------------------------
    // HVAC States
    //-------------------------------------------------------------------
    SAVEntityState_CoolPoint,
    SAVEntityState_HeatPoint,
    SAVEntityState_CurrentTemp,
    SAVEntityState_RemoteTemp,
    SAVEntityState_HumidityPoint,
    SAVEntityState_HumidifyPoint,
    SAVEntityState_DehumidifyPoint,
    SAVEntityState_CurrentHumidity,
    SAVEntityState_FanmodeAuto,
    SAVEntityState_FanmodeOn,
    SAVEntityState_FanmodeOff,
    SAVEntityState_Fanmode,
    SAVEntityState_FanOn,
    SAVEntityState_FanSpeedHigh,
    SAVEntityState_FanSpeedMediumHigh,
    SAVEntityState_FanSpeedMedium,
    SAVEntityState_FanSpeedMediumLow,
    SAVEntityState_FanSpeedLow,
    SAVEntityState_FanSpeedAuto, //SAVHVACEntityStateFanSpeedOff assume this is auto set speed
    SAVEntityState_FanSpeed,
    SAVEntityState_ModeAuto,
    SAVEntityState_ModeCool,
    SAVEntityState_ModeHeat,
    SAVEntityState_ModeOff,
    SAVEntityState_ModeHumidity,
    SAVEntityState_HumidityModeOn,  //fake modes
    SAVEntityState_HumidityModeOff, //fake modes
    SAVEntityState_ModeHumidify,
    SAVEntityState_ModeDehumidify,
    SAVEntityState_ModeACDehumidify,
    SAVEntityState_Mode,
    SAVEntityState_Stage1Heating,
    SAVEntityState_Stage1Cooling,
    SAVEntityState_Stage2Heating,
    SAVEntityState_Stage2Cooling,
    SAVEntityState_Stage3Heating,
    SAVEntityState_CurrentSchedule,
    SAVEntityState_ScheduleList,
    
    SAVEntityState_AutoMinimumDeadband,
    SAVEntityState_AutoSetPoint,

    //-------------------------------------------------------------------
    // Pool & Spa States
    //-------------------------------------------------------------------
    SAVEntityState_PoolTemperature,
    SAVEntityState_SpaTemperature,
    SAVEntityState_AirTemperature,
    SAVEntityState_TemperatureUnits,

    SAVEntityState_PoolHeaterSetpoint,
    SAVEntityState_PoolHeaterMode,
    SAVEntityState_PoolHeaterModeOn, //fake modes
    SAVEntityState_PoolHeaterModeOff, //fake modes
    SAVEntityState_IsPoolHeaterOn,

    SAVEntityState_PoolHeaterSecondarySetpoint,
    SAVEntityState_SecondaryPoolHeaterMode,
    SAVEntityState_SecondaryPoolHeaterModeOn, //fake modes
    SAVEntityState_SecondaryPoolHeaterModeOff, //fake modes
    SAVEntityState_IsSecondaryPoolHeaterMode,
    
    SAVEntityState_SolarHeaterTemperature,
    SAVEntityState_SolarHeaterMode,
    SAVEntityState_SolarHeaterModeOn, //fake modes
    SAVEntityState_SolarHeaterModeOff, //fake modes
    SAVEntityState_IsSolarHeaterOn,
    

    SAVEntityState_SpaHeaterSetpoint,
    SAVEntityState_SpaHeaterMode,
    SAVEntityState_SpaHeaterModeOn, //fake modes
    SAVEntityState_SpaHeaterModeOff, //fake modes
    SAVEntityState_IsSpaHeaterOn,
    
    SAVEntityState_PumpMode,
    SAVEntityState_PumpModeOn, //fake modes
    SAVEntityState_PumpModeOff, //fake modes
    SAVEntityState_IsPumpModeOn,
    
    SAVEntityState_PumpSpeed,
    SAVEntityState_PumpSpeedLow, //fake modes
    SAVEntityState_PumpSpeedHigh, //fake modes

    
    SAVEntityState_SpaMode,
    SAVEntityState_SpaModeOn, //fake modes
    SAVEntityState_SpaModeOff, //fake modes
    SAVEntityState_IsSpaModeOn,
    
    SAVEntityState_WaterfallMode,
    SAVEntityState_WaterfallModeOn, //fake modes
    SAVEntityState_WaterfallModeOff, //fake modes
    SAVEntityState_IsWaterfallModeOn,
    
    SAVEntityState_CleaningSystemMode,
    SAVEntityState_CleaningSystemModeOn, //fake modes
    SAVEntityState_CleaningSystemModeOff, //fake modes
    SAVEntityState_IsCleaningSystemModeOn,
    
    SAVEntityState_Opmode, //unused
    
    SAVEntityState_AuxiliaryModeOn,
    SAVEntityState_AuxiliaryModeOff,
    
    SAVEntityState_AuxiliaryIsAuxiliaryOn,
    SAVEntityState_CurrentAuxiliaryState,
    SAVEntityState_CurrentExtraAuxiliaryState,
    SAVEntityState_UnknownAuxiliaryState,

    //-------------------------------------------------------------------
    // Lighting States
    //-------------------------------------------------------------------
    SAVEntityState_Lighting,

    //-------------------------------------------------------------------
    // Security States
    //-------------------------------------------------------------------
    SAVEntityState_SensorStatus,
    SAVEntityState_SensorDetailedStatus,
    SAVEntityState_SensorBypassToggle,
    SAVEntityState_PartitionStatus,
    SAVEntityState_PartitionMenuLine1,
    SAVEntityState_PartitionMenuLine2,
    SAVEntityState_PartitionUserAccessCode,
    SAVEntityState_PartitionUserNumber,
    SAVEntityState_PartitionArmingStatus
};

typedef NS_ENUM(NSInteger, SAVEntityType)
{
    SAVEntityType_Unknown = -1,

    //-------------------------------------------------------------------
    // HVAC Types
    //-------------------------------------------------------------------
    SAVEntityType_Thermostat,
    SAVEntityType_Humidity,

    //-------------------------------------------------------------------
    // Pool Type
    //-------------------------------------------------------------------
    SAVEntityType_Pool,
    
    //-------------------------------------------------------------------
    // Lighting/Shade Types
    //-------------------------------------------------------------------
    SAVEntityType_Button,
    SAVEntityType_Switch,
    SAVEntityType_Scene,

    //-------------------------------------------------------------------
    // Lighting Types
    //-------------------------------------------------------------------
    SAVEntityType_Dimmer,
    SAVEntityType_Hue,

    //-------------------------------------------------------------------
    // Shade Types
    //-------------------------------------------------------------------
    SAVEntityType_Shade,
    SAVEntityType_Variable,
    
    //-------------------------------------------------------------------
    // Fan Type
    //-------------------------------------------------------------------
    SAVEntityType_Fan,

    //-------------------------------------------------------------------
    // Camera Types
    //-------------------------------------------------------------------
    SAVEntityType_Fixed,
    SAVEntityType_PTZ,

    //-------------------------------------------------------------------
    // Security Types
    //-------------------------------------------------------------------
    SAVEntityType_Sensor,
    SAVEntityType_Partition
};

typedef NS_ENUM(NSInteger, SAVEntityEvent)
{
    SAVEntityEvent_Unknown = -1,

    //-------------------------------------------------------------------
    // HVAC Events
    //-------------------------------------------------------------------
    SAVEntityEvent_CoolUp,
    SAVEntityEvent_CoolDown,
    SAVEntityEvent_CoolSet,
    SAVEntityEvent_HeatUp,
    SAVEntityEvent_HeatDown,
    SAVEntityEvent_HeatSet,
    SAVEntityEvent_SingleTempUp,
    SAVEntityEvent_SingleTempDown,
    SAVEntityEvent_SingleTempSet,
    SAVEntityEvent_HumidfyUp,
    SAVEntityEvent_HumidfyDown,
    SAVEntityEvent_HumidfySet,
    SAVEntityEvent_HumidtyUp,
    SAVEntityEvent_HumidtyDown,
    SAVEntityEvent_HumidtySet,
    SAVEntityEvent_DehumidfyUp,
    SAVEntityEvent_DehumidfyDown,
    SAVEntityEvent_DehumidfySet,
    SAVEntityEvent_SingleHumidityUp,
    SAVEntityEvent_SingleHumidityDown,
    SAVEntityEvent_SingleHumiditySet,
    SAVEntityEvent_FanAuto,
    SAVEntityEvent_FanOn,
    SAVEntityEvent_FanOff,
    SAVEntityEvent_FanSpeedHigh,
    SAVEntityEvent_FanSpeedMediumHigh,
    SAVEntityEvent_FanSpeedMedium,
    SAVEntityEvent_FanSpeedMediumLow,
    SAVEntityEvent_FanSpeedLow,
    SAVEntityEvent_FanSpeedAuto, //SAVHVACEntityStateFanSpeedOff assume this is auto set speed
    SAVEntityEvent_ModeAuto,
    SAVEntityEvent_ModeCool,
    SAVEntityEvent_ModeHeat,
    SAVEntityEvent_ModeOff,
    SAVEntityEvent_ModeHumidity, //single set point for systems with both Humidify and Dehumidify
    SAVEntityEvent_ModeHumidityAuto, //don't know if this is a command but this would be a dual setpoint system
    SAVEntityEvent_ModeHumidityOff,
    SAVEntityEvent_ModeHumidify,
    SAVEntityEvent_ModeDehumidify,
    SAVEntityEvent_ModeACDehumidify,
    SAVEntityEvent_AutoUp,
    SAVEntityEvent_AutoDown,
    SAVEntityEvent_AutoSet,

    //-------------------------------------------------------------------
    // Pool Events
    //-------------------------------------------------------------------
    SAVEntityEvent_EnablePoolHeater,
    SAVEntityEvent_DisablePoolHeater,
    SAVEntityEvent_TogglePoolHeater,
    SAVEntityEvent_IncrementPoolHeaterSetpoint,
    SAVEntityEvent_DecrementPoolHeaterSetpoint,
    SAVEntityEvent_SetPoolHeaterSetpoint,
    SAVEntityEvent_DisableSecondaryPoolHeater,
    SAVEntityEvent_EnableSecondaryPoolHeater,
    SAVEntityEvent_ToggleSecondaryPoolHeater,
    SAVEntityEvent_IncrementPoolHeaterSecondarySetpoint,
    SAVEntityEvent_DecrementPoolHeaterSecondarySetpoint,
    SAVEntityEvent_SetPoolHeaterSecondarySetpoint,
    SAVEntityEvent_DisableSolarHeater,
    SAVEntityEvent_EnableSolarHeater,
    SAVEntityEvent_ToggleSolarHeater,
    SAVEntityEvent_DisableSpaHeater,
    SAVEntityEvent_EnableSpaHeater,
    SAVEntityEvent_ToggleSpaHeater,
    SAVEntityEvent_IncrementSpaHeaterSetpoint,
    SAVEntityEvent_DecrementSpaHeaterSetpoint,
    SAVEntityEvent_SetSpaHeaterSetpoint,
    SAVEntityEvent_SetPumpModeOn,
    SAVEntityEvent_SetPumpModeOff,
    SAVEntityEvent_TogglePumpMode,
    SAVEntityEvent_SetPumpSpeedHigh,
    SAVEntityEvent_SetPumpSpeedLow,
    SAVEntityEvent_TogglePumpSpeed,
    SAVEntityEvent_SetWaterfallModeOn,
    SAVEntityEvent_SetWaterfallModeOff,
    SAVEntityEvent_ToggleWaterfallMode,
    SAVEntityEvent_SetSpaModeOn,
    SAVEntityEvent_SetSpaModeOff,
    SAVEntityEvent_ToggleSpaMode,
    SAVEntityEvent_SetCleaningSystemOn,
    SAVEntityEvent_SetCleaningSystemOff,
    SAVEntityEvent_ToggleCleaningSystem,
    
    //-------------------------------------------------------------------
    // Lighting/Shade Events
    //-------------------------------------------------------------------
    SAVEntityEvent_Press,
    SAVEntityEvent_Hold,
    SAVEntityEvent_Release,
    SAVEntityEvent_TogglePress,
    SAVEntityEvent_ToggleHold,
    SAVEntityEvent_ToggleRelease,
    SAVEntityEvent_SwitchOn,
    SAVEntityEvent_SwitchOff,

    //-------------------------------------------------------------------
    // Lighting Events
    //-------------------------------------------------------------------
    SAVEntityEvent_Dimmer,
    SAVEntityEvent_Restore,

    //-------------------------------------------------------------------
    // Shade Events
    //-------------------------------------------------------------------
    SAVEntityEvent_ShadeDown,
    SAVEntityEvent_ShadeUp,
    SAVEntityEvent_ShadeSet,
    SAVEntityEvent_ShadeStop,
    
    //-------------------------------------------------------------------
    // Fan Events (FanOff command is under HVAC - duplicate name)
    //-------------------------------------------------------------------
    SAVEntityEvent_FanLow,
    SAVEntityEvent_FanMedium,
    SAVEntityEvent_FanHigh,

    //-------------------------------------------------------------------
    // Camera Events
    //-------------------------------------------------------------------
    SAVEntityEvent_ZoomIn,
    SAVEntityEvent_ZoomOut,
    SAVEntityEvent_TiltUp,
    SAVEntityEvent_TiltDown,
    SAVEntityEvent_PanLeft,
    SAVEntityEvent_PanRight,
    SAVEntityEvent_IrisOpen,
    SAVEntityEvent_IrisClose,

    //-------------------------------------------------------------------
    // Security Events
    //-------------------------------------------------------------------
    SAVEntityEvent_1,
    SAVEntityEvent_2,
    SAVEntityEvent_3,
    SAVEntityEvent_4,
    SAVEntityEvent_5,
    SAVEntityEvent_6,
    SAVEntityEvent_7,
    SAVEntityEvent_8,
    SAVEntityEvent_9,
    SAVEntityEvent_0,
    SAVEntityEvent_Clear,
    SAVEntityEvent_Pound,
    SAVEntityEvent_Star,
    SAVEntityEvent_Panic,
    SAVEntityEvent_Stay,
    SAVEntityEvent_Away,
    SAVEntityEvent_Disarm,
    SAVEntityEvent_Fire,
    SAVEntityEvent_Medical,
    SAVEntityEvent_Police,
    SAVEntityEvent_UserUp,
    SAVEntityEvent_UserDown,
    SAVEntityEvent_Left,
    SAVEntityEvent_Right,
    SAVEntityEvent_Menu,
    SAVEntityEvent_Bypass,
    SAVEntityEvent_Unbypass
};

@interface SAVEntity : NSObject

/**
 *  The room associated with the entity.
 */
@property NSString *roomName;

/**
 *  The zone associated with the entity.
 */
@property NSString *zoneName;
@property SAVService *service;

/**
 *  The entity type (dimmer, switch, etc). The possible types will depend
 *  on the entity class.
 */
@property SAVEntityType type;

/**
 *   A list of addresses to be used when sending requests.
 */
@property NSArray *addresses;

/**
 *  The label of the entity.
 */
@property NSString *label;

/**
 *  The ID of the entity in the table. This should be unique
 */
@property NSInteger identifier;

/**
*  Creates an entity with the associated room, zone, and service.
*
*  @param room    The room associated with the entity.
*  @param zone    The zone associated with the entity.
*  @param service The service associated with the entity.
*
*  @return return A new entity object.
*/
- (SAVEntity *)initWithRoomName:(NSString *)room zoneName:(NSString *)zone service:(SAVService *)service;

/**
 * Creates an entity with the associated service.
 *
 * @param service
 *            The service associated with the entity.
 *
 *  @return return A new entity object.
 */
+ (SAVEntity *)entityFromService:(SAVService *)service;

/**
 *  Returns a given event for a command string.
 *
 *  @param command The command string
 *
 *  @return an entity event.
 */
- (SAVEntityEvent)eventForCommand:(NSString *)command;

/**
 * Returns the service request associated with a particular event.
 *
 * @param event
 *            An integer representing the event (button press, dimmer
 *            set, HVAC cool point, etc).
 * @param value
 *            An optional value argument associated with the event. If
 *            this is a dimmer entity,for example, this will be a float
 *            with the dimmer level.
 * @return A service request to send to the system or null.
 */
- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value;

+ (SAVEntityClass)entityClassForService:(SAVService *)service;

/**
 * Given a string this will return the type integer associated with it.
 *
 * @param typeString
 *            A string representing the entity type. This should come
 *            from the database.
 * @return An SAVEntityType representing the entity type.
 */
- (SAVEntityType)typeFromString:(NSString *)typeString;

/**
 * Given the entity type this will return the string associeted with it.
 * @param type An integer representing the entity type.
 * @return A string representing the entity type.
 */
- (NSString *)stateFromType:(SAVEntityState)type;

/**
 * Given a state string this will return an SAVEntityState representing the
 * state type.
 *
 * @param state
 *            A fully qualified state string.
 * @return A integer representing the state
 */
- (SAVEntityState)typeFromState:(NSString *)state;

/**
 *  Given a state string this will return the name of the state (without
 * scope or address).
 *
 *  @param state A fully qualified state string.
 *
 *  @return The state name without the address.
 */
- (NSString *)nameFromState:(NSString *)state;

/**
 *  Given a state string this will return the addresses of the state (without
 * scope or address).
 *
 *  @param state A fully qualified state string.
 *
 *  @return The addresses.
 */
- (NSArray *)addressesFromState:(NSString *)state;

/**
 * Create a request based upon the service and the address arguments.
 *
 * @return A service request.
 */
- (SAVServiceRequest *)baseRequest;

/**
 * Creates a dictionary structure with the current address
 * arguments in it.
 *
 * @return a dictionary containing the current arguments
 */
- (NSDictionary *)createAddressArguments;

/**
 * Gets a list of states associate with the entity.
 *
 * @return A list of strings representing the states.
 */
- (NSArray *)states;

/**
 * Returns the suffix needed by the states.
 *
 * @return A string representing the state suffix. This typically will
 *         be _Addr1_Addr2_etc.
 */
- (NSString *)stateSuffix;

/**
 * Gets the state scope associated with the entity's service.
 *
 * @return A string representing the state scope.
 */
- (NSString *)stateScope;

/**
 *  A fully qualified state including the scope and suffix, given a state name.
 *
 *  @param stateName State name.
 *
 *  @return Fully qualified state.
 */
- (NSString *)stateFromStateName:(NSString *)stateName;

/**
 * Gets the address prefix for the current class.
 *
 * @return A string representing the address prefix.
 */
- (NSString *)addressKeyPrefix;

/**
 * Gets the address numbering scheme.
 *
 * @return An SAVEntityAddressScheme representing the address scheme.
 */
- (SAVEntityAddressScheme)addressScheme;

@end
