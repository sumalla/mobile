//
//  SCUUserSettingsTableViewControllerModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>

@protocol SCUUserSettingsTableViewControllerModelDelegate <NSObject>

- (void)reloadData;

- (void)presentSettingsForUser:(SAVCloudUser *)user;

@end

@interface SCUUserSettingsTableViewControllerModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUUserSettingsTableViewControllerModelDelegate> delegate;

@property (nonatomic, readonly) BOOL loadData;

@end
