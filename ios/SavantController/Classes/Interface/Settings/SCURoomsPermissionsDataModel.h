//
//  SCURoomsPermissionsDataModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>

@protocol SCURoomsPermissionsDataModelDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCURoomsPermissionsDataModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCURoomsPermissionsDataModelDelegate> delegate;

- (instancetype)initWithUser:(SAVCloudUser *)user;

- (void)commit;

@end
