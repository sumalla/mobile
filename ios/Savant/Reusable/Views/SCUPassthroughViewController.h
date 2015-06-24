//
//  SCUPassthroughViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SCUToolbar.h"
#import "SCUPassthroughSupplementaryViewController.h"
@import Extensions;

@interface SCUPassthroughViewController : UIViewController

@property (nonatomic) UIViewController *rootViewController;

@property (nonatomic) UIEdgeInsets edgeInsets;

@property (nonatomic) UIColor *backgroundColor;

@property (nonatomic) UIView *footerView;

@property (nonatomic) CGFloat footerHeight;

@property (nonatomic) BOOL detectUserInteraction;

@property (nonatomic, readonly, getter = isSupplementaryViewVisible) BOOL supplementaryViewVisible;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

- (void)configureToolbar;

- (void)setSupplementaryViewController:(SCUPassthroughSupplementaryViewController *)viewController withPinningOptions:(SAVViewPinningOptions)options size:(CGFloat)size;

@end

@interface UIViewController (Optional)

- (void)userInteractionDetected:(CGPoint)pont;

@end
