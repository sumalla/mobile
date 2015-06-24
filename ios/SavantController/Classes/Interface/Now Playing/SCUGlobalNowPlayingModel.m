//
//  SCUNowPlayingModel.m
//  SavantController
//
//  Created by Nathan Trapp on 8/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingModel.h"
#import "SCUGlobalNowPlayingStatusCell.h"
#import "SCUGlobalNowPlayingDistributeCell.h"
#import "SCUGlobalNowPlayingTransportsCell.h"
#import "SCUVolumeTableViewCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUGlobalNowPlayingNowPlayingViewController.h"
#import "SCUDataSourceModelPrivate.h"

#import "SCUInterface.h"

#import <SavantControl/SavantControl.h>

// LMQ
static NSString *const CurrentSongName             = @"CurrentSongName";
static NSString *const CurrentArtistName           = @"CurrentArtistName";
static NSString *const CurrentArtworkPath          = @"CurrentArtworkPath";

// Sat Radio
static NSString *const CurrentSatelliteChannelName = @"CurrentSatelliteChannelName";
static NSString *const CurrentSatelliteSongTitle   = @"CurrentSatelliteSongTitle";
static NSString *const CurrentSatelliteArtistName  = @"CurrentSatelliteArtistName";

// Radio
static NSString *const CurrentTunerFrequency       = @"CurrentTunerFrequency";

// Cable/Sat
static NSString *const CurrentMajorChannelNumber   = @"CurrentMajorChannelNumber";
static NSString *const CurrentMinorChannelNumber   = @"CurrentMinorChannelNumber";

// Cable/Sat/Radio
static NSString *const CurrentStation              = @"CurrentStation";

// DVD/CD/Bluray
static NSString *const CurrentDiskNumber           = @"CurrentDiskNumber";
static NSString *const CurrentTrack                = @"CurrentTrack";
static NSString *const CurrentChapter              = @"CurrentChapter";

@interface SCUGlobalNowPlayingModel () <ActiveServiceObserver, StateDelegate>

@property SAVCoalescedTimer *loadServicesTimer;
@property NSArray *dataSource;
@property NSArray *registeredStates;
@property NSMutableDictionary *serviceMap;
@property NSMutableDictionary *cachedStates;
@property NSArray *lastActiveServices;
@property SAVCoalescedTimer *reloadDataTimer;
@property NSMutableDictionary *stateScopeToServiceGroup;
@property SAVDISRequestGenerator *generator;
@property NSMutableDictionary *favoritesForServiceType;
@property NSMutableArray *favoriteStates;
@property NSMutableDictionary *artworkForService;
@property NSArray *serviceOrder;
@property NSArray *serviceGroups;
@property NSDictionary *dataSourceBelowService;
@property NSMutableDictionary *numberOfChildrenBelowService;
@property NSMutableArray *autoExpandedServices;
@property NSTimer *autoCollapseTimer;

@end

@implementation SCUGlobalNowPlayingModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.loadServicesTimer = [[SAVCoalescedTimer alloc] init];
        self.loadServicesTimer.timeInverval = 0;
        self.autoExpandedServices = [NSMutableArray array];

        self.numberOfChildrenBelowService = [NSMutableDictionary dictionary];
        self.artworkForService = [NSMutableDictionary dictionary];
        self.cachedStates = [NSMutableDictionary dictionary];
        self.stateScopeToServiceGroup = [NSMutableDictionary dictionary];
        self.reloadDataTimer = [[SAVCoalescedTimer alloc] init];
        self.reloadDataTimer.timeInverval = 0;

        self.favoritesForServiceType = [NSMutableDictionary dictionary];
        self.favoriteStates = [NSMutableArray array];

        self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"channelFavorites"];
    }
    return self;
}

- (void)dealloc
{
    [[SavantControl sharedControl] unregisterForStates:self.favoriteStates forObserver:self];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [[SavantControl sharedControl] registerForStates:self.registeredStates forObserver:self];
    [[SavantControl sharedControl].stateManager addActiveServiceObserver:self];
    [self reloadServices];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    [[SavantControl sharedControl] unregisterForStates:self.registeredStates forObserver:self];
    [[SavantControl sharedControl].stateManager removeActiveServiceObserver:self];
}

