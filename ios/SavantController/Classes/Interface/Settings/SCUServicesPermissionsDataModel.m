//
//  SCUServicesPermissionsDataModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesPermissionsDataModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAlertView.h"

@interface SCUServicesPermissionsDataModel ()

@property (nonatomic) SAVCloudUser *user;
@property (nonatomic) NSSet *blacklistedServices;
@property (nonatomic, copy) NSDictionary *serviceToIndexMap;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) NSMutableIndexSet *uncheckedIndexes;
@property (nonatomic) NSUInteger maxNumberOfIndexes;

@end

@implementation SCUServicesPermissionsDataModel

- (instancetype)initWithUser:(SAVCloudUser *)user
{
    self = [super init];

    if (self)
    {
        self.user = user;

        self.blacklistedServices = [self.user.serviceBlackList mutableCopy];

        //-------------------------------------------------------------------
        // Lighting :: SVC_ENV_LIGHTING
        // Shades   :: SVC_ENV_SHADE
        // Climate  :: SVC_ENV_HVAC, SVC_ENV_POOLANDSPA
        // Media    :: SVC_AV
        // Security :: SVC_ENV_SECURITY, SVC_ENV_USERLOGIN_SECURITYSYSTEM, SVC_ENV_SECURITYCAMERA
        //-------------------------------------------------------------------
        NSMutableDictionary *serviceToIndexPath = [NSMutableDictionary dictionary];
        NSMutableArray *dataSource = [NSMutableArray array];
        NSUInteger counter = 0;

        SAVData *data = [SavantControl sharedControl].data;

        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_LIGHTING"]] count])
        {
            serviceToIndexPath[@"SVC_ENV_LIGHTING"] = @(counter);
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Lighting", nil),
                                    SCUDefaultTableViewCellKeyImage: [UIImage sav_imageNamed:@"Lighting" tintColor:[[SCUColors shared] color04]]}];

            counter++;
        }

        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_SHADE"]] count])
        {
            serviceToIndexPath[@"SVC_ENV_SHADE"] = @(counter);
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Shades", nil),
                                    SCUDefaultTableViewCellKeyImage: [UIImage sav_imageNamed:@"Shades" tintColor:[[SCUColors shared] color04]]}];

            counter++;
        }

        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_HVAC", @"SVC_ENV_POOLANDSPA"]] count])
        {
            serviceToIndexPath[@"SVC_ENV_HVAC"] = @(counter);
            serviceToIndexPath[@"SVC_ENV_POOLANDSPA"] = @(counter);
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Climate", nil),
                                    SCUDefaultTableViewCellKeyImage: [UIImage sav_imageNamed:@"Climate" tintColor:[[SCUColors shared] color04]]}];

            counter++;
        }

        if ([[data servicesFilteredByServiceID:@"SVC_AV%"] count])
        {
            serviceToIndexPath[@"SVC_AV"] = @(counter);
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Media", nil),
                                    SCUDefaultTableViewCellKeyImage: [UIImage sav_imageNamed:@"Media" tintColor:[[SCUColors shared] color04]]}];

            counter++;
        }

        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_SECURITY", @"SVC_ENV_USERLOGIN_SECURITYSYSTEM", @"SVC_ENV_SECURITYCAMERA"]] count])
        {
            serviceToIndexPath[@"SVC_ENV_SECURITY"] = @(counter);
            serviceToIndexPath[@"SVC_ENV_USERLOGIN_SECURITYSYSTEM"] = @(counter);
            serviceToIndexPath[@"SVC_ENV_SECURITYCAMERA"] = @(counter);
            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Security", nil),
                                    SCUDefaultTableViewCellKeyImage: [UIImage sav_imageNamed:@"Security" tintColor:[[SCUColors shared] color04]]}];

            counter++;
        }

        self.serviceToIndexMap = serviceToIndexPath;
        self.dataSource = dataSource;


        self.maxNumberOfIndexes = [[NSSet setWithArray:[self.serviceToIndexMap allValues]] count];

        self.uncheckedIndexes = [self indexSetForBlacklistedServices:self.user.serviceBlackList];
        self.blacklistedServices = [self blacklistedServicesFromUncheckedIndexes:self.uncheckedIndexes];
    }

    return self;
}

