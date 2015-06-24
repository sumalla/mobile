//
//  SCUServiceViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;
@import SDK;

extern NSTimeInterval const SCUServiceModelDefaultHoldInterval;

@interface SCUServiceViewModel : NSObject

@property (nonatomic, readonly) SAVService *service;
@property (nonatomic) SAVServiceGroup *serviceGroup;
@property (nonatomic, readonly) NSString *stateScope;

@property (nonatomic) NSArray *radioCommands;

- (instancetype)initWithService:(SAVService *)service;

/**
 *  Send a command to the system for the current service model.
 *
 *  @param command Command String
 */
- (void)sendCommand:(NSString *)command;

/**
 *  Send a command to the system with arguments for the current service model.
 *
 *  @param command       Command String
 *  @param arguments     Command arguments
 */
- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments;

/**
 *  Send an arbitrary command to the system.
 *
 *  @param serviceRequest A service request object that represents the destination command.
 */
- (void)sendServiceRequest:(SAVServiceRequest *)serviceRequest;


/**
 *  Send a batch of arbitrary command to the system.
 *
 *  @param serviceRequests An array of service request objects that represents the destination commands.
 */
- (void)sendServiceRequests:(NSArray *)serviceRequests;

/**
 *  Send a command repeatedly to the system for the current service model.
 *
 *  @param command  Command string
 *  @param interval The interval to send the command string on
 */
- (void)sendHoldCommand:(NSString *)command withInterval:(NSTimeInterval)interval;

/**
 *  End a hold command.
 */
- (void)endHoldCommandWithCommand:(NSString *)command;

// wrapper methods for getting commands from SAVData
@property (nonatomic, readonly, copy) NSArray *serviceCommands;

@property (nonatomic, readonly, copy) NSArray *transportCommands;
@property (nonatomic, readonly, copy) NSArray *transportGenericCommands;
@property (nonatomic, readonly, copy) NSArray *transportBackCommands;
@property (nonatomic, readonly, copy) NSArray *transportForwardCommands;
@property (nonatomic, readonly, copy) NSArray *numberPadCommands;
@property (nonatomic, readonly, copy) NSArray *channelCommands;
@property (nonatomic, readonly, copy) NSArray *pageCommands;
@property (nonatomic, readonly, copy) NSArray *navigationCommands;

@property (nonatomic, readonly, copy) NSArray *volumeCommands;
@property (nonatomic, readonly, copy) NSArray *powerCommands;

@property (nonatomic, readonly, copy) NSDictionary *dynamicCommands;
@property (nonatomic, copy) NSArray *favorites;
@property (nonatomic, readonly, copy) NSArray *disSendFavoriteCommands;

- (void)setOrderOfCommands:(NSDictionary *)orderedAndHiddenCommandsDict;

@property BOOL shouldPowerOn;
@property (nonatomic, getter = isServicesFirst) BOOL servicesFirst;

- (void)viewWillAppear;

- (void)viewWillDisappear;

@end