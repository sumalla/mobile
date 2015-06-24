//
//  SCUEditableCollectionViewCell.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewCell.h"

extern NSInteger const SCUButtonCollectionViewCellPlaceHolderTag;

@protocol SCUCollectionViewCellDeleteButtonDelegate <NSObject>

- (void)removeCell:(UICollectionViewCell *)cell;

@end

@interface SCUEditableCollectionViewCell : SCUButtonCollectionViewCell

@property (nonatomic) CGSize deleteButtonSize;
@property (strong, nonatomic) NSString *deleteButtonImageName;
@property (weak, nonatomic) id<SCUCollectionViewCellDeleteButtonDelegate> delegate;

- (void)showDeleteButton:(BOOL)show;
- (void)configureWithInfo:(NSDictionary *)info andPlaceHolderView:(UIView *)phView;

@end