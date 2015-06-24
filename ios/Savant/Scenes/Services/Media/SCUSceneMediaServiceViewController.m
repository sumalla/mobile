//
//  SCUSceneMediaServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneMediaServiceViewController.h"
#import "SCUMediaServiceViewControllerPrivate.h"
#import "SCUSceneCreationViewController.h"
#import "SCUMediaRequestViewControllerModel.h"
#import "SCUSceneMediaHeaderView.h"

@import SDK;

@interface SCUSceneMediaServiceViewController () <SCUMediaRequestViewControllerSceneDelegate, StateDelegate>

@property NSMutableDictionary *currentStates;
@property SAVScene *sceneObject;

@end

@implementation SCUSceneMediaServiceViewController

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService
{
    self = [super initWithService:service];
    if (self)
    {
        self.model.shouldPowerOn = NO;
        self.currentStates = [NSMutableDictionary dictionary];
        self.sceneObject = scene;
    }
    
    return self;
}

- (void)dealloc
{
    [[Savant states] unregisterForStates:self.states forObserver:self];
}

- (void)viewDidLoad
{
    [[Savant states] registerForStates:self.states forObserver:self];

    [super viewDidLoad];
    
    self.mediaModel.sceneDelegate = self;
    if (self.creationVC.isFirstView)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(popViewControllerCanceled)];
    }

    for (SAVService *service in self.serviceGroup.services)
    {
        SAVSceneService *sceneService = [self.sceneObject sceneServiceForService:service];

        if ([sceneService.combinedStates count])
        {
            self.headerView = [[SCUSceneMediaHeaderView alloc] initWithService:sceneService];
            break;
        }
    }
}

- (void)next
{
    self.navController.delegate = self.creationVC;
    self.creationVC.activeState = SCUSceneCreationState_ServiceRoom;
}

- (void)popViewControllerCanceled
{
    self.navController.delegate = self.creationVC;

    for (SAVService *service in self.serviceGroup.services)
    {
        SAVSceneService *sceneService = [self.sceneObject sceneServiceForService:service];

        [sceneService rollback];
    }

    if ([UIDevice isPad] && !self.creationVC.isLeftView)
    {
        [self.creationVC viewControllerDidCancel:self];
    }
    else
    {
        [self.navController popViewControllerAnimated:YES];
    }
}

- (void)reachedLeaf
{
    [super reachedLeaf];

    [NSTimer sav_scheduledBlockWithDelay:.3 block:^{
        [self updateHeader];
    }];
}

- (void)updateHeader
{
    for (SAVService *service in self.serviceGroup.services)
    {
        SAVSceneService *sceneService = [self.sceneObject sceneServiceForService:service];

        //-------------------------------------------------------------------
        // Clear all previous states
        //-------------------------------------------------------------------
        for (NSString *state in self.states)
        {
            [sceneService applyValue:nil forSetting:state immediately:NO];
        }

        //-------------------------------------------------------------------
        // Set any new states
        //-------------------------------------------------------------------
        for (NSString *state in self.currentStates)
        {
            [sceneService applyValue:self.currentStates[state] forSetting:state immediately:NO];
        }

        //-------------------------------------------------------------------
        // Update header
        //-------------------------------------------------------------------
        if ([sceneService.combinedStates count])
        {
            self.headerView = [[SCUSceneMediaHeaderView alloc] initWithService:sceneService];
        }
        else
        {
            self.headerView = nil;
        }
    }
}

- (BOOL)isScene
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navController removeDelegate:(id)self.creationVC];
}

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

- (NSArray *)states
{
    NSString *scope = [self.model.stateScope stringByAppendingString:@"."];

    return @[[scope stringByAppendingString:@"CurrentAlbumName"],
             [scope stringByAppendingString:@"CurrentArtistName"],
             [scope stringByAppendingString:@"CurrentArtworkPath"],
             [scope stringByAppendingString:@"CurrentSongName"]];
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.value length])
    {
        self.currentStates[stateUpdate.stateName] = stateUpdate.value;
    }
    else
    {
        [self.currentStates removeObjectForKey:stateUpdate.value];
    }

    if ([stateUpdate.stateName isEqualToString:@"CurrentArtworkPath"])
    {
        for (SAVService *service in self.serviceGroup.services)
        {
            SAVSceneService *sceneService = [self.sceneObject sceneServiceForService:service];

            if ([self.currentStates[@"CurrentAlbumName"] isEqualToString:sceneService.combinedStates[@"CurrentAlbumName"]] &&
                [self.currentStates[@"CurrentSongName"] isEqualToString:sceneService.combinedStates[@"CurrentSongName"]])
            {
                [self updateHeader];
                break;
            }
        }
    }

}

@end
