//
//  SCUDefaultCollectionViewCell.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;

extern NSString *const SCUDefaultCollectionViewCellKeyTitle;
extern NSString *const SCUDefaultCollectionViewCellKeyModelObject;

@interface SCUDefaultCollectionViewCell : UICollectionViewCell

@property (nonatomic, readonly) UILabel *textLabel;

- (void)configureWithInfo:(NSDictionary *)info;

@end