//
//  SCUUserSettingsTableViewControllerModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserSettingsTableViewControllerModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import <SavantControl/SavantControl.h>

@interface SCUUserSettingsTableViewControllerModel ()

@property (nonatomic, copy) NSArray *dataSource;

@end

@implementation SCUUserSettingsTableViewControllerModel

- (BOOL)loadData
{
    [self loadUsers];
    //-------------------------------------------------------------------
    // CBP TODO: Handle correct return type.
    //-------------------------------------------------------------------
    return YES;
}

- (void)loadDataIfNecessary
{
    [self loadUsers];
}

- (void)loadUsers
{
    SavantControl *sc = [SavantControl sharedControl];

    SAVWeakSelf;
    [sc cloudUsers:^(BOOL success, NSArray *users, NSError *error, BOOL isHTTPTransportError) {

        SAVStrongWeakSelf;
        if (success)
        {
            NSArray *sortedUsers = [users sortedArrayUsingComparator:^NSComparisonResult(SAVCloudUser *user1, SAVCloudUser *user2) {
                return [user1.name compare:user2.name options:NSCaseInsensitiveNumericSearch];
            }];

            if ([sortedUsers count] > 1)
            {
                __block NSUInteger index = NSNotFound;

                [sortedUsers enumerateObjectsUsingBlock:^(SAVCloudUser *user, NSUInteger idx, BOOL *stop) {
                    if (user.isCurrentUser)
                    {
                        index = idx;

                        if (stop)
                        {
                            *stop = YES;
                        }
                    }
                }];

                if (index != NSNotFound)
                {
                    NSMutableArray *mSortedUsers = [sortedUsers mutableCopy];
                    SAVCloudUser *user = mSortedUsers[index];
                    [mSortedUsers removeObjectAtIndex:index];
                    [mSortedUsers insertObject:user atIndex:0];
                    sortedUsers = mSortedUsers;
                }
            }

            NSArray *parsedUsers = [sortedUsers arrayByMappingBlock:^id(SAVCloudUser *user) {

                if (user.isCurrentUser && [user.name length])
                {
                    NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:user.name
                                                                                                       attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04]}];

                    [attributedName appendAttributedString:[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@" (Me)", nil)
                                                                                                  attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade06]}]];

                    return @{SCUDefaultTableViewCellKeyAttributedTitle: [attributedName copy],
                             SCUDefaultTableViewCellKeyModelObject: user};
                }
                else
                {
                    return @{SCUDefaultTableViewCellKeyTitle: user.name,
                             SCUDefaultTableViewCellKeyModelObject: user};
                }
            }];

            sSelf.dataSource = parsedUsers;
        }
        else
        {
            //-------------------------------------------------------------------
            // CBP TODO: handle error
            //-------------------------------------------------------------------
        }

        [sSelf.delegate reloadData];
    }];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

    SAVCloudUser *user = modelObject[SCUDefaultTableViewCellKeyModelObject];
    [self.delegate presentSettingsForUser:user];
}

@end
