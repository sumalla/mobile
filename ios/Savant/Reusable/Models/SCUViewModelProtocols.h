//
//  SCUTableViewModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
@import Extensions;

#pragma mark - SCUViewModel methods

@protocol SCUViewModel <NSObject>

@optional

- (void)viewWillAppear;

- (void)viewDidAppear;

- (void)viewWillDisappear;

- (void)viewDidDisappear;

@end

#pragma mark - SCUDataSourceModel methods

@protocol SCUDataSourceModel <SCUViewModel>

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfSections;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;

@optional

- (void)loadDataIfNecessary;

- (NSArray *)dataSource;

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)configureCell:(id)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath;

/* table view only methods */

- (NSArray *)sectionIndexTitles;

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)sectionTitleIndex;

- (NSString *)titleForHeaderInSection:(NSInteger)section;

- (NSString *)titleForFooterInSection:(NSInteger)section;

- (NSUInteger)headerTypeForSection:(NSInteger)section;

- (void)accessoryButtonTappedAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

/* table view swipe cell methods */

- (BOOL)shouldAllowSwipingForIndexPath:(NSIndexPath *)indexPath;

- (void)buttonWasTappedAtIndex:(NSUInteger)index atIndexPath:(NSIndexPath *)indexPath;

- (BOOL)canDeleteIndexPath:(NSIndexPath *)indexPath;

- (void)commitDeleteForIndexPath:(NSIndexPath *)indexPath;

/* collection view only methods */

- (id)modelObjectForSection:(NSInteger)section;

- (void)didEndDisplayingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)willBegingDisplayingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)didBegingDisplayingItemAtIndexPath:(NSIndexPath *)indexPath;

/* section methods */

- (BOOL)isFlat;

- (NSArray *)arrayForSection:(NSInteger)section;

@end

@protocol SCUExpandableDataSourceModel <SCUDataSourceModel>

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

- (BOOL)toggleIndexPath:(NSIndexPath *)indexPath;

- (void)setExpandedIndexPaths:(NSArray *)indexPaths;

- (NSArray *)expandedIndexPaths;

- (NSIndexPath *)absoluteIndexPathForRelativeIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)absoluteIndexPathForRelativeChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)relativeIndexPathForAbsoluteIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)expandedRowsBeforeIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)parentForAbsoluteIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)cellTypeForAbsoluteIndexPath:(NSIndexPath *)indexPath;

- (id)modelObjectForAbsoluteIndexPath:(NSIndexPath *)indexPath;

@optional

- (void)selectChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

- (void)configureCell:(id)cell withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath;

- (void)updateExpandedIndexPaths:(NSArray *)expandedIndexPaths;

@end
