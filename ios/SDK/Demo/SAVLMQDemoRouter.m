//
//  SAVLMQDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 9/8/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVLMQDemoRouter.h"
#import "Savant.h"
#import "SAVControlPrivate.h"
#import "RPMCommunicationConstants.h"

static NSString *const SCUMediaModelKeyRequestingService = @"requestingService";

@interface SAVLMQDemoRouter ()

@property NSDictionary *demoData;

@end

@implementation SAVLMQDemoRouter

- (BOOL)handleFileRequest:(SAVFileRequest *)request
{
    BOOL shouldHandle = NO;
    NSString *base64String = request.payload[@"key"];

    if (base64String)
    {
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];

        if ([decodedString length])
        {
            NSArray *artistOnlyComponents = [decodedString componentsSeparatedByString:@"-"];

            if ([artistOnlyComponents count])
            {
                NSString *artworkImageName = [artistOnlyComponents firstObject];
                UIImage *image = [UIImage imageNamed:artworkImageName];

                if (image)
                {
                    [[Savant control].demoServer sendBinaryData:UIImagePNGRepresentation(image)
                                                                      ofType:RPM_WEBSOCKET_FILEUPLOAD_TYPE
                                                              withIdentifier:request.payload];
                    shouldHandle = YES;
                }
            }
        }
    }

    return shouldHandle;
}

- (BOOL)handleMediaRequest:(SAVMediaRequest *)request
{
    BOOL handleRequest = NO;

    if (!self.demoData)
    {
        NSString *demoDataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"demo-lmq-data" ofType:@".json"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:demoDataPath])
        {
            NSData *jsonData = [NSData dataWithContentsOfFile:demoDataPath];

            self.demoData = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:NULL];
        }
    }

    NSString *serviceId = request.arguments[SCUMediaModelKeyRequestingService];

    NSDictionary *serviceDemoData = nil;
    __block NSInteger index = -1;
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    response[@"query"] = [request dictionaryRepresentation];

    if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_DAAP"])
    {
        serviceDemoData = self.demoData[@"AppleTV"];

        if ([request.query isEqualToString:@"getRoot"])
        {
            index = 85;
        }
    }
    else if ([serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_PANDORA"] ||
             [serviceId hasPrefix:@"SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_SPOTIFY"])
    {
        serviceDemoData = self.demoData[@"Pandora"];

        if ([request.query isEqualToString:@"getRoot"])
        {
            index = 0;
        }
    }

    if (serviceDemoData)
    {
        handleRequest = YES;

        if (index < 0)
        {
            [serviceDemoData[@"requests"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                if ([obj[@"Query"] isEqualToString:request.query])
                {
                    if ([obj[@"Query arguments"] isEqualToDictionary:request.arguments])
                    {
                        index = (NSInteger)idx;
                        *stop = YES;
                    }
                }
            }];
        }

        if (index >= 0 && (NSInteger)[serviceDemoData[@"responses"] count] > index)
        {
            response[@"results"] = serviceDemoData[@"responses"][(NSUInteger)index];
        }
    }

    [[Savant control].demoServer sendURIToDevice:request.uri withMessages:@[@[response]]];

    return handleRequest;
}

@end
