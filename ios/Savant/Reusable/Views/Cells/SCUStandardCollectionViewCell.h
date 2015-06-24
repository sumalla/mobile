//
//  SCUStandardCollectionViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultCollectionViewCell.h"

extern NSString *const SCUDefaultCollectionViewCellKeyImage;

@interface SCUStandardCollectionViewCell : SCUDefaultCollectionViewCell

@property (nonatomic, readonly) UIImageView *backgroundImageView;

@end
