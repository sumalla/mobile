//
//  SCUOverflowAddViewController.m
//  SavantController
//
//  Created by Stephen Silber on 2/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowAddViewController.h"
#import "SCUButton.h"
#import "SCUToolbar.h"
#import "SCUOverflowViewController.h"
#import "SCUOverflowViewControllerPrivate.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowTableViewController.h"
#import "SCUOverflowTableViewModel.h"

@interface SCUOverflowAddViewController () <SCUOverlayDelegate>

@property (nonatomic) UIView *toolBar;
@property (nonatomic) SCUOverflowTableViewController *viewController;

@end

@implementation SCUOverflowAddViewController

static CGFloat topOffset = 65;

- (instancetype)initWithService:(SAVService *)service andTableViewController:(SCUOverflowTableViewController *)tableView forViewController:(UIViewController *)viewController
{
    self = [super initWithService:service andTableViewController:tableView];
    
    if (self)
    {
        self.viewController = tableView;
        self.viewController.delegate = self;
        
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonPressed:)];
        done.tintColor = [[SCUColors shared] color01];
        
        self.navigationItem.rightBarButtonItem = done;
        
        [self.closeButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
            [self disableAdding];
            SCUOverflowViewController *controller = (SCUOverflowViewController *)viewController;
            
            [self dismissViewControllerAnimated:NO completion:nil];
            [controller willDismissTableViewControllerWithCancelled:YES];
            [self willDismissTableViewControllerWithCancelled:YES];
        }];
    }
    
    return self;
}

- (void)setupPad
{
    UIView *navigationBar = [[UIView alloc] initWithFrame:CGRectZero];
    navigationBar.backgroundColor = [[SCUColors shared] color03shade01];
    
    UILabel *navigationTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    navigationTitle.text = NSLocalizedString(@"Add Button", nil);
    navigationTitle.textColor = [[SCUColors shared] color04];
    navigationTitle.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    
    SCUButton *doneButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleAccent title:NSLocalizedString(@"Done", nil)];
    doneButton.color = [[SCUColors shared] color01];
    doneButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    [doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [navigationBar addSubview:navigationTitle];
    [navigationBar addSubview:doneButton];
    
    [navigationBar sav_addCenteredConstraintsForView:navigationTitle];
    [navigationBar sav_pinView:doneButton withOptions:SAVViewPinningOptionsCenterY];
    [navigationBar sav_pinView:doneButton withOptions:SAVViewPinningOptionsToRight withSpace:5];
    
    [self.view addSubview:navigationBar];
    
    [self.view sav_pinView:navigationBar withOptions:SAVViewPinningOptionsToRight];
    [self.view sav_pinView:navigationBar withOptions:SAVViewPinningOptionsToTop withSpace:topOffset];
    [self.view sav_setWidth:0.65 forView:navigationBar isRelative:YES];
    [self.view sav_setHeight:50 forView:navigationBar isRelative:NO];
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    backgroundView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.0];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(willDismissViewController)];
    [backgroundView addGestureRecognizer:tap];
    
    [self.view addSubview:backgroundView];
    
    [self.view sav_setHeight:64 forView:self.toolBar isRelative:NO];
    [self.view sav_pinView:self.toolBar withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToRight];
    [self.view sav_setWidth:0.65 forView:self.toolBar isRelative:YES];
    
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToRight];
    [self.view sav_setWidth:0.65 forView:self.viewController.tableView isRelative:YES];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToBottom ofView:navigationBar withSpace:0];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop ofView:self.toolBar withSpace:0];
    
    [self.view sav_pinView:backgroundView withOptions:SAVViewPinningOptionsToLeft ofView:self.viewController.tableView withSpace:0];
    [self.view sav_pinView:backgroundView withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToLeft];
    [self.view sav_pinView:backgroundView withOptions:SAVViewPinningOptionsToTop withSpace:0];
}

- (void)setupPhone
{
    [self.view sav_setHeight:44 forView:self.toolBar isRelative:NO];
    [self.view sav_pinView:self.toolBar withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight];
    
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop withSpace:64];
    [self.view sav_pinView:self.viewController.tableView withOptions:SAVViewPinningOptionsToTop ofView:self.toolBar withSpace:0];
}

- (void)disableAdding
{
    SCUOverflowTableViewController *tableView = self.viewController;
    
    SCUOverflowTableViewModel *model = (SCUOverflowTableViewModel *)tableView.tableViewModel;
    model.adding = NO;
}

- (void)doneButtonPressed:(id)sender
{
    [self disableAdding];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)willDismissViewController
{
    [self willDismissTableViewControllerWithCancelled:YES];
}

- (void)willDismissTableViewControllerWithCancelled:(BOOL)cancelled
{
    [self disableAdding];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(willDismissViewControllerWithCancelled:)])
    {
        [self.delegate willDismissViewControllerWithCancelled:cancelled];
    }
}

@end
