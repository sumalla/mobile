//
//  SCUEditableButtonsCollectionViewModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUReorderableTileLayout.h"
@import SDK;

typedef NS_ENUM(NSUInteger, SCUEditableButtonCollectionViewCellType)
{
    SCUEditableButtonCollectionViewCellTypeNormal = 0,
    SCUEditableButtonCollectionViewCellTypePlusAndTrashcan = 1
};

@interface SCUEditableButtonsCollectionViewModel : SCUDataSourceModel <SCUReorderableTileLayoutDelegate>

- (instancetype)initWithService:(SAVService *)service;

/**
 *  YES to append the plus button; otherwise, NO. The default is YES.
 */
@property (nonatomic) BOOL appendPlusButton;

@end
