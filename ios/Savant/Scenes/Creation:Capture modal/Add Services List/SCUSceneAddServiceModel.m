//
//  SCUSceneAddServiceModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneAddServiceModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUSceneCreationDataSourcePrivate.h"

@import SDK;

@implementation SCUSceneAddServiceModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        NSArray *serviceGroups = [[Savant data] allServiceGroups];
        NSMutableArray *dataSource = [NSMutableArray array];

        BOOL addedLighting = NO;
        BOOL addedShades = NO;
        BOOL addedClimate  = NO;

        for (SAVServiceGroup *serviceGroup in serviceGroups)
        {
            if (([serviceGroup.serviceId hasPrefix:@"SVC_SETTINGS"] ||
                [serviceGroup.serviceId isEqualToString:@"SVC_GEN_GENERIC"] ||
                [serviceGroup.serviceId hasPrefix:@"SVC_ENV"] ||
                [serviceGroup.serviceId hasPrefix:@"SVC_COMM"] ||
                [serviceGroup.serviceId hasPrefix:@"SVC_INFO"]) &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"] &&
                ![serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"])
            {
                continue;
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
            {
                if (addedLighting)
                {
                    continue;
                }
                else
                {
                    addedLighting = YES;
                }
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_SHADE"])
            {
                if (addedShades)
                {
                    continue;
                }
                else
                {
                    addedShades = YES;
                }
            }

            if ([serviceGroup.serviceId isEqualToString:@"SVC_ENV_HVAC"])
            {
                if (addedClimate)
                {
                    continue;
                }
                else
                {
                    addedClimate = YES;
                }
            }

            NSMutableDictionary *serviceData = [@{SCUDefaultTableViewCellKeyTitle: serviceGroup.alias ? : serviceGroup.displayName,
                                                  SCUDefaultTableViewCellKeyModelObject: serviceGroup,
                                                  SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)
} mutableCopy];

            UIImage *serviceIcon = [UIImage imageNamed:serviceGroup.iconName];

            if (serviceIcon)
            {
                serviceData[SCUDefaultTableViewCellKeyImage] = serviceIcon;
                serviceData[SCUDefaultTableViewCellKeyImageTintColor] = [[SCUColors shared] color04];
            }

            if ([serviceGroup.serviceId hasPrefix:@"SVC_ENV"])
            {
                serviceData[SCUDefaultTableViewCellKeyTitle] = serviceGroup.displayName;

                [dataSource insertObject:serviceData atIndex:0];
            }
            else
            {
                [dataSource addObject:serviceData];
            }
        }

        [dataSource sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            NSComparisonResult result = NSOrderedAscending;

            SAVServiceGroup *service1 = obj1[SCUDefaultTableViewCellKeyModelObject];
            SAVServiceGroup *service2 = obj2[SCUDefaultTableViewCellKeyModelObject];

            if ([service1.serviceId hasPrefix:@"SVC_ENV"])
            {
                result = NSOrderedAscending;
            }
            else
            {
                result = [[service1 alias] compare:[service2 alias]];
            }

            return result;
        }];

        NSDictionary *power = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Power Off", nil),
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:@"Power"],
                                SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]};

        [dataSource insertObject:power atIndex:0];

        self.dataSource = dataSource;
    }
    return self;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVServiceGroup *service = self.dataSource[indexPath.row][SCUDefaultTableViewCellKeyModelObject];

    [self.delegate selectedServiceGroup:service];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Available", nil);
}

@end
