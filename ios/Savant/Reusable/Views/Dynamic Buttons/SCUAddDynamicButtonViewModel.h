//
//  SCUAddDynamicButtonViewModel.h
//  SavantController
//
//  Created by Jason Wolkovitz on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@protocol SCUAddDynamicButtonViewModelDelegate <NSObject>

- (void)addButton:(NSDictionary *)button;

@end

@interface SCUAddDynamicButtonViewModel : SCUDataSourceModel

@property (weak) id <SCUAddDynamicButtonViewModelDelegate> delegate;

- (instancetype)initWithCommands:(NSArray *)commands;

@end
