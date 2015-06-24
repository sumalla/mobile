//
//  SCUScenesSelectedServiceModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"

@interface SCUScenesSelectedServiceModel : SCUSceneCreationDataSource

- (void)prepareData;
- (SAVService *)serviceForIndexPath:(NSIndexPath *)indexPath;

@end
