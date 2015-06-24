//
//  SCUCreateInviteDataModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUUserModifyTableDataModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUTextFieldListener.h"
#import "SCUAlertView.h"
#import "SCUServicesPermissionsDataModel.h"

#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSInteger, SCUCreateInviteModelType)
{
    SCUCreateInviteModelTypeEmail,
    SCUCreateInviteModelTypeFirstName,
    SCUCreateInviteModelTypeLastName,
    SCUCreateInviteModelTypeChangePassword,
    SCUCreateInviteModelTypeAdmin,
    SCUCreateInviteModelTypeRemoteAccess,
    SCUCreateInviteModelTypeNotifications,
    SCUCreateInviteModelTypeServices,
    SCUCreateInviteModelTypeRooms
};

static NSString *SCUCreateInviteModelTypeKey = @"SCUCreateInviteModelTypeKey";
static NSString *SCUCreateInviteModelCellTypeKey = @"SCUCreateInviteModelCellTypeKey";

@interface SCUUserModifyTableDataModel () <SCUTextFieldListenerDelegate>

@property (nonatomic) SAVCloudUser *user;
@property (nonatomic, getter = isInvite) BOOL invite;
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) SCUTextFieldListener *textFieldListener;
@property (nonatomic) BOOL emailIsValid;
@property (nonatomic) BOOL shouldAddDeleteRow;
@property (nonatomic) NSString *originalFirstName;
@property (nonatomic) NSString *originalLastName;
@property (nonatomic) BOOL originalCanManageUsers;
@property (nonatomic) BOOL originalCanManageNotifications;
@property (nonatomic) BOOL originalHasRemoteAccess;
@property (nonatomic) NSSet *originalZoneBlackList;
@property (nonatomic) NSSet *originalServiceBlackList;
@property (nonatomic) NSSet *rooms;
@property (nonatomic) BOOL hasBecomeFirstResponderOnce;

@end

@implementation SCUUserModifyTableDataModel

- (instancetype)initWithCloudUser:(SAVCloudUser *)user
{
    self = [super init];

    if (self)
    {
        if (!user)
        {
            self.invite = YES;
        }
        else if (!user.isCurrentUser)
        {
            self.shouldAddDeleteRow = YES;
        }

        if (user)
        {
            self.originalFirstName = user.firstName;
            self.originalLastName = user.lastName;
            self.originalCanManageUsers = user.canManageUsers;
            self.originalCanManageNotifications = user.canManageNotifications;
            self.originalHasRemoteAccess = user.hasRemoteAccess;
            self.originalZoneBlackList = user.zoneBlackList;
            self.originalServiceBlackList = user.serviceBlackList;
        }

        self.user = user ?[user copy] : [[SAVCloudUser alloc] init];
        [self commonSetup];
    }

    return self;
}

