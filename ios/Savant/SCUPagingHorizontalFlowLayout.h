//
//  SCUPagingHorizontalFlowLayout.h
//  SavantController
//
//  Created by Cameron Pulsford on 2/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUAnimationFixFlowLayout.h"

@interface SCUPagingHorizontalFlowLayout : UICollectionViewLayout

@property (nonatomic) CGFloat pageInset;
@property (nonatomic) NSUInteger numberOfColums; // The default is 1.
@property (nonatomic) CGFloat interSpace; // The default is 0.

@end
