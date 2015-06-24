//
//  SAVConnectionState.h
//  SavantControl
//
//  Created by Adam Shiemke on 2/10/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

typedef NS_ENUM(NSUInteger, SAVConnectionState)
{
    SAVConnectionStateNotConnected, /* not connected */
    SAVConnectionStateLocal, /* connected locally */
    SAVConnectionStateCloud, /* connected to the cloud */
    SAVConnectionStateProvisionable, /* connected to a provisionable host */
};
