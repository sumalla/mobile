//
//  SCUNotificationBannerManager.m
//  SavantController
//
//  Created by Cameron Pulsford on 2/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationBannerManager.h"
#import "SCUBannerView.h"

static NSString *const SAVNotificationPayloadMessageKey = @"message";
static NSString *const SAVNotificationPayloadTypeKey = @"type";

static NSString *const SAVNotificationPayloadEntertainment = @"entertainment";
static NSString *const SAVNotificationPayloadLighting      = @"lighting";
static NSString *const SAVNotificationPayloadTemperature   = @"temperature";
static NSString *const SAVNotificationPayloadHumidity      = @"humidity";

@interface SCUNotificationBannerManager ()

@property (nonatomic) SCUBannerView *lastBannerView;

@end

@implementation SCUNotificationBannerManager

- (void)presentBannerWithInfo:(NSDictionary *)info interactionHandler:(dispatch_block_t)interactionHandler
{
    if (![info count])
    {
        return;
    }

    NSString *text = info[SAVNotificationPayloadMessageKey];
    NSString *type = info[SAVNotificationPayloadTypeKey];

    UIImage *image = nil;

    if ([type isEqualToString:SAVNotificationPayloadLighting])
    {
        image = [UIImage sav_imageNamed:@"Lighting_Notification" tintColor:[[SCUColors shared] color01]];
    }
    else if ([type isEqualToString:SAVNotificationPayloadTemperature] || [type isEqualToString:SAVNotificationPayloadHumidity])
    {
        image = [UIImage sav_imageNamed:@"Climate_Notification" tintColor:[[SCUColors shared] color01]];
    }
    else if ([type isEqualToString:SAVNotificationPayloadEntertainment])
    {
        image = [UIImage sav_imageNamed:@"Entertainment_Notification" tintColor:[[SCUColors shared] color01]];
    }

    SCUBannerView *bannerView = [[SCUBannerView alloc] initWithFrame:CGRectMake(0, -64, CGRectGetWidth([UIScreen mainScreen].bounds), 64)
                                                               image:image
                                                                text:text];

    if (interactionHandler)
    {
        bannerView.tapHandler = ^{
            interactionHandler();
        };
    }

    SAVWeakSelf;
    bannerView.dismissHandler = ^(SCUBannerView *dismissedBanner) {
        SAVStrongWeakSelf;

        if (sSelf.lastBannerView == dismissedBanner)
        {
            sSelf.lastBannerView = nil;
        }
    };

    dispatch_block_t completion = NULL;

    if (self.lastBannerView)
    {
        SCUBannerView *b = self.lastBannerView;

        completion = ^{
            [b hideAnimated:YES withVelocity:0.f withCompletionHandler:NULL];
        };
    }

    [bannerView showAnimated:YES withVelocity:0.f withCompletionHandler:completion];
    self.lastBannerView = bannerView;
}

@end
