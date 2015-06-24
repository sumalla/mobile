//
//  SAVUserDataDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVUserDataDemoRouter.h"
#import "Savant.h"
#import "SAVControlPrivate.h"
#import "RPMCommunicationConstants.h"

@interface SAVUserDataDemoRouter ()

@property NSMutableArray *registeredStates;

@end

@implementation SAVUserDataDemoRouter

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    BOOL shouldHandle = NO;

    NSMutableArray *responses = [NSMutableArray array];

    if ([request.request isEqualToString:@"register"])
    {
        NSString *state = request.arguments[SAVMESSAGE_STATE_KEY];

        if ([state hasSuffix:@".image.update"])
        {
            if (!self.registeredStates)
            {
                self.registeredStates = [NSMutableArray array];
            }
            
            [self.registeredStates addObject:state];
            
            [responses addObject:[self imageListForState:state]];
        }
    }
    else if ([request.request isEqualToString:@"DeleteImage"])
    {
        for (NSString *state in self.registeredStates)
        {
            [responses addObject:[self imageListForState:state]];
        }
    }

    for (SAVDISFeedback *response in responses)
    {
        shouldHandle = YES;
        
        response.app = request.app;
        
        [[Savant control].demoServer sendMessage:response];
    }
    
    return shouldHandle;
}

- (BOOL)handleFileRequest:(SAVFileRequest *)request
{
    BOOL handleRequest = NO;

    SAVDISResults *result = nil;
    
    if ([request.fileURI isEqualToString:@"dis/userData"])
    {
        result = [self fetchImage:request.payload[@"key"] withSize:(SAVImageSize)[request.payload[@"size"] integerValue]];
    }
    
    if (result)
    {
        handleRequest = YES;
        
        result.app = SAVUserDataIdentifer;
        result.request = @"FetchImage";
        
        [[Savant control].demoServer sendMessage:result];
    }

    return handleRequest;
}

- (SAVDISResults *)fetchImage:(NSString *)key withSize:(SAVImageSize)size
{    
    NSString *fileName = [[key stringByReplacingOccurrencesOfString:@"room." withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@".jpg"];

    if (!bundlePath)
    {
        bundlePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@".png"];
    }

    SAVDISResults *results = [[SAVDISResults alloc] init];
    
    if (bundlePath)
    {
        results.results = @{@"key": key, @"path": bundlePath, @"version": @1, @"size": @(size), @"global": @YES};
    }
    else
    {
        results.results = @{@"key": key, @"error": @"no image", @"version": @1, @"size": @(size), @"global": @YES};
    }
    
    return results;
}

- (SAVDISFeedback *)imageListForState:(NSString *)state
{
    SAVDISFeedback *feedback = [[SAVDISFeedback alloc] init];
    feedback.state = state;

    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    feedback.value = value;

    for (NSString *room in [[Savant data] allRoomIds])
    {
        value[[@"room." stringByAppendingString:room]] = @1;
    }

    return feedback;
}

@end
