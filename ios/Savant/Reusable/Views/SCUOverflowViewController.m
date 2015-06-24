//
//  SCUTVOverlayViewController.m
//  SavantController
//
//  Created by Stephen Silber on 2/3/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUButton.h"
#import "SCUToolbar.h"
#import "SCUOverflowViewController.h"
#import "SCUOverflowViewControllerPrivate.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowTableViewController.h"

@interface SCUOverflowViewController () <SCUOverlayDelegate>

@property (nonatomic) UIView *toolBar;
@property (nonatomic) UITableViewController *viewController;

@end

@implementation SCUOverflowViewController

static CGFloat topOffset = 65;

- (instancetype)initWithService:(SAVService *)service andTableViewController:(SCUOverflowTableViewController *)tableView
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.model.shouldPowerOn = NO;
        self.view.backgroundColor = [UIColor clearColor];
        self.title = NSLocalizedString(@"Menu", nil);
        
        tableView.delegate = self;
        self.viewController = tableView;
        self.viewController.tableView.backgroundColor = [[SCUColors shared] color03shade02];
        
        [self sav_addChildViewController:self.viewController];
        
        self.toolBar = [[UIView alloc] initWithFrame:CGRectZero];
        self.toolBar.backgroundColor = [[SCUColors shared] color03];
        
        self.navigationController.toolbarHidden = NO;
        
        UIImage *closeImage = [UIImage sav_imageNamed:@"hotdog" tintColor:[[SCUColors shared] color01]];
        
        SCUButton *closeButton = [[SCUButton alloc] initWithImage:closeImage];
        closeButton.color = [[SCUColors shared] color01];
        [closeButton addTarget:self action:@selector(dismissViewControllers) forControlEvents:UIControlEventTouchUpInside];
        
        self.closeButton = closeButton;
        
        [self.toolBar addSubview:closeButton];
        
        [self.toolBar sav_pinView:closeButton withOptions:SAVViewPinningOptionsCenterY];
        [self.toolBar sav_pinView:self.closeButton withOptions:SAVViewPinningOptionsToRight withSpace:17];

        [self.view addSubview:self.toolBar];
        
        if ([UIDevice isPad])
        {
            [self setupPad];
        }
        else
        {
            [self setupPhone];
        }
    }
    
    return self;
}

- (void)setupPad
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    backgroundView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.0];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewControllers)];
    [backgroundView addGestureRecognizer:tap];
    
    [self.view addSubview:backgroundView];

    [self.view sav_setHeight:64 forView:self.toolBar isRelative:NO];
    [self.view sav_pinView:self.toolBar withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToRight];
    [self.view sav_setWidth:0.65 forView:self.toolBar isRelative:YES];
    
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToRight];
    [self.view sav_setWidth:0.65 forView:self.viewController.tableView isRelative:YES];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop withSpace:topOffset];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop ofView:self.toolBar withSpace:0];
    
    [self.view sav_pinView:backgroundView withOptions:SAVViewPinningOptionsToLeft ofView:self.viewController.tableView withSpace:0];
    [self.view sav_pinView:backgroundView withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToTop];
    
}

- (void)setupPhone
{
    [self.view sav_setHeight:50 forView:self.toolBar isRelative:NO];
    [self.view sav_pinView:self.toolBar withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight];

    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight|SAVViewPinningOptionsToTop];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop ofView:self.toolBar withSpace:0];
}

- (void)dismissViewControllers
{
    [self willDismissTableViewControllerWithCancelled:YES];
}

- (void)willDismissTableViewControllerWithCancelled:(BOOL)cancelled
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(willDismissViewControllerWithCancelled:)])
    {
        [self.delegate willDismissViewControllerWithCancelled:cancelled];
    }
}

@end
