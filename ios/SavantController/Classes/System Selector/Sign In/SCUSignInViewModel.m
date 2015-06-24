//
//  SCUSignInViewModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSignInViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUTextFieldListener.h"
#import "SCUCascadingTimer.h"
#import "SCUMainViewModel.h"
#import "SCUTextFieldProgressTableViewCell.h"
#import "SCUAlertView.h"
#import "SCUToggleSwitchTableViewCell.h"

typedef NS_ENUM(NSInteger, SCUSignInViewModelTextFieldTag)
{
    SCUSignInViewModelTextFieldTagUserName = 100,
    SCUSignInViewModelTextFieldTagPassword = 101
};

@interface SCUSignInViewModel () <UITextFieldDelegate, SystemStatusDelegate, SCUTextFieldListenerDelegate>

@property (nonatomic) SCUTextFieldListener *textFieldListener;
@property (nonatomic) SAVLocalUser *user;
@property (nonatomic) BOOL fixedUserName;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *password;
@property (nonatomic) SCUSignInViewModelCellAccessoryType accessoryState;
@property (nonatomic) SCUCascadingTimer *timer;

@end

@implementation SCUSignInViewModel

- (void)dealloc
{
    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

- (instancetype)initWithUser:(SAVLocalUser *)user
{
    self = [super init];

    if (self)
    {
        [[SavantControl sharedControl] addSystemStatusObserver:self];

        self.timer = [[SCUCascadingTimer alloc] init];

        self.textFieldListener = [[SCUTextFieldListener alloc] init];
        self.textFieldListener.delegate = self;

        if (user)
        {
            self.user = user;

            if (self.user.accountName)
            {
                self.fixedUserName = YES;
            }

            self.userName = self.user.accountName ? self.user.accountName : @"";
        }

        if (!self.userName)
        {
            self.userName = @"";
        }

        if (!self.password)
        {
            self.password = @"";
        }
    }

    return self;
}

- (void)signIn
{
    [self.delegate endEditing];
    [self.delegate updateTitle:NSLocalizedString(@"Signing In", nil)];
    [self updatePasswordFieldWithAccessoryType:SCUSignInViewModelCellAccessoryTypeSpinner];
    [[SavantControl sharedControl] loginToLocalUser:self.userName password:self.password];
}

- (void)listenToTextField:(UITextField *)textField forIndexPath:(NSIndexPath *)indexPath
{
    SCUSignInViewModelTextFieldTag tag = SCUSignInViewModelTextFieldTagPassword;

    if (indexPath.row == 0 && !self.fixedUserName)
    {
        tag = SCUSignInViewModelTextFieldTagUserName;
    }

    [self.textFieldListener listenToTextField:textField withTag:tag];
}

#pragma mark - SCUViewModel methods

- (void)viewDidAppear
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.delegate setFirstResponderForIndexPath:indexPath];
}

- (void)viewWillAppear
{
    [self.delegate updateTitle:NSLocalizedString(@"Sign In", nil)];
}

- (void)viewWillDisappear
{
    [self.timer invalidate];
}

#pragma mark - SCUDataSourceModel methods

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = nil;
    
    if (self.user)
    {
        modelObject = [self passwordModelObject];
    }
    else
    {
        if (indexPath.row == 0)
        {
            modelObject = [self userModelObject];
        }
        else
        {
            modelObject = [self passwordModelObject];
        }
    }

    return modelObject;
}

- (NSDictionary *)userModelObject
{
    return @{SCUTextFieldProgressTableViewCellKeyEditableText: self.userName,
             SCUTextFieldProgressTableViewCellKeyReturnKeyType: @(UIReturnKeyNext),
             SCUTextFieldProgressTableViewCellKeyPlaceholderText: NSLocalizedString(@"Username", nil),
             SCUTextFieldProgressTableViewCellKeyIsSecure: @NO,
             SCUTextFieldProgressTableViewCellKeyClearType: @(UITextFieldViewModeWhileEditing)};
}

- (NSDictionary *)passwordModelObject
{
    return @{SCUTextFieldProgressTableViewCellKeyEditableText: self.password,
             SCUTextFieldProgressTableViewCellKeyReturnKeyType: @(UIReturnKeyDone),
             SCUTextFieldProgressTableViewCellKeyPlaceholderText: NSLocalizedString(@"Password", nil),
             SCUTextFieldProgressTableViewCellKeyIsSecure: @YES,
             SCUProgressTableViewCellKeyAccessoryType: @(self.accessoryState),
             SCUTextFieldProgressTableViewCellKeyClearType: @(UITextFieldViewModeWhileEditing)};
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return SCUSignInViewModelCellTypeEditable;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return self.user ? 1 : 2;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return [SavantControl sharedControl].currentSystem.name;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self cellTypeForIndexPath:indexPath] == SCUSignInViewModelCellTypeEditable)
    {
        [self.delegate setFirstResponderForIndexPath:indexPath];
    }
}

#pragma mark - SCUTextFieldListenerDelegate methods

- (void)textFieldListener:(SCUTextFieldListener *)listener didReceiveText:(NSString *)text fromTag:(NSInteger)tag
{
    if (tag == SCUSignInViewModelTextFieldTagUserName)
    {
        self.userName = text;
    }
    else if (tag == SCUSignInViewModelTextFieldTagPassword)
    {
        self.password = text;
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidReturnWithTag:(NSInteger)tag finalText:(NSString *)text
{
    if (tag == SCUSignInViewModelTextFieldTagUserName)
    {
        [self.delegate setFirstResponderForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }
    else
    {
        [self signIn];
    }
}

#pragma mark - SystemStatusDelegate

- (void)connectionDidAuthorizeForUser:(NSString *)user
{
    SAVWeakSelf;
    [self.timer addBlockAfterDelay:0.2 block:^{
        [wSelf.delegate updateTitle:NSLocalizedString(@"Connected", nil)];
        [wSelf updatePasswordFieldWithAccessoryType:SCUSignInViewModelCellAccessoryTypeCheckmark];
    }];
}

- (void)connectionDidReceiveAuthChallengeForUser:(NSString *)user
{
    [self.timer invalidate];

    SAVWeakSelf;
    [self.timer addBlockAfterDelay:0.4 block:^{

        [wSelf.delegate updateTitle:NSLocalizedString(@"Sign In", nil)];
        [wSelf updatePasswordFieldWithAccessoryType:SCUSignInViewModelCellAccessoryTypeNone];

        NSString *message = nil;

        if (wSelf.fixedUserName)
        {
            message = NSLocalizedString(@"Incorrect password", nil);
        }
        else
        {
            message = NSLocalizedString(@"Incorrect password or username", nil);
        }

        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In Error", nil)
                                                              message:message
                                                         buttonTitles:@[NSLocalizedString(@"OK", nil)]];

        [alertView show];

    }];
}

#pragma mark -

- (void)updatePasswordFieldWithAccessoryType:(SCUSignInViewModelCellAccessoryType)accessoryType
{
    self.accessoryState = accessoryType;
    [self.delegate reloadIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

@end
