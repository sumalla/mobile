//
//  SCUMainToolbar.h
//  SavantController
//
//  Created by Nathan Trapp on 4/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@protocol SCUMainToolbarManager;
@class SCUToolbarButton;

extern NSString *const SCUToolbarLeftItemsKey;
extern NSString *const SCUToolbarRightItemsKey;
extern NSString *const SCUToolbarCenterItemsKey;
extern NSString *const SCUToolbarLeftItemSpacingKey;
extern NSString *const SCUToolbarRightItemSpacingKey;
extern NSString *const SCUToolbarCenterItemSpacingKey;

@interface SCUToolbar : UIView

@property (nonatomic) UIColor *barTintColor;

@property (readonly) NSArray *leftBarItems;
@property (readonly) NSArray *rightBarItems;

@property (nonatomic, readonly) CGSize leftBarItemsSize;
@property (nonatomic, readonly) CGSize rightBarItemsSize;

@property (readonly) NSNumber *leftBarItemSpacing;
@property (readonly) NSNumber *rightBarItemSpacing;

/**
 *  When enabled, the toolbar's contentView will horizontally scroll as needed.
 */
@property (nonatomic) BOOL scrolling;

/**
 *  Create a dictionary appropriate for using with @p -configureWithItems:.
 *
 *  @param leftItems    The left views/view controllers.
 *  @param leftSpacing  The left item spacing.
 *  @param rightItems   The right views/view controllers.
 *  @param rightSpacing The right item spacing.
 *
 *  @return A dictionary for use by @p -configureWithItems:.
 */
+ (NSDictionary *)itemConfigurationWithLeftItems:(NSArray *)leftItems leftSpacing:(NSUInteger)leftSpacing rightItems:(NSArray *)rightItems rightSpacing:(NSUInteger)rightSpacing;

/**
 *  Layout the toolbar with a dictionary of left and right items. Items can either be viewControllers
 *  or views and should be defined using the keys: SCUToolbarLeftItemsKey, SCUToolbarLeftItemSpacing, etc.
 *
 *  @param items Dictionary of items
 */
- (void)configureWithItems:(NSDictionary *)items;

/**
 *  Setup the tooblar with a manager object that defines what items to populate.
 *
 *  @param manager Toolbar manager
 */
- (void)configureWithManager:(id <SCUMainToolbarManager>)manager;

/**
 *  When scrolling is enabled, this will scroll the provided item into view.
 *
 *  @param item     A current left or right toolbar item.
 *  @param animated Should the transition be animated.
 */
- (void)scrollToItem:(UIView *)item animated:(BOOL)animated;

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;

@end

