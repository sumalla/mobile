//
//  SCURoomDistributionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomDistributionViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCURoomDistributionModel.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUScenesRoomCell.h"
#import "SCUVolumeTableViewCell.h"
#import "SCUSceneVariantCell.h"
#import "SCUPopoverMenu.h"
#import "SCUPassthroughViewController.h"

@import SDK;

@interface SCURoomDistributionViewController () <SCURoomDistributionModelDelegate>

@property SCURoomDistributionModel *model;
@property SCUPopoverMenu *variantMenu;
@property (weak) SCUPassthroughViewController *passthrough;
@property UIActivityIndicatorView *loadingIndicator;

@end

@implementation SCURoomDistributionViewController

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service
{
    self = [super init];
    if (self)
    {
        self.model = [[SCURoomDistributionModel alloc] initWithServiceGroup:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsMultipleSelection = YES;

    if (self.model.serviceGroup)
    {
        self.title = self.model.serviceGroup.alias;
    }
    
    if ([self.navigationController.viewControllers count] == 1)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"x"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(dismissButtonPressed:)];

        // TODO: Handle control button
//        if ([[SCUInterface sharedInstance] hasViewControllerForSerivce:self.model.serviceGroup.wildCardedService])
//        {
//            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Control", nil)
//                                                                                      style:UIBarButtonItemStyleDone
//                                                                                     target:self
//                                                                                     action:@selector(control:)];
//            self.navigationItem.rightBarButtonItem.enabled = NO;
//        }
    }
}

- (void)control:(UIBarButtonItem *)button
{
    //TODO: Present service
 //   [[SCUInterface sharedInstance] presentServicesFirstServiceGroup:self.model.serviceGroup animated:NO];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dismissButtonPressed:(UIBarButtonItem *)button
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([UIDevice isPad])
    {
        self.passthrough = (SCUPassthroughViewController *)self.parentViewController;
    }

    [self applyEdgeInsetsForOrentiation:[UIDevice interfaceOrientation]];
}

- (void)applyEdgeInsetsForOrentiation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        self.passthrough.edgeInsets = UIEdgeInsetsMake(0, 158, 0, 158);
    }
    else
    {
        self.passthrough.edgeInsets = UIEdgeInsetsMake(0, 30, 0, 30);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self applyEdgeInsetsForOrentiation:orientation];
    }];
}

- (void)listenToSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on){
        if (on)
        {
            [wSelf.model powerOnRoom:[wSelf.model roomForIndexPath:indexPath]];
        }
        else
        {
            [wSelf.model powerOffRoom:[wSelf.model roomForIndexPath:indexPath]];
        }
    };
}

