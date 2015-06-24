//
//  SCUSystemSelectorModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorTableViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUMainViewModel.h"
#import "SCUCascadingTimer.h"
#import "SCUProgressTableViewCell.h"
#import "SCUTextEntryAlert.h"
#import "SCUMainViewController.h"
#import "SCUBackgroundHandler.h"
#import "SCUDataSourceModelPrivate.h"

typedef NS_ENUM(NSUInteger, SCUSystemSelectorSection)
{
    SCUSystemSelectorSectionNone,
    SCUSystemSelectorSectionCloud,
    SCUSystemSelectorSectionLocal,
    SCUSystemSelectorSectionDemo,
    SCUSystemSelectorSectionConnect
};

static NSString *SCUSystemSelectorKeySectionType = @"SCUSystemSelectorKeySectionType";
static NSString *SCUSystemSelectorKeySectionList = @"SCUSystemSelectorKeySectionList";

@interface SCUSystemSelectorTableViewModel () <SystemStatusDelegate, DiscoveryDelegate, SCUBackgroundHandlerDelegate, SCUOnboardViewControllerDelegate>

@property (nonatomic) SCUProgressTableViewCellAccessoryType accessoryState;
@property (nonatomic) NSString *selectedUID;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic, copy) NSArray *cloudSystems;
@property (nonatomic, copy) NSArray *localSystems;
@property (nonatomic) NSDictionary *demoSystemArrayItem;
@property (nonatomic) NSDictionary *connectToSystemArrayItem;
@property (nonatomic) NSDictionary *noLocalSystemsArrayItem;
@property (nonatomic) SCUCascadingTimer *timer;
@property (nonatomic, copy) SCSCancelBlock cloudCancelBlock;
@property (nonatomic) BOOL didTapCloudAccount;
@property (nonatomic) BOOL didTapManualConnect;
@property (nonatomic, weak) NSTimer *cloudHomesPoll;
@property (nonatomic) BOOL establishedConnection;

@end

@implementation SCUSystemSelectorTableViewModel

- (void)dealloc
{
    [[SCUBackgroundHandler sharedInstance] removeDelegate:self];
    [[SavantControl sharedControl] removeDiscoveryObserver:self];
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
    [[SavantControl sharedControl] stopSystemBrowse];
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.noLocalSystemsArrayItem = [self createNoLocalSystemsArrayItem];
        self.demoSystemArrayItem = [self createDemoSystemsArray];
#ifdef DEBUG
        self.connectToSystemArrayItem = [self createConnectToSystemArray];
#endif
        self.localSystems = @[];
        self.timer = [[SCUCascadingTimer alloc] init];
    }

    return self;
}

- (void)startDemoMode
{
    [[SavantControl sharedControl] connectToDemoSystem];
}

- (void)clearCheckMark
{
    self.selectedUID = nil;
    [self.delegate reloadTableAnimated:NO];
}

#pragma mark - SCUViewModel methods

- (void)viewWillAppear
{
    [self resetTable];
    [[SavantControl sharedControl] removeSystemStatusObserver:self];

    [UIImage sav_clearImageCache];
    [[SavantControl sharedControl].imageModel purgeMemory];

    [[SCUBackgroundHandler sharedInstance] addDelegate:self];
    SavantControl *sc = [SavantControl sharedControl];
    [sc addDiscoveryObserver:self];
    [sc startSystemBrowse];
}

- (void)viewWillDisappear
{
    [self.timer invalidate];
}

#pragma mark - SCUDataSourceModel methods

- (BOOL)isFlat
{
    return NO;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    SAVSystem *system = modelObject[SCUDefaultTableViewCellKeyModelObject];

    if ([self.selectedUID isEqualToString:system.hostID])
    {
        modelObject = [modelObject dictionaryByAddingObject:@(self.accessoryState) forKey:SCUProgressTableViewCellKeyAccessoryType];
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    SCUSystemSelectorSection sectionType = [self cellTypeForSection:indexPath.section];

    if (sectionType == SCUSystemSelectorSectionNone)
    {
        return SCUSystemSelectorViewModelCellTypePlaceholder;
    }
    else
    {
        return SCUSystemSelectorViewModelCellTypeSystem;
    }
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;

    switch ([self cellTypeForSection:section])
    {
        case SCUSystemSelectorSectionLocal:
        {
            title = NSLocalizedString(@"Local Systems", nil);
            break;
        }
    }

    return title;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCUSystemSelectorSection type = [self cellTypeForSection:indexPath.section];
    [self.timer invalidate];

    self.didTapCloudAccount = NO;
    self.didTapManualConnect = NO;

    switch (type)
    {
        case SCUSystemSelectorSectionCloud:
        case SCUSystemSelectorSectionLocal:
        {
            [[SavantControl sharedControl] disconnect];
            self.establishedConnection = NO;

            SAVSystem *system = [self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

            if (system.remoteAccessDisableReason == SAVSystemRemoteAccessDisabledReasonTrialPeriodExpired && !system.localURL)
            {
                NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Your 90 day trial has expired.\n", nil)
                                                                                            attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];

                [message appendAttributedString:[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"For remote access:", nil)
                                                                                       attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]}]];

                [[[SCUAlertView alloc] initErrorAlertWithMessage:[message copy]
                                                         bullets:@[NSLocalizedString(@"Savant Plus is required.", nil), NSLocalizedString(@"This app requires an update.", nil)]
                                                   buttontTitles:@[NSLocalizedString(@"OK", nil)]] show];
                break;
            }

            if ([[SavantControl sharedControl] canOnboardSystem:system])
            {
                [self.delegate onboardSystem:system showDoNotLink:YES delegate:self];
            }
            else
            {
                dispatch_block_t connectBlock = ^{
                    if (system.isCloudSystem)
                    {
                        self.didTapCloudAccount = YES;
                    }

                    [[SavantControl sharedControl] addSystemStatusObserver:self];
                    [[SavantControl sharedControl] connectToSystem:system];

                    SAVWeakSelf;
                    [self.timer addBlockAfterDelay:0.2 block:^{
                        [wSelf updateTableWithAccessoryType:SCUProgressTableViewCellAccessoryTypeSpinner uid:system.hostID];
                    }];
                };

                //-------------------------------------------------------------------
                // If there is no localURL, and this is a cloud system, but the
                // "isCloudOnline" flag is false,  attempt to refresh the
                // "isCloudOnline" info. If it's online after refreshing we will
                // reconnect, otherwise we will display an error noting that the
                // system is offline.
                //-------------------------------------------------------------------
                if (!system.localURL && system.cellURL && !system.isCloudOnline && system.homeID)
                {
                    [[SavantControl sharedControl] currentInfoForHomeWithHomeID:system.homeID completionHandler:^(BOOL success, NSDictionary *homeInfo, NSError *error, BOOL isHTTPTransportError) {

                        BOOL online = [[NSNull nilOrIdentityFromObject:homeInfo[kSAVSystemCloudOnlineKey]] boolValue];

                        if (success && online)
                        {
                            //-------------------------------------------------------------------
                            // Set the online flag and connect.
                            //-------------------------------------------------------------------
                            system.cloudOnline = online;
                            connectBlock();
                        }
                        else
                        {
                            SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", nil)
                                                                                  message:[NSString stringWithFormat:NSLocalizedString(@"%@ is currently offline", nil), system.name]
                                                                             buttonTitles:@[NSLocalizedString(@"OK", nil)]];

                            [alertView show];
                        }
                    }];
                }
                else
                {
                    connectBlock();
                }
            }

            break;
        }
        case SCUSystemSelectorSectionDemo:
        {
            [self resetTable];
            [self.delegate presentDemoModeDialog];
            break;
        }
        case SCUSystemSelectorSectionConnect:
        {
            SCUTextEntryAlert *alert = [[SCUTextEntryAlert alloc] initWithTitle:NSLocalizedString(@"Manual Connection", nil)
                                                                        message:NSLocalizedString(@"Enter remote host address", nil)
                                                                  textEntryType:SCUTextEntryAlertFieldTypeDefault
                                                                   buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Connect", nil)]];

            self.didTapManualConnect = YES;

            SAVWeakVar(alert, sAlert);
            alert.callback = ^(NSUInteger buttonIndex) {
                if (buttonIndex != 0)
                {
                    NSString *address = [sAlert textForFieldWithType:SCUTextEntryAlertFieldTypeDefault];

                    NSArray *addressComponents = [address componentsSeparatedByString:@":"];

                    SAVSystem *system = [[SAVSystem alloc] init];

                    if ([addressComponents count])
                    {
                        system.localAddress = addressComponents[0];

                        if ([addressComponents count] >= 2)
                        {
                            system.localPort = [addressComponents[1] integerValue];
                        }
                        else
                        {
                            system.localPort = 9108;
                        }

                        system.localScheme = @"wss";
                        system.manualConnection = YES;
                    }

                    [[SavantControl sharedControl] addSystemStatusObserver:self];
                    [[SavantControl sharedControl] connectToSystem:system];
                }
            };

            [alert show];

            break;
        }
    }
}

#pragma mark - SystemStatusDelegate methods

- (void)connectionDidFailToConnect
{
    if (!self.establishedConnection)
    {
        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"Could not connect to %@", nil), [SavantControl sharedControl].currentSystem.name]
                                                         buttonTitles:@[NSLocalizedString(@"OK", nil)]];

        [alertView show];

        [[SavantControl sharedControl] disconnect];
        [[SavantControl sharedControl] removeSystemStatusObserver:self];
        [self.timer invalidate];
        [self resetTable];
    }
}

- (void)connectionDidConnect
{
    self.establishedConnection = YES;

    SAVWeakSelf;
    [self.timer addBlockAfterDelay:0.2 block:^{
        SAVStrongWeakSelf;
        [sSelf updateTableWithAccessoryType:SCUProgressTableViewCellAccessoryTypeCheckmark uid:sSelf.selectedUID];
    }];

    [self.timer addBlockAfterDelay:0.3 block:^{

        SavantControl *sc = [SavantControl sharedControl];

        if (wSelf.didTapManualConnect)
        {
            [[SCUMainViewController sharedInstance] presentSignInForceModal:YES];
        }
        else if (!wSelf.didTapCloudAccount)
        {
            [[SCUMainViewController sharedInstance] presentUserListWithTitle:sc.currentSystem.name];
        }
    }];
}

- (void)establishedConnectionDidFail
{
    [self.delegate systemDidDisconnectWhileTryingToLogin];
    [[SavantControl sharedControl] disconnect];
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

#pragma mark - DiscoveryDelegate methods

- (void)discoveryDidUpdateSystemList:(SAVDiscovery *)discovery
{
    NSMutableArray *systemArray = [NSMutableArray array];

    NSDictionary *systemList = [SavantControl sharedControl].systemList;

    SAVArrayMappingBlock mappingBlock = ^id(SAVSystem *system) {
        NSMutableDictionary *modelObject = [NSMutableDictionary dictionaryWithObject:system forKey:SCUDefaultTableViewCellKeyModelObject];

        if (system.name)
        {
            modelObject[SCUDefaultTableViewCellKeyTitle] = system.name;
        }

        return modelObject;
    };

    NSArray *cloudSystems = systemList[SAVDiscoveryCloudSystemsKey];
    NSArray *localSystems = systemList[SAVDiscoveryLocalSystemsKey];

    if ([cloudSystems count])
    {
        [systemArray addObject:[self dataSourceEntryWithArray:[cloudSystems arrayByMappingBlock:mappingBlock]
                                                  sectionType:SCUSystemSelectorSectionCloud]];
    }

    if ([localSystems count])
    {
        [systemArray addObject:[self dataSourceEntryWithArray:[localSystems arrayByMappingBlock:mappingBlock]
                                                  sectionType:SCUSystemSelectorSectionLocal]];
    }

    if (![systemArray count])
    {
        //-------------------------------------------------------------------
        // Add placeholder system if there are no other systems.
        //-------------------------------------------------------------------
        [systemArray addObject:self.noLocalSystemsArrayItem];
    }

    //-------------------------------------------------------------------
    // Add demo system.
    //-------------------------------------------------------------------
    [systemArray addObject:self.demoSystemArrayItem];

    //-------------------------------------------------------------------
    // Add connect to system button, debug only
    //-------------------------------------------------------------------
    if (self.connectToSystemArrayItem)
    {
        [systemArray addObject:self.connectToSystemArrayItem];
    }

    self.dataSource = systemArray;
    [self.delegate reloadTableAnimated:NO];
}

#pragma mark -

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section][SCUSystemSelectorKeySectionList];
}

- (NSUInteger)cellTypeForSection:(NSInteger)section
{
    return [self.dataSource[section][SCUSystemSelectorKeySectionType] unsignedIntegerValue];
}

- (void)updateTableWithAccessoryType:(SCUProgressTableViewCellAccessoryType)accessoryType uid:(NSString *)uid
{
    self.selectedUID = uid;
    self.accessoryState = accessoryType;
    [self.delegate reloadTableAnimated:NO];
}

- (void)resetTable
{
    self.accessoryState = SCUProgressTableViewCellAccessoryTypeNone;
    self.selectedUID = nil;
    [self.delegate reloadTableAnimated:NO];
}

- (NSDictionary *)dataSourceEntryWithArray:(NSArray *)array sectionType:(SCUSystemSelectorSection)sectionType
{
    return @{SCUSystemSelectorKeySectionType: @(sectionType),
             SCUSystemSelectorKeySectionList: array};
}

- (NSDictionary *)createNoLocalSystemsArrayItem
{
    NSArray *array = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"No Savant systems have been located on the current network. Make sure you are on the correct network and that the Savant system is powered on.", nil)}];
    return [self dataSourceEntryWithArray:array sectionType:SCUSystemSelectorSectionNone];
}

- (NSDictionary *)createDemoSystemsArray
{
    NSArray *array = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Demonstration Mode", nil)}];
    return [self dataSourceEntryWithArray:array sectionType:SCUSystemSelectorSectionDemo];
}

- (NSDictionary *)createConnectToSystemArray
{
    NSArray *array = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Connect to System (debug only)", nil)}];
    return [self dataSourceEntryWithArray:array sectionType:SCUSystemSelectorSectionConnect];
}

#pragma mark - SCUBackgroundHandler methods

- (void)backgroundHandlerEnterBackground
{
    [[SavantControl sharedControl] stopSystemBrowse];
}

- (void)backgroundHandlerEnterForeground
{
    [[SavantControl sharedControl] startSystemBrowse];
}

#pragma mark - SCUOnboardViewControllerDelegate

- (void)systemDidBind:(SAVSystem *)system
{
    system.cloudSystem = YES;
    [[SavantControl sharedControl] disconnect];
    [[SavantControl sharedControl] connectToSystem:system];
}

- (void)system:(SAVSystem *)system didNotBindWithError:(NSError *)error
{
    [[[SCUAlertView alloc] initWithError:error] show];
}

- (void)systemBindWasSkipped:(SAVSystem *)system
{
    [[SavantControl sharedControl] addSystemStatusObserver:self];
    [[SavantControl sharedControl] connectToSystem:system];
}

@end
