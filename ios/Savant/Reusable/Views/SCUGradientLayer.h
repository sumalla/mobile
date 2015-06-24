//
//  SCUGradientView.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;


@interface SCUGradientLayer : CALayer

- (instancetype)initWithFrame:(CGRect)frame andColors:(NSArray *)colors;

/**
 *  Draw a radial type gradient, setting this value with restore the start
 *  and end points to their default values.
 */
@property (nonatomic) BOOL radial;

@property (copy, nonatomic) NSArray *colors;

/* An optional array of NSNumber objects defining the location of each
 * gradient stop as a value in the range [0,1]. The values must be
 * monotonically increasing. If a nil array is given, the stops are
 * assumed to spread uniformly across the [0,1] range. When rendered,
 * the colors are mapped to the output colorspace before being
 * interpolated. Defaults to nil. Animatable. 
 */
@property (copy, nonatomic) NSArray *locations;

/* The start and end points of the gradient when drawn into the layer's
 * coordinate space. The start point corresponds to the first gradient
 * stop, the end point to the last gradient stop. Both points are
 * defined in a unit coordinate space that is then mapped to the
 * layer's bounds rectangle when drawn. (I.e. [0,0] is the bottom-left
 * corner of the layer, [1,1] is the top-right corner.) The default values
 * are [.5,0] and [.5,1] respectively. Both are animatable.
 */
@property (nonatomic) CGPoint startPoint, endPoint;


/**
 *  The start and end radius, used for radial gradients.
 */
@property (nonatomic) CGFloat startRadius, endRadius;

@end
