//
//  SCUDynamicButtonsCollectionViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEditableButtonsCollectionViewModel.h"

@protocol SCUDynamicButtonsCollectionViewModelDelegate <NSObject>

- (void)presentAddButtonsViewController;

@end

@interface SCUDynamicButtonsCollectionViewModel : SCUEditableButtonsCollectionViewModel

@property (nonatomic, weak) id<SCUDynamicButtonsCollectionViewModelDelegate> delegate;

+ (NSString *)localizedCommand:(NSString *)command;

@property (readonly, nonatomic) NSArray *hiddenCommands;

- (void)addButton:(NSDictionary *)button;
- (void)saveOrdering;

@end