//
//  SCUPopoverMenu.h
//  SavantController
//
//  Created by Nathan Trapp on 7/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void (^SCUPopoverMenuCallback)(NSInteger buttonIndex);

@interface SCUPopoverMenu : NSObject

@property (nonatomic, copy) NSArray  *buttonTitles;

@property (nonatomic, copy) SCUPopoverMenuCallback callback;

@property (nonatomic) NSInteger selectedIndex;

- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles;

- (void)showFromToolbar:(UIToolbar *)view;
- (void)showFromTabBar:(UITabBar *)view;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;
- (void)showFromView:(UIView *)view animated:(BOOL)animated;
- (void)showFromButton:(UIButton *)button animated:(BOOL)animated;

@end
