//
//  SCUSceneServiceRoomModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneServiceRoomModel.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUSliderWithMinMaxImageCell.h"
#import "SCUSceneCreationDataSourcePrivate.h"
#import "SCUSlider.h"
#import "SCURoomDistributionModelPrivate.h"

@interface SCUSceneServiceRoomModel ()

@property SAVScene *originalScene;
@property NSMutableArray *selectedRooms;

@end

@implementation SCUSceneServiceRoomModel

- (instancetype)initWithScene:(SAVScene *)scene andServiceGroup:(SAVServiceGroup *)serviceGroup
{
    self = [super initWithServiceGroup:serviceGroup];
    if (self)
    {
        self.selectedRooms = [NSMutableArray array];
        self.serviceGroup = serviceGroup;
        self.originalScene = [scene copy];
        self.scene = scene;
    }
    return self;
}

- (void)loadAdditionalData
{
    for (NSIndexPath *indexPath in self.expandedIndexPaths)
    {
        [self toggleIndexPath:indexPath];
    }

    for (SAVService *service in self.serviceGroup.services)
    {
        SAVSceneService *sceneService = [self.scene sceneServiceForService:service];

        for (NSString *room in sceneService.rooms)
        {
            NSIndexPath *indexPath = [self indexPathForRoom:room];

            NSString *serviceString = [[self.scene.avPower[room] allKeys] firstObject];

            if ([serviceString isEqualToString:service.serviceString])
            {
                SAVService *service = [[SAVService alloc] initWithString:serviceString];
                self.serviceForRoom[room] = service;

                [self.selectedRooms addObject:room];
                [self toggleIndexPath:indexPath];
                [self calculateNumberOfChildrenUnderIndexPath:indexPath];
            }
        }
    }
}

- (BOOL)sendCommands
{
    return NO;
}

- (BOOL)showMasterVolume
{
    return NO;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return SCURoomDistributionCellTypeToggle;
}

- (NSDictionary *)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[self _modelObjectForIndexPath:indexPath] mutableCopy];
    NSString *room = self.rooms[indexPath.row];

    BOOL on = [self.selectedRooms containsObject:room] ? YES : NO;

    modelObject[SCUToggleSwitchTableViewCellKeyValue] = @(on);

    if ([self indexPathIsAudioOnly:indexPath])
    {
        UIImage *serviceIcon = [UIImage imageNamed:@"NoVideo"];

        if (serviceIcon)
        {
            modelObject[SCUToggleSwitchTableViewCellKeyImage] = [serviceIcon tintedImageWithColor:[[SCUColors shared] color03shade05]];
        }
    }
    else if ([self.scene.avPower[room] count] && !on)
    {
        NSString *activeServiceString = [[self.scene.avPower[room] allKeys] firstObject];

        SAVService *activeService = [[SAVService alloc] initWithString:activeServiceString];

        UIImage *serviceIcon = [UIImage imageNamed:activeService.iconName];

        if (serviceIcon)
        {
            modelObject[SCUToggleSwitchTableViewCellKeyImage] = [serviceIcon tintedImageWithColor:[[SCUColors shared] color03shade05]];
        }
    }
    
    modelObject[SCUDefaultTableViewCellKeyBottomLineType] = [self numberOfChildrenBelowIndexPath:indexPath] ? @(SCUDefaultTableViewCellBottomLineTypeNone) : @(SCUDefaultTableViewCellBottomLineTypeFull);

    return modelObject;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Rooms", nil);
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

        modelObject = @{SCUDefaultTableViewCellKeyTitle: activeServiceName};
    }
    else
    {
        NSMutableDictionary *mModelObject = [@{SCUDefaultTableViewCellKeyModelObject: room,
                                               SCUSliderMinMaxCellKeyDelta: @1,
                                               SCUSliderMinMaxCellKeyMaxValue: @50,
                                               SCUSliderMinMaxCellKeyMinValue: @0} mutableCopy];

        mModelObject[SCUSliderMinMaxCellKeyValue] = self.scene.volume[room] ? self.scene.volume[room] : @25;
        
        modelObject = mModelObject;
    }

    return modelObject;
}

- (void)calculateNumberOfChildrenUnderIndexPath:(NSIndexPath *)indexPath
{
    [super calculateNumberOfChildrenUnderIndexPath:indexPath];

    NSUInteger numberOfChildren = [self.numberOfChildren[indexPath] integerValue];

    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *room = modelObject[SCUDefaultTableViewCellKeyTitle];

    if ([self serviceIsActive:self.serviceForRoom[room]] &&
        ![self.serviceForRoom[room] discreteVolume])
    {
        numberOfChildren -= 1;
    }

    self.numberOfChildren[indexPath] = @(numberOfChildren);
}

