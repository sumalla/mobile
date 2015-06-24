//
//  SCUTableViewModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@interface SCUDataSourceModel ()

@property (nonatomic, getter = isFlat, readonly) BOOL flat;

- (NSArray *)arrayForSection:(NSInteger)section;

- (id)_modelObjectForIndexPath:(NSIndexPath *)indexPath;

- (void)enumerateModelObjects:(void (^)(NSIndexPath *indexPath))enumerator;

@end
