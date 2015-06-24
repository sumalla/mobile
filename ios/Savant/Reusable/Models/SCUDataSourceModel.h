//
//  SCUTableViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"

@interface SCUDataSourceModel : SCUViewModel <SCUDataSourceModel>

- (BOOL)isIndexPathValid:(NSIndexPath *)indexPath;

@end
