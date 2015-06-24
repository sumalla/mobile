//
//  SCURoomGroupTableModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsRoomGroupTableModel.h"
#import "SCUAVSettingsModelPrivate.h"
#import "SCUDataSourceModelPrivate.h"
#import <SavantControl/SavantControl.h>
#import "SCUDefaultTableViewCell.h"
#import "SCUAVSettingsEqualizerModel.h"
#import "SCUAVSettingsVideoModel.h"
#import "SCUAVSettingsAudioModel.h"
#import "SCUAVSettingsRoomGroupTableModelPrivate.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVSettingsRoomGroupTableModel ()

@property (nonatomic) NSArray *roomGroupNames;

@end

@implementation SCUAVSettingsRoomGroupTableModel

#pragma mark -

- (void)loadDataIfNecessary
{
    [self parseRoomGroupsAndFilter:nil];
}

- (void)parseRoomGroupsAndFilter:(SAVRoom *)filterRoom
{
    NSMutableArray *roomGroups = [[[SavantControl sharedControl].data allRoomGroups] mutableCopy];
    
    NSArray *ungroupedRooms = [[SavantControl sharedControl].data roomsInRoomGroup:nil];
    
    if ([ungroupedRooms count])
    {
        [roomGroups addObject:[NSNull null]];
    }
    
    NSArray *roomGroupNames = [roomGroups arrayByMappingBlock:^id(id roomGroup) {
        
        if ([roomGroup isKindOfClass:[SAVRoomGroup class]])
        {
            return ((SAVRoomGroup *)roomGroup).groupId;
        }
        else
        {
            return NSLocalizedString(@"Other", nil);
        }
        
    }];
    
    NSArray *dataSource = [roomGroups arrayByMappingBlock:^id(SAVRoomGroup *roomGroup) {
        
        SAVRoomGroup *rg = nil;
        
        if ([roomGroup isKindOfClass:[SAVRoomGroup class]])
        {
            rg = roomGroup;
        }
        
        return [[[SavantControl sharedControl].data roomsInRoomGroup:rg] arrayByMappingBlock:^id(SAVRoom *room) {
            
            NSDictionary *dict = nil;
            
            if (![room.roomId isEqualToString:filterRoom.roomId])
            {
                SAVMutableService *service = [[SAVMutableService alloc] init];
                service.serviceId = self.serviceID;
                service.zoneName = room.roomId;
                
                if ([[[SavantControl sharedControl].data servicesFilteredByService:service] count])
                {
                    dict = @{SCUDefaultTableViewCellKeyTitle: room.roomId,
                             SCUDefaultTableViewCellKeyModelObject: room};
                }
            }
            
            return dict;
            
        }];
        
    }];
    
    //-------------------------------------------------------------------
    // Remove any empty sections.
    //-------------------------------------------------------------------
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSUInteger section = 0;
    
    for (NSArray *array in dataSource)
    {
        if (![array count])
        {
            [indexSet addIndex:section];
        }
        
        section++;
    }
    
    if ([indexSet count])
    {
        NSMutableArray *mRoomGroupNames = [roomGroupNames mutableCopy];
        NSMutableArray *mDataSource = [dataSource mutableCopy];
        
        [mRoomGroupNames removeObjectsAtIndexes:indexSet];
        [mDataSource removeObjectsAtIndexes:indexSet];
        
        self.roomGroupNames = [mRoomGroupNames copy];
        self.dataSource = [mDataSource copy];
    }
    else
    {
        self.roomGroupNames = roomGroupNames;
        self.dataSource = dataSource;
    }
}

#pragma mark - SCUDataSourceModel methods

- (NSInteger)numberOfSections
{
    return [self.roomGroupNames count];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];
    switch (self.type)
    {
        case SCUAVSettingsModelTypeVideo:
        {
            SCUAVSettingsVideoModel *model = [[SCUAVSettingsVideoModel alloc] initWithServices:[self servicesForServiceID:@"SVC_SETTINGS_VIDEO" andRoom:room]];
            [self.delegate presentVideoSettingsScreenWithModel:model];
            break;
        }
        case SCUAVSettingsModelTypeAudio:
        {
            SCUAVSettingsAudioModel *model = [[SCUAVSettingsAudioModel alloc] initWithStereoServices:[self servicesForServiceID:@"SVC_SETTINGS_STEREO" andRoom:room]
                                                                                    surroundServices:[self servicesForServiceID:@"SVC_SETTINGS_SURROUND" andRoom:room]];
            [self.delegate presentAudioSettingsScreenWithModel:model];
            break;
        }
        case SCUAVSettingsModelTypeEqualizer:
        {
            SCUAVSettingsEqualizerModel *model = [[SCUAVSettingsEqualizerModel alloc] initWithRoom:room];
            [self.delegate presentEqualizerScreenWithModel:model];
            break;
        }
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return self.roomGroupNames[section];
}

- (NSArray *)servicesForServiceID:(NSString *)serviceID andRoom:(SAVRoom *)room
{
    SAVMutableService *filterService = [[SAVMutableService alloc] init];
    filterService.serviceId = serviceID;
    filterService.zoneName = room.roomId;
    return [[SavantControl sharedControl].data servicesFilteredByService:filterService];
}

#pragma mark -

- (NSString *)title
{
    return NSLocalizedString(@"Room Groups", nil);
}

- (BOOL)isFlat
{
    return NO;
}

- (void)viewWillAppear
{
    ;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section];
}

@end
