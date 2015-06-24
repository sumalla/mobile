//
//  SAVSecurityEntity.h
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVEntity.h"

// Number Commands
extern NSString *const SAVSecurityEntityCommandOne;
extern NSString *const SAVSecurityEntityCommandTwo;
extern NSString *const SAVSecurityEntityCommandThree;
extern NSString *const SAVSecurityEntityCommandFour;
extern NSString *const SAVSecurityEntityCommandFive;
extern NSString *const SAVSecurityEntityCommandSix;
extern NSString *const SAVSecurityEntityCommandSeven;
extern NSString *const SAVSecurityEntityCommandEight;
extern NSString *const SAVSecurityEntityCommandNine;
extern NSString *const SAVSecurityEntityCommandZero;
extern NSString *const SAVSecurityEntityCommandPound;
extern NSString *const SAVSecurityEntityCommandAsterix;

// Keypad Commands
extern NSString *const SAVSecurityEntityCommandPanic;
extern NSString *const SAVSecurityEntityCommandStay;
extern NSString *const SAVSecurityEntityCommandAway;
extern NSString *const SAVSecurityEntityCommandDisarm;
extern NSString *const SAVSecurityEntityCommandFire;
extern NSString *const SAVSecurityEntityCommandMedical;
extern NSString *const SAVSecurityEntityCommandPolice;
extern NSString *const SAVSecurityEntityCommandLeft;
extern NSString *const SAVSecurityEntityCommandRight;
extern NSString *const SAVSecurityEntityCommandMenu;
extern NSString *const SAVSecurityEntityCommandEndKeypress;
extern NSString *const SAVSecurityEntityCommandClearUserCode;
extern NSString *const SAVSecurityEntityCommandIncrementUser;
extern NSString *const SAVSecurityEntityCommandDecrementUser;

extern NSString *const SAVSecurityKeypadServiceID;
extern NSString *const SAVSecurityUserServiceID;

typedef NS_ENUM(NSInteger, SAVSecurityEntityStatus)
{
    SAVSecurityEntityStatus_Unknown = -1,
    SAVSecurityEntityStatus_Ready    = 0,
    SAVSecurityEntityStatus_Trouble  = 1,
    SAVSecurityEntityStatus_Critical = 2
};

typedef NS_ENUM(NSInteger, SAVSecurityEntityArmingStatus)
{
    SAVSecurityEntityArmingStatus_Unknown,
    SAVSecurityEntityArmingStatus_Disarmed,
    SAVSecurityEntityArmingStatus_Away,
    SAVSecurityEntityArmingStatus_Stay,
    SAVSecurityEntityArmingStatus_Instant,
    SAVSecurityEntityArmingStatus_Vaction,
    SAVSecurityEntityArmingStatus_NightStay
};

typedef NS_ENUM(NSInteger, SAVSecurityEntityServiceType)
{
    SAVSecurityEntityServiceType_NotSecurity = -1,
    SAVSecurityEntityServiceType_KeypadSecurity,
    SAVSecurityEntityServiceType_UserSecurity
};

@interface SAVSecurityEntity : SAVEntity

@property NSString *partition;
@property NSString *sensor;

@property BOOL hasBypass;

@property NSString *statusState;
@property NSString *bypassToggleState;
@property NSString *bypassTextState;

@property BOOL inGlobalZone;

/**
 * Returns true if this is the user login based security system. False if it is keypad.
 * @return True if user login security service. False otherwise.
 */
@property (readonly, nonatomic, getter = isUserSecurity) BOOL userSecurity;

/**
 * Returns the type of the security service.
 * @param service securityService A security service.
 * @return The type of the security service or SAVSecurityEntityServiceType_NotSecurity
 *                        if it is not a security service.
 */
- (SAVSecurityEntityServiceType)serviceTypeForService:(SAVService *)service;

/**
 *  Returns the arming status for a given state value.
 *
 *  @param armingString The arming status provided by the arming state update.
 *
 *  @return arming status
 */
+ (SAVSecurityEntityArmingStatus)armingStatusForString:(NSString *)armingString;

@end
