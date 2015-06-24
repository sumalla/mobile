//
//  SCUChangeServerTableViewControllerModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUChangeServerTableViewControllerModel.h"
#import "SCUProgressTableViewCell.h"
#import "SCUAlertView.h"
#import <SavantControl/SavantControlPrivate.h>
#import <CrashlyticsFramework/Crashlytics.h>

static NSString *SCUChangeServerCellType = @"SCUChangeServerCellType";

@interface SCUChangeServerTableViewControllerModel ()

@property (nonatomic, copy) NSArray *dataSource;

@end

@implementation SCUChangeServerTableViewControllerModel

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.dataSource = @[
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Production", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressProduction)},

                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Alpha", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressAlpha)},

                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Beta", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressBeta)},

                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"QA", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressQA)},

                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Developer", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressDev1)},

                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Training", nil),
                              SCUChangeServerCellType: @(SAVCloudServerAddressTraining)},

                            ];
    }

    return self;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [super modelObjectForIndexPath:indexPath];
    modelObject = [modelObject dictionaryByAddingObject:@([self accessoryTypeFromServerType:[modelObject[SCUChangeServerCellType] integerValue]])
                                                 forKey:SCUProgressTableViewCellKeyAccessoryType];

    return modelObject;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Pick a cloud server", nil);
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    SAVCloudServerAddress type = [modelObject[SCUChangeServerCellType] integerValue];

    [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
        [defaults setInteger:type forKey:SAVCustomServerAddress];
    }];

    [SavantControl sharedControl].cloudServerAddress = type;

    [self.delegate reloadData];

    //-------------------------------------------------------------------
    // Useless to localize.
    //-------------------------------------------------------------------
    SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:@"Sorry" message:@"I have to crash now." buttonTitles:@[@":-("]];

    alertView.callback = ^(NSUInteger buttonIndex) {
        [[Crashlytics sharedInstance] crash];
    };

    [alertView show];
}

- (SCUProgressTableViewCellAccessoryType)accessoryTypeFromServerType:(SAVCloudServerAddress)serverType
{
    SCUProgressTableViewCellAccessoryType type = SCUProgressTableViewCellAccessoryTypeNone;

    if ([[NSUserDefaults standardUserDefaults] integerForKey:SAVCustomServerAddress] == serverType)
    {
        type = SCUProgressTableViewCellAccessoryTypeCheckmark;
    }

    return type;
}

@end
