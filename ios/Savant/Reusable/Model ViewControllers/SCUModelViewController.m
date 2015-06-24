//
//  SCUModelViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"

@interface SCUModelViewController ()

@end

@implementation SCUModelViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[self viewModel] respondsToSelector:@selector(viewWillAppear)])
    {
        [[self viewModel] viewWillAppear];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[self viewModel] respondsToSelector:@selector(viewDidAppear)])
    {
        [[self viewModel] viewDidAppear];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([[self viewModel] respondsToSelector:@selector(viewWillDisappear)])
    {
        [[self viewModel] viewWillDisappear];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if ([[self viewModel] respondsToSelector:@selector(viewDidDisappear)])
    {
        [[self viewModel] viewDidDisappear];
    }
}

#pragma mark - Methods to subclass

- (id<SCUViewModel>)viewModel
{
    return nil;
}

@end
