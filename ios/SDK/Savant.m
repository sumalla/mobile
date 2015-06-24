//
//  Savant.m
//  Savant
//
//  Created by Cameron Pulsford on 5/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SavantPrivate.h"
#import <SDK/SDK-Swift.h>

@implementation Savant

+ (SAVControl *)control
{
    static SAVControl *control = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        control = [[SAVControl alloc] init];
    });
    
    return control;
}

+ (SAVDiscovery *)discovery
{
    static SAVDiscovery *discovery = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        discovery = [[SAVDiscovery alloc] init];
    });
    
    return discovery;
}

+ (SAVStateManager *)states
{
    static SAVStateManager *states = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        states = [[SAVStateManager alloc] init];
    });
    
    return states;
}

+ (SAVData *)data
{
    static SAVData *data = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        data = [[SAVData alloc] init];
    });
    
    return data;
}

+ (SAVImageModel *)images
{
    static SAVImageModel *images = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        images = [[SAVImageModel alloc] init];
    });
    
    return images;
}

+ (SAVNotificationManager *)notifications
{
    static SAVNotificationManager *notifications = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notifications = [[SAVNotificationManager alloc] init];
    });
    
    return notifications;
}

+ (SAVCloud *)cloud
{
    static SAVCloud *cloud = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cloud = [[SAVCloud alloc] init];
    });
    
    return cloud;
}

+ (SAVCredentialManager *)credentials
{
    static SAVCredentialManager *credentialManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        credentialManager = [[SAVCredentialManager alloc] init];
    });
    
    return credentialManager;
}

+ (SAVCloudServices *)scs
{
    static SAVCloudServices *scs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scs = [[SAVCloudServices alloc] init];
    });
    
    return scs;
}

+ (SignalingServices *)signaling
{
    static SignalingServices *signaling = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signaling = [[SignalingServices alloc] init];
    });
    
    return signaling;
}

+ (HostServices *)hostServices
{
    static HostServices *hostServices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hostServices = [[HostServices alloc] init];
    });
    
    return hostServices;
}

+ (SAVProvisioner *)provisioner
{
    static SAVProvisioner *provisioner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provisioner = [[SAVProvisioner alloc] init];
    });
    
    return provisioner;
}

@end
