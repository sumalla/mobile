//
//  SCUGraph.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUGraphLineStyle)
{
    SCUGraphStyle_Standard,
    SCUGraphStyle_Dashed,
    SCUGraphStyle_Dotted
};

@protocol SCUGraphDataSource;

@interface SCUGraph : UIView

- (void)reloadData:(BOOL)animated;

@property (nonatomic, weak) id <SCUGraphDataSource> dataSource;

@property (nonatomic) BOOL smoothing;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) SCUGraphLineStyle lineStyle;
@property (nonatomic) UIColor *lineColor;
@property (nonatomic) NSInteger identifer;

@property CGFloat minimumValue, maximumValue;

@end

@protocol SCUGraphDataSource <NSObject>

- (NSUInteger)numberOfVerticalValuesInGraph:(SCUGraph *)graph;
- (CGFloat)graph:(SCUGraph *)graph verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex;

@end
