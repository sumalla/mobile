//
//  SCUSystemSelectorSettingsModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSystemSelectorSettingsModel.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUMainViewController.h"
#import "SCUTextEntryAlert.h"
#import <SavantControl/SavantControl.h>
#import "SCUAppDelegate.h"
@import MessageUI;

static NSString *const SCUSystemSelectorHasAccountKey = @"SCUSystemSelectorHasAccountKey";

@interface SCUSystemSelectorSettingsModel ()

@property (nonatomic) NSArray *dataSource;
@property (nonatomic) SCUActionSheet *sheet;

@end

@implementation SCUSystemSelectorSettingsModel

- (void)loadDataIfNecessary
{
    BOOL hasAccount = [[SavantControl sharedControl] hasCloudCredentials];
    NSString *account = hasAccount ? [[SavantControl sharedControl] cloudUser] : NSLocalizedString(@"None", nil);

    if (!account)
    {
        abort();
    }

    self.dataSource = @[
                        @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Account", nil),
                          SCUDefaultTableViewCellKeyDetailTitle: account,
                          SCUSystemSelectorHasAccountKey: @(hasAccount)},
                        @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Email Logs", nil)}
                        ];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

        SCUActionSheet *actionSheet = nil;

        if ([modelObject[SCUSystemSelectorHasAccountKey] boolValue])
        {
            if ([UIDevice isPhone])
            {
                NSString *title = [[SavantControl sharedControl] cloudUser];
                NSString *destructiveButtonTitle = NSLocalizedString(@"Sign Out", nil);
                NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
                
                actionSheet = [[SCUActionSheet alloc] initWithTitle:title buttonTitles:nil cancelTitle:cancelButtonTitle destructiveTitle:destructiveButtonTitle];

                SAVWeakSelf;
                actionSheet.callback = ^(NSInteger buttonIndex) {
                    if (buttonIndex == -2)
                    {
                        [wSelf signOut];
                    }
                };
            }
            else
            {
                SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Savant ID", nil)
                                                                      message:[[SavantControl sharedControl] cloudUser]
                                                                 buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Sign Out", nil)]];

                alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

                [alertView show];

                SAVWeakSelf;
                alertView.callback = ^(NSUInteger buttonIndex) {
                    if (buttonIndex == 1)
                    {
                        [wSelf signOut];
                    }
                };
            }
        }
        else
        {
            if ([UIDevice isPhone])
            {
                actionSheet = [[SCUActionSheet alloc] initWithButtonTitles:@[NSLocalizedString(@"Sign In", nil)]
                                                               cancelTitle:NSLocalizedString(@"Cancel", nil)];

                SAVWeakSelf;
                actionSheet.callback = ^(NSInteger buttonIndex) {
                    if (buttonIndex == 0)
                    {
                        [wSelf signOut];
                    }
                };
            }
            else
            {
                SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Savant ID", nil)
                                                                  contentView:nil
                                                                 buttonTitles:@[NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Sign In", nil)]];

                alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

                [alertView show];

                SAVWeakSelf;
                alertView.callback = ^(NSUInteger buttonIndex) {
                    if (buttonIndex == 1)
                    {
                        [wSelf signOut];
                    }
                };
            }
        }
        
        if (actionSheet)
        {
            self.sheet = actionSheet;
            [self.delegate presentActionSheet:actionSheet];
        }
    }
    else if (indexPath.row == 1)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];

            mc.subject = NSLocalizedString(@"Savant iOS Device Logs", nil);
            [mc setMessageBody:[NSString stringWithFormat:NSLocalizedString(@"Attached, please find Savant iOS device log files.\n\nApp version: %@\nDevice Identifier: %@", nil), [self version], [[[UIDevice currentDevice] identifierForVendor] UUIDString]]
                        isHTML:NO];

            NSDictionary *logs = [[SavantControl sharedControl] logData];

            for (NSString *fileName in logs)
            {
                [mc addAttachmentData:logs[fileName] mimeType:@"text/plain" fileName:fileName];
            }
            
            [self.delegate presentMailComposeVC:mc];
        }
        else
        {
            SCUAlertView *alert = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Send Email", nil)
                                                              message:NSLocalizedString(@"Please make sure an email account is enabled in the Settings app.", nil)
                                                         buttonTitles:@[NSLocalizedString(@"OK", nil)]];
            
            [alert show];
        }
    }
}

- (NSString *)version
{
    return [NSString stringWithFormat:@"Savant %@", [(SCUAppDelegate *)[[UIApplication sharedApplication] delegate] appVersion]];
}

- (void)signOut
{
    [[SavantControl sharedControl] disconnect];
    [[SavantControl sharedControl] signOut];

    dispatch_next_runloop(^{
        [[SCUMainViewController sharedInstance] presentSplashScreen];
    })
}

@end
