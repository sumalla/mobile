//
//  SCUSecurityModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

@protocol SCUSecurityModelDelegate;

@class SAVService, SAVSecurityEntity;

@interface SCUSecurityModel : SCUServiceViewModel

@property (weak) id <SCUSecurityModelDelegate> delegate;

/**
 *  A list of available security system components.
 */
@property (readonly, nonatomic) NSArray *systems;

/**
 *  Select a system from the list of available security systems.
 *
 *  @param componentName the name of the system.
 */
- (void)selectSecuritySystem:(NSString *)componentName;

/**
 *  The currently selected security system component.
 */
@property (readonly) NSString *currentSystem;

/**
 *  A list of partitions for the currently selected system.
 */
@property (readonly, nonatomic) NSArray *partitions;

/**
 *  A list of sensors for the currently selected system.
 */
@property (readonly, nonatomic) NSArray *sensors;

/**
 *  A flag indicating whether the currently selected system is a user security system.
 */
@property (readonly, nonatomic, getter = isUserSecurity) BOOL userSecurity;

/**
 *  The service for the currently selected system.
 */
@property (readonly, nonatomic) SAVService *service;

/**
 *  Sensor counts
 */
@property (readonly, nonatomic) NSUInteger unknownSensors;
@property (readonly, nonatomic) NSUInteger readySensors;
@property (readonly, nonatomic) NSUInteger troubleSensors;
@property (readonly, nonatomic) NSUInteger criticalSensors;

@property (readonly) NSUInteger userNumber;

- (SAVSecurityEntity *)sensorForSensorNumber:(NSString *)sensorKey;
- (SAVSecurityEntity *)sensorForIdentifier:(NSInteger)identifier;

@end

@protocol SCUSecurityModelDelegate <NSObject>

@optional
- (void)securitySystemSensorCountDidChange:(NSString *)componentName;
- (void)securitySystemDidChange:(NSString *)componentName;

@end
