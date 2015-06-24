//
//  SCUScenesSelectedServiceModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesSelectedServiceModel.h"
#import "SCUSceneCreationDataSourcePrivate.h"
#import "SCUSceneCell.h"

@interface SCUScenesSelectedServiceModel ()

@property NSArray *sceneServices;

@end

@implementation SCUScenesSelectedServiceModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        [self prepareData];
    }
    return self;
}

- (void)prepareData
{
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *sceneService = [NSMutableArray array];

    if ([self.scene.avOff count])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Media Off", nil),
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:@"Media"],
                                SCUDefaultTableViewCellKeyModelObject: self.scene.avOff,
                                SCUSceneCellKeyOff: @YES,
                                SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]}];

        [sceneService addObject:@"SVC_AV_%"];
    }

    if ([self.scene.lightingOff count])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Lighting Off", nil),
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:@"Lighting"],
                                SCUDefaultTableViewCellKeyModelObject: self.scene.lightingOff,
                                SCUSceneCellKeyOff: @YES,
                                SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                    SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]}];

        [sceneService addObject:@"SVC_ENV_LIGHTING"];
    }

    if ([self.scene.hvacOff count])
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Climate Off", nil),
                                SCUDefaultTableViewCellKeyImage: [UIImage imageNamed:@"Climate"],
                                SCUDefaultTableViewCellKeyModelObject: self.scene.hvacOff,
                                SCUSceneCellKeyOff: @YES,
                                SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]}];

        [sceneService addObject:@"SVC_ENV_HVAC"];
    }

    if ([self.scene.lightingServices count])
    {
        NSMutableSet *lightingRooms = [NSMutableSet set];
        NSMutableSet *shadeRooms = [NSMutableSet set];

        SAVSceneService *lightingService = nil;
        SAVSceneService *shadeService = nil;

        NSMutableDictionary *servicesPerDevice = [NSMutableDictionary dictionary];

        for (SAVSceneService *service in self.scene.lightingServices)
        {
            //-------------------------------------------------------------------
            // Check if the device supports lighting or shades or both
            //-------------------------------------------------------------------
            NSString *deviceName = [NSString stringWithFormat:@"%@-%@", service.component, service.logicalComponent];
            NSArray *deviceServices = servicesPerDevice[deviceName];

            if (!deviceServices)
            {
                SAVMutableService *mutableService = [service.service mutableCopy];
                mutableService.serviceId = nil;

                NSArray *services = [[Savant data] servicesFilteredByService:mutableService];
                deviceServices = [services arrayByMappingBlock:^id(SAVService *object) {
                    return object.serviceId;
                }];
                servicesPerDevice[deviceName] = deviceServices;
            }

            if ([deviceServices containsObject:@"SVC_ENV_LIGHTING"])
            {
                [lightingRooms addObjectsFromArray:service.rooms];

                if (!lightingService)
                {
                    lightingService = service;
                }
            }
            else if ([deviceServices containsObject:@"SVC_ENV_SHADE"])
            {
                [shadeRooms addObjectsFromArray:service.rooms];

                if (!shadeService)
                {
                    shadeService = service;
                }
            }
        }

        if ([lightingRooms count])
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle: lightingService.service.displayName ?: @"",
                                                  SCUDefaultTableViewCellKeyModelObject: [lightingRooms allObjects],
                                                  SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                                  SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]} mutableCopy];

            UIImage *icon = [UIImage imageNamed:[SAVService iconNameForServiceID:@"SVC_ENV_LIGHTING"]];

            if (icon)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = icon;
            }

            [dataSource addObject:modelObject];

            if (lightingService)
            {
                [sceneService addObject:lightingService];
            }
        }

        if ([shadeRooms count])
        {
            SAVMutableService *service = [[SAVMutableService alloc] init];
            service.serviceId = @"SVC_ENV_SHADE";

            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle: shadeService.service.displayName ?: @"",
                                                  SCUDefaultTableViewCellKeyModelObject: [shadeRooms allObjects],
                                                  SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                                  SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]} mutableCopy];

            UIImage *icon = [UIImage imageNamed:[SAVService iconNameForServiceID:@"SVC_ENV_SHADE"]];

            if (icon)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = icon;
            }

            [dataSource addObject:modelObject];

            if (shadeService)
            {
                [sceneService addObject:shadeService];
            }
        }
    }

    if ([self.scene.hvacServices count])
    {
        NSMutableSet *rooms = [NSMutableSet set];

        for (SAVSceneService *service in self.scene.hvacServices)
        {
            [rooms addObjectsFromArray:service.rooms];
        }

        if ([rooms count])
        {
            SAVSceneService *service = [self.scene.hvacServices lastObject];

            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle: service.service.displayName,
                                                  SCUDefaultTableViewCellKeyModelObject: [rooms allObjects],
                                                  SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                                  SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]} mutableCopy];

            UIImage *icon = [UIImage imageNamed:[SAVService iconNameForServiceID:service.serviceID]];

            if (icon)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = icon;
            }

            [dataSource addObject:modelObject];
            
            [sceneService addObject:service];
        }
    }

    for (SAVServiceGroup *serviceGroup in self.scene.serviceGroups)
    {
        if ([serviceGroup.zones count] && serviceGroup.alias)
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle: serviceGroup.alias,
                                                  SCUDefaultTableViewCellKeyModelObject: serviceGroup.zones,
                                                  SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator),
                                                  SCUDefaultTableViewCellKeyImageTintColor: [[SCUColors shared] color04]} mutableCopy];

            UIImage *icon = [UIImage imageNamed:serviceGroup.iconName];

            if (icon)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = icon;
            }

            [dataSource addObject:modelObject];

            [sceneService addObject:serviceGroup];
        }
    }

    self.sceneServices = sceneService;
    self.dataSource = dataSource;
}

- (SAVService *)serviceForIndexPath:(NSIndexPath *)indexPath
{
    SAVMutableService *service = [[SAVMutableService alloc] init];

    id serviceObj = self.sceneServices[indexPath.row];

    if ([serviceObj isKindOfClass:[SAVSceneService class]])
    {
        SAVSceneService *sceneService = (SAVSceneService *)serviceObj;

        service.logicalComponent = sceneService.logicalComponent;
        service.component = sceneService.component;
        service.serviceId = sceneService.serviceID;
    }
    else if ([serviceObj isKindOfClass:[SAVServiceGroup class]])
    {
        SAVServiceGroup *serviceGroup = (SAVServiceGroup *)serviceObj;
        service = [serviceGroup.services firstObject];
    }
    else
    {
        service.serviceId = serviceObj;
    }

    return [service copy];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Include", nil);
}

@end
