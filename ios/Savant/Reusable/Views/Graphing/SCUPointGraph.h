//
//  SCUPointGraph.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGraph.h"

@interface SCUPointGraph : SCUGraph

@property UIColor *pointColor;
@property CGFloat pointRadius;
@property CGSize pointSize;
@property BOOL displayLabel;
@property UIColor *labelColor;
@property UIFont *labelFont;

@end
