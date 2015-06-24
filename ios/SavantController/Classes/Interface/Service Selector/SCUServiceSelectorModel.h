//
//  SCUServiceSelectorModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"
#import "SCUButton.h"

typedef NS_ENUM(NSUInteger, SCUServiceSelectorModelCellType)
{
    SCUServiceSelectorModelCellTypePlaceholder,
    SCUServiceSelectorModelCellTypeNormal,
};

@protocol SCUServiceSelectorModelDelegate;

@interface SCUServiceSelectorModel : SCUExpandableDataSourceModel

@property (nonatomic, weak) id<SCUServiceSelectorModelDelegate> delegate;

- (void)listenToSwitch:(UISwitch *)toggleSwith forIndexPath:(NSIndexPath *)indexPath;

- (void)listenToSwitch:(UISwitch *)toggleSwith forChildIndexPath:(NSIndexPath *)childIndexPath below:(NSIndexPath *)indexPath;

- (void)listenToPowerButton:(SCUButton *)powerButton forIndexPath:(NSIndexPath *)indexPath;

- (void)listenToPowerButton:(SCUButton *)powerButton forChildIndexPath:(NSIndexPath *)childIndexPath below:(NSIndexPath *)indexPath;

@end

@protocol SCUServiceSelectorModelDelegate <NSObject>

- (void)reloadTable;

- (void)resetTableToTop;

- (void)toggleIndexPath:(NSIndexPath *)indexPath;

@end