- (void)loadServices:(NSArray *)services
{
    if ([self.lastActiveServices isEqualToArray:services])
    {
        return;
    }

    if (!self.lastActiveServices)
    {
        [self.delegate showSpinner];
    }

    self.lastActiveServices = services;

    NSArray *serviceGroups = [[SavantControl sharedControl].data serviceGroupsForServices:services];

    NSMutableSet *newGroups = [NSMutableSet setWithArray:[serviceGroups arrayByMappingBlock:^id(SAVServiceGroup *serviceGroup) {
        return serviceGroup.identifier;
    }]];

    [newGroups minusSet:[NSSet setWithArray:self.serviceOrder]];

    NSMutableSet *removedGroups = [NSMutableSet setWithArray:self.serviceOrder];

    [removedGroups minusSet:[NSSet setWithArray:[serviceGroups arrayByMappingBlock:^id(SAVServiceGroup *serviceGroup) {
        return serviceGroup.identifier;
    }]]];

    for (SAVServiceGroup *group in removedGroups)
    {
        [self.autoExpandedServices removeObject:group];
    }

    //-------------------------------------------------------------------
    // Reload parents and children if we have a new group
    //-------------------------------------------------------------------
    if ([newGroups count] || [removedGroups count])
    {
        NSMutableArray *expendedServices = [NSMutableArray array];
        NSMutableArray *oldExpandedIndexes = [self.expandedIndexPaths mutableCopy];

        //-------------------------------------------------------------------
        // Store the previous expanded services, so we can keep them expanded
        //-------------------------------------------------------------------
        for (NSIndexPath *indexPath in oldExpandedIndexes)
        {
            [self toggleIndexPath:indexPath];

            SAVServiceGroup *serviceGroup = [self serviceGroupForSection:indexPath.section];
            [expendedServices addObject:serviceGroup.identifier];
        }

        NSMutableArray *dataSource = [NSMutableArray array];
        NSMutableDictionary *serviceMap = [NSMutableDictionary dictionary];
        NSMutableSet *newStates = [NSMutableSet set];
        NSMutableDictionary *dataSourceBelowService = [NSMutableDictionary dictionary];
        NSMutableDictionary *numberOfChildrenBelowService = [NSMutableDictionary dictionary];

        for (SAVServiceGroup *serviceGroup in serviceGroups)
        {
            NSString *scope = serviceGroup.identifier;

            NSMutableDictionary *serviceData = serviceMap[scope];

            if (!serviceData)
            {
                if (self.serviceMap[scope])
                {
                    serviceData = self.serviceMap[scope];
                }
                else
                {
                    serviceData = [NSMutableDictionary dictionary];
                }

                serviceMap[scope] = serviceData;

                [serviceData addEntriesFromDictionary:@{SCUGlobalNowPlayingStatusCellKeyServiceGroup: serviceGroup}];

                NSMutableArray *sectionData = [NSMutableArray array];

                [sectionData addObject:serviceData];

                // Transports
                if ([[SCUGlobalNowPlayingNowPlayingViewController transportButtonsForServiceGroup:serviceGroup] count])
                {
                    [sectionData addObject:@{SCUGlobalNowPlayingTransportsCellKeyServiceGroup: serviceGroup}];
                }

                // Volume
                [sectionData addObject:@{SCUVolumeCellKeyServiceGroup: serviceGroup}];

                // Distribution
                [sectionData addObject:@{SCUGlobalNowPlayingDistributeCellKeyServiceGroup: serviceGroup}];

                [dataSource addObject:sectionData];

                NSArray *childData = [self childDataForServiceGroup:serviceGroup excludingService:nil];

                dataSourceBelowService[serviceGroup.identifier] = childData;

                numberOfChildrenBelowService[serviceGroup.identifier] = @([childData count]);
            }


            NSString *stateScope = serviceGroup.stateScope;
            self.stateScopeToServiceGroup[stateScope] = serviceGroup;

            if (stateScope)
            {
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentSongName]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentArtistName]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentArtworkPath]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentSatelliteChannelName]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentSatelliteSongTitle]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentSatelliteArtistName]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentTunerFrequency]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentMajorChannelNumber]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentMinorChannelNumber]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentStation]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentDiskNumber]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentChapter]];
                [newStates addObject:[stateScope stringByAppendingFormat:@".%@", CurrentTrack]];
            }
        }

        __block SAVServiceGroup *activeService = nil;

        [dataSource sortUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
            NSComparisonResult result = NSOrderedAscending;

            SAVServiceGroup *service1 = [obj1 firstObject][SCUGlobalNowPlayingStatusCellKeyServiceGroup];
            SAVServiceGroup *service2 = [obj2 firstObject][SCUGlobalNowPlayingStatusCellKeyServiceGroup];

            //-------------------------------------------------------------------
            // The service for the current room should always be at the top
            //-------------------------------------------------------------------
            if ([service1.zones containsObject:[SCUInterface sharedInstance].currentRoom.roomId] ||
                [service1 matchesWildcardedService:[SCUInterface sharedInstance].currentService])
            {
                activeService = service1;

                result = NSOrderedAscending;
            }
            else if (([service2.zones containsObject:[SCUInterface sharedInstance].currentRoom.roomId] ||
                      [service2 matchesWildcardedService:[SCUInterface sharedInstance].currentService]))
            {
                activeService = service2;

                result = NSOrderedDescending;
            }
            else
            {
                result = [[service1 alias] compare:[service2 alias]];
            }

            return result;
        }];

        NSSet *previousStates = [NSSet setWithArray:self.registeredStates];
        NSMutableSet *removedStates = [NSMutableSet setWithSet:previousStates];

        self.registeredStates = [newStates allObjects];

        [removedStates minusSet:newStates];
        [newStates minusSet:previousStates];

        NSMutableArray *serviceGroupList = [NSMutableArray array];

        self.serviceOrder = [dataSource arrayByMappingBlock:^id(NSArray *object) {
            SAVServiceGroup *serviceGroup = [object firstObject][SCUGlobalNowPlayingStatusCellKeyServiceGroup];
            [serviceGroupList addObject:serviceGroup];
            return serviceGroup.identifier;
        }];

        self.dataSourceBelowService = dataSourceBelowService;
        self.serviceGroups = serviceGroupList;
        self.numberOfChildrenBelowService = numberOfChildrenBelowService;

        if ([newStates count])
        {
            [[SavantControl sharedControl] registerForStates:[newStates allObjects] forObserver:self];
        }

        if ([removedStates count])
        {
            [[SavantControl sharedControl] unregisterForStates:[previousStates allObjects] forObserver:self];

            for (NSString *state in removedStates)
            {
                [self.cachedStates removeObjectForKey:state];
            }
        }

        self.serviceMap = serviceMap;
        self.dataSource = dataSource;

        if (activeService &&
            [self.numberOfChildrenBelowService[activeService.identifier] integerValue] > 2)
        {
            [self expandRoomVolumeForSection:[self sectionForIdentifier:activeService.identifier] animated:NO];
        }

        for (NSString *identifier in expendedServices)
        {
            NSInteger section = [self sectionForIdentifier:identifier];
            if (section != NSNotFound)
            {
                [self expandRoomVolumeForSection:section animated:NO];
            }
        }

        //-------------------------------------------------------------------
        // Delayed to handle when multiple rooms for the same service power off
        //-------------------------------------------------------------------
        [self reloadDataAfterDelay];
    }
    else
    {
        //-------------------------------------------------------------------
        // Reload child data only
        //-------------------------------------------------------------------
        NSArray *changedGroups = [serviceGroups arrayByMappingBlock:^id(SAVServiceGroup *serviceGroup) {
            return [self.serviceGroups containsObject:serviceGroup] ? nil : serviceGroup;
        }];

        NSMutableDictionary *dataSourceBelowService = [self.dataSourceBelowService mutableCopy];

        for (SAVServiceGroup *serviceGroup in changedGroups)
        {
            NSArray *childData = [self childDataForServiceGroup:serviceGroup excludingService:nil];
            NSInteger section = [self sectionForIdentifier:serviceGroup.identifier];

            SAVServiceGroup *originalServiceGroup = [self serviceGroupForSection:[self sectionForIdentifier:serviceGroup.identifier]];

            NSMutableSet *newServices = [NSMutableSet setWithArray:serviceGroup.services];
            [newServices minusSet:[NSSet setWithArray:originalServiceGroup.services]];

            NSMutableSet *removedServices = [NSMutableSet setWithArray:originalServiceGroup.services];
            [removedServices minusSet:[NSSet setWithArray:serviceGroup.services]];

            for (SAVService *service in newServices)
            {
                [originalServiceGroup addService:service];
            }

            for (SAVService *service in removedServices)
            {
                [originalServiceGroup removeService:service];
            }

            if ([newServices count] || [removedServices count])
            {
                dataSourceBelowService[serviceGroup.identifier] = childData;

                dispatch_async_main(^{
                    self.dataSourceBelowService = [dataSourceBelowService copy];

                    if ([self.expandedIndexPaths containsObject:[self volumeIndexPathForSection:section]])
                    {
                        [self.delegate updateNumberOfChildrenBelowIndexPath:[self volumeIndexPathForSection:section] animated:YES updateBlock:^{
                            self.numberOfChildrenBelowService[serviceGroup.identifier] = @([childData count]);
                        }];
                    }
                    else
                    {
                        self.numberOfChildrenBelowService[serviceGroup.identifier] = @([childData count]);
                    }

                    // Update volume slider style
                    [self.delegate reconfigureIndexPath:[self volumeIndexPathForSection:section]];
                });
            }
        }
    }
}

