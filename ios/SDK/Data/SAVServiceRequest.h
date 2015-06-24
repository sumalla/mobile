//
//  SAVServiceRequest.h
//  SavantControl
//
//  Created by Ian Mortimer on 12/6/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

@import Foundation;
#import "SAVMessages.h"

@interface SAVServiceRequest : SAVMessage <NSCopying>

//-------------------------------------------------------------------
// CBP TODO: FIX ME
//-------------------------------------------------------------------
#define SAVMESSAGE_SERVICE_REQUEST_COMMAND @"request"
#define SAVMESSAGE_ZONE_KEY @"zone"
#define SAVMESSAGE_COMPONENT_KEY @"component"
#define SAVMESSAGE_LOGICAL_COMPONENT_KEY @"logicalComponent"
#define SAVMESSAGE_VARIANT_ID_KEY @"variantID"
#define SAVMESSAGE_SERVICE_TYPE_KEY @"serviceType"
#define SAVMESSAGE_REQUEST_KEY @"request"
#define SAVMESSAGE_REQUEST_ARGS_KEY @"requestArgs"

@property NSString *zoneName;
@property NSString *component;
@property NSString *logicalComponent;
@property NSString *variantId;
@property NSString *serviceId;
@property NSString *request;
@property NSDictionary *requestArguments;

- (instancetype)initWithService:(SAVService *)service;

- (void)setService:(SAVService *)service;

- (BOOL)isEqualToRequest:(SAVServiceRequest *)request;

@end
