//
//  Savant.h
//  Savant
//
//  Created by Cameron Pulsford on 5/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;
#import "SAVControl.h"
#import "SAVStateManager.h"
#import "SAVDiscovery.h"
#import "SAVData.h"
#import "SAVImageModel.h"
#import "SAVNotificationManager.h"
#import "SAVCloud.h"
#import "SAVProvisioner.h"

NS_ASSUME_NONNULL_BEGIN

@interface Savant : NSObject

+ (SAVControl *)control;

+ (SAVDiscovery *)discovery;

+ (SAVStateManager *)states;

+ (SAVData *)data;

+ (SAVImageModel *)images;

+ (SAVNotificationManager *)notifications;

+ (SAVCloud *)cloud;

+ (SAVProvisioner *)provisioner;

@end

NS_ASSUME_NONNULL_END
