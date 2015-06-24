//
//  SCUToolbarButtonAnimated.h
//  SavantController
//
//  Created by Julian Locke on 11/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToolbarButton.h"

@interface SCUToolbarButtonAnimated : SCUToolbarButton

- (instancetype)initWithTitle:(NSString *)title;
- (void)animateButton:(BOOL)shouldAnimate;

@end
