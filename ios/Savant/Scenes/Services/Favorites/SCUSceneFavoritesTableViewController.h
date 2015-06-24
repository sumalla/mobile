//
//  SCUSceneFavoritesTableViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"

@class SCUSceneFavoritesDataSource;

@interface SCUSceneFavoritesTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUSceneFavoritesDataSource *)model;

@end
