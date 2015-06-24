//
//  SCUNowPlayingModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingModel.h"

@interface SCUNowPlayingModel ()

@property (nonatomic, readonly, copy) NSDictionary *stateNamesToDelegateSelectors; /* { stateName -> delegateSelector } */

@property (nonatomic, readonly, copy) NSArray *stateNamesEffectingVisibility;

/**
 *  Inspect the states and determine if the toolbar should be visible or hidden. You shouldn't normally need to override this.
 *
 *  @param stateValues The state values to consider.
 *
 *  @return YES to show the toolbar; otherwise, NO.
 */
- (BOOL)toolbarVisibleStateForStates:(NSDictionary *)stateValues;

- (NSString *)commandWithButtonType:(SCUNowPlayingModelTransportButtonType)buttonType forState:(NSInteger)state;

@end
