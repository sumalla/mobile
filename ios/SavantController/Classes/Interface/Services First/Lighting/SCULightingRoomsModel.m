//
//  SCULightingRoomsModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingRoomsModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import <SavantControl/SavantControl.h>
#import "SCUDefaultTableViewCell.h"

static NSString *SCULightingRoomsModelStateKey = @"SCULightingRoomsModelStateKey";

@interface SCULightingRoomsModel () <StateDelegate>

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) NSIndexPath *lastSelectedIndexPath;
@property (nonatomic, copy) NSArray *states;
@property (nonatomic) NSMutableDictionary *stateValues;
@property (nonatomic) SAVCoalescedTimer *reloadTimer;
@property (nonatomic) BOOL shadesOnly;

@end

@implementation SCULightingRoomsModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];

    if (self)
    {
        if ([service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
        {
            self.shadesOnly = YES;
        }

        NSMutableSet *states = [NSMutableSet set];

        NSArray *dataSource = [[[SavantControl sharedControl].data allRooms] arrayByMappingBlock:^id(SAVRoom *room) {
            if (self.shadesOnly && room.hasShades)
            {
                return room.roomId;
            }
            else if (!self.shadesOnly && (room.hasLighting || room.hasFans))
            {
                [states addObject:[NSString stringWithFormat:@"%@.RoomLightsAreOn", room.roomId]];
                return room.roomId;
            }
            else
            {
                return nil;
            }
        }];

        self.dataSource = [dataSource arrayByMappingBlock:^id(NSString *room) {
            return @{SCUDefaultTableViewCellKeyTitle: room,
                     SCULightingRoomsModelStateKey: [NSString stringWithFormat:@"%@.RoomLightsAreOn", room]};
        }];

        self.states = [states allObjects];
        self.stateValues = [NSMutableDictionary dictionary];
        self.reloadTimer = [[SAVCoalescedTimer alloc] init];
        self.reloadTimer.timeInverval = .1;
    }

    return self;
}

- (NSString *)firstRoom
{
    self.lastSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    return [self.dataSource firstObject][SCUDefaultTableViewCellKeyTitle];
}

- (NSIndexPath *)indexPathForRoom:(NSString *)room
{
    __block NSIndexPath *indexPath = nil;

    [self.dataSource enumerateObjectsUsingBlock:^(NSDictionary *modelObject, NSUInteger idx, BOOL *stop) {
        if ([modelObject[SCUDefaultTableViewCellKeyTitle] isEqualToString:room])
        {
            indexPath = [NSIndexPath indexPathForItem:idx inSection:0];

            if (stop)
            {
                *stop = YES;
            }
        }
    }];

    return indexPath;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    if ([self.states count])
    {
        [[SavantControl sharedControl] registerForStates:self.states forObserver:self];
    }
}

- (void)viewDidDisappear
{
    if ([self.states count])
    {
        [[SavantControl sharedControl] unregisterForStates:self.states forObserver:self];
    }
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    NSString *state = modelObject[SCULightingRoomsModelStateKey];

    if ([self.stateValues[state] boolValue])
    {
        NSMutableDictionary *mModelObject = [modelObject mutableCopy];
        mModelObject[SCUDefaultTableViewCellKeyRightImageName] = @"Lighting";
        mModelObject[SCUDefaultTableViewCellKeyRightImageTintColor] = [[SCUColors shared] color04];
        modelObject = [mModelObject copy];
    }
    else
    {
        modelObject = [modelObject dictionaryByAddingObject:@"" forKey:SCUDefaultTableViewCellKeyRightImageName];
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice isPhone] || ![indexPath isEqual:self.lastSelectedIndexPath])
    {
        self.lastSelectedIndexPath = indexPath;
        [self.delegate showLightingControlsForRoom:[self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyTitle] indexPath:indexPath animated:YES];
    }
}

- (BOOL)shouldDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIDevice isPhone] ? YES : NO;
}

#pragma mark - StateDelegate methods

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if (stateUpdate.state && stateUpdate.value)
    {
        self.stateValues[stateUpdate.state] = @([stateUpdate.value boolValue]);

        SAVWeakSelf;
        [self.reloadTimer addWorkWithKey:@"reload" work:^{
            [wSelf.delegate reloadData];
        }];
    }
}

@end
