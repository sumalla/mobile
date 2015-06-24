//
//  SCUCameraAnimator.h
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@class SCUCameraCollectionViewCell;

@interface SCUCameraAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;
@property UIImageView *cellImageView;

@end
