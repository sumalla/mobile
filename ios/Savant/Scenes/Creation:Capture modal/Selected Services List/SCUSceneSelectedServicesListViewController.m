//
//  SCUSceneServicesListViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSelectedServicesListViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUScenesSelectedServiceModel.h"
#import "SCUSceneCell.h"
#import "SCUButton.h"
#import "SCUAlertView.h"

@import SDK;

@interface SCUSceneSelectedServicesListViewController ()

@property SCUScenesSelectedServiceModel *model;
@property BOOL viewLoaded;

@end

@implementation SCUSceneSelectedServicesListViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUScenesSelectedServiceModel alloc] initWithScene:scene andService:service];
    }
    return self;
}

- (void)reloadData
{
    if (self.viewLoaded)
    {
        self.title = self.model.scene.name ? self.model.scene.name : NSLocalizedString(@"My Scene", nil);

        [self.model prepareData];
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 150;

    self.title = self.model.scene.name ? self.model.scene.name : NSLocalizedString(@"New Scene", nil);

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(addService)];

    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(closeScene)];

    // SRS TODO: Come back and fix this once SCUButton refactor has been finished/merged
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [[SCUColors shared] color03shade08],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateDisabled];
    
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

    self.viewLoaded = YES;
}

- (void)closeScene
{
    if (self.creationVC.sceneIsDirty)
    {
        SCUAlertView *alertView = [[SCUAlertView alloc] initWithTitle:NSLocalizedString(@"Your Scene Will Not Be Saved", nil) contentView:nil buttonTitles:@[@"Cancel", @"OK"]];
        alertView.primaryButtons = [NSIndexSet indexSetWithIndex:1];

        SAVWeakSelf;
        alertView.callback = ^(NSUInteger buttonIndex){
            if (buttonIndex == 1)
            {
                [wSelf dismissViewController];
            }
        };

        [alertView show];
    }
    else
    {
        [self dismissViewController];
    }
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSceneCell class] forCellType:0];
}

- (void)saveScenePressed
{
    self.creationVC.activeState = SCUSceneCreationState_Save;
}

- (void)addService
{
    self.creationVC.activeState = SCUSceneCreationState_AddServicesList;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    SAVService *service = [self.model serviceForIndexPath:indexPath];
    self.creationVC.editingService = [service mutableCopy];

    if ([service.serviceId hasPrefix:@"SVC_AV"] &&
        ![service.serviceId isEqualToString:@"SVC_AV_%"])
    {
        self.creationVC.activeState = SCUSceneCreationState_Service;
    }
    else if (service && ([service.serviceId hasPrefix:@"SVC_ENV_HVAC"]))
    {
        self.creationVC.activeState = SCUSceneCreationState_ZonesList;
    }
    else
    {
        self.creationVC.activeState = SCUSceneCreationState_RoomsList;
    }
}

- (void)setScene:(SAVScene *)scene
{
    for (SAVSceneService *sceneService in scene.avServices)
    {
        if (![sceneService.rooms count])
        {
            [scene removeAVSceneService:sceneService];
        }
    }

    for (SAVSceneService *sceneService in scene.lightingServices)
    {
        if (![sceneService.rooms count])
        {
            [scene removeLightingSceneService:sceneService];
        }
    }

    for (SAVSceneService *sceneService in scene.hvacServices)
    {
        if (![sceneService.rooms count])
        {
            [scene removeHVACSceneService:sceneService];
        }
    }

    self.model.scene = scene;
    [self reloadData];
}

- (SAVScene *)scene
{
    return self.model.scene;
}

@end
