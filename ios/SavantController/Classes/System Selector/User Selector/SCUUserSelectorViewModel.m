//
//  SCUUserSelectorModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserSelectorViewModel.h"
#import "SCUDataSourceModelPrivate.h"
#import <SavantControl/SavantControl.h>
#import "SCUMainViewModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAlertView.h"

static NSString *SCUUserSelectorCellTypeKey = @"SCUUserSelectorCellTypeKey";

@interface SCUUserSelectorViewModel () <SystemStatusDelegate>

@property (nonatomic) NSArray *dataSource;
@property (nonatomic) SAVLocalUser *currentUser;

@end

@implementation SCUUserSelectorViewModel

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.dataSource = [[[SavantControl sharedControl] localUsers] arrayByMappingBlock:^id(SAVUser *user) {
            return @{SCUDefaultTableViewCellKeyModelObject: user,
                     SCUUserSelectorCellTypeKey: @(SCUUserSelectorTableViewCellTypeUser)};
        }];

        if (![self.dataSource count])
        {
            self.dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"No users are available", nil),
                           SCUUserSelectorCellTypeKey: @(SCUUserSelectorTableViewCellTypePlaceholder)}];
        }
    }

    return self;
}

#pragma mark - SCUViewModel methods

- (void)viewWillDisappear
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

#pragma mark - SCUDataSourceModel methods

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCUUserSelectorCellTypeKey] unsignedIntegerValue];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    switch ([modelObject[SCUUserSelectorCellTypeKey] unsignedIntegerValue])
    {
        case SCUUserSelectorTableViewCellTypeUser:
        {
            self.currentUser = (SAVLocalUser *)(modelObject[SCUDefaultTableViewCellKeyModelObject]);

            SavantControl *sc = [SavantControl sharedControl];

            if ([sc hasSavedPasswordForUser:self.currentUser.accountName])
            {
                [sc addSystemStatusObserver:self];
                [sc loginToLocalUserWithSavedPassword:self.currentUser.accountName];
            }
            else
            {
                [self showSignInForCurrentUser];
            }

            break;
        }
    }
}

#pragma mark - SystemStatusDelegate

- (void)connectionDidAuthorizeForUser:(NSString *)user
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

- (void)connectionDidReceiveAuthChallengeForUser:(NSString *)user
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
    [self showSignInForCurrentUser];
}

#pragma mark -

- (void)showSignInForCurrentUser
{
    NSDictionary *userInfo = nil;
    if (self.currentUser)
    {
        userInfo = @{SCUMainViewSignInUserKey: self.currentUser};
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:SCUMainViewPresentUserSignInNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

@end
