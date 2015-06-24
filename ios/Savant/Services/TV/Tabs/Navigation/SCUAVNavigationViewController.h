//
//  SCUTVNavigationViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewController.h"
#import "SCUButtonCollectionViewController.h"
#import "SCUOverflowTableViewModel.h"
#import "SCUSwipeView.h"

@interface SCUAVNavigationViewController : SCUServiceViewController <SCUButtonCollectionViewControllerDelegate, SCUSwipeViewDelegate>

@property (nonatomic) BOOL hideBottomBar;

@property (nonatomic, readonly) CGFloat holdInterval;

@end
