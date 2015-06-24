//
//  SCUMainToolbarManager.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

typedef NS_OPTIONS(NSUInteger, SCUMainToolbarItems)
{
    SCUMainToolbarItemsNone = 0,
    SCUMainToolbarItemsServiceSelector = 1 << 0,
    SCUMainToolbarItemsVolumeControl = 1 << 1,
    SCUMainToolbarItemsLeftButtons = 1 << 2,
    SCUMainToolbarItemsRightButtons = 1 << 3,
    SCUMainToolbarItemsBarTintColor = 1 << 4,
    SCUMainToolbarItemsLeftSpacing = 1 << 5,
    SCUMainToolbarItemsRightSpacing = 1 << 6,
    SCUMainToolbarItemsCenterSpacing = 1 << 7,
    SCUMainToolbarItemsCenterButtons = 1 << 8
};

@class SAVServiceGroup;

@protocol SCUMainToolbarManager <NSObject>

@optional

- (BOOL)mainToolbarIsVisible;

- (BOOL)forceSlingshot;

- (SCUMainToolbarItems)mainToolbarItems;

/**
 *  An array of items to populate the left half of the toolbar.
 *
 *  @return An array of views and view controllers.
 */
- (NSArray *)mainToolbarLeftItems;

/**
 *  An array of items to populate the right half of the toolbar.
 *
 *  @return An array of views and view controllers.
 */
- (NSArray *)mainToolbarRightItems;

/**
 *  An array of items to populate the center of the toolbar.
 *
 *  @return An array of views and view controllers.
 */
- (NSArray *)mainToolbarCenterItems;

- (UIColor *)mainToolbarTintColor;

/**
 *  Spacing between toolbar items.
 *
 *  @return A number representing the spacing between toolbar items, if not provided system default is used.
 */
- (NSNumber *)mainToolbarItemLeftSpacing;
- (NSNumber *)mainToolbarItemRightSpacing;
- (NSNumber *)mainToolbarItemCenterSpacing;

- (SAVServiceGroup *)serviceGroup;
- (BOOL)isServicesFirst;

@end
