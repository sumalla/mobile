//
//  SCUUserPermissionsTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCURoomsPermissionsDataModel.h"
#import "SCUServicesPermissionsDataModel.h"

@interface SCUUserPermissionsTableViewController : SCUModelTableViewController

- (instancetype)initWithRoomsModel:(SCURoomsPermissionsDataModel *)roomsModel;

- (instancetype)initWithServicesModel:(SCUServicesPermissionsDataModel *)servicesModel;

@end
