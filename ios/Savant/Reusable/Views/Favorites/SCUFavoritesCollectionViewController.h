//
//  SCUScenesViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceCollectionViewController.h"

@class SCUFavoritesCollectionViewModel;

@interface SCUFavoritesCollectionViewController : SCUServiceCollectionViewController

- (instancetype)initWithModel:(SCUFavoritesCollectionViewModel *)model;

@property (nonatomic, getter = isServicesFirst) BOOL servicesFirst;

@end
