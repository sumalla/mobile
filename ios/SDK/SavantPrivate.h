//
//  SavantPrivate.h
//  Savant
//
//  Created by Cameron Pulsford on 5/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "Savant.h"
#import "SAVCredentialManager.h"
#import "SAVCloudServices.h"

@class SignalingServices;
@class HostServices;

@interface Savant ()

+ (SAVCredentialManager *)credentials;

+ (SAVCloudServices *)scs;

+ (SignalingServices *)signaling;

+ (HostServices *)hostServices;

@end
