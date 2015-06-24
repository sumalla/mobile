//
//  SCUChangeServerTableViewControllerModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@protocol SCUChangeServerTableViewControllerModelDelegate <NSObject>

- (void)reloadData;

@end

@interface SCUChangeServerTableViewControllerModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUChangeServerTableViewControllerModelDelegate> delegate;

@end
