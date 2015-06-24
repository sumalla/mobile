//
//  SCUViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModelProtocols.h"

@interface SCUViewModel : NSObject <SCUViewModel>

- (void)viewWillAppear NS_REQUIRES_SUPER;
- (void)viewWillDisappear NS_REQUIRES_SUPER;

- (void)registerStates;

- (void)unregisterStates;

@end
