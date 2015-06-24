//
//  SCUHomeCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeCollectionViewController.h"
#import "SCUHomeCollectionViewModel.h"
#import "SCUButton.h"
#import "SCUServiceViewController.h"
#import "SCUToolbar.h"
#import "SCUInterface.h"
#import "SCUHomePageCollectionViewController.h"
#import "SCUHomeGridCollectionViewController.h"
#import "SCUHomeCell.h"
#import "SCUActionSheet.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>
@import ImageIO;

@interface SCUHomeCollectionViewController () <SCUHomeCollectionViewModelDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) SCUHomeCollectionViewModel *model;
@property (nonatomic) NSIndexPath *currentIndex;
@property SCUActionSheet *actionSheet;
@property UIPopoverController *popover;
@property NSString *pickingRoom;

@end

@implementation SCUHomeCollectionViewController

- (instancetype)init
{
    SCUHomeCollectionViewModel *model = [[SCUHomeCollectionViewModel alloc] init];
    return [self initWithRoom:[SCUInterface sharedInstance].currentRoom delegate:model model:model];
}

- (instancetype)initWithRoom:(SAVRoom *)room delegate:(id <SCUHomeCollectionViewControllerDelegate>)delegate model:(SCUHomeCollectionViewModel *)model
{
    self = [super init];
    if (self)
    {
        self.model = model;
        self.model.delegate = self;
        self.delegate = delegate;

        if (room)
        {
            if ([self.delegate respondsToSelector:@selector(willSwitchToRoomGroup:)])
            {
                [self.delegate willSwitchToRoomGroup:room.group];
            }

            self.currentIndex = [self.model indexPathForRoom:room.roomId];

            if ([self.delegate respondsToSelector:@selector(didSwitchRoomGroups)])
            {
                [self.delegate didSwitchRoomGroups];
            }
        }
    }
    [self configureLayout:self.collectionViewLayout withOrientation:[UIDevice deviceOrientation]];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;

    self.viewHasLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.model.delegate = self;
}

- (void)scrollToRoomGroup:(NSString *)groupId
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:sender];

    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:sender afterDelay:.01];
}

#pragma mark - Service Indicators

- (void)listenToSecurityButton:(SCUButton2 *)securityButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [securityButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([wSelf respondsToSelector:@selector(presentFullscreenView:)])
        {
            [SCUInterface sharedInstance].currentRoom = [wSelf.model roomForIndexPath:indexPath];
            [wSelf presentFullscreenView:NO];
        }

        SAVService *service = [[SAVService alloc] initWithZone:[SCUInterface sharedInstance].currentRoom.roomId
                                                     component:nil
                                              logicalComponent:nil
                                                     variantId:nil
                                                     serviceId:@"SVC_ENV_SECURITYSYSTEM"];

        [[SCUInterface sharedInstance] presentService:service];
    }];
}

- (void)listenToLightingButton:(SCUButton2 *)lightingButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [lightingButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([wSelf respondsToSelector:@selector(presentFullscreenView:)])
        {
            [SCUInterface sharedInstance].currentRoom = [wSelf.model roomForIndexPath:indexPath];
            [wSelf presentFullscreenView:NO];
        }

        SAVService *service = [[SAVService alloc] initWithZone:[SCUInterface sharedInstance].currentRoom.roomId
                                                     component:nil
                                              logicalComponent:nil
                                                     variantId:nil
                                                     serviceId:@"SVC_ENV_LIGHTING"];

        [[SCUInterface sharedInstance] presentService:service];
    }];
}

- (void)listenToFanButton:(SCUButton2 *)fanButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [fanButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([wSelf respondsToSelector:@selector(presentFullscreenView:)])
        {
            [SCUInterface sharedInstance].currentRoom = [wSelf.model roomForIndexPath:indexPath];
            [wSelf presentFullscreenView:NO];
        }
        
        SAVService *service = [[SAVService alloc] initWithZone:[SCUInterface sharedInstance].currentRoom.roomId
                                                     component:nil
                                              logicalComponent:nil
                                                     variantId:nil
                                                     serviceId:@"SVC_ENV_LIGHTING"];
        
        [[SCUInterface sharedInstance] presentService:service];
    }];
}

- (void)listenToTemperatureButton:(SCUButton2 *)temperatureButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [temperatureButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([wSelf respondsToSelector:@selector(presentFullscreenView:)])
        {
            [SCUInterface sharedInstance].currentRoom = [wSelf.model roomForIndexPath:indexPath];
            [wSelf presentFullscreenView:NO];
        }

        SAVMutableService *dummyService = [[SAVMutableService alloc] init];
        dummyService.serviceId = @"SVC_ENV_HVAC";
        NSArray *havcEntities = [[[SavantControl sharedControl] data] HVACEntities:[SCUInterface sharedInstance].currentRoom.roomId zone:nil service:dummyService];
        if ([havcEntities count] > 0)
        {
            dummyService.zoneName = [SCUInterface sharedInstance].currentRoom.roomId;

            if ([[[SavantControl sharedControl].data servicesFilteredByService:dummyService] count])
            {
                [[SCUInterface sharedInstance] presentService:((SAVEntity *)havcEntities[0]).service];
            }
        }
    }];
}

- (void)listenToServiceButton:(SCUButton2 *)serviceButton forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    [serviceButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        if ([wSelf respondsToSelector:@selector(presentFullscreenView:)])
        {
            [SCUInterface sharedInstance].currentRoom = [wSelf.model roomForIndexPath:indexPath];
            [wSelf presentFullscreenView:NO];
        }

        SCUHomeCell *cell = (SCUHomeCell *)[wSelf.collectionView cellForItemAtIndexPath:indexPath];

        [[SCUInterface sharedInstance] presentService:cell.activeService];
    }];
}

