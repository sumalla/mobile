//
//  SCUModelViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"

@interface SCUModelViewController : UIViewController

#pragma mark - Methods to subclass

@property (nonatomic, readonly, strong) id<SCUViewModel> viewModel;

@end
