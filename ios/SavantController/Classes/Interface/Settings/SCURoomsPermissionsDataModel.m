//
//  SCURoomsPermissionsDataModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomsPermissionsDataModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAlertView.h"

@interface SCURoomsPermissionsDataModel ()

@property (nonatomic) SAVCloudUser *user;
@property (nonatomic) NSMutableSet *blacklistedRooms;
@property (nonatomic) NSArray *dataSource;
@property (nonatomic) NSMutableIndexSet *checkedIndexes;

@end

@implementation SCURoomsPermissionsDataModel

- (instancetype)initWithUser:(SAVCloudUser *)user
{
    self = [super init];

    if (self)
    {
        self.user = user;

        self.blacklistedRooms = [self.user.zoneBlackList mutableCopy];

        if (!self.blacklistedRooms)
        {
            self.blacklistedRooms = [NSMutableSet set];
        }

        self.checkedIndexes = [NSMutableIndexSet indexSet];

        self.dataSource = [[[SavantControl sharedControl].data allRooms] arrayByMappingIndexBlock:^id(SAVRoom *room, NSUInteger idx, BOOL *stop) {

            if (![self.user.zoneBlackList containsObject:room.roomId])
            {
                [self.checkedIndexes addIndex:idx];
            }

            return @{SCUDefaultTableViewCellKeyTitle: room.roomId};
        }];
    }

    return self;
}

- (void)commit
{
    self.user.zoneBlackList = [self.blacklistedRooms copy];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    if ([self.checkedIndexes containsIndex:indexPath.row])
    {
        modelObject = [modelObject dictionaryByAddingObject:@(UITableViewCellAccessoryCheckmark) forKey:SCUDefaultTableViewCellKeyAccessoryType];
    }
    else
    {
        modelObject = [modelObject dictionaryByAddingObject:@(UITableViewCellAccessoryNone) forKey:SCUDefaultTableViewCellKeyAccessoryType];
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = [self _modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyTitle];

    if ([self.checkedIndexes containsIndex:indexPath.row])
    {
        if ([self.dataSource count] && ([self.checkedIndexes count] - 1 == 0))
        {
            [[[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                         message:NSLocalizedString(@"A user must be allowed to control at least one room.", nil)
                                    buttonTitles:@[NSLocalizedString(@"OK", nil)]] show];
        }
        else
        {
            [self.blacklistedRooms addObject:room];
            [self.checkedIndexes removeIndex:indexPath.row];
        }
    }
    else
    {
        [self.blacklistedRooms removeObject:room];
        [self.checkedIndexes addIndex:indexPath.row];
    }

    [self.delegate reloadIndexPath:indexPath];
}

@end
