//
//  SCUMediaModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
@import SDK;
@class SCUMediaRequestViewControllerModel;

extern NSString *const SCUMediaModelKeyTitle;
extern NSString *const SCUMediaModelKeySubtitle;
extern NSString *const SCUMediaModelKeyHasSubmenu;
extern NSString *const SCUMediaModelKeyIsTextfield;
extern NSString *const SCUMediaModelKeyArtworkURL;
extern NSString *const SCUMediaModelKeyQuery;
extern NSString *const SCUMediaModelKeyQueryArguments;
extern NSString *const SCUMediaModelKeyCurrentIndex;

@protocol SCUMediaDataModelDelegate;

@interface SCUMediaDataModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUMediaDataModelDelegate> delegate;
@property (nonatomic, getter = isScene) BOOL scene;
@property (nonatomic) NSIndexPath *selectedIndexPath;

+ (BOOL)isSearchNode:(NSDictionary *)query;

- (instancetype)initWithModelObjects:(NSArray *)modelObjects mediaModel:(SCUMediaRequestViewControllerModel *)mediaModel service:(SAVService *)service;

- (void)stopLoadingIndicator;

- (BOOL)hasArtworkForIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)artworkForIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUMediaDataModelDelegate <NSObject>

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

- (void)setArtwork:(UIImage *)artwork forIndexPath:(NSIndexPath *)indexPath;

@optional

- (void)addCheckmarkAtIndexPath:(NSIndexPath *)indexPath;

@end