- (void)reloadDataAfterDelay
{
    SAVWeakSelf;
    [self.reloadDataTimer addWorkWithKey:@"reloadData" work:^{
        [wSelf.delegate reloadData];
    }];
}

- (BOOL)isFlat
{
    return NO;
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    SAVServiceGroup *serviceGroup = [self serviceGroupForSection:indexPath.section];

    return [self.numberOfChildrenBelowService[serviceGroup.identifier] integerValue];
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    SAVServiceGroup *serviceGroup = [self serviceGroupForSection:indexPath.section];

    return self.dataSourceBelowService[serviceGroup.identifier];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    if ([self.artworkForService count] && indexPath.row == 0)
    {
        modelObject = [modelObject dictionaryByAddingObject:@(YES) forKey:SCUGlobalNowPlayingDistributeCellKeyArtworkPresent];
    }

    if ([self numberOfSections] > indexPath.section)
    {
        if ((indexPath.row + 1) == [self numberOfParentsInSection:indexPath.section])
        {
            modelObject = [modelObject dictionaryByAddingObject:@([self.expandedIndexPaths containsObject:[self volumeIndexPathForSection:indexPath.section]]) forKey:SCUGlobalNowPlayingDistributeCellKeyExpanded];
        }

        return modelObject;
    }
    else
    {
        return nil;
    }
}

