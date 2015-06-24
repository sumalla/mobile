//
//  SCUServiceSelectorTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUButton.h"

extern NSString *const SCUServiceSelectorTableViewCellKeyServiceIconName;
extern NSString *const SCUServiceSelectorTableViewCellKeyIsPowered;
extern NSString *const SCUServiceSelectorTableViewCellKeyShowsPowerButton;
extern NSString *const SCUServiceSelectorTableViewCellKeyExpandableImage;

typedef NS_ENUM(NSUInteger, SCUServiceSelectorTableViewCellExpandableImageType)
{
    SCUServiceSelectorTableViewCellExpandableImageTypeNone,
    SCUServiceSelectorTableViewCellExpandableImageTypeFirstAndMiddle,
    SCUServiceSelectorTableViewCellExpandableImageTypeLast
};

@interface SCUServiceSelectorTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) SCUButton *powerButton;

@end
