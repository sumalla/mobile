//
//  SCUToolbarButtonAnimated.h
//  SavantController
//
//  Created by Julian Locke on 11/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToolbarButton.h"

@interface SCUToolbarButtonAnimated : SCUToolbarButton

@property (nonatomic, getter = isAnimating) BOOL animating;

- (instancetype)initWithTitle:(NSString *)title;

@end
