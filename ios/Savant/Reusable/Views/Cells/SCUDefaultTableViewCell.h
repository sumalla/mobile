//
//  SCUDefaultTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwipeCell.h"

extern NSString *const SCUDefaultTableViewCellKeyTitle;
extern NSString *const SCUDefaultTableViewCellKeyTitleColor;
extern NSString *const SCUDefaultTableViewCellKeyAttributedTitle;
extern NSString *const SCUDefaultTableViewCellKeyDetailTitle;
extern NSString *const SCUDefaultTableViewCellKeyDetailTitleColor;
extern NSString *const SCUDefaultTableViewCellKeyImage;
extern NSString *const SCUDefaultTableViewCellKeyImageTintColor;
extern NSString *const SCUDefaultTableViewCellKeyRightImageName;
extern NSString *const SCUDefaultTableViewCellKeyRightImageTintColor;
extern NSString *const SCUDefaultTableViewCellKeyModelObject;
extern NSString *const SCUDefaultTableViewCellKeyAccessoryType;
extern NSString *const SCUDefaultTableViewCellKeyBottomLineType;
extern NSString *const SCUDefaultTableViewCellKeyBottomLineColor;
extern NSString *const SCUDefaultTableViewCellKeyBorderType;

typedef NS_ENUM(NSUInteger, SCUDefaultTableViewCellBottomLineType)
{
    SCUDefaultTableViewCellBottomLineTypeNone,
    SCUDefaultTableViewCellBottomLineTypeFull,
    SCUDefaultTableViewCellBottomLineTypePartial
};

typedef NS_ENUM(NSUInteger, SCUDefaultTableViewCellBorderType)
{
    SCUDefaultTableViewCellBorderTypeNone,
    SCUDefaultTableViewCellBorderTypeSection,
    SCUDefaultTableViewCellBorderTypeBottomAndSides,
    SCUDefaultTableViewCellBorderTypeCell,
    SCUDefaultTableViewCellBorderTypeTopPartial
};

@interface SCUDefaultTableViewCell : SCUSwipeCell

@property (nonatomic) UIView *customSeparator;
@property (nonatomic) NSIndexPath *indexPath;
@property (nonatomic) NSInteger numberOfRowsInSection;
@property (nonatomic) SCUDefaultTableViewCellBorderType borderType UI_APPEARANCE_SELECTOR;
@property (nonatomic) SCUDefaultTableViewCellBottomLineType bottomLineType UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *bottomLineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat bottomLineOffset UI_APPEARANCE_SELECTOR;
@property (nonatomic, getter = isBottomLineOffsetRelative) CGFloat bottomLineOffsetRelative UI_APPEARANCE_SELECTOR;

@end
