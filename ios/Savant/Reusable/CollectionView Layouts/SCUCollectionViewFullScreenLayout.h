//
//  SCUCollectionViewFullScreenLayout.h
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCollectionViewFlowLayout.h"

@interface SCUCollectionViewFullScreenLayout : SCUCollectionViewFlowLayout

- (void)scrollToPage:(NSUInteger)page animated:(BOOL)animated;

@property (nonatomic, readonly) NSInteger currentPage;

@end
