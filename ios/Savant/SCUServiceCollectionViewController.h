//
//  SCUServiceCollectionViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"
#import "SCUServiceViewProtocol.h"

@interface SCUServiceCollectionViewController : SCUModelCollectionViewController <SCUServiceViewProtocol>

@property (nonatomic) SCUServiceViewModel *model;
@property (nonatomic, getter = isServicesFirst) BOOL servicesFirst;

@end
