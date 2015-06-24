//
//  SAVRestServices.h
//  Savant
//
//  Created by Joseph Ross on 3/31/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;
#import "SAVCloudBlockTypes.h"

// @abstract
@interface SAVRestServices : NSObject

@property (nonatomic) NSString *authenticationToken;
@property (nonatomic) NSString *secretKey;
@property (nonatomic) NSString *userID;
@property (nonatomic,strong) NSURLSession *session;

- (void)invalidateAndCreateSession;
- (NSURLRequest *)urlRequestWithHTTPMethod:(NSString *)method request:(NSString *)request body:(NSDictionary *)body requiresAuth:(BOOL)requiresAuth;
- (SCSCancelBlock)sendRequest:(NSURLRequest *)request success:(SAVCloudServiceRequestSuccessBlock)success failure:(SAVCloudServiceRequestFailureBlock)failure;

// These methods must be overidden by subclasses!

- (NSString *)serviceScheme;
- (NSString *)serviceAddress;
- (NSInteger)servicePort;
- (NSString *)serviceRequestBase;
- (BOOL)attemptReloginWithFailureBlock:(dispatch_block_t)failureBlock;

@end