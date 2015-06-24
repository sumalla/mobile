//
//  SAVRestServices.m
//  Savant
//
//  Created by Joseph Ross on 3/31/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "Savant.h"
#import "SAVRestServices.h"
#import "SAVControlPrivate.h"
#import "SAVCredentialManager.h"
#import <CommonCrypto/CommonHMAC.h>
#import "rpmSharedLogger.h"
@import Extensions;


@interface SAVRestServices () <NSURLSessionDelegate>

@property NSURLSessionConfiguration *configuration;

@end

@implementation SAVRestServices

#pragma mark - Private

- (void)invalidateAndCreateSession
{
    self.authenticationToken = nil;
    self.secretKey = nil;
    self.userID = nil;
    self.configuration = nil;
    self.authenticationToken = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (void)createSessionIfNecessary
{
    if (!self.configuration)
    {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 3;
        self.configuration = configuration;
    }
    
    if (!self.session)
    {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self.session = session;
    }
}

- (NSString *)serviceScheme
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)serviceAddress
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSInteger)servicePort
{
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (NSString *)serviceRequestBase
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (BOOL)attemptReloginWithFailureBlock:(dispatch_block_t)failureBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return YES;
}

- (NSURLRequest *)urlRequestWithHTTPMethod:(NSString *)method request:(NSString *)request body:(NSDictionary *)body requiresAuth:(BOOL)requiresAuth
{
    [self createSessionIfNecessary];
    
    NSParameterAssert(request);
    NSString *mutableURL = [NSString stringWithFormat:@"%@://%@%@", self.serviceScheme, self.serviceAddress, self.servicePort == 443 ? @"" : [NSString stringWithFormat:@":%ld", (long)self.servicePort]];
    mutableURL = [mutableURL stringByAppendingPathComponent:self.serviceRequestBase];
    mutableURL = [mutableURL stringByAppendingPathComponent:request];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:mutableURL]];
    
    if (method)
    {
        urlRequest.HTTPMethod = method;
    }
    
    if (body)
    {
        urlRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:NULL];
    }
    
    //-------------------------------------------------------------------
    // Set auth headers.
    //-------------------------------------------------------------------
    if (requiresAuth)
    {
        if (self.authenticationToken && self.secretKey)
        {
            NSDictionary *authDict = @{@"alg": @"SHA256",
                                       @"iss": @"SCS",
                                       @"typ": @"user",
                                       @"sub": self.authenticationToken,
                                       @"iat": @((NSInteger)[[NSDate date] timeIntervalSince1970])};
            
            //-------------------------------------------------------------------
            // Compute the key.
            //-------------------------------------------------------------------
            NSData *authData = [NSJSONSerialization dataWithJSONObject:authDict options:kNilOptions error:NULL];
            NSString *key = [authData base64EncodedStringWithOptions:kNilOptions];
            
            //-------------------------------------------------------------------
            // Compute the value.
            //-------------------------------------------------------------------
            NSData *saltData = [self.secretKey dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
            CCHmac(kCCHmacAlgSHA256, saltData.bytes, saltData.length, authData.bytes, authData.length, hash.mutableBytes);
            
            NSMutableString *value = [NSMutableString string];
            
            const unsigned char *bytes = (const unsigned char*)[hash bytes];
            
            for (NSUInteger i = 0; i < [hash length]; i++)
            {
                [value appendFormat:@"%02x", bytes[i]];
            }
            
            [urlRequest setValue:[NSString stringWithFormat:@"%@:%@", key, value] forHTTPHeaderField:@"SCS-Authorization"];
        }
        else
        {
            urlRequest = nil;
        }
    }
    
    if (urlRequest)
    {
        //-------------------------------------------------------------------
        // Set standard headers.
        //-------------------------------------------------------------------
        [urlRequest setValue:Savant.control.cloudWebAPIKey forHTTPHeaderField:@"SCS-Agent"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSString *userAgent = [NSString stringWithFormat:@"%@: %@; %@: %@; %@",
                               Savant.control.deviceOperatingSystem,
                               Savant.control.deviceOperatingSystemVersion,
                               Savant.control.appName,
                               Savant.control.appVersion,
                               Savant.control.deviceFormFactor];
        
        [urlRequest setValue:userAgent forHTTPHeaderField:@"SCS-UserAgent"];
        
        //-------------------------------------------------------------------
        // Set timeout
        //-------------------------------------------------------------------
        urlRequest.timeoutInterval = self.session.configuration.timeoutIntervalForRequest;
    }
    
    return [urlRequest copy];
}

- (SCSCancelBlock)sendRequest:(NSURLRequest *)request success:(SAVCloudServiceRequestSuccessBlock)success failure:(SAVCloudServiceRequestFailureBlock)failure
{
    NSParameterAssert(success);
    NSParameterAssert(failure);
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        
        if (urlResponse.statusCode == 200)
        {
            NSError *jsonError = nil;
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (responseData)
            {
                NSDictionary *payloadData = responseData[@"payload"];
                NSDictionary *errorData = responseData[@"error"];
                
                if (errorData)
                {
                    NSInteger code = [errorData[@"code"] integerValue];
                    NSString *message = errorData[@"message"];
                    NSError *responseError = [NSError errorWithDomain:SCSResponseErrorDomain
                                                                 code:code
                                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(message, nil)}];
                    
                    failure(responseError, NO);
                }
                else
                {
                    success(payloadData);
                }
            }
            else
            {
                failure(jsonError, YES);
            }
        }
        else if (urlResponse.statusCode == 401 || urlResponse.statusCode == 403 || [error.domain isEqualToString:NSURLErrorDomain])
        {
            RPMLogErr(@"Could not communicated with savant. Status code: %ld. Error: %@", (long)urlResponse.statusCode, error);
            
            dispatch_block_t failureBlock = ^{
                NSString *errorString = nil;
                
                switch (error.code)
                {
                    case NSURLErrorSecureConnectionFailed:
                    case NSURLErrorServerCertificateHasBadDate:
                    case NSURLErrorServerCertificateUntrusted:
                    case NSURLErrorServerCertificateHasUnknownRoot:
                    case NSURLErrorServerCertificateNotYetValid:
                    case NSURLErrorClientCertificateRejected:
                    case NSURLErrorClientCertificateRequired:
                        errorString = NSLocalizedString(@"We cannot establish a secure connection with Savant. To ensure your privacy, please update your app.", nil);
                        break;
                    default:
                        errorString = NSLocalizedString(@"Could not communicate with Savant.", nil);
                        break;
                }
                
                failure([NSError errorWithDomain:SCSResponseErrorDomain code:SCSResponseErrorConnectionError userInfo:@{NSLocalizedDescriptionKey: errorString}], NO);
            };
            
            BOOL callFailureBlock = YES;
            
            if (urlResponse.statusCode == 401 || urlResponse.statusCode == 403)
            {
                callFailureBlock = [self attemptReloginWithFailureBlock:failureBlock];
            }
            
            if (callFailureBlock)
            {
                failureBlock();
            }
        }
        else
        {
            failure(error, YES);
        }
    }];
    
    [dataTask resume];
    
    return ^{
        [dataTask cancel];
    };
}

@end
