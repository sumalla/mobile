//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2013 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2013 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2013 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

@import Foundation;
#import "SavantProtocols.h"
#import "SAVCloudBlockTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Use this constant in conjunction with the @p groupedSystems property to get the current list of cloud systems.
 */
extern NSString *const SAVDiscoveryCloudSystemsKey;

/**
 *  Use this constant in conjunction with the @p groupedSystems property to get the current list of local systems.
 */
extern NSString *const SAVDiscoveryLocalSystemsKey;

/**
 *  Use this constant in conjunction with the @p groupedSystems property to get the current list of provisionable systems.
 */
extern NSString *const SAVDiscoveryProvisionableSystemsKey;

/**
 *  Use this constant in conjunction with the @p groupedPeripherals property to get the current list of lighting peripherals.
 */
extern NSString *const SAVDiscoveryPeripheralLampModuleKey;
/**
 *  Use this constant in conjunction with the @p groupedPeripherals property to get the current list of lighting peripherals.
 */
extern NSString *const SAVDiscoveryPeripheralLightingKey;
/**
 *  Use this constant in conjunction with the @p groupedPeripherals property to get the current list of camera peripherals.
 */
extern NSString *const SAVDiscoveryPeripheralCameraKey;
/**
 *  Use this constant in conjunction with the @p groupedPeripherals property to get the current list of controller peripherals.
 */
extern NSString *const SAVDiscoveryPeripheralControllersKey;

@interface SAVDiscovery : NSObject

/**
 *  Does not include provisionable systems
 */
@property (nonatomic, readonly) NSArray *combinedCloudAndLocalSystems;

@property (nonatomic, readonly) NSArray *combinedPeripherals;

/**
 *  Return the list of current systems. Use the @p SAVDiscoveryCloudSystemsKey, @p SAVDiscoveryLocalSystemsKey, and SAVDiscoveryProvisionableSystemsKey keys as needed.
 *
 *  @return A list of systems keyed by @p SAVDiscoveryCloudSystemsKey, @p SAVDiscoveryLocalSystemsKey, and SAVDiscoveryProvisionableSystemsKey.
 */
@property (nonatomic, readonly, copy) NSDictionary *groupedSystems;

/**
 *  Return the list of current systems. Use the @p SAVDiscoveryPeripheralLightingKey, @p SAVDiscoveryPeripheralCameraKey, and SAVDiscoveryPeripheralControllersKey keys as needed.
 *
 *  @return A list of systems keyed by @p SAVDiscoveryPeripheralLightingKey, @p SAVDiscoveryPeripheralCameraKey, and SAVDiscoveryPeripheralControllersKey.
 */
@property (nonatomic, readonly, copy) NSDictionary *groupedPeripherals;

/**
 *  Add a discovery observer.
 *
 *  @param observer The discovery observer.
 */
- (void)addDiscoveryObserver:(id<DiscoveryDelegate>)observer;

/**
 *  Remove a discovery observer.
 *
 *  @param observer The discovery observer.
 */
- (void)removeDiscoveryObserver:(id<DiscoveryDelegate>)observer;

/**
 *  Refresh the system list.
 *
 *  @return YES if the list will be refreshed; otherwise, NO.
 */
- (BOOL)update;

/**
 *  Get the latest cloud homes list. Use this method if you just need a list of cloud homes and aren't interested in local homes.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)cloudHomesWithCompletionHandler:(void (^)(BOOL success, NSArray *systems, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END