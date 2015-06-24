//
//  UITableView+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UITableView (SAVExtensions)

- (void)sav_performUpdates:(dispatch_block_t)updates;

- (void)sav_registerClass:(Class)cellClass forCellType:(NSUInteger)cellType;

- (void)sav_scrollToTop;

- (CGFloat)sav_heightForText:(NSString *)text font:(UIFont *)font;

- (CGFloat)sav_heightForText:(NSString *)text attributes:(NSDictionary *)attributes;

@property UITableViewCellSeparatorStyle sav_separatorStyle UI_APPEARANCE_SELECTOR;

@end
