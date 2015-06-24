//
//  SCUPagedViewControl.h
//  SavantController
//
//  Created by Stephen Silber on 4/17/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

@protocol SCUPagedViewControlDelegate <NSObject>

@optional

- (void)pageChanged:(NSUInteger)page;

@end

@interface SCUPagedViewControl : UIView

@property (nonatomic, weak) id<SCUPagedViewControlDelegate> delegate;

@property (nonatomic) NSUInteger currentPage;

@property (nonatomic, readonly) UIView *currentView;

- (instancetype)initWithViews:(NSArray *)views;

- (NSUInteger)numberOfPages;

@end
