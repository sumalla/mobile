//
//  SCUSwingingViewController.h
//  SavantController
//
//  Created by Stephen Silber on 8/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

#import "SCUModelTableViewController.h"

//-------------------------------------------------------------------
// secondaryViewController must call contentOffsetDidChange on using
// UITableView delegate and the scrollViewDidScroll call
//-------------------------------------------------------------------
@protocol SCUSwingingAnimator <NSObject>

- (void)contentOffsetDidChange:(UIScrollView *)scrollView;

@end

@protocol SCUSwingingAnimatorDelegate <NSObject>

@property (nonatomic, weak) id<SCUSwingingAnimator> swingingDelegate;

@end

@interface SCUSwingingViewController : UIViewController <SCUSwingingAnimator>

@property id<SCUSwingingAnimator> swingingAnimator;

@property (nonatomic, weak) UIViewController *rootViewController;

@property (nonatomic, weak) SCUModelTableViewController<SCUSwingingAnimatorDelegate> *secondaryViewController;

@property (nonatomic, readonly, getter = isOpen) BOOL open;

@property (nonatomic) CGFloat closeThreshold;

@property (nonatomic) CGFloat initialHeight;

@property (nonatomic) CGFloat initialSwingPadding;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController andSecondaryViewController:(SCUModelTableViewController<SCUSwingingAnimatorDelegate> *)secondaryViewController;

- (void)toggleSwinging;

- (BOOL)openWithCompletionHandler:(dispatch_block_t)completionHandler;

- (BOOL)closeWithCompletionHandler:(dispatch_block_t)completionHandler;

@end
