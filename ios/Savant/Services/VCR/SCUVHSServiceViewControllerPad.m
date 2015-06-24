//
//  SCUVHSServiceViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVHSServiceViewControllerPad.h"
#import "SCUVHSServiceViewControllerPrivate.h"

@implementation SCUVHSServiceViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //-------------------------------------------------------------------
    // Setup the initial layout for the current orientation.
    //-------------------------------------------------------------------
    [self setupConstraintsForOrientation:[UIDevice interfaceOrientation]];
}

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    self.buttonViewController.columns = UIInterfaceOrientationIsPortrait(orientation) ? 3 : 4;
    [self.transportControls.collectionViewController.collectionView reloadData];
}

@end
