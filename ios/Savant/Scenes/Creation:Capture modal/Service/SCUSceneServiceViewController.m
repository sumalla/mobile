//
//  SCUSceneServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneServiceViewController.h"
#import "SCUSceneServiceViewModel.h"
#import "SCUSceneCreationViewController.h"
#import "SCUServiceViewController.h"

@import SDK;

@interface SCUSceneServiceViewController ()

@end

@implementation SCUSceneServiceViewController

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService
{
    self = [super init];
    if (self)
    {
        self.model = [[SCUSceneServiceViewModel alloc] initWithScene:scene service:service sceneService:sceneService];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self.model.service.serviceId hasPrefix:@"SVC_ENV"])
    {
        self.title = self.model.service.displayName;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.creationVC.isEnvAdd ? NSLocalizedString(@"Add", nil) : NSLocalizedString(@"Done", nil)
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(popViewControllerCommit)];

        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(popViewControllerCanceled)];


    }
    else
    {
        self.title = self.model.service.alias;

        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil)
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(next)];

        if (self.creationVC.isFirstView)
        {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                  target:self
                                                                                                  action:@selector(popViewControllerCanceled)];
        }
    }

    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    SAVWeakSelf;

    UIBarButtonItem *defaultLeftButton = self.navigationItem.leftBarButtonItem;

    self.leftBarButtonModifyBlock = ^(UIBarButtonItem *item) {
        SAVStrongWeakSelf;

        if ([item isEqual:[NSNull null]])
        {
            sSelf.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:nil action:NULL];
        }
        else if (item)
        {
            sSelf.navigationItem.leftBarButtonItem = item;
        }
        else
        {
            sSelf.navigationItem.leftBarButtonItem = defaultLeftButton;
        }
    };

    UIBarButtonItem *defaultRightButton = self.navigationItem.rightBarButtonItem;

    self.rightBarButtonModifyBlock = ^(UIBarButtonItem *item) {
        SAVStrongWeakSelf;

        if ([item isEqual:[NSNull null]])
        {
            sSelf.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:nil action:NULL];
        }
        else if (item)
        {
            sSelf.navigationItem.rightBarButtonItem = item;
        }
        else
        {
            sSelf.navigationItem.rightBarButtonItem = defaultRightButton;
        }
    };
}

- (void)popViewControllerCanceled
{
    if (self.creationVC.isEnvAdd)
    {
        for (SAVSceneService *service in [self.model.scene.lightingServices arrayByAddingObjectsFromArray:self.model.scene.hvacServices])
        {
            // Special case for HVAC since we deal with zones instead of rooms for some things
            if (service.zones.count)
            {
                [service.zones removeObject:self.model.service.zoneName];
            }
            else
            {
                [service.rooms removeObject:self.model.service.zoneName];
            }
        }

        [self popViewController];
    }
    else
    {
        if ([UIDevice isPad] && !self.creationVC.isLeftView)
        {
            if ([self.model.service.serviceId hasPrefix:@"SVC_ENV"])
            {
                [self popViewController];
            }
            else
            {
                [self.creationVC viewControllerDidCancel:self];
            }
        }
        else
        {
            [self popViewController];
        }
    }

    [self rollback];
}

- (void)popViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)popViewControllerCommit
{
    [self popViewController];
    [self commit];
}

- (void)next
{
    self.creationVC.activeState = SCUSceneCreationState_ServiceRoom;
}

- (void)commit
{
    ;
}

- (void)rollback
{
    ;
}

@end
