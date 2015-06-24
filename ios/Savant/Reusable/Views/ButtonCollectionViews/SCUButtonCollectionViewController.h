//
//  SCUButtonCollectionViewController.h
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"
#import "SCUButtonCollectionViewModel.h"

@protocol SCUButtonCollectionViewControllerDelegate;
@class SCUButtonCollectionViewCell;

@interface SCUButtonCollectionViewController : SCUModelCollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

- (instancetype)initWithCommands:(NSArray *)commands;

@property (nonatomic, weak) id<SCUButtonCollectionViewControllerDelegate> delegate;

@property (nonatomic) NSArray *commands;

@property (nonatomic) UIColor *tintColor;

@property (nonatomic) BOOL squareCells;

@end

@protocol SCUButtonCollectionViewControllerDelegate <NSObject>

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command;

@optional

- (void)tappedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command;

- (void)setOrderOfDynamicCommands:(NSDictionary *)orderedAndHiddenCommandsDict;

- (void)updateFavoritesList:(NSArray *)updatedFavoritesList;

@end
