//
//  SCUIconSelectView.h
//  SavantController
//
//  Created by Stephen Silber on 1/19/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

@protocol SCUIconSelectViewDelegate <NSObject>

- (void)selectedIndex:(NSInteger)index forImage:(NSString *)imageName;

@end

@interface SCUIconSelectView : UIView

- (instancetype)initWithImages:(NSArray *)images;

- (void)selectIndex:(NSInteger)index;

@property (nonatomic, weak) id<SCUIconSelectViewDelegate> delegate;

@end
