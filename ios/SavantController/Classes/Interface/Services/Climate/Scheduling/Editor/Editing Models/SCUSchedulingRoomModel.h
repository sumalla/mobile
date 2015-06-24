//
//  SCUSchedulingRoomModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditingModel.h"

@interface SCUSchedulingRoomModel : SCUSchedulingEditingModel

- (void)toggleRoomSelectedAtIndexPath:(NSIndexPath *)indexPath;

- (void)invalidateImageReloadTimer;

- (void)registerForObservers;

@end


