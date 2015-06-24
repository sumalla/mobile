//
//  SCUTransportButtonCollectionViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonCollectionViewController.h"

@interface SCUTransportButtonCollectionViewController : SCUButtonCollectionViewController

- (instancetype)initWithGenericCommands:(NSArray *)commands backCommands:(NSArray *)backCommands forwardCommands:(NSArray *)forwardCommands;

@property (nonatomic) BOOL singleRow;

@property (nonatomic) NSInteger columns;

@end
