//
//  SCUMediaTabBarModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"
@class SCUMediaRequestViewControllerModel;

@interface SCUMediaTabBarModel : SCUViewModel

+ (BOOL)modelObjectsRequestTabBar:(NSArray *)modelObjects;

- (instancetype)initWithModelObjects:(NSArray *)modelObjects mediaRequestModel:(SCUMediaRequestViewControllerModel *)mediaRequestModel;

@property (nonatomic, readonly, copy) NSArray *items;

- (void)transition;

@end
