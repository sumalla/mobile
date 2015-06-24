//
//  SCUCDServiceViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

@protocol SCUCDServiceViewModelDelegate;
@class SCUButton;

@interface SCUCDServiceViewModel : SCUServiceViewModel

@property (nonatomic, weak) id <SCUCDServiceViewModelDelegate> delegate;

- (void)toggleShuffle:(SCUButton *)sender;
- (void)toggleRepeat:(SCUButton *)sender;

@end

@protocol SCUCDServiceViewModelDelegate <NSObject>

- (void)diskChanged:(NSString *)disk;
- (void)trackChanged:(NSString *)track;
- (void)progressChanged:(NSString *)progress;

@end