- (void)commonSetup
{
    self.textFieldListener = [[SCUTextFieldListener alloc] init];
    self.textFieldListener.delegate = self;
    self.emailIsValid = YES;

    SCUTextFieldListenerValidationOptions *emailValidationOptions = [[SCUTextFieldListenerValidationOptions alloc] init];
    emailValidationOptions.email = YES;
    emailValidationOptions.errorMessage = NSLocalizedString(@"Enter a valid email", nil);
    emailValidationOptions.continuous = NO;
    [self.textFieldListener setValidationOptions:emailValidationOptions forTag:SCUCreateInviteModelTypeEmail];

    NSDictionary *editableEmail = @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeEmail),
                                    SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeTextEntry),
                                    SCUTextFieldProgressTableViewCellKeyPlaceholderText: NSLocalizedString(@"Email", nil),
                                    SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Email", nil),
                                    SCUDefaultTableViewCellKeyTitleColor: [[SCUColors shared] color03shade07],
                                    SCUTextFieldProgressTableViewCellKeyKeyboardType: @(UIKeyboardTypeEmailAddress),
                                    SCUTextFieldProgressTableViewCellKeyAutocorrectionType: @(UITextAutocorrectionTypeNo),
                                    SCUTextFieldProgressTableViewCellKeyReturnKeyType: @(UIReturnKeyNext),
                                    SCUTextFieldProgressTableViewCellKeyClearType: @(UITextFieldViewModeWhileEditing),
                                    SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]};

    NSDictionary *fixedEmail = @{SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeFixed),
                                 SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Email", nil),
                                 SCUDefaultTableViewCellKeyDetailTitle: self.user.email ? self.user.email : @""};

    NSArray *manageUsers = @[@{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeAdmin),
                               SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeToggle),
                               SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Manage Users", nil)}];

    NSArray *access = @[@{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeRemoteAccess),
                          SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeToggle),
                          SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Remote Access", nil)},
                        @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeNotifications),
                          SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeToggle),
                          SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Notifications", nil)},
                        @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeRooms),
                          SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeDouble),
                          SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                          SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Rooms", nil),
                          SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)},
                        @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeServices),
                          SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeDouble),
                          SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Services", nil),
                          SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07],
                          SCUDefaultTableViewCellKeyAccessoryType: @(UITableViewCellAccessoryDisclosureIndicator)}];

    NSDictionary *firstName = @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeFirstName),
                                SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeTextEntry),
                                SCUTextFieldProgressTableViewCellKeyPlaceholderText: NSLocalizedString(@"First Name", nil),
                                SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"First Name", nil),
                                SCUDefaultTableViewCellKeyTitleColor: [[SCUColors shared] color03shade07],
                                SCUTextFieldProgressTableViewCellKeyAutocorrectionType: @(UITextAutocorrectionTypeNo),
                                SCUTextFieldProgressTableViewCellKeyReturnKeyType: @(UIReturnKeyNext),
                                SCUTextFieldProgressTableViewCellKeyClearType: @(UITextFieldViewModeWhileEditing),
                                SCUTextFieldProgressTableViewCellKeyAutocapitalizationType: @(UITextAutocapitalizationTypeWords),
                                SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]};

    NSDictionary *lastName = @{SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeLastName),
                               SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeTextEntry),
                               SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Last Name", nil),
                               SCUDefaultTableViewCellKeyTitleColor: [[SCUColors shared] color03shade07],
                               SCUTextFieldProgressTableViewCellKeyPlaceholderText: NSLocalizedString(@"Last Name", nil),
                               SCUTextFieldProgressTableViewCellKeyAutocorrectionType: @(UITextAutocorrectionTypeNo),
                               SCUTextFieldProgressTableViewCellKeyReturnKeyType: @(UIReturnKeyDone),
                               SCUTextFieldProgressTableViewCellKeyClearType: @(UITextFieldViewModeWhileEditing),
                               SCUTextFieldProgressTableViewCellKeyAutocapitalizationType: @(UITextAutocapitalizationTypeWords),
                               SCUDefaultTableViewCellKeyDetailTitleColor: [[SCUColors shared] color03shade07]};

    SCUTextFieldListenerValidationOptions *firstNameValidationOptions = [[SCUTextFieldListenerValidationOptions alloc] init];
    firstNameValidationOptions.minimumLength = 1;
    firstNameValidationOptions.continuous = NO;
    firstNameValidationOptions.errorMessage = NSLocalizedString(@"Enter your first name", nil);

    SCUTextFieldListenerValidationOptions *lastNameValidationOptions = [[SCUTextFieldListenerValidationOptions alloc] init];
    lastNameValidationOptions.minimumLength = 1;
    lastNameValidationOptions.continuous = NO;
    lastNameValidationOptions.errorMessage = NSLocalizedString(@"Enter your last name", nil);

    [self.textFieldListener setValidationOptions:firstNameValidationOptions forTag:SCUCreateInviteModelTypeFirstName];
    [self.textFieldListener setValidationOptions:lastNameValidationOptions forTag:SCUCreateInviteModelTypeLastName];

    if (self.user.isCurrentUser)
    {
        NSDictionary *changePassword = @{SCUCreateInviteModelCellTypeKey: @(SCUCreateInviteCellTypeNormal),
                                         SCUCreateInviteModelTypeKey: @(SCUCreateInviteModelTypeChangePassword),
                                         SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Change Password", nil)};

        self.dataSource = @[@[fixedEmail, firstName, lastName, changePassword]];
    }
    else if (self.isInvite)
    {
        self.dataSource = @[@[editableEmail, firstName, lastName], manageUsers, access];
    }
    else
    {
        self.dataSource = @[@[fixedEmail], manageUsers, access];
    }

    self.rooms = [NSSet setWithArray:[[[SavantControl sharedControl].data allRooms] arrayByMappingBlock:^id(SAVRoom *room) {
        return room.roomId;
    }]];
}

