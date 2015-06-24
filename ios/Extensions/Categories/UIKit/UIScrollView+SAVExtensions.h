//
//  UIScrollView+SAVExtensions.h
//  SavantExtensions
//
//  Created by Nathan Trapp on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIScrollView (SAVExtensions)

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
