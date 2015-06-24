//
//  SAVRoom.h
//  SavantControl
//
//  Created by Ian Mortimer on 12/3/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@class SAVRoomGroup;

@interface SAVRoom : NSObject <NSCopying>

/** Id of the room */
@property (nonatomic, nonnull) NSString *roomId;

/** Id of the room */
@property (nonatomic, nonnull) NSString *roomType;

/**The group which the room belongs to. */
@property (nonatomic, nullable) SAVRoomGroup *group;

/** Indicates if the room has audio/video services. */
@property (nonatomic) BOOL hasAV;

/** Indicates if the room has lighting services. */
@property (nonatomic) BOOL hasLighting;

/** Indicates if the room has fan service. */
@property (nonatomic) BOOL hasFans;

/** Indicates if the room has shade services. */
@property (nonatomic) BOOL hasShades;

/** Indicates if the room has HVAC services. */
@property (nonatomic) BOOL hasHVAC;

/** Indicates if the room has security services. */
@property (nonatomic) BOOL hasSecurity;

/** Indicates if the room has cameras. */
@property (nonatomic) BOOL hasCameras;

- (BOOL)isEqualToRoom:(nullable SAVRoom *)room;

@end
