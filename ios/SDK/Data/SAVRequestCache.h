//
//  SAVRequestCache.h
//  SavantControl
//
//  Created by Nathan Trapp on 10/17/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@class SAVService;

@interface SAVRequestCache : NSObject

+ (instancetype)sharedInstance;

- (NSArray *)commandsForService:(SAVService *)service;
- (NSArray *)customCommandsForService:(SAVService *)service;
- (NSArray *)channelCommandsForService:(SAVService *)service;
- (NSArray *)pageCommandsForService:(SAVService *)service;
- (NSArray *)numberPadCommandsForService:(SAVService *)service;
- (NSArray *)navigationCommandsForService:(SAVService *)service;
- (NSArray *)dynamicCommandsForService:(SAVService *)service;
- (NSArray *)volumeCommandsForService:(SAVService *)service;
- (NSArray *)powerCommandsForService:(SAVService *)service;
- (NSArray *)transportCommandsForService:(SAVService *)service;
- (NSArray *)transportBackCommandsForService:(SAVService *)service;
- (NSArray *)transportForwardCommandsForService:(SAVService *)service;
- (NSArray *)favoriteCommandsForService:(SAVService *)service;
- (NSArray *)transportGenericCommandsForService:(SAVService *)service;

@end
