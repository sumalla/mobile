//
//  SCUEditableButtonsCollectionViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceCollectionViewController.h"
#import "SCUEditableButtonsCollectionViewModel.h"
#import "SCUMainToolbarManager.h"
#import "SCUMainNavbarManager.h"

@interface SCUEditableButtonsCollectionViewController : SCUServiceCollectionViewController

@property (nonatomic, readonly) SCUEditableButtonsCollectionViewModel *dataModel;

- (instancetype)initWithModel:(SCUEditableButtonsCollectionViewModel *)model;

- (Class)normalCellClass;

- (SCUReorderableTileLayout *)tileLayout;

@end