#pragma mark - Table View

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    return type == SCURoomDistributionCellTypeToggle ? 60 : self.tableView.rowHeight;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSceneVariantCell class] forCellType:SCURoomDistributionCellTypeVariant];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCURoomDistributionCellTypeToggle];
    [self.tableView sav_registerClass:[SCUVolumeTableViewCell class] forCellType:SCURoomDistributionCellTypeVolume];
    [self.tableView sav_registerClass:[SCUSceneVariantCell class] forCellType:SCURoomDistributionCellTypeAudioOnly];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == SCURoomDistributionCellTypeToggle)
    {
        SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
        [self listenToSwitch:cell.toggleSwitch forIndexPath:indexPath];

        if ([self.model indexPathAllowsAudioOnly:indexPath])
        {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
    }
    else if (type == SCURoomDistributionCellTypeVolume)
    {
        SCUVolumeTableViewCell *cell = (SCUVolumeTableViewCell *)c;
        c.backgroundColor = [[SCUColors shared] color03shade03];
        c.borderType = SCUDefaultTableViewCellBorderTypeNone;
        cell.ignoreFirstAnimation = YES;
    }
    c.borderType = SCUDefaultTableViewCellBorderTypeNone;
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [[SCUColors shared] color03shade03];
    cell.borderType = SCUDefaultTableViewCellBorderTypeNone;

    if (child.row == [self.model numberOfChildrenBelowIndexPath:indexPath] - 1)
    {
        cell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeFull;
    }
    
    if (type == SCURoomDistributionCellTypeAudioOnly)
    {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    SCUDefaultTableViewCell *parentCell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    parentCell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeFull;
    [self reconfigureIndexPath:indexPath];
}

- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    SCUDefaultTableViewCell *parentCell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    parentCell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeNone;
    [self reconfigureIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    SCURoomDistributionCellTypes type = [self.model cellTypeForAbsoluteIndexPath:indexPath];

    NSIndexPath *parent = [self.model parentForAbsoluteIndexPath:indexPath];

    if (type != SCURoomDistributionCellTypeToggle &&
        type != SCURoomDistributionCellTypeAudioOnly &&
        ![parent isEqual:self.model.audioOnlyIndexPath])
    {
        [self.model selectRoomAtIndexPath:nil];
    }

    if (type == SCURoomDistributionCellTypeToggle)
    {
        NSIndexPath *relative = [self.model relativeIndexPathForAbsoluteIndexPath:indexPath];
        [self.model selectRoomAtIndexPath:relative];
    }
    else if (type == SCURoomDistributionCellTypeAudioOnly)
    {
        [self.model enableAudioOnlyForIndexPath:parent];
    }
    else if (type == SCURoomDistributionCellTypeVariant)
    {
        NSArray *services = [self.model servicesForIndexPath:parent];
        NSMutableArray *variantNames = [NSMutableArray array];

        for (SAVService *service in services)
        {
            [variantNames addObject:service.alias];
        }

        self.variantMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:variantNames];
        self.variantMenu.selectedIndex = [services indexOfObject:[self.model selectedServiceForIndexPath:parent]];
        SAVWeakSelf;
        self.variantMenu.callback = ^(NSInteger buttonIndex){
            if (buttonIndex != -1)
            {
                [wSelf.model selectService:services[buttonIndex] forIndexPath:parent];
                [wSelf reloadChildrenBelowIndexPath:parent animated:YES];
            }
        };
        [self.variantMenu showFromView:[self.tableView cellForRowAtIndexPath:indexPath] animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];
    headerLabel.textColor = [[SCUColors shared] color03shade07];
    headerLabel.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];

    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:headerLabel];
    [headerView sav_pinView:headerLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:15];
    [headerView sav_pinView:headerLabel withOptions:SAVViewPinningOptionsToBottom withSpace:8];

    return headerView;
}

#pragma mark - Delegate

- (void)updateActiveState:(BOOL)isActive
{
    self.navigationItem.rightBarButtonItem.enabled = isActive;
}

- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath updateBlock:(dispatch_block_t)update
{
    [self updateNumberOfChildrenBelowIndexPath:indexPath animated:YES updateBlock:update];
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absolutePath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:absolutePath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];

    SCURoomDistributionCellTypes type = [self.model cellTypeForAbsoluteIndexPath:absolutePath];

    if (type == SCURoomDistributionCellTypeToggle)
    {
        SCUToggleSwitchTableViewCell *toggleCell = (SCUToggleSwitchTableViewCell *)cell;
        [self listenToSwitch:toggleCell.toggleSwitch forIndexPath:indexPath];
    }
}

- (void)reloadData
{
    if (self.loadingIndicator)
    {
        [self.loadingIndicator stopAnimating];
        [self.loadingIndicator removeFromSuperview];
        self.loadingIndicator = nil;
    }

    //-------------------------------------------------------------------
    // Animate first tableview reload
    //-------------------------------------------------------------------
    if (![[self.tableView visibleCells] count])
    {
        CATransition *transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.fillMode = kCAFillModeForwards;
        transition.duration = 0.2;

        [[self.tableView layer] addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
    }

    [self.tableView reloadData];
}

- (void)showSpinner
{
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.loadingIndicator.hidesWhenStopped = YES;

    [self.parentViewController.view addSubview:self.loadingIndicator];
    [self.parentViewController.view sav_addCenteredConstraintsForView:self.loadingIndicator];

    [self.loadingIndicator startAnimating];
}

@end
