//
//  SAVDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/2/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVDemoRouter.h"

@implementation SAVDemoRouter

- (BOOL)handleStateRegistration:(SAVStateRegister *)request
{
    return NO;
}

- (BOOL)handleStateUnregistration:(SAVStateUnregister *)request
{
    return NO;
}

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    return NO;
}

- (BOOL)handleMediaRequest:(SAVMediaRequest *)request
{
    return NO;
}

- (BOOL)handleServiceRequest:(SAVServiceRequest *)request
{
    return NO;
}

- (BOOL)handleFileRequest:(SAVFileRequest *)request
{
    return NO;
}

@end
