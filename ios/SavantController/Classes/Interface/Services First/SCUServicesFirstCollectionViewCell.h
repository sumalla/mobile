//
//  SCUServicesFirstCollectionViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultEditableCollectionViewCell.h"
#import "SCUAnimatedLabel.h"

extern NSString *const SCUServicesFirstCollectionViewCellSubordinateTextKey;
extern NSString *const SCUServicesFirstCollectionViewCellSubordinateTextColorKey;
extern NSString *const SCUServicesFirstCollectionViewCellSupplimentaryTextKey;
extern NSString *const SCUServicesFirstCollectionViewCellSupplimentaryTextColorKey;
extern NSString *const SCUServicesFirstCollectionViewCellCycleValuesKey;

@interface SCUServicesFirstCollectionViewCell : SCUDefaultEditableCollectionViewCell

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) SCUAnimatedLabel *subordinateLabel;

@end
