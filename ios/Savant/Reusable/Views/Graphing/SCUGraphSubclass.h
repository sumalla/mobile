//
//  SCUGraphSubclass.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGraph.h"

@interface SCUGraphPoint : NSObject

@property CGFloat x;
@property CGFloat y;
@property CGFloat value;

@property (nonatomic, readonly) CGPoint point;

@end

@interface SCUGraph ()

@property (nonatomic, readonly) CAShapeLayer *layer;

- (void)buildPointsData:(dispatch_block_t)completion;
- (void)drawPointsData:(BOOL)animated;
- (void)styleLayer;
- (BOOL)allowZeroValues;
- (void)animatePath;

@property (nonatomic, copy) NSArray *points;

@end
