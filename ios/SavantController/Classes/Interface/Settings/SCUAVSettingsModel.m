//
//  SCUInitialSettingsModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsModel.h"
#import "SCUAVSettingsModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUAVSettingsRoomGroupTableModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUAlertView.h"
#import "SCUMainViewController.h"

typedef NS_ENUM(NSUInteger, SCUAVSettingsModelUserType)
{
    SCUAVSettingsModelUserTypeUsersList,
    SCUAVSettingsModelUserTypeCurrentUser,
    SCUAVSettingsModelUserTypeLink,
    SCUAVSettingsModelUserTypeNotifications,
    SCUAVSettingsModelUserTypeSwitchSystems,
    SCUAVSettingsModelUserTypeSignOut
};

static NSString *const SCUAVSettingsSectionKey = @"SCUAVSettingsSectionKey";
static NSString *const SCUAVSettingsArrayKey = @"SCUAVSettingsArrayKey";

typedef NS_ENUM(NSUInteger, SCUAVSettingsSection)
{
    SCUAVSettingsSectionCloud,
    SCUAVSettingsSectionSettings
};

static NSString *SCUAVSettingsModelKeyType = @"SCUAVSettingsModelKeyType";

@interface SCUAVSettingsModel () <SCUOnboardViewControllerDelegate, SystemStatusDelegate>

@property (nonatomic, copy) SCSCancelBlock cancelBlock;

@end

@implementation SCUAVSettingsModel

- (void)viewWillAppear
{
    [[SavantControl sharedControl] addSystemStatusObserver:self];
    [self updateDataSource];
}

- (void)viewWillDisappear
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
    self.cancelBlock = NULL;
}

- (BOOL)isFlat
{
    return NO;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

    NSUInteger modelType = [modelObject[SCUAVSettingsModelKeyType] unsignedIntegerValue];

    if ([self.dataSource[indexPath.section][SCUAVSettingsSectionKey] unsignedIntegerValue] == SCUAVSettingsSectionCloud)
    {
        SCUAVSettingsModelUserType type = modelType;

        if (type == SCUAVSettingsModelUserTypeUsersList)
        {
            [self.delegate presentUserList];
        }
        else if (type == SCUAVSettingsModelUserTypeCurrentUser)
        {
            if (self.cancelBlock)
            {
                return;
            }

            SAVWeakSelf;
            self.cancelBlock = [[SavantControl sharedControl] cloudUsers:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {

                SAVStrongWeakSelf;

                if (success)
                {
                    [sSelf.delegate presentUser:[[data firstObject] copy]];
                }
                else
                {
                    //-------------------------------------------------------------------
                    // Handle error
                    //-------------------------------------------------------------------
                }

                sSelf.cancelBlock = NULL;
            }];
        }
        else if (type == SCUAVSettingsModelUserTypeLink)
        {
            [self.delegate onboardSystem:[SavantControl sharedControl].currentSystem showDoNotLink:NO delegate:self];
        }
        else if (type == SCUAVSettingsModelUserTypeSwitchSystems)
        {
            [self switchSystems];
        }
        else if (type == SCUAVSettingsModelUserTypeSignOut)
        {
            [self signOut];
        }
    }
    else
    {
        SCUAVSettingsModelType type = modelType;
        self.type = type;

        SCUAVSettingsRoomGroupTableModel *roomGroupModel = [[SCUAVSettingsRoomGroupTableModel alloc] init];
        [self presentNextModel:roomGroupModel];
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;

    if ([self.dataSource[section][SCUAVSettingsSectionKey] unsignedIntegerValue] == SCUAVSettingsSectionCloud)
    {
        title = NSLocalizedString(@"System", nil);
    }
    else
    {
        title = NSLocalizedString(@"Entertainment", nil);
    }

    return title;
}

#pragma mark - Methods to subclass

- (NSString *)title
{
    return NSLocalizedString(@"Settings", nil);
}

#pragma mark -

- (void)presentNextModel:(SCUAVSettingsModel *)nextModel
{
    nextModel.type = self.type;

    // TODO: Fix this for the edge case of both surround and stereo
    nextModel.serviceID = [self serviceIDsForType:self.type][0];
    [self.delegate presentNextAVSettingsViewControllerWithModel:nextModel];
}

- (NSArray *)serviceIDsForType:(SCUAVSettingsModelType)type
{
    NSArray *serviceIDs = nil;
    switch (type)
    {
        case SCUAVSettingsModelTypeVideo:
            serviceIDs = @[@"SVC_SETTINGS_VIDEO"];
            break;
        case SCUAVSettingsModelTypeAudio:
            serviceIDs = @[@"SVC_SETTINGS_STEREO", @"SVC_SETINGS_SURROUND"];
            break;
        case SCUAVSettingsModelTypeEqualizer:
            serviceIDs = @[@"SVC_SETTINGS_EQUALIZER"];
            break;
    }

    return serviceIDs;
}

#pragma mark - SCUOnboardViewControllerDelegate

- (void)systemDidBind:(SAVSystem *)system
{
    system.cloudSystem = YES;
    [self.delegate navigateBack];
}

- (void)system:(SAVSystem *)system didNotBindWithError:(NSError *)error
{
    switch (error.code)
    {
        case SCSResponseErrorConnectionError:
        case SCSResponseErrorHasAlreadyBeenOnboarded:
        {
            [[[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription buttonTitles:@[NSLocalizedString(@"OK", nil)]] show];
            break;
        }
    }
}

- (void)updateDataSource
{
    NSMutableArray *dataSource = [NSMutableArray array];

    {
        NSMutableArray *systemSettings = [NSMutableArray array];

        //-------------------------------------------------------------------
        // Make user settings.
        //-------------------------------------------------------------------
        if ([SavantControl sharedControl].isConnectedToACloudSystem)
        {
            if ([SavantControl sharedControl].isAdmin || [SavantControl sharedControl].isDemoSystem)
            {
                [systemSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Users", nil),
                                            SCUAVSettingsModelKeyType: @(SCUAVSettingsModelUserTypeUsersList)}];
            }
            else
            {
                [systemSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"My Settings", nil),
                                            SCUAVSettingsModelKeyType: @(SCUAVSettingsModelUserTypeCurrentUser),
                                            SCUDefaultTableViewCellKeyDetailTitle: [SavantControl sharedControl].cloudUser ? [SavantControl sharedControl].cloudUser : @"",
                                            SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]}];
            }
        }
        else if ([[SavantControl sharedControl] canOnboardSystem:[SavantControl sharedControl].currentSystem])
        {
            [systemSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Users", nil),
                                        SCUAVSettingsModelKeyType: @(SCUAVSettingsModelUserTypeLink),
                                        SCUDefaultTableViewCellKeyDetailTitle: NSLocalizedString(@"No Administrator", nil),
                                        SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color01]}];
        }

        [systemSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Switch Systems", nil),
                                    SCUAVSettingsModelKeyType: @(SCUAVSettingsModelUserTypeSwitchSystems)}];

        [systemSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Sign Out", nil),
                                    SCUAVSettingsModelKeyType: @(SCUAVSettingsModelUserTypeSignOut)}];

        [dataSource addObject:@{SCUAVSettingsSectionKey: @(SCUAVSettingsSectionCloud),
                                SCUAVSettingsArrayKey: [systemSettings copy]}];
    }

    //-------------------------------------------------------------------
    // Make AV settings.
    //-------------------------------------------------------------------
    {
        NSMutableArray *avSettings = [NSMutableArray array];

        if ([[[SavantControl sharedControl].data servicesFilteredByServiceIDs:[self serviceIDsForType:SCUAVSettingsModelTypeVideo]] count])
        {
            [avSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Video", nil),
                                    SCUAVSettingsModelKeyType: @(SCUAVSettingsModelTypeVideo)}];
        }

        if ([[[SavantControl sharedControl].data servicesFilteredByServiceIDs:[self serviceIDsForType:SCUAVSettingsModelTypeAudio]] count])
        {
            [avSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Audio", nil),
                                    SCUAVSettingsModelKeyType: @(SCUAVSettingsModelTypeAudio)}];
        }

        //-------------------------------------------------------------------
        // No equalizer for now.
        //-------------------------------------------------------------------
        //        if ([[[SavantControl sharedControl].data servicesFilteredByServiceIDs:[self serviceIDsForType:SCUAVSettingsModelTypeEqualizer]] count])
        //        {
        //            [avSettings addObject:@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Equalizer", nil),
        //                                    SCUAVSettingsModelKeyType: @(SCUAVSettingsModelTypeEqualizer)}];
        //        }

        if ([avSettings count])
        {
            [dataSource addObject:@{SCUAVSettingsSectionKey: @(SCUAVSettingsSectionSettings),
                                    SCUAVSettingsArrayKey: [avSettings copy]}];
        }
    }

    self.dataSource = [dataSource copy];
    [self.delegate reloadData];
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUAVSettingsArrayKey];
}

- (void)switchSystems
{
    [[SavantControl sharedControl] disconnect];
    [[SCUMainViewController sharedInstance] presentSystemSelector:SCUSystemSelectorFromLocationInterface];
}

- (void)signOut
{
    //-------------------------------------------------------------------
    // Remove all the credentials for a system.
    //-------------------------------------------------------------------
    [[SavantControl sharedControl] disconnect];
    [[SavantControl sharedControl] signOut];

    dispatch_next_runloop(^{
        [[SCUMainViewController sharedInstance] presentSplashScreen];
    })
}

#pragma mark - SystemStatusDelegate methods

- (void)connectionAdminStatusDidChange
{
    [self updateDataSource];
}

@end
