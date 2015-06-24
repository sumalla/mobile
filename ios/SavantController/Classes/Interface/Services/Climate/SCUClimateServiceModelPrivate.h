//
//  SCUClimateServiceModelPrivate.h
//  SavantController
//
//  Created by David Fairweather on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateServiceModel.h"
#import "SCUInterface.h"

@interface SCUClimateServiceModel () <SCUStateReceiver, SCUSettingsConainerViewModelCommandDelegate>

@property (nonatomic) SAVService *service;
@property (nonatomic) NSMutableDictionary *stateUpdatesDict;
@property (nonatomic) NSInteger valueInterval;

@property (nonatomic, strong) SCUSettingsConainerViewModel *settingsModel;

- (void)setSelectedMode:(SAVEntityState)mode forSettingsIndex:(NSUInteger)settingsIndex;

@end