- (void)finishEditing
{
    BOOL sentACommand = NO;

    [self.delegate endEditing];

    if (self.user.isCurrentUser)
    {
        [self.textFieldListener validateTextFieldWithTag:SCUCreateInviteModelTypeFirstName];
        [self.textFieldListener validateTextFieldWithTag:SCUCreateInviteModelTypeLastName];

        if ([self.user.firstName length] && [self.user.lastName length])
        {
            if (!([self.originalFirstName isEqualToString:self.user.firstName] && [self.originalLastName isEqualToString:self.user.lastName]))
            {
                [self.delegate setDoneButtonAnimating:YES];

                sentACommand = YES;
                SAVWeakSelf;
                [[SavantControl sharedControl] modifyUserName:[self.user copy] completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                    SAVStrongWeakSelf;
                    [sSelf.delegate setDoneButtonAnimating:NO];
                    [sSelf.delegate navigateBack];
                }];
            }
        }
    }
    else if (self.isInvite)
    {
        [self.textFieldListener validateTextFieldWithTag:SCUCreateInviteModelTypeEmail];
        [self.textFieldListener validateTextFieldWithTag:SCUCreateInviteModelTypeFirstName];
        [self.textFieldListener validateTextFieldWithTag:SCUCreateInviteModelTypeLastName];

        if ([self.user.email length] && [self.user.firstName length] && [self.user.lastName length])
        {
            sentACommand = YES;

            [self.delegate setDoneButtonAnimating:YES];

            SAVWeakSelf;
            [[SavantControl sharedControl] inviteUser:self.user completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                SAVStrongWeakSelf;
                [sSelf.delegate setDoneButtonAnimating:NO];
                if (success)
                {
                    [sSelf.delegate navigateBack];
                }
                else
                {
                    [[[SCUAlertView alloc] initWithError:error] show];
                }

            }];
        }
        else
        {
            return;
        }
    }
    else
    {
        if (!(self.originalCanManageUsers == self.user.canManageUsers &&
              self.originalCanManageNotifications == self.user.canManageNotifications &&
              self.originalHasRemoteAccess == self.user.hasRemoteAccess &&
              [self.originalZoneBlackList isEqualToSet:self.user.zoneBlackList] &&
              [self.originalServiceBlackList isEqualToSet:self.user.serviceBlackList]))
        {
            [self.delegate setDoneButtonAnimating:YES];

            sentACommand = YES;
            SAVWeakSelf;
            [[SavantControl sharedControl] modifyUserPermissions:[self.user copy] completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                SAVStrongWeakSelf;
                [sSelf.delegate setDoneButtonAnimating:NO];
                if (success)
                {
                    [sSelf.delegate navigateBack];
                }
                else
                {
                    [[[SCUAlertView alloc] initWithError:error] show];
                }
            }];
        }
    }

    if (!sentACommand)
    {
        [self.delegate navigateBack];
    }
}

- (void)listenToTextField:(UITextField *)textField forIndexPath:(NSIndexPath *)indexPath
{
    [self.textFieldListener listenToTextField:textField withTag:indexPath.row];
}

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SCUCreateInviteModelType type = [[self _modelObjectForIndexPath:indexPath][SCUCreateInviteModelTypeKey] integerValue];

    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on) {

        if (type == SCUCreateInviteModelTypeAdmin)
        {
            wSelf.user.canManageUsers = on;
        }
        else if (type == SCUCreateInviteModelTypeRemoteAccess)
        {
            wSelf.user.hasRemoteAccess = on;
        }
        else if (type == SCUCreateInviteModelTypeNotifications)
        {
            wSelf.user.canManageNotifications = on;
        }
    };
}

- (void)delete
{
    SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Delete User", nil)
                                                          message:NSLocalizedString(@"Are you sure you would like to delete this user?", nil)
                                                     buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Delete", nil)]];

    SAVWeakSelf;
    alertView.callback = ^(NSUInteger buttonIndex) {
        SAVStrongWeakSelf;

        if (buttonIndex == 1)
        {
            [sSelf deleteUser];
        }
    };

    alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];
    [alertView show];
}

#pragma mark - SCUDataSourceModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self.delegate reloadData];
}

