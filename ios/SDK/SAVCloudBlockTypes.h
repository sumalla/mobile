//
//  SAVCloudBlockTypes.h
//  Savant
//
//  Created by Cameron Pulsford on 3/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#ifndef Savant_SAVCloudBlockTypes_h
#define Savant_SAVCloudBlockTypes_h

/**
 *  A response block for most of the Savant Cloud Services calls.
 *
 *  @param success              @p YES if the request was successful; otherwise, @p NO.
 *  @param data                 The response data, or nil.
 *  @param error                An @p NSError, or nil.
 *  @param isHTTPTransportError @p This will be YES if the error was due to an HTTP error. It will be @p NO if the response failed to being supplied with incorrect information. In either case, see the error for more details.
 */
typedef void (^SCSResponseBlock)(BOOL success, id data, NSError *error, BOOL isHTTPTransportError);

/**
 *  This block is returned by most methods that interact with Savant's Cloud Services. Call this block to cancel the request. This cancellation has the same semantics as cancelling an NSURLSessionTask.
 */
typedef void (^SCSCancelBlock)(void);

typedef void (^SAVCloudServiceRequestSuccessBlock)(id response);
typedef void (^SAVCloudServiceRequestFailureBlock)(NSError *error, BOOL isHTTPTransportError);

#endif
