//
//  SCUCollectionViewFlowLayout.h
//  SavantController
//
//  Created by Jason Wolkovitz on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic) NSUInteger numberOfColumns, numberOfRows;

@property (nonatomic) NSUInteger maxNumberOfRows, minNumberOfRows;

@property (nonatomic) CGFloat spaceBetweenItems;

@property (nonatomic, readonly) CGFloat cellWidth, cellHeight;

@property (nonatomic) BOOL squareCells;

@property (nonatomic) BOOL stickyHeader;

@end