- (void)listenToLongPress:(UILongPressGestureRecognizer *)longPressGR forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    longPressGR.sav_handler = ^(UIGestureRecognizerState state, CGPoint location) {
        [wSelf handleLongPress:state forIndexPath:indexPath location:location];
    };
}

- (void)handleLongPress:(UIGestureRecognizerState)state forIndexPath:(NSIndexPath *)indexPath location:(CGPoint)location
{
    if (state == UIGestureRecognizerStateBegan && ![self.popover isPopoverVisible] && !self.actionSheet.visible)
    {
        self.pickingRoom = [self.model roomForIndexPath:indexPath].roomId;

        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.modalPresentationStyle = UIModalPresentationFormSheet;
        imagePicker.delegate = self;

        CGPoint convertedPoint = [self.view convertPoint:location fromView:[self.collectionView cellForItemAtIndexPath:indexPath]];

        NSArray *buttons = @[NSLocalizedString(@"Image from Library", nil)];

        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            buttons = [buttons arrayByAddingObject:NSLocalizedString(@"Image from Camera", nil)];
        }

        self.actionSheet = [[SCUActionSheet alloc] initWithTitle:nil buttonTitles:buttons cancelTitle:nil destructiveTitle:NSLocalizedString(@"Remove Image", nil)];

        SAVWeakSelf;
        self.actionSheet.callback = ^(NSInteger buttonIndex) {
            SAVStrongWeakSelf;
            if (buttonIndex == -2)
            {
                [[SavantControl sharedControl].imageModel removeImageForKey:sSelf.pickingRoom andType:SAVImageTypeRoomImage];
            }
            else if (buttonIndex != -1)
            {
                if (buttonIndex == 0)
                {
                    if ([UIDevice isPhone])
                    {
                        [sSelf presentViewController:imagePicker animated:YES completion:nil];
                    }
                    else
                    {
                        sSelf.popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
                        [sSelf.popover presentPopoverFromRect:CGRectMake(convertedPoint.x, convertedPoint.y, 0, 0) inView:sSelf.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    }
                }
                else
                {
                    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
                    [sSelf presentViewController:imagePicker animated:YES completion:nil];
                }
            }
        };

        [self.actionSheet showFromRect:CGRectMake(convertedPoint.x, convertedPoint.y, 0, 0) inView:self.view withMaxWidth:CGRectGetWidth([[UIScreen mainScreen] bounds])];
    }
}

#pragma mark - State Management

- (void)activeServiceChangedForIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(updateIndexPath:) withObject:indexPath afterDelay:0];
}

- (void)lightsAreOnChangedForIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(updateIndexPath:) withObject:indexPath afterDelay:0];
}

- (void)fansAreOnChangedForIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(updateIndexPath:) withObject:indexPath afterDelay:0];
}

- (void)securityStatusChangedForIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(updateIndexPath:) withObject:indexPath afterDelay:0];
}

- (void)currentTemperatureChangedForIndexPath:(NSIndexPath *)indexPath
{
    [self performSelector:@selector(updateIndexPath:) withObject:indexPath afterDelay:0];
}

- (void)updateIndexPath:(NSIndexPath *)indexPath
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:indexPath];
    
    if (self.viewHasLoaded && indexPath)
    {
        [self.collectionView sav_reloadItemsAtIndexPaths:@[indexPath] animated:NO];
    }
}

- (void)updateImage:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath isDefault:(BOOL)isDefault
{
    SCUHomeCell *cell = (SCUHomeCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.displayingDefaultImage = isDefault;
    cell.backgroundImage.image = image;
}

#pragma mark - Methods to subclass

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.popover isPopoverVisible] && !self.actionSheet.visible)
    {
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUHomeCell *homeCell = (SCUHomeCell *)cell;

    [self listenToLightingButton:homeCell.lightsButton forIndexPath:indexPath];
    [self listenToFanButton:homeCell.fanButton forIndexPath:indexPath];
    [self listenToSecurityButton:homeCell.securityButton forIndexPath:indexPath];
    [self listenToServiceButton:homeCell.serviceButton forIndexPath:indexPath];
    [self listenToTemperatureButton:homeCell.temperatureButton forIndexPath:indexPath];
    [self listenToLongPress:homeCell.longPressGestureRecognizer forIndexPath:indexPath];
    BOOL isDefault = NO;
    UIImage *image = [self.model imageForIndexPath:indexPath isDefault:&isDefault];
    homeCell.displayingDefaultImage = isDefault;
    homeCell.backgroundImage.image = image;
    [homeCell endUpdates];
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

#pragma mark - Properties

- (SAVRoom *)currentRoom
{
    return [self.model roomForIndexPath:self.currentIndex];
}

#pragma mark - ImagePicker Delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    BOOL resizeImage = NO;

    CGFloat maxSize = 3264; // largest size for a typical camera image
    CGSize size = image.size;

    if (size.width > maxSize)
    {
        CGFloat scale = size.width / maxSize;
        size.width = maxSize;
        size.height /= scale;
        resizeImage = YES;
    }

    if (size.height > maxSize)
    {
        CGFloat scale = size.height / maxSize;
        size.height = maxSize;
        size.width /= scale;
        resizeImage = YES;
    }

    if (resizeImage)
    {
        image = [image scaleToSize:size];
    }

    NSString *key = self.pickingRoom;

    dispatch_async_global(^{
        [[SavantControl sharedControl].imageModel saveImage:image withKey:key type:SAVImageTypeRoomImage];

        dispatch_async_main(^{
            [[SavantControl sharedControl].imageModel purgeMemory];
        });
    });

    self.actionSheet = nil;
    self.pickingRoom = nil;

    [self dismissViewControllerAnimated:YES completion:nil];

    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

@end
