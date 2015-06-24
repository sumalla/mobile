//
//  SAVServicePrivate.h
//  SavantControl
//
//  Created by Cameron Pulsford on 1/21/15.
//  Copyright (c) 2015 Savant Systems, LLC. All rights reserved.
//

#import "SAVService.h"

@interface SAVService ()

@property (nonatomic, nullable) NSString *zoneName;
@property (nonatomic, nullable) NSString *component;
@property (nonatomic, nullable) NSString *logicalComponent;
@property (nonatomic, nullable) NSString *variantId;
@property (nonatomic, nullable) NSString *serviceId;
@property (nonatomic, nullable) NSString *alias;
@property (nonatomic, nullable) NSString *serviceAlias;
@property (nonatomic, nullable) NSString *connectorId;
@property (nonatomic, nullable) NSArray *capabilities;
@property (nonatomic) SAVServiceAVIOType avioType;
@property (nonatomic) SAVServiceOutputType outputType;
@property (nonatomic) BOOL discreteVolume;
@property (nonatomic) BOOL hidden;

@end
