//
//  SAVRoomGroup.h
//  SavantControl
//
//  Created by Ian Mortimer on 12/4/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@interface SAVRoomGroup : NSObject <NSCopying>

@property NSString *groupId;
@property NSString *groupAlias;

- (BOOL)isEqualToRoomGroup:(SAVRoomGroup *)roomGroup;

@end
