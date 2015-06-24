//
//  SCUReorderableTileLayoutSpanPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUReorderableTileLayoutSpan () <NSCopying>

@property (nonatomic) NSUInteger row;
@property (nonatomic) NSUInteger column;

- (void)normalizeWithNumberOfColumns:(NSUInteger)numberOfColumns;

- (CGRect)frameWithPadding:(CGFloat)padding baseSize:(CGSize)baseSize insets:(UIEdgeInsets)insets;

- (BOOL)isEqualToSpan:(SCUReorderableTileLayoutSpan *)span;

@end
