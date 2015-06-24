//
//  SCUSchedulingHumidityModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingTempModel.h"

typedef NS_ENUM(NSInteger, SCUSchedulingHumidityMode)
{
    SCUSchedulingHumidityModeBoth,
    SCUSchedulingHumidityModeHumidify,
    SCUSchedulingHumidityModeDehumidify,
    SCUSchedulingHumidityModeHumidity
    
};

@interface SCUSchedulingHumidityModel : SCUSchedulingTempModel

@end
