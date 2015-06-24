//
//  SCUSchedulingEditor.m
//  SavantController
//
//  Created by Nathan Trapp on 7/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditor.h"
#import "SCUSchedulingEditorCollectionViewController.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUGradientView.h"
#import "SCUAlertView.h"

#import <SavantControl/SAVClimateSchedule.h>

@interface SCUSchedulingEditor () <UITextFieldDelegate>

@property SCUSchedulingEditorCollectionViewController *collectionViewController;
@property (nonatomic, readonly) SAVClimateSchedule *schedule;

@end

@implementation SCUSchedulingEditor

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super init];
    if (self)
    {
        self.collectionViewController = [[DeviceClassFromClass([SCUSchedulingEditorCollectionViewController class]) alloc] initWithSchedule:schedule];
    }
    return self;
}

- (void)loadView
{
    self.view = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:[SCUGradientView standardGradient]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self sav_addChildViewController:self.collectionViewController];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    self.navigationItem.rightBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped)];
    self.title = self.newSchedule ? NSLocalizedString(@"New Schedule", nil) : NSLocalizedString(@"Edit Schedule", nil);

    doneButton.enabled = self.schedule.name ? YES : NO;

    UITextField *nameField = [[UITextField alloc] initWithFrame:CGRectZero];
    nameField.textAlignment = NSTextAlignmentCenter;
    nameField.textColor = [[SCUColors shared] color04];
    nameField.autocorrectionType = UITextAutocorrectionTypeNo;
    nameField.font = [UIFont fontWithName:@"Gotham" size:17];
    nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter a schedule name" attributes:@{NSForegroundColorAttributeName: [UIColor sav_colorWithRGBValue:0x666565]}];
    nameField.returnKeyType = UIReturnKeyDone;
    nameField.delegate = self;
    nameField.backgroundColor = [UIColor sav_colorWithRGBValue:0x242424 alpha:0.9];
    nameField.text = self.schedule.name;

    [self.view addSubview:nameField];

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                       views:@{@"collectionView": self.collectionViewController.view,
                                                                               @"nameField": nameField}
                                                                     formats:@[@"V:|[nameField(40)][collectionView]|",
                                                                               @"|[nameField]|",
                                                                               @"|[collectionView]|"]]];

    SAVWeakSelf;
    [nameField sav_forControlEvent:UIControlEventEditingChanged performBlock:^{
        if (!wSelf.schedule.oldName && !self.newSchedule)
        {
            wSelf.schedule.oldName = wSelf.schedule.name;
        }

        wSelf.schedule.name = nameField.text;

        if ([wSelf.schedule.oldName isEqualToString:wSelf.schedule.name])
        {
            wSelf.schedule.oldName = nil;
        }

        doneButton.enabled = wSelf.schedule.name ? YES : NO;
    }];
}

- (SAVClimateSchedule *)schedule
{
    return self.collectionViewController.model.schedule;
}

- (void)setDelegate:(id<SCUSchedulingEditorDelegate>)delegate
{
    _delegate = delegate;

    [self.collectionViewController.model.schedule applyGlobalSettings:[self.delegate schedulerSettings]];
}

- (void)doneButtonTapped
{
    SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Save Climate Schedule", nil) message:NSLocalizedString(@"Would you like to activate this schedule?", nil) buttonTitles:@[@"Not Now", @"Activate"]];
    SAVWeakSelf;
    [alertView setCallback:^(NSUInteger buttonIndex) {
        if (buttonIndex == 1)
        {
            [wSelf.collectionViewController.model.schedule setActive:YES];
        }
        
        [wSelf.delegate willDismissEditor:self.collectionViewController.model.schedule];
        [wSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    
    if ([self.collectionViewController.model.schedule isActive])
    {
        [wSelf.delegate willDismissEditor:self.collectionViewController.model.schedule];
        [wSelf dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [alertView show];
    }
    
}

- (void)cancelButtonTapped
{
    [self.delegate willDismissEditor:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
