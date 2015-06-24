//
//  SCUVHSServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVHSServiceViewController.h"
#import "SCUVHSServiceViewControllerPrivate.h"

@interface SCUVHSServiceViewController () <SCUButtonCollectionViewControllerDelegate>

@end

@implementation SCUVHSServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.buttonViewController = [[SCUTransportButtonCollectionViewController alloc] initWithGenericCommands:self.model.transportGenericCommands
                                                                   backCommands:self.model.transportBackCommands
                                                                forwardCommands:self.model.transportForwardCommands];
    
    self.buttonViewController.columns = 2;
    
    self.transportControls = [[SCUButtonViewController alloc] initWithCollectionViewController:self.buttonViewController];
    self.transportControls.delegate = self;
    self.transportControls.squareCells = YES;
    
    [self addChildViewController:self.transportControls];
    
    [self.contentView addSubview:self.transportControls.view];
    [self.contentView sav_addFlushConstraintsForView:self.transportControls.view];
}

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    [self.model sendCommand:command];
}

@end
