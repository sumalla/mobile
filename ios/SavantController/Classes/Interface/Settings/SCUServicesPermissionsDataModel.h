//
//  SCUServicesPermissionsDataModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import <SavantControl/SavantControl.h>

@protocol SCUServicesPermissionsDataModelDelegate <NSObject>

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUServicesPermissionsDataModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUServicesPermissionsDataModelDelegate> delegate;

- (instancetype)initWithUser:(SAVCloudUser *)user;

- (void)commit;

+ (NSArray *)localizedServiceTitlesForUser:(SAVCloudUser *)user;

@end
