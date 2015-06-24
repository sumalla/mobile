//
//  SCUScenePowerOffModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenePowerOffModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUSceneCreationDataSourcePrivate.h"

@import SDK;

@implementation SCUScenePowerOffModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        __block BOOL returnedAV = NO;
        __block BOOL returnedLighting = NO;
        NSArray *services = [[[Savant data] allServices] arrayByMappingBlock:^id(SAVService *service) {
            if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"] && !returnedLighting)
            {
                returnedLighting = YES;
                return service;
            }
            else if ([service.serviceId hasPrefix:@"SVC_AV"] && !returnedAV)
            {
                returnedAV = YES;
                return NSLocalizedString(@"Media", nil);
            }

            return nil;
        }];

        NSMutableArray *dataSource = [NSMutableArray array];

        for (id s in services)
        {
            NSDictionary *serviceData = nil;

            if ([s isKindOfClass:[SAVService class]])
            {
                SAVService *service = (SAVService *)s;

                serviceData = @{SCUDefaultTableViewCellKeyTitle: service.displayName,
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:service.iconName],
                                SCUDefaultTableViewCellKeyModelObject: service.serviceId,
                                SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]};
            }
            else
            {
                serviceData = @{SCUDefaultTableViewCellKeyTitle: s,
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:s],
                                SCUDefaultTableViewCellKeyModelObject: @"SVC_AV_%",
                                SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]};
            }

            [dataSource addObject:serviceData];

        }

        self.dataSource = dataSource;
    }
    return self;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Services", nil);
}

- (BOOL)shouldDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
