//
//  SCUSliderPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSlider.h"
@import Extensions;

#define ANIMATION_CONSTANT 1

@interface SCUSlider ()

@property (nonatomic) UIView *trackView;
@property (nonatomic) UIView *fillView;

/**
 *  Update the look of slider given the new percentage. Manipulate the track view, fill view, and any other views as necessary.
 *
 *  @param percentage The percentage of the slider (0 -> 1).
 */
- (void)updateFillWithPercentage:(CGFloat)percentage;

/**
 *  Normalize the given point. This could be used to add center snapping based on some threshold.
 *
 *  @param point The current point.
 *  @param isTap YES if the point was caused by a tap; NO if point was caused by the slider.
 *
 *  @return The normalized point.
 */
- (CGPoint)normalizedPointFromPoint:(CGPoint)point isTap:(BOOL)isTap;

@end
