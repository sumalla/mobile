//
//  SCUAVSettingsRoomGroupTableModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsRoomGroupTableModel.h"
@class SAVRoom;

@interface SCUAVSettingsRoomGroupTableModel ()

- (void)parseRoomGroupsAndFilter:(SAVRoom *)room;

@end
