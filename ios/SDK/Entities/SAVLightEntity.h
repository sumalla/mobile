//
//  SAVLightEntity.h
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVEntity.h"

@interface SAVLightEntity : SAVEntity

@property NSString *pressCommand;
@property NSString *holdCommand;
@property NSString *releaseCommand;
@property NSString *togglePressCommand;
@property NSString *toggleHoldCommand;
@property NSString *toggleReleaseCommand;
@property NSString *dimmerCommand;
@property NSString *restoreCommand;

@property NSString *fadeTime;
@property NSString *delayTime;
@property NSString *stateName;
@property (getter = isSceneable) BOOL scenable;

@end
