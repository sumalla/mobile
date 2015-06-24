//
//  SCUGenericCommandTableModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 10/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@interface SCUGenericCommandTableModel : SCUDataSourceModel

- (instancetype)initWithCommands:(NSArray *)commands;

@end