- (NSInteger)numberOfParentsInSection:(NSInteger)section
{
    NSInteger numberOfItems = NSNotFound;

    if ((NSInteger)[self.dataSource count] > section)
    {
        numberOfItems = [self.dataSource[section] count];
    }

    return numberOfItems;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUGlobalNowPlayingCellTypes type = SCUGlobalNowPlayingCellType_Status;

    NSUInteger index = indexPath.row;

    if (index > 0 && [self numberOfParentsInSection:indexPath.section] == 3)
    {
        index++;
    }

    switch (index)
    {
        case 0:
            type = SCUGlobalNowPlayingCellType_Status;
            break;
        case 1:
            type = SCUGlobalNowPlayingCellType_Transports;
            break;
        case 2:
            type = SCUGlobalNowPlayingCellType_Volume;
            break;
        case 3:
            type = SCUGlobalNowPlayingCellType_Distribute;
            break;
    }

    return type;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUGlobalNowPlayingCellTypes type = SCUGlobalNowPlayingCellType_Toggle;

    if (child.row % 2)
    {
        type = SCUGlobalNowPlayingCellType_Volume;
    }

    return type;
}

- (SAVServiceGroup *)serviceGroupForSection:(NSInteger)section
{
    SAVServiceGroup *serviceGroup = nil;

    if (section < (NSInteger)[self.serviceGroups count])
    {
        serviceGroup = self.serviceGroups[section];
    }

    return serviceGroup;
}

- (NSInteger)sectionForIdentifier:(NSString *)identifier
{
    return [self.serviceOrder indexOfObject:identifier];
}

- (NSIndexPath *)indexForServiceGroup:(SAVServiceGroup *)serviceGroup
{
    NSInteger index = [self.serviceOrder indexOfObject:serviceGroup.identifier];
    NSIndexPath *indexPath = nil;

    if (index != NSNotFound)
    {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    }

    return indexPath;
}

- (BOOL)toggleRoomVolumeForSection:(NSInteger)section
{    BOOL expanded = NO;
    NSIndexPath *volumeIndex = [self volumeIndexPathForSection:section];

    if ([self.expandedIndexPaths containsObject:volumeIndex])
    {
        [self collapseRoomVolumeForSection:section];
    }
    else
    {
        [self expandRoomVolumeForSection:section];
        expanded = YES;
    }

    return expanded;
}

- (void)expandRoomVolumeForSection:(NSInteger)section
{
    [self expandRoomVolumeForSection:section animated:YES];
}

- (void)expandRoomVolumeForSection:(NSInteger)section animated:(BOOL)animated
{
    NSIndexPath *volumeIndex = [self volumeIndexPathForSection:section];

    [self.delegate expandIndex:volumeIndex animated:animated];
    [self.delegate reconfigureIndexPath:[NSIndexPath indexPathForItem:volumeIndex.row + 1 inSection:section]];
}

- (void)collapseRoomVolumeForSection:(NSInteger)section animated:(BOOL)animated
{
    NSIndexPath *volumeIndex = [self volumeIndexPathForSection:section];
    [self.delegate collapseIndex:volumeIndex animated:animated];
    [self.delegate reconfigureIndexPath:[NSIndexPath indexPathForItem:volumeIndex.row + 1 inSection:section]];
    [self.autoExpandedServices removeObject:[self serviceGroupForSection:section].identifier];
}

- (void)collapseRoomVolumeForSection:(NSInteger)section
{
    [self collapseRoomVolumeForSection:section animated:YES];
}

- (void)autoExpandRoomVolumeForSection:(NSInteger)section
{
    if (![self.expandedIndexPaths containsObject:[self volumeIndexPathForSection:section]])
    {
        SAVServiceGroup *serviceGroup = [self serviceGroupForSection:section];

        if ([self.numberOfChildrenBelowService[serviceGroup.identifier] integerValue] > 2)
        {
            if (serviceGroup.identifier)
            {
                [self.autoExpandedServices addObject:serviceGroup.identifier];
            }

            dispatch_next_runloop(^{
                [self expandRoomVolumeForSection:section];
            });
        }
    }

    [self userInteractionDetected];
}

- (void)userInteractionDetected
{
    [self.autoCollapseTimer invalidate];

    if (![self.autoExpandedServices count])
    {
        self.autoCollapseTimer = nil;
    }
    else
    {
        self.autoCollapseTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(collapseAutoExpandedServices) userInfo:nil repeats:NO];
    }
}

- (void)collapseAutoExpandedServices
{
    for (NSString *identifier in [self.autoExpandedServices copy])
    {
        [self collapseRoomVolumeForSection:[self sectionForIdentifier:identifier]];
    }

    [self.autoExpandedServices removeAllObjects];
}

- (NSIndexPath *)volumeIndexPathForSection:(NSInteger)section
{
    NSInteger numberOfItems = [self numberOfParentsInSection:section];
    NSIndexPath *indexPath = nil;

    if (numberOfItems >= 3)
    {
        indexPath = [NSIndexPath indexPathForItem:numberOfItems - 2 inSection:section];
    }

    return indexPath;
}

- (void)powerOffService:(SAVService *)service
{
    SAVServiceRequest *request = [[SAVServiceRequest alloc] initWithService:service];
    request.request = @"PowerOff";
    [[SavantControl sharedControl] sendMessage:request];
}

- (NSArray *)childDataForServiceGroup:(SAVServiceGroup *)serviceGroup excludingService:(SAVService *)service
{
    NSMutableArray *serviceData = [NSMutableArray array];

    NSMutableArray *activeServices = [serviceGroup.activeServices mutableCopy];

    NSArray *allRooms = [[SavantControl sharedControl].data allRoomIds];

    [activeServices sortUsingComparator:^NSComparisonResult(SAVService *obj1, SAVService *obj2) {
        if ([obj1 isEqual:[SCUInterface sharedInstance].currentService])
        {
            return NSOrderedAscending;
        }
        else if ([obj2 isEqual:[SCUInterface sharedInstance].currentService])
        {
            return NSOrderedDescending;
        }
        else
        {
            return [allRooms indexOfObject:obj1.zoneName] < [allRooms indexOfObject:obj2.zoneName] ? NSOrderedAscending : NSOrderedDescending;
        }
    }];

    for (SAVService *activeService in activeServices)
    {
        if (![activeService isEqual:service])
        {
            [serviceData addObject:@{SCUDefaultTableViewCellKeyTitle: activeService.zoneName,
                                     SCUToggleSwitchTableViewCellKeyValue: @YES,
                                     SCUToggleSwitchTableViewCellKeyAnimate: @NO,
                                     SCUDefaultTableViewCellKeyModelObject: activeService}];
            [serviceData addObject:@{SCUVolumeCellKeyService: activeService}];
        }
    }

    return [serviceData copy];
}

#pragma mark - State Observers

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    NSArray *scopeComponents = [stateUpdate.scope componentsSeparatedByString:@"."];

    if ([scopeComponents count] == 2)
    {
        NSString *component = scopeComponents[0];

        if ([stateUpdate.value length])
        {
            self.cachedStates[stateUpdate.state] = stateUpdate.value;
        }
        else
        {
            [self.cachedStates removeObjectForKey:stateUpdate.state];
        }

        SAVServiceGroup *serviceGroup = self.stateScopeToServiceGroup[stateUpdate.scope];

        if (serviceGroup)
        {
            SAVService *service = [serviceGroup.activeServices firstObject];
            NSString *serviceId = serviceGroup.serviceId;


            if ([SAVService serviceID:serviceId
                    matchesServiceIDs:@[@"SVC_AV_AMRADIO",
                                        @"SVC_AV_FMRADIO",
                                        @"SVC_AV_MULTIBANDRADIO",
                                        @"SVC_AV_TV",
                                        @"SVC_AV_SATELLITETV"]
                 includeAudioVariants:YES])
            {
                [self updateFavoriteForServiceGroup:serviceGroup];
            }
            else
            {
                NSMutableDictionary *serviceData = self.serviceMap[serviceGroup.identifier];
                NSString *statusString = [self statusStringForService:service];
                NSIndexPath *indexPath = [self indexForServiceGroup:serviceGroup];

                if (([serviceId containsString:@"LIVEMEDIAQUERY"] ||
                     [serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"]) &&
                    [stateUpdate.stateName isEqualToString:CurrentArtworkPath])
                {
                    [self.artworkForService removeObjectForKey:serviceGroup.identifier];

                    if ([stateUpdate.value length])
                    {
                        SAVWeakSelf;
                        [[SavantControl sharedControl].imageModel imageForKey:stateUpdate.value
                                                                         type:SAVImageTypeLMQNowPlayingArtwork
                                                                         size:SAVImageSizeOriginal
                                                                      blurred:NO
                                                         requestingIdentifier:self
                                                          componentIdentifier:component
                                                            completionHandler:^(UIImage *image, BOOL isDefault) {
                                                                SAVStrongWeakSelf;
                                                                if (image)
                                                                {
                                                                    NSIndexPath *currentIndexPath = [self indexForServiceGroup:serviceGroup];

                                                                    if (currentIndexPath)
                                                                    {
                                                                        sSelf.artworkForService[serviceGroup.identifier] = image;

                                                                        [sSelf.delegate reloadBackgroundForSection:currentIndexPath.section];
                                                                        [sSelf.delegate reconfigureIndexPath:indexPath];
                                                                    }
                                                                }
                                                            }];
                    }
                }

                if ([statusString length])
                {
                    serviceData[SCUGlobalNowPlayingStatusCellKeyStatus] = statusString;
                }
                else
                {
                    [serviceData removeObjectForKey:SCUGlobalNowPlayingStatusCellKeyStatus];
                }

                if ([self isIndexPathValid:indexPath])
                {
                    [self.delegate reconfigureIndexPath:indexPath];
                }
            }
        }
    }
}

- (NSString *)statusStringForServiceGroup:(SAVServiceGroup *)service
{
    return [self statusStringForService:[service.services firstObject]];
}

- (NSString *)statusStringForService:(SAVService *)service
{
    NSString *statusString = @"";
    NSString *serviceId = service.serviceId;
    NSString *scope = [NSString stringWithFormat:@"%@.%@", service.component, service.logicalComponent];
    NSString *currentStation = [self currentStationForService:service];

    if ([serviceId hasPrefix:@"SVC_AV_SATELLITERADIO"])
    {
        statusString = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentSatelliteSongTitle]];

        NSString *currentArtist = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentSatelliteArtistName]];

        if ([currentArtist length])
        {
            if ([statusString length])
            {
                statusString = [statusString stringByAppendingString:@" - "];
            }

            statusString = [statusString stringByAppendingString:currentArtist];
        }

        NSString *currentChannel = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentSatelliteChannelName]];

        if ([currentChannel length])
        {
            if ([statusString length])
            {
                statusString = [statusString stringByAppendingString:@" - "];
            }

            statusString = [statusString stringByAppendingString:currentChannel];
        }

        if (![statusString length] && [currentStation length])
        {
            statusString = currentStation;
        }
    }
    else if ([SAVService serviceID:serviceId
                 matchesServiceIDs:@[@"SVC_AV_DVD",
                                     @"SVC_AV_ENHANCEDDVD",
                                     @"SVC_AV_CD"]
              includeAudioVariants:YES])
    {
        NSString *currentTrack = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentTrack]];
        NSString *currentChapter = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentChapter]];
        NSString *currentDisk = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentDiskNumber]];

        if ([currentTrack length])
        {
            statusString = [statusString stringByAppendingString:[NSLocalizedString(@"Track", nil) stringByAppendingFormat:@" %@", currentTrack]];
        }

        if ([currentChapter length])
        {
            if ([statusString length])
            {
                statusString = [statusString stringByAppendingString:@" - "];
            }

            statusString = [statusString stringByAppendingString:[NSLocalizedString(@"Chapter", nil) stringByAppendingFormat:@" %@", currentDisk]];
        }

        if ([currentDisk length])
        {
            if ([statusString length])
            {
                statusString = [statusString stringByAppendingString:@" - "];
            }

            statusString = [statusString stringByAppendingString:[NSLocalizedString(@"Disc", nil) stringByAppendingFormat:@" %@", currentDisk]];
        }
    }
    else if ([serviceId containsString:@"LIVEMEDIAQUERY"] ||
             [serviceId containsString:@"APPLEREMOTEMEDIASERVER"] ||
             [serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"])
    {
        statusString = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentSongName]];

        NSString *currentArtist = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentArtistName]];

        if ([currentArtist length])
        {
            if ([statusString length])
            {
                statusString = [statusString stringByAppendingString:@" - "];
            }

            statusString = [statusString stringByAppendingString:currentArtist];
        }
    }

    if (currentStation && ![statusString length])
    {
        NSString *stationPrefix = nil;
        if ([serviceId hasPrefix:@"SVC_AV_SATELLITETV"] ||
            [serviceId hasPrefix:@"SVC_AV_TV"])
        {
            stationPrefix = NSLocalizedString(@"Channel", nil);
        }

        if (stationPrefix)
        {
            statusString = [stationPrefix stringByAppendingFormat:@" %@", currentStation];
        }
        else
        {
            statusString = currentStation;
        }

        NSString *serviceType = [self fetchFavoritesForService:service];

        for (SAVFavorite *favorite in self.favoritesForServiceType[serviceType])
        {
            if ([favorite.number isEqualToString:currentStation])
            {
                if ([favorite.name length])
                {
                    statusString = [favorite.name stringByAppendingFormat:@" - %@", statusString];
                }
            }
        }
    }

    return [statusString length] ? statusString : nil;
}

- (UIImage *)artworkForSection:(NSInteger)section
{
    SAVServiceGroup *serviceGroup = [self serviceGroupForSection:section];

    return self.artworkForService[serviceGroup.identifier];
}

- (NSString *)currentStationForService:(SAVService *)service
{
    NSString *serviceId = service.serviceId;
    NSString *scope = [NSString stringWithFormat:@"%@.%@", service.component, service.logicalComponent];
    NSString *currentStation = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentStation]];

    if ([SAVService serviceID:serviceId
            matchesServiceIDs:@[@"SVC_AV_AMRADIO",
                                @"SVC_AV_FMRADIO",
                                @"SVC_AV_MULTIBANDRADIO"]
         includeAudioVariants:YES])
    {
        NSString *currentFrequency = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentTunerFrequency]];

        if ([currentFrequency length])
        {
            currentStation = currentFrequency;
        }
    }
    else if ([serviceId hasPrefix:@"SVC_AV_SATELLITETV"] ||
             [serviceId hasPrefix:@"SVC_AV_TV"])
    {
        NSString *currentMajorChannel = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentMajorChannelNumber]];
        NSString *currentMinorChannel = self.cachedStates[[scope stringByAppendingFormat:@".%@", CurrentMinorChannelNumber]];

        if ([currentMajorChannel length])
        {
            currentStation = currentMajorChannel;

            if ([currentMinorChannel length])
            {
                currentStation = [currentStation stringByAppendingFormat:@"%@", currentMinorChannel];
            }
        }
    }

    return currentStation;
}

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    [self reloadServices];
}

- (void)reloadServices
{
    SAVWeakSelf;
    [self.loadServicesTimer addWorkWithKey:@"loadServices" work:^{
        [wSelf loadLatestServices];
    }];
}

- (void)loadLatestServices
{
    [self loadServices:[SavantControl sharedControl].stateManager.activeServices];
}

- (void)room:(NSString *)roomId didUpdateMuteStatus:(BOOL)muted
{

}

- (void)room:(NSString *)roomId didUpdateVolume:(NSNumber *)volume
{

}

#pragma mark - Favorites

- (NSString *)fetchFavoritesForService:(SAVService *)service
{
    NSString *serviceType = [SAVServiceGroup genericServiceIdForServiceId:service.serviceId];

    NSString *favoriteState = [[self.generator feedbackStringsWithStateNames:@[[NSString stringWithFormat:@"favorites.%@", serviceType]]] lastObject];
    if (![self.favoriteStates containsObject:favoriteState])
    {
        [self.favoriteStates addObject:favoriteState];
        [[SavantControl sharedControl] registerForStates:@[favoriteState] forObserver:self];
    }

    return serviceType;
}

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    NSString *serviceType = feedback.stateName;

    NSMutableArray *favorites = [NSMutableArray array];
    for (NSDictionary *favoriteSettings in feedback.value)
    {
        [favorites addObject:[SAVFavorite favoriteWithSettings:favoriteSettings]];
    }

    self.favoritesForServiceType[serviceType] = favorites;

    for (SAVServiceGroup *serviceGroup in [self.stateScopeToServiceGroup allValues])
    {
        if ([serviceGroup.serviceId isEqualToString:serviceType])
        {
            [self updateFavoriteForServiceGroup:serviceGroup];
        }
    }
}

- (void)updateFavoriteForServiceGroup:(SAVServiceGroup *)serviceGroup
{
    SAVService *service = [serviceGroup.services firstObject];
    NSMutableDictionary *serviceData = self.serviceMap[serviceGroup.identifier];
    NSString *statusString = [self statusStringForService:service];
    NSIndexPath *indexPath = [self indexForServiceGroup:serviceGroup];

    [self.artworkForService removeObjectForKey:serviceGroup.identifier];

    NSString *currentStation = [self currentStationForService:service];

    NSString *serviceType = [self fetchFavoritesForService:service];

    for (SAVFavorite *favorite in self.favoritesForServiceType[serviceType])
    {
        if ([favorite.number isEqualToString:currentStation])
        {
            if (favorite.image)
            {
                self.artworkForService[serviceGroup.identifier] = favorite.image;
            }
            else
            {
                SAVWeakSelf;
                favorite.imageChangeCallback = ^(UIImage *image){
                    SAVStrongWeakSelf;
                    if (image)
                    {
                        NSIndexPath *currentIndexPath = [sSelf indexForServiceGroup:serviceGroup];
                        
                        if (currentIndexPath)
                        {
                            sSelf.artworkForService[serviceGroup.identifier] = image;
                            
                            [sSelf.delegate reloadBackgroundForSection:currentIndexPath.section];
                        }
                    }
                };
            }
            
            break;
        }
    }
    
    if ([statusString length])
    {
        serviceData[SCUGlobalNowPlayingStatusCellKeyStatus] = statusString;
    }
    else
    {
        [serviceData removeObjectForKey:SCUGlobalNowPlayingStatusCellKeyStatus];
    }
    
    if ([self isIndexPathValid:indexPath])
    {
        [self.delegate reconfigureIndexPath:indexPath];
    }
}

@end
