//
//  SCUSceneSaveViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSaveViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneSaveDataSource.h"
#import "SCUSceneSaveStockImageViewController.h"
#import "SCUSceneNameCell.h"
#import "SCUButton.h"
#import "SCUPopoverController.h"
#import "SCUActionSheet.h"
#import "SCUSceneSubtitleCell.h"

@interface SCUSceneSaveViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) SCUButton *saveScene;
@property SCUPopoverController *popover;
@property SCUActionSheet *actionSheet;
@property BOOL hasShownKeyboard;

@end

@implementation SCUSceneSaveViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        self.model = [[SCUSceneSaveDataSource alloc] initWithScene:scene andService:service];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];

    self.saveScene.enabled = [self saveEnabled];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([UIDevice isPad])
    {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];
    }

    SCUButton *cancel = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"chevron-down"]];
    cancel.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 15);
    cancel.backgroundColor = nil;
    cancel.selectedBackgroundColor = nil;
    cancel.target = self;
    cancel.releaseAction = @selector(popToRootViewController);

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.titleView = cancel;

    SCUButton *saveScene = [[SCUButton alloc] initWithTitle:[NSLocalizedString(@"Save Scene", nil) uppercaseString]];
    saveScene.backgroundColor = [[SCUColors shared] color01];
    saveScene.selectedBackgroundColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.8];
    saveScene.color = [[SCUColors shared] color03];
    saveScene.target = self;
    saveScene.releaseAction = @selector(saveScenePressed);
    saveScene.titleLabel.font = [UIFont fontWithName:@"Gotham-Medium" size:14];
    saveScene.disabledColor = [[SCUColors shared] color03];
    saveScene.disabledBackgroundColor = [[SCUColors shared] color03shade06];

    self.passthroughVC.footerView = saveScene;
    self.passthroughVC.footerHeight = 60;

    self.saveScene = saveScene;

    self.saveScene.enabled = [self saveEnabled];

    SAVWeakSelf;
    self.model.scene.imageChangeCallback = ^(UIImage *image, UIImage *blurredImage)
    {
        SCUSceneNameCell *cell = (SCUSceneNameCell *)[wSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        cell.image = image;
    };

    self.tableView.rowHeight = 83;
}

- (BOOL)saveEnabled
{
    BOOL saveEnabled = NO;

    if ([self.model.scene.name length] && self.creationVC.sceneIsDirty)
    {
        saveEnabled = YES;
    }

    return saveEnabled;
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    return type == 0 ? 100 : self.tableView.rowHeight;
}

- (void)saveScenePressed
{
    [self dismissViewController];

    [self.creationVC.delegate saveScene:self.model.scene];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == 0)
    {
        SCUSceneNameCell *cell = (SCUSceneNameCell *)c;

        cell.textField.delegate = self;

        if (!self.hasShownKeyboard && ![self.model.scene.name length])
        {
            [cell.textField becomeFirstResponder];
            self.hasShownKeyboard = YES;
        }

        SAVWeakSelf;
        [cell.textField sav_forControlEvent:UIControlEventEditingChanged performBlock:^{
            wSelf.model.scene.name = cell.textField.text;
            wSelf.saveScene.enabled = [self saveEnabled];
        }];

        cell.image = self.model.scene.image;

        [cell.addPhotoButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
            if (![wSelf.popover isPopoverVisible])
            {
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                imagePicker.modalPresentationStyle = UIModalPresentationFormSheet;
                imagePicker.delegate = wSelf;

                NSInteger buttonCount = 0;
                NSArray *buttons = @[NSLocalizedString(@"Savant Images", nil), NSLocalizedString(@"Image from Library", nil)];

                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
                {
                    buttons = [buttons arrayByAddingObject:NSLocalizedString(@"Image from Camera", nil)];
                }

                buttonCount += [buttons count];
                
                if ([wSelf.model.scene.imageKey length])
                {
                    wSelf.actionSheet = [[SCUActionSheet alloc] initWithTitle:nil buttonTitles:buttons cancelTitle:nil destructiveTitle:NSLocalizedString(@"Remove Image", nil)];
                    buttonCount += 1;
                }
                else
                {
                    wSelf.actionSheet = [[SCUActionSheet alloc] initWithButtonTitles:buttons];
                }

                SCUActionSheetCallback callback = ^(NSInteger buttonIndex){
                    if (buttonIndex == -2)
                    {
                        [[Savant images] removeImageForKey:wSelf.model.scene.imageKey andType:SAVImageTypeSceneImage];

                        wSelf.model.scene.imageKey = nil;
                        wSelf.model.scene.hasCustomImage = NO;

                        wSelf.saveScene.enabled = [wSelf saveEnabled];
                    }
                    else if (buttonIndex != -1)
                    {
                        if (buttonIndex == 0)
                        {
                            SCUSceneSaveStockImageViewController *stockImagePicker = [[SCUSceneSaveStockImageViewController alloc] initWithScene:self.model.scene];
                            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:stockImagePicker];
                            
                            [stockImagePicker setCallback:^{
                                wSelf.saveScene.enabled = [wSelf saveEnabled];
                            }];
                            
                            if ([UIDevice isPad])
                            {
                                navController.modalPresentationStyle = UIModalPresentationFormSheet;
                            }
                            
                            [wSelf presentViewController:navController animated:YES completion:nil];
                            
                        }
                        else if (buttonIndex == 1)
                        {
                            if ([UIDevice isPhone])
                            {
                                [wSelf presentViewController:imagePicker animated:YES completion:nil];
                            }
                            else
                            {
                                wSelf.popover = [[SCUPopoverController alloc] initWithContentViewController:imagePicker];
                                [wSelf.popover presentPopoverFromButton:cell.addPhotoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                            }
                        }
                        else
                        {
                            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                            imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;

                            [wSelf presentViewController:imagePicker animated:YES completion:nil];
                        }

                    }
                };

                if (buttonCount > 1)
                {
                    wSelf.actionSheet.callback = callback;
                    [wSelf.actionSheet showFromRect:cell.addPhotoButton.frame inView:self.view withMaxWidth:[UIDevice isPad] ? 320.0f : CGRectGetWidth([[UIScreen mainScreen] bounds])];
                }
                else
                {
                    callback(0);
                }
            }
        }];
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSceneNameCell class] forCellType:0];
    [self.tableView sav_registerClass:[SCUSceneSubtitleCell class] forCellType:1];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        SCUSceneNameCell *cell = (SCUSceneNameCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [cell.textField resignFirstResponder];

        if (indexPath.row == 0)
        {
            self.creationVC.activeState = SCUSceneCreationState_Schedule;
        }
        else
        {
            self.creationVC.activeState = SCUSceneCreationState_FadeTime;
        }
        
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

#pragma mark - ImagePicker Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.delegate = self;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    NSString *previousImageKey = self.model.scene.hasCustomImage ? self.model.scene.imageKey : nil;
    self.model.scene.hasCustomImage = YES;
    self.model.scene.imageKey = [[NSUUID UUID] UUIDString];

    dispatch_async_global(^{
        if ([previousImageKey length])
        {
            [[Savant images] removeImageForKey:previousImageKey andType:SAVImageTypeSceneImage];
        }

        [[Savant images] saveImage:image withKey:self.model.scene.imageKey type:SAVImageTypeSceneImage];
    });

    self.actionSheet = nil;

    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera || [UIDevice isPhone])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;

    self.saveScene.enabled = [self saveEnabled];
}

@end
