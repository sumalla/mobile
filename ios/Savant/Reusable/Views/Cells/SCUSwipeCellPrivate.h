//
//  SCUSwipeCellPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 6/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwipeCell.h"

@interface SCUSwipeCell ()

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, readonly) CGFloat leftContentOffset;

@property (nonatomic, readonly) BOOL pinAccessoryViewToRight;

@end
