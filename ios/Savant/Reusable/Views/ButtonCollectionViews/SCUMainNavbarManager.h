//
//  SCUMainNavbarManager.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMainToolbarManager.h"

typedef NS_OPTIONS(NSUInteger, SCUMainNavbarItems)
{
    SCUMainNavbarItemsNone = 0,
    SCUMainNavbarItemsDefault = 1 << 0,
    SCUMainNavbarItemsCustom = 1 << 1,
    SCUMainNavbarItemsLeftButtons = 1 << 2,
    SCUMainNavbarItemsRightButtons = 1 << 3,
    SCUMainNavbarItemsLeftSpacing = 1 << 4,
    SCUMainNavbarItemsRightSpacing = 1 << 5,
    SCUMainNavbarItemsServiceSelector = 1 << 6,
    SCUMainNavbarItemsEntertainment = 1 << 7,
    SCUMainNavbarItemsNavigation = 1 << 8
};

@protocol SCUMainNavbarManager <SCUMainToolbarManager>

- (SCUMainNavbarItems)mainNavbarItems;

@optional

- (NSArray *)mainNavbarLeftButtonItems;
- (NSArray *)mainNavbarRightButtonItems;

- (NSNumber *)mainNavbarItemsLeftSpacing;
- (NSNumber *)mainNavbarItemsRightSpacing;

@end