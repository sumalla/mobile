
//
//  SCURoomDistributionModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomDistributionModelPrivate.h"

@interface SCURoomDistributionModel () <ActiveServiceObserver>

@property BOOL hasLoaded;
@property NSArray *activeServices;

@end

@implementation SCURoomDistributionModel

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service
{
    self = [super init];
    if (self)
    {
        self.serviceGroup = [service copy];
        self.activeRooms = @[];
    }
    return self;
}

- (void)dealloc
{
    [[Savant states] removeActiveServiceObserver:self];
}

- (void)loadDataIfNecessary
{
    if (!self.hasLoaded)
    {
        [self.delegate showSpinner];

        //-------------------------------------------------------------------
        // The now playing service group only contains active services,
        // distribution needs to know the complete group
        //-------------------------------------------------------------------
        [self.serviceGroup addService:self.serviceGroup.wildCardedService];

        self.rooms = [[Savant data] sortedRoomsWithRooms:self.serviceGroup.zones];

        self.numberOfChildren = [NSMutableDictionary dictionary];
        self.serviceForRoom = [NSMutableDictionary dictionary];
        NSMutableArray *dataSource = [NSMutableArray array];

        for (NSUInteger i = 0; i < [self.rooms count]; i++)
        {
            NSString *room = self.rooms[i];

            [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle:room}];

            SAVService *activeService = [[Savant states] activeServiceForRoom:room];

            if ([self.serviceGroup.services containsObject:activeService])
            {
                self.serviceForRoom[room] = activeService;
            }
            else
            {
                NSArray *services = [self.serviceGroup avServicesForRoom:room];

                if (![services count])
                {
                    services = [self.serviceGroup audioServicesForRoom:room];
                }

                self.serviceForRoom[room] = [services firstObject];
            }
        }

        self.dataSource = dataSource;

        [self updateActiveRooms:NO];

        for (NSString *room in self.rooms)
        {
            NSIndexPath *indexPath = [self indexPathForRoom:room];

            [self toggleIndexPath:indexPath];
            [self calculateNumberOfChildrenUnderIndexPath:indexPath];
        }

        if ([self respondsToSelector:@selector(loadAdditionalData)])
        {
            [self loadAdditionalData];
        }

        dispatch_async_main(^{
            self.hasLoaded = YES;
            [self.delegate reloadData];
        });

        if ([self sendCommands])
        {
            [[Savant states] addActiveServiceObserver:self];
        }
    }
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    if ([self sendCommands] && self.hasLoaded)
    {
        [self updateActiveRooms:YES];
    }
}

- (BOOL)sendCommands
{
    return YES;
}

- (BOOL)showMasterVolume
{
    return YES;
}

- (BOOL)childIsVariantPicker:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    BOOL isVariantPicker = NO;

    NSInteger childRow = [self.audioOnlyIndexPath isEqual:indexPath] ? 1 : 0;

    if ([[self servicesForIndexPath:indexPath] count] > 1 && child.row == childRow)
    {
        isVariantPicker = YES;
    }

    return isVariantPicker;
}

- (void)calculateNumberOfChildrenUnderIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfChildren = 0;

    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *room = modelObject[SCUDefaultTableViewCellKeyTitle];

    if ([self serviceIsActive:self.serviceForRoom[room]])
    {
        numberOfChildren += 1;
    }

    if ([self.audioOnlyIndexPath isEqual:indexPath])
    {
        numberOfChildren += 1;
    }

    if ([[self servicesForIndexPath:indexPath] count] > 1)
    {
        numberOfChildren += 1;
    }

    self.numberOfChildren[indexPath] = @(numberOfChildren);
}

- (BOOL)serviceIsActive:(SAVService *)service
{
    return [[Savant states].activeServices containsObject:service];
}

#pragma mark - Rooms

- (void)powerOnRoom:(NSString *)room
{
    SAVService *service = self.serviceForRoom[room];

    SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:service];
    serviceRequest.request = @"PowerOn";

    [[Savant control] sendMessage:serviceRequest];

    if ([self.audioOnlyIndexPath isEqual:[self indexPathForRoom:room]])
    {
        self.audioOnlyIndexPath = nil;
    }
}

- (void)powerOffRoom:(NSString *)room
{
    SAVService *service = self.serviceForRoom[room];

    SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:service];
    serviceRequest.request = @"PowerOff";

    [[Savant control] sendMessage:serviceRequest];

    NSIndexPath *indexPath = [self indexPathForRoom:room];

    if ([self indexPathAllowsAudioOnly:indexPath])
    {
        self.serviceForRoom[room] = [[self.serviceGroup avServicesForRoom:room] firstObject];
    }
}

- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath
{
    return self.rooms[indexPath.row];
}

- (NSIndexPath *)indexPathForRoom:(NSString *)room
{
    return [NSIndexPath indexPathForRow:[self.rooms indexOfObject:room] inSection:[self showMasterVolume] ? 1 : 0];
}

#pragma mark - Variants

- (NSString *)selectedServiceForIndexPath:(NSIndexPath *)indexPath
{
    return self.serviceForRoom[self.rooms[indexPath.row]];
}

- (NSArray *)servicesForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *services = nil;
    NSString *room = self.rooms[indexPath.row];

    if ([self indexPathAllowsAudioOnly:indexPath])
    {
        //-------------------------------------------------------------------
        // If we're in the process of picking audio only, show the appropriate choices
        //-------------------------------------------------------------------
        if ([self.audioOnlyIndexPath isEqual:indexPath])
        {
            if (![self indexPathIsAudioOnly:indexPath])
            {
                services = [self.serviceGroup audioServicesForRoom:room];
            }
            else
            {
                services = [self.serviceGroup avServicesForRoom:room];
            }
        }
        else
        {
            if ([self indexPathIsAudioOnly:indexPath])
            {
                services = [self.serviceGroup audioServicesForRoom:room];
            }
            else
            {
                services = [self.serviceGroup avServicesForRoom:room];
            }
        }
    }
    else
    {
        services = [self.serviceGroup servicesForRoom:room];
    }

    return services;
}

- (void)selectService:(SAVService *)service forIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = self.rooms[indexPath.row];

    SAVService *previousService = self.serviceForRoom[room];

    self.serviceForRoom[room] = service;

    if ([self serviceIsActive:previousService])
    {
        if ([self sendCommands])
        {
            [self powerOnRoom:room];
        }
        else
        {
            if ([self respondsToSelector:@selector(addRoom:)])
            {
                [self addRoom:room];
            }
        }
    }
}

#pragma mark - Audio Only

- (BOOL)indexPathIsAudioOnly:(NSIndexPath *)indexPath
{
    NSString *room = [self roomForIndexPath:indexPath];

    NSArray *activeServiceList = [[Savant states] activeServiceListForRoom:room];
    SAVService *roomService = self.serviceForRoom[room];

    return ([self indexPathAllowsAudioOnly:indexPath] &&
            [activeServiceList containsObject:roomService] &&
            [[self.serviceGroup audioServicesForRoom:room] containsObject:roomService]);
}

- (BOOL)indexPathAllowsAudioOnly:(NSIndexPath *)indexPath
{
    NSString *room = [self roomForIndexPath:indexPath];
    return [[self.serviceGroup avServicesForRoom:room] count] && [[self.serviceGroup audioServicesForRoom:room] count];
}

- (void)selectRoomAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.audioOnlyIndexPath)
    {
        NSIndexPath *oldIndexPath = self.audioOnlyIndexPath;
        self.audioOnlyIndexPath = nil;

        [self.delegate updateNumberOfChildrenBelowIndexPath:oldIndexPath updateBlock:^{
            [self calculateNumberOfChildrenUnderIndexPath:oldIndexPath];
        }];

        [self.delegate reconfigureIndexPath:oldIndexPath];

        if ([oldIndexPath isEqual:indexPath])
        {
            return;
        }
    }

    if (indexPath && [self indexPathAllowsAudioOnly:indexPath])
    {
        self.audioOnlyIndexPath = indexPath;

        [self.delegate updateNumberOfChildrenBelowIndexPath:indexPath updateBlock:^{
            [self calculateNumberOfChildrenUnderIndexPath:indexPath];
        }];

        [self.delegate reconfigureIndexPath:indexPath];
    }
}

- (void)enableAudioOnlyForIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = [self roomForIndexPath:indexPath];

    if ([self indexPathIsAudioOnly:indexPath])
    {
        self.serviceForRoom[room] = [[self.serviceGroup avServicesForRoom:room] firstObject];
    }
    else
    {
        self.serviceForRoom[room] = [[self.serviceGroup audioServicesForRoom:room] firstObject];
    }

    [self selectRoomAtIndexPath:indexPath];

    if ([self sendCommands])
    {
        [self powerOnRoom:room];
    }
    else if ([self respondsToSelector:@selector(addRoom:)])
    {
        [self addRoom:room];
    }
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSections
{
    if (self.hasLoaded)
    {
        return [self showMasterVolume] ? 2 : 1;
    }
    else
    {
        return 0;
    }
}

- (BOOL)isFlat
{
    return ![self showMasterVolume];
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return section ? self.dataSource : @[@{SCUVolumeCellKeyServiceGroup: self.serviceGroup,
                                           SCUVolumeCellKeyDisallowGlobalRoomVolume: @YES}];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[self _modelObjectForIndexPath:indexPath] mutableCopy];

    if (indexPath.section)
    {
        NSString *room = self.rooms[indexPath.row];

        BOOL on = [self.activeRooms containsObject:room] ? YES : NO;

        modelObject[SCUToggleSwitchTableViewCellKeyValue] = @(on);

        modelObject[SCUDefaultTableViewCellKeyBottomLineType] = [self numberOfChildrenBelowIndexPath:indexPath] ? @(SCUDefaultTableViewCellBottomLineTypeNone) : @(SCUDefaultTableViewCellBottomLineTypeFull);

        NSArray *activeServiceList = [[Savant states] activeServiceListForRoom:room];

        if ([self indexPathIsAudioOnly:indexPath])
        {
            UIImage *serviceIcon = [UIImage imageNamed:@"NoVideo"];

            if (serviceIcon)
            {
                modelObject[SCUToggleSwitchTableViewCellKeyImage] = [serviceIcon tintedImageWithColor:[[SCUColors shared] color03shade05]];
            }
        }
        else if ([activeServiceList count] && !on)
        {
            SAVService *activeService = [[[Savant states] activeServiceListForRoom:room] firstObject];

            UIImage *serviceIcon = [UIImage imageNamed:activeService.iconName];

            if (serviceIcon)
            {
                modelObject[SCUToggleSwitchTableViewCellKeyImage] = [serviceIcon tintedImageWithColor:[[SCUColors shared] color03shade05]];
            }
        }
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section ? SCURoomDistributionCellTypeToggle : SCURoomDistributionCellTypeVolume;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger type = SCURoomDistributionCellTypeVolume;

    if ([self childIsVariantPicker:child belowIndexPath:indexPath])
    {
        type = SCURoomDistributionCellTypeVariant;
    }

    if (child.row == 0 && [self.audioOnlyIndexPath isEqual:indexPath])
    {
        type = SCURoomDistributionCellTypeAudioOnly;
    }

    return type;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = NSLocalizedString(@"Rooms", nil);

    if (!section)
    {
        title = NSLocalizedString(@"Master Volume", nil);
    }

    return title;
}

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = self.rooms[indexPath.row];
    NSDictionary *modelObject = nil;

    if (child.row == 0 && [self.audioOnlyIndexPath isEqual:indexPath])
    {
        NSString *message = [self indexPathIsAudioOnly:indexPath] ? NSLocalizedString(@"Restore Video", nil) : NSLocalizedString(@"Play Audio Only", nil);
        modelObject = @{SCUDefaultTableViewCellKeyTitle: message};
    }
    else if ([self childIsVariantPicker:child belowIndexPath:indexPath])
    {
        NSString *activeServiceName = [self.serviceForRoom[room] alias];

        modelObject = @{SCUDefaultTableViewCellKeyTitle: activeServiceName ? activeServiceName : @""};
    }
    else
    {
        SAVService *service = self.serviceForRoom[room];

        if (!service)
        {
            service = [[SAVService alloc] init];
        }

        modelObject = @{SCUVolumeCellKeyService: service};
    }

    modelObject = [modelObject dictionaryByAddingObject:@(SCUDefaultTableViewCellBottomLineTypeNone) forKey:SCUDefaultTableViewCellKeyBottomLineType];

    return modelObject;
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    return [self.numberOfChildren[indexPath] integerValue];
}

#pragma mark - Active Service Handler

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    if (self.hasLoaded)
    {
        [self updateActiveRooms:YES];
    }
}

- (void)updateActiveRooms:(BOOL)hasLoaded
{
    if (![self sendCommands])
    {
        return;
    }

    NSArray *originalActiveServices = [NSArray arrayWithArray:self.activeServices];
    NSArray *originalActiveRooms = self.activeRooms;
    NSArray *activeServices = [Savant states].activeServices;
    self.activeServices = activeServices;

    NSMutableSet *activeRooms = [NSMutableSet set];
    NSMutableSet *changedRooms = [NSMutableSet set];

    for (SAVService *activeService in activeServices)
    {
        if ([activeService.identifier isEqualToString:self.serviceGroup.identifier])
        {
            [activeRooms addObject:activeService.zoneName];
            self.serviceForRoom[activeService.zoneName] = activeService;

            if (![originalActiveServices containsObject:activeService])
            {
                [changedRooms addObject:activeService.zoneName];
            }
        }
    }

    if (hasLoaded)
    {
        NSMutableSet *removedActiveRooms = [NSMutableSet setWithArray:originalActiveRooms];
        [removedActiveRooms minusSet:activeRooms];

        [changedRooms addObjectsFromArray:[removedActiveRooms allObjects]];

        if ([changedRooms count])
        {
            self.activeRooms = [activeRooms allObjects];

            for (NSString *room in changedRooms)
            {
                NSIndexPath *indexPath = [self indexPathForRoom:room];

                if (indexPath.row != NSNotFound)
                {
                    [self.delegate updateNumberOfChildrenBelowIndexPath:indexPath updateBlock:^{
                        [self calculateNumberOfChildrenUnderIndexPath:indexPath];
                    }];

                    [self.delegate reconfigureIndexPath:indexPath];
                }
            }

            //-------------------------------------------------------------------
            // Update master volume rooms
            //-------------------------------------------------------------------
            [self.delegate reconfigureIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            [self.delegate updateActiveState:[self.activeRooms count] ? YES : NO];
        }
    }
    else
    {
        self.activeRooms = [activeRooms allObjects];
    }
}

@end
