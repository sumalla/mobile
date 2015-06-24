//
//  SCUSecuritySensorCell.h
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUSecuritySensorCellKeyIsBypassed;
extern NSString *const SCUSecuritySensorCellKeyHasBypass;
extern NSString *const SCUSecuritySensorCellKeyStatus;
extern NSString *const SCUSecuritySensorCellKeyDetailedStatus;
extern NSString *const SCUSecuritySensorCellKeyIdentifier;

@class SCUButton;

@interface SCUSecuritySensorCell : SCUDefaultTableViewCell

@property (readonly) SCUButton *bypassButton;

@end
