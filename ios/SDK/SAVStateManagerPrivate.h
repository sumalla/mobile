//
//  SAVStateManagerPrivate.h
//  Savant
//
//  Created by Cameron Pulsford on 3/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#ifndef Savant_SAVStateManagerPrivate_h
#define Savant_SAVStateManagerPrivate_h

#import "SAVStateManager.h"

@interface SAVStateManager ()

/**
 *  Re-register for all global states.
 */
- (void)updateGlobalStates;

/**
 *  Reset the state manager to its default state.
 */
- (void)reset;

#pragma mark - State restoration

/**
 *  Returns an opaque data structure that is used to restore the current observer state of the state manager.
 *
 *  @return The info needed to restore the current observers.
 */
- (id)restorationInfo;

/**
 *  Restore the state that was saved.
 *
 *  @param state The previously stored state.
 */
- (void)restoreState:(id)state;

@end

#endif
