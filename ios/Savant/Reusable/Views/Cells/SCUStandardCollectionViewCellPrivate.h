//
//  SCUStandardCollectionViewCellPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultCollectionViewCell.h"
@import Extensions;

@interface SCUStandardCollectionViewCell ()

@property (nonatomic) UIImageView *imageView;

- (UIColor *)imageTintColorWithInfo:(NSDictionary *)info;

@end
