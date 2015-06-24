//
//  SCUMainNavViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSettingsModel.h"

typedef NS_ENUM(NSUInteger, SCUMainNavSelectedView)
{
    SCUMainNavSelectedViewRooms    = 0,
    SCUMainNavSelectedViewServices = 1,
    SCUMainNavSelectedViewScenes   = 2,
    SCUMainNavSelectedViewSettings = 3,
};

@protocol SCUMainNavDelegate;

@interface SCUMainNavViewModel : SCUSettingsModel

@property (weak) id <SCUMainNavDelegate> delegate;
@property (readonly) SCUMainNavSelectedView selectedView;

@end

@protocol SCUMainNavDelegate <NSObject>

- (void)selectedViewDidChange;

@end
