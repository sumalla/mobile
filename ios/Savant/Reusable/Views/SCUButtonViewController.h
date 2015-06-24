//
//  SCUButtonViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewController.h"

@interface SCUButtonViewController : UIViewController

- (instancetype)initWithCommands:(NSArray *)commands;

- (instancetype)initWithCollectionViewController:(SCUButtonCollectionViewController *)collectionViewController;

@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) NSUInteger numberOfRows;

@property (nonatomic) NSUInteger maxNumberOfRows;
@property (nonatomic) NSUInteger minNumberOfRows;

@property (nonatomic) CGFloat spaceBetweenItems;

@property (nonatomic) UIColor *tintColor;
@property (nonatomic) NSArray *commands;

@property (nonatomic) BOOL squareCells;

@property (nonatomic, weak) id<SCUButtonCollectionViewControllerDelegate> delegate;

@property (nonatomic, readonly) SCUButtonCollectionViewController *collectionViewController;

@property (nonatomic, readonly) BOOL needsFlushConstraints;

@end
