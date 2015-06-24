//
//  SCUAnimator.h
//  SavantController
//
//  Created by Nathan Trapp on 7/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUAnimatorType)
{
    SCUAnimatorTypePresent,
    SCUAnimatorTypeDismiss
};

@interface SCUAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property SCUAnimatorType type;

@end
