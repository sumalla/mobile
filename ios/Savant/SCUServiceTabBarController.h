//
//  SCUServiceTabBarController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTabBarController.h"
#import "SCUServiceViewProtocol.h"

@interface SCUServiceTabBarController : SCUTabBarController <SCUServiceViewProtocol>

@property (nonatomic) SCUServiceViewModel *model;
@property (nonatomic, getter = isServicesFirst) BOOL servicesFirst;

@end
