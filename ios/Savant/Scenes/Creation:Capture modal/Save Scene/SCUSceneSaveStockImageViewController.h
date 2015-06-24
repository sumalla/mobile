//
//  SCUSceneSaveStockImageViewController.h
//  SavantController
//
//  Created by Stephen Silber on 10/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelCollectionViewController.h"

typedef void (^SCUStockImageCallback)();

@interface SCUSceneSaveStockImageViewController : SCUModelCollectionViewController

- (instancetype)initWithScene:(SAVScene *)scene;

@property (nonatomic, copy) SCUStockImageCallback callback;

@end