- (void)addRoom:(NSString *)room
{
    NSMutableDictionary *roomDict = self.scene.avPower[room];
    if (!roomDict)
    {
        roomDict = [NSMutableDictionary dictionary];
        self.scene.avPower[room] = roomDict;
    }

    SAVService *service = self.serviceForRoom[room];
    SAVSceneService *sceneService = [self.scene sceneServiceForService:service];

    for (NSString *activeServiceString in [roomDict allKeys])
    {
        SAVService *activeService = [[SAVService alloc] initWithString:activeServiceString];
        SAVSceneService *activeSceneService = [self.scene sceneServiceForService:activeService];

        [activeSceneService.rooms removeObject:room];

        if (activeSceneService && ![activeSceneService.rooms count] && ![activeSceneService isEqual:sceneService])
        {
            [self.scene removeAVSceneService:activeSceneService];
        }
    }

    [sceneService.rooms addObject:room];
    [roomDict removeAllObjects];
    roomDict[service.serviceString] = @YES;

    [self.selectedRooms addObject:room];
    self.scene.volume[room] = @25;

    if ([self.audioOnlyIndexPath isEqual:[self indexPathForRoom:room]])
    {
        self.audioOnlyIndexPath = nil;
    }

    [self.delegate updateActiveState:[self hasSelectedRows]];

    NSIndexPath *indexPath = [self indexPathForRoom:room];
    [self.delegate expandIndex:indexPath animated:YES];

    [self.delegate updateNumberOfChildrenBelowIndexPath:indexPath updateBlock:^{
        [self calculateNumberOfChildrenUnderIndexPath:indexPath];
    }];

    [self.delegate reconfigureIndexPath:indexPath];
}

- (void)removeRoom:(NSString *)room
{
    NSMutableDictionary *roomDict = self.scene.avPower[room];
    if (!roomDict)
    {
        roomDict = [NSMutableDictionary dictionary];
        self.scene.avPower[room] = roomDict;
    }

    SAVService *service = self.serviceForRoom[room];
    SAVSceneService *sceneService = [self.scene sceneServiceForService:service];

    [sceneService.rooms removeObject:room];
    [roomDict removeObjectForKey:service.serviceString];

    if (![roomDict count])
    {
        [self.scene.avPower removeObjectForKey:room];
    }

    [self.scene.volume removeObjectForKey:room];

    if ([self.originalScene.avPower[room] count])
    {
        NSString *originalServiceString = [[self.originalScene.avPower[room] allKeys] firstObject];
        SAVService *originalService = nil;

        if ([originalServiceString length])
        {
            originalService = [[SAVService alloc] initWithString:originalServiceString];

            if (![originalService matchesWildcardedService:self.serviceGroup.wildCardedService])
            {
                self.scene.avPower[room] = [self.originalScene.avPower[room] mutableCopy];

                SAVService *activeService = [[SAVService alloc] initWithString:[[self.originalScene.avPower[room] allKeys] firstObject]];
                SAVSceneService *activeSceneService = [self.originalScene sceneServiceForService:activeService];

                if (activeSceneService)
                {
                    [self.scene addAVSceneService:[activeSceneService copy]];
                }

                if (self.originalScene.volume[room])
                {
                    self.scene.volume[room] = self.originalScene.volume[room];
                }
            }
        }
    }

    [self.selectedRooms removeObject:room];

    NSIndexPath *indexPath = [self indexPathForRoom:room];

    if ([self indexPathAllowsAudioOnly:indexPath])
    {
        self.serviceForRoom[room] = [[self.serviceGroup avServicesForRoom:room] firstObject];
    }

    [self selectRoomAtIndexPath:nil];

    [self.delegate updateNumberOfChildrenBelowIndexPath:indexPath updateBlock:^{
        [self calculateNumberOfChildrenUnderIndexPath:indexPath];
    }];

    [self.delegate reconfigureIndexPath:indexPath];
}

- (void)selectRoomAtIndexPath:(NSIndexPath *)indexPath
{
    [super selectRoomAtIndexPath:indexPath];

    if (indexPath && [indexPath isEqual:self.audioOnlyIndexPath])
    {
        [self.delegate expandIndex:indexPath animated:YES];
    }
}

- (void)listenToSlider:(SCUSlider *)slider withParent:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    slider.callback = ^(SCUSlider *changedSlider) {
        SAVStrongWeakSelf;
        NSString *room = sSelf.rooms[indexPath.row];
        sSelf.scene.volume[room] = @(changedSlider.value);
    };
}

- (BOOL)serviceIsActive:(SAVService *)service
{
    return [self.selectedRooms containsObject:service.zoneName];
}

- (BOOL)hasSelectedRows
{
    return [self.selectedRooms count] ? YES : NO;
}

- (BOOL)indexPathIsAudioOnly:(NSIndexPath *)indexPath
{
    NSString *room = [self roomForIndexPath:indexPath];

    SAVService *roomService = self.serviceForRoom[room];

    return ([self indexPathAllowsAudioOnly:indexPath] &&
            [[self.serviceGroup audioServicesForRoom:room] containsObject:roomService]);
}

- (void)doneEditing
{
    for (NSString *room in self.selectedRooms)
    {
        for (NSString *serviceString in self.scene.avPower[room])
        {
            SAVService *service = [[SAVService alloc] initWithString:serviceString];
            if ([self.serviceGroup.services containsObject:service])
            {
                SAVSceneService *sceneService = [self.scene sceneServiceForService:service];
                [sceneService commit];

                if (![sceneService.rooms count])
                {
                    [self.scene removeAVSceneService:sceneService];
                }

                break;
            }
        }
    }
}

@end