- (void)commit
{
    self.user.serviceBlackList = [self.blacklistedServices copy];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    if ([self.uncheckedIndexes containsIndex:indexPath.row])
    {
        modelObject = [modelObject dictionaryByAddingObject:@(UITableViewCellAccessoryNone) forKey:SCUDefaultTableViewCellKeyAccessoryType];
    }
    else
    {
        modelObject = [modelObject dictionaryByAddingObject:@(UITableViewCellAccessoryCheckmark) forKey:SCUDefaultTableViewCellKeyAccessoryType];
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.uncheckedIndexes containsIndex:indexPath.row])
    {
        [self.uncheckedIndexes removeIndex:indexPath.row];
    }
    else
    {
        if ([self.uncheckedIndexes count] == self.maxNumberOfIndexes - 1)
        {
            [[[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                         message:NSLocalizedString(@"A user must be allowed to control at least one type of service.", nil)
                                    buttonTitles:@[NSLocalizedString(@"OK", nil)]] show];
        }
        else
        {
            [self.uncheckedIndexes addIndex:indexPath.row];
        }
    }

    self.blacklistedServices = [self blacklistedServicesFromUncheckedIndexes:self.uncheckedIndexes];

    [self.delegate reloadIndexPath:indexPath];
}

- (NSMutableIndexSet *)indexSetForBlacklistedServices:(NSSet *)blacklistedServices
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

    for (NSString *service in blacklistedServices)
    {
        [indexes addIndex:[self.serviceToIndexMap[service] unsignedIntegerValue]];
    }

    return indexes;
}

- (NSSet *)blacklistedServicesFromUncheckedIndexes:(NSIndexSet *)indexes
{
    NSMutableSet *blacklistedServices = [NSMutableSet set];

    [self.serviceToIndexMap enumerateKeysAndObjectsUsingBlock:^(NSString *service, NSNumber *idx, BOOL *stop) {
        if ([indexes containsIndex:[idx unsignedIntegerValue]])
        {
            [blacklistedServices addObject:service];
        }
    }];

    return [blacklistedServices copy];
}

+ (NSArray *)localizedServiceTitlesForUser:(SAVCloudUser *)user
{
    NSMutableArray *services = [NSMutableArray array];

    SAVData *data = [SavantControl sharedControl].data;

    if (![user.serviceBlackList containsObject:@"SVC_ENV_LIGHTING"])
    {
        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_LIGHTING"]] count])
        {
            [services addObject:NSLocalizedString(@"Lighting", nil)];
        }
    }

    if (![user.serviceBlackList containsObject:@"SVC_ENV_SHADE"])
    {
        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_SHADE"]] count])
        {
            [services addObject:NSLocalizedString(@"Shades", nil)];
        }
    }

    if (![user.serviceBlackList containsObject:@"SVC_ENV_HVAC"])
    {
        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_HVAC", @"SVC_ENV_POOLANDSPA"]] count])
        {
            [services addObject:NSLocalizedString(@"Climate", nil)];
        }
    }

    if (![user.serviceBlackList containsObject:@"SVC_AV"])
    {
        if ([[data servicesFilteredByServiceID:@"SVC_AV%"] count])
        {
            [services addObject:NSLocalizedString(@"Media", nil)];
        }
    }

    if (![user.serviceBlackList containsObject:@"SVC_ENV_SECURITY"] || ![user.serviceBlackList containsObject:@"SVC_ENV_USERLOGIN_SECURITYSYSTEM"] || ![user.serviceBlackList containsObject:@"SVC_ENV_SECURITYCAMERA"])
    {
        if ([[data servicesFilteredByServiceIDs:@[@"SVC_ENV_SECURITY", @"SVC_ENV_USERLOGIN_SECURITYSYSTEM", @"SVC_ENV_SECURITYCAMERA"]] count])
        {
            [services addObject:NSLocalizedString(@"Security", nil)];
        }
    }

    return [services copy];
}

@end
