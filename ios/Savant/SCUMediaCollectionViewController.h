//
//  SCUMediaCollectionViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"
#import "SCUMediaDataModel.h"

@interface SCUMediaCollectionViewController : SCUModelCollectionViewController

- (instancetype)initWithModel:(SCUMediaDataModel *)mediaModel;

@end