- (void)viewDidAppear
{
    if (self.isInvite && !self.hasBecomeFirstResponderOnce)
    {
        self.hasBecomeFirstResponderOnce = YES;
        [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
}

- (BOOL)isFlat
{
    return NO;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCUCreateInviteModelCellTypeKey] unsignedIntegerValue];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;

    if (section == 1)
    {
        title = NSLocalizedString(@"Administration", nil);
    }
    else if (section == 2)
    {
        title = NSLocalizedString(@"Access", nil);
    }

    return title;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    SCUCreateInviteModelType type = [modelObject[SCUCreateInviteModelTypeKey] integerValue];

    switch (type)
    {
        case SCUCreateInviteModelTypeEmail:
        {
            NSMutableDictionary *mModelObject = [modelObject mutableCopy];
            mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText] = self.user.email ? self.user.email : @"";
            mModelObject[SCUDefaultTableViewCellKeyDetailTitle] = mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText];

            if ([self.user.email length])
            {
                mModelObject[SCUDefaultTableViewCellKeyTitleColor] = [[SCUColors shared] color04];
            }
            else
            {
                mModelObject[SCUDefaultTableViewCellKeyTitleColor] = [[SCUColors shared] color03shade07];
            }

            if (!self.emailIsValid)
            {
                mModelObject[SCUTextFieldProgressTableViewCellKeyErrorText] = NSLocalizedString(@"Enter a valid email", nil);
            }

            modelObject = [mModelObject copy];

            break;
        }
        case SCUCreateInviteModelTypeFirstName:
        {
            NSMutableDictionary *mModelObject = [modelObject mutableCopy];
            mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText] = self.user.firstName ? self.user.firstName : @"";
            mModelObject[SCUDefaultTableViewCellKeyDetailTitle] = mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText];

            if ([self.user.firstName length])
            {
                mModelObject[SCUDefaultTableViewCellKeyTitleColor] = [[SCUColors shared] color04];
            }

            modelObject = [mModelObject copy];
            break;
        }
        case SCUCreateInviteModelTypeLastName:
        {
            NSMutableDictionary *mModelObject = [modelObject mutableCopy];
            mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText] = self.user.lastName ? self.user.lastName : @"";
            mModelObject[SCUDefaultTableViewCellKeyDetailTitle] = mModelObject[SCUTextFieldProgressTableViewCellKeyEditableText];

            if ([self.user.lastName length])
            {
                mModelObject[SCUDefaultTableViewCellKeyTitleColor] = [[SCUColors shared] color04];
            }

            modelObject = [mModelObject copy];
            break;
        }
        case SCUCreateInviteModelTypeAdmin:
            modelObject = [modelObject dictionaryByAddingObject:@(self.user.canManageUsers) forKey:SCUToggleSwitchTableViewCellKeyValue];
            break;
        case SCUCreateInviteModelTypeRemoteAccess:
            modelObject = [modelObject dictionaryByAddingObject:@(self.user.hasRemoteAccess) forKey:SCUToggleSwitchTableViewCellKeyValue];
            break;
        case SCUCreateInviteModelTypeNotifications:
            modelObject = [modelObject dictionaryByAddingObject:@(self.user.canManageNotifications) forKey:SCUToggleSwitchTableViewCellKeyValue];
            break;
        case SCUCreateInviteModelTypeServices:
        {
            NSArray *services = [SCUServicesPermissionsDataModel localizedServiceTitlesForUser:self.user];

            if ([services count])
            {
                NSString *servicesString = [services componentsJoinedByString:@"\n"];
                modelObject = [modelObject dictionaryByAddingObject:servicesString forKey:SCUDefaultTableViewCellKeyDetailTitle];
            }
            else
            {
                NSMutableDictionary *mModelObject = [modelObject mutableCopy];
                mModelObject[SCUDefaultTableViewCellKeyDetailTitle] = NSLocalizedString(@"None", nil);
                mModelObject[SCUDefaultTableViewCellKeyDetailTitleColor] = [[SCUColors shared] color01];
                modelObject = [mModelObject copy];
            }

            break;
        }
        case SCUCreateInviteModelTypeRooms:
        {
            NSMutableSet *mRooms = [self.rooms mutableCopy];
            [mRooms minusSet:self.user.zoneBlackList];

            if (![self.user.zoneBlackList count] && [mRooms count])
            {
                //-------------------------------------------------------------------
                // There is nothing in the black list and there are rooms available.
                //-------------------------------------------------------------------
                modelObject = [modelObject dictionaryByAddingObject:NSLocalizedString(@"All", nil)
                                                             forKey:SCUDefaultTableViewCellKeyDetailTitle];
            }
            else if ([mRooms count])
            {
                modelObject = [modelObject dictionaryByAddingObject:[NSString stringWithFormat:NSLocalizedString(@"%ld rooms", nil), [mRooms count]]
                                                             forKey:SCUDefaultTableViewCellKeyDetailTitle];
//                if ([mRooms count] - 1 > 1)
//                {
//                    //-------------------------------------------------------------------
//                    // A few rooms are available.
//                    //-------------------------------------------------------------------
//                    modelObject = [modelObject dictionaryByAddingObject:[NSString stringWithFormat:NSLocalizedString(@"%@ and %lu others", nil), [mRooms anyObject], [mRooms count] - 1]
//                                                                 forKey:SCUDefaultTableViewCellKeyDetailTitle];
//                }
//                else
//                {
//                    //-------------------------------------------------------------------
//                    // Only one room is available.
//                    //-------------------------------------------------------------------
//                    modelObject = [modelObject dictionaryByAddingObject:[mRooms anyObject]
//                                                                 forKey:SCUDefaultTableViewCellKeyDetailTitle];
//                }
            }
            else
            {
                NSMutableDictionary *mModelObject = [modelObject mutableCopy];
                mModelObject[SCUDefaultTableViewCellKeyDetailTitle] = NSLocalizedString(@"None", nil);
                mModelObject[SCUDefaultTableViewCellKeyDetailTitleColor] = [[SCUColors shared] color01];
                modelObject = [mModelObject copy];
            }

            break;
        }
    }

    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    SCUCreateInviteModelType type = [modelObject[SCUCreateInviteModelTypeKey] integerValue];

    if (type == SCUCreateInviteModelTypeEmail)
    {
        [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else if (type == SCUCreateInviteModelTypeFirstName)
    {
        [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    else if (type == SCUCreateInviteModelTypeLastName)
    {
        [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    }
    else if (type == SCUCreateInviteModelTypeChangePassword)
    {
        [self.delegate changePasswordForUser:self.user];
    }
    else if (type == SCUCreateInviteModelTypeRooms)
    {
        [self.delegate showZoneBlacklistTableForUser:self.user];
    }
    else if (type == SCUCreateInviteModelTypeServices)
    {
        [self.delegate showServiceBlacklistTableForUser:self.user];
    }
}

#pragma mark - SCUTextFieldListenerDelegate methods

- (void)textFieldListener:(SCUTextFieldListener *)listener didReceiveText:(NSString *)text fromTag:(NSInteger)tag
{
    switch (tag)
    {
        case SCUCreateInviteModelTypeEmail:
            self.user.email = text;
            break;
        case SCUCreateInviteModelTypeFirstName:
            self.user.firstName = text;
            break;
        case SCUCreateInviteModelTypeLastName:
            self.user.lastName = text;
            break;
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidReturnWithTag:(NSInteger)tag finalText:(NSString *)text
{
    switch (tag)
    {
        case SCUCreateInviteModelTypeEmail:
            [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            self.user.email = text;
            break;
        case SCUCreateInviteModelTypeFirstName:
            [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            self.user.firstName = text;
            break;
        case SCUCreateInviteModelTypeLastName:
            self.user.lastName = text;
            [self.delegate endEditing];
            break;
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener errorTextFieldDidEndInInvalidState:(SCUErrorTextField *)textField
{
    switch (textField.tag)
    {
        case SCUCreateInviteModelTypeEmail:
            self.emailIsValid = NO;
            break;
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener didClearTextForErrorTextField:(SCUErrorTextField *)textField
{
    switch (textField.tag)
    {
        case SCUCreateInviteModelTypeEmail:
            [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            self.emailIsValid = YES;
            break;
        case SCUCreateInviteModelTypeFirstName:
            [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            break;
        case SCUCreateInviteModelTypeLastName:
            [self.delegate setFirstResponderAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            break;
    }
}

#pragma mark -

- (void)deleteUser
{
    SAVWeakSelf;
    [[SavantControl sharedControl] deleteUser:self.user completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        if (success)
        {
            [wSelf.delegate editingComplete];
        }
        else
        {
            //-------------------------------------------------------------------
            // CBP TODO: Handle error
            //-------------------------------------------------------------------
        }
    }];
}

@end
