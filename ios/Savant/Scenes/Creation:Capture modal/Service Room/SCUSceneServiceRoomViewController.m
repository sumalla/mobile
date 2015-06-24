//
//  SCUSceneServiceroomViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneServiceRoomViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneServiceRoomModel.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUScenesRoomCell.h"
#import "SCUSliderWithMinMaxImageCell.h"
#import "SCUSceneVariantCell.h"
#import "SCUPopoverMenu.h"

@import SDK;

@interface SCUSceneServiceRoomViewController () <SCURoomDistributionModelDelegate>

@property SCUSceneServiceRoomModel *model;
@property SCUPopoverMenu *variantMenu;
@property SAVScene *scene;
@property UIActivityIndicatorView *loadingIndicator;

@end

@implementation SCUSceneServiceRoomViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.scene = scene;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    SAVServiceGroup *serviceGroup = nil;
    if (self.creationVC.editingServiceGroup)
    {
        serviceGroup = self.creationVC.editingServiceGroup;
    }
    else
    {
        serviceGroup = [[SAVServiceGroup alloc] init];
        [serviceGroup addService:self.creationVC.editingService];
    }

    self.model = [[SCUSceneServiceRoomModel alloc] initWithScene:self.scene andServiceGroup:serviceGroup];
    self.model.delegate = self;

    self.tableView.allowsMultipleSelection = YES;

    if (self.model.serviceGroup)
    {
        self.title = self.model.serviceGroup.alias;
    }

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:self.creationVC.add ? NSLocalizedString(@"Add", nil) : NSLocalizedString(@"Done", nil)
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(doneEditing)];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17.0f],
                                 NSForegroundColorAttributeName: [[SCUColors shared] color01]};
    
    [rightButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:rightButton];
    
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    if (self.creationVC.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = [self.model hasSelectedRows];
    }
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    if (type == SCUSceneServiceRoomCellTypeToggle)
    {
        return 60;
    }
    else
    {
        return self.tableView.rowHeight;
    }
}

- (void)doneEditing
{
    [self.model doneEditing];

    [self popToRootViewController];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSceneVariantCell class] forCellType:SCUSceneServiceRoomCellTypeVariant];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUSceneServiceRoomCellTypeToggle];
    [self.tableView sav_registerClass:[SCUSliderWithMinMaxImageCell class] forCellType:SCUSceneServiceRoomCellTypeSlider];
    [self.tableView sav_registerClass:[SCUSceneVariantCell class] forCellType:SCUSceneServiceRoomCellTypeAudioOnly];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)c;
    [self listenToSwitch:cell.toggleSwitch forIndexPath:indexPath];

    if ([self.model indexPathAllowsAudioOnly:indexPath])
    {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    if (type == SCUSceneServiceRoomCellTypeSlider)
    {
        SCUSliderWithMinMaxImageCell *cell = (SCUSliderWithMinMaxImageCell *)c;
        [self.model listenToSlider:cell.slider withParent:indexPath];
    }
    else if (type == SCUSceneServiceRoomCellTypeAudioOnly)
    {
        c.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    c.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
    c.backgroundColor = [[SCUColors shared] color03shade03];

    if (child.row == [self.model numberOfChildrenBelowIndexPath:indexPath] - 1)
    {
        c.bottomLineType = SCUDefaultTableViewCellBottomLineTypeFull;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    SCUSceneServiceRoomCellTypes type = [self.model cellTypeForAbsoluteIndexPath:indexPath];


    NSIndexPath *parent = [self.model parentForAbsoluteIndexPath:indexPath];

    if (type != SCUSceneServiceRoomCellTypeToggle &&
        type != SCUSceneServiceRoomCellTypeAudioOnly &&
        ![parent isEqual:self.model.audioOnlyIndexPath])
    {
        [self.model selectRoomAtIndexPath:nil];
    }

    if (type == SCUSceneServiceRoomCellTypeToggle)
    {
        NSIndexPath *relative = [self.model relativeIndexPathForAbsoluteIndexPath:indexPath];
        if ([self.model.expandedIndexPaths containsObject:relative])
        {
            [self.model selectRoomAtIndexPath:relative];
        }
    }
    else if (type == SCUSceneServiceRoomCellTypeAudioOnly)
    {
        [self.model enableAudioOnlyForIndexPath:parent];
    }
    else if (type == SCUSceneServiceRoomCellTypeVariant)
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

- (void)listenToSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwitch.sav_didChangeHandler = ^(BOOL on){
        if (on)
        {
            [wSelf expandIndex:indexPath animated:YES];
            [wSelf.model addRoom:[wSelf.model roomForIndexPath:indexPath]];
        }
        else
        {
            [wSelf.model removeRoom:[wSelf.model roomForIndexPath:indexPath]];
            [wSelf collapseIndex:indexPath animated:YES];
        }

        SCUToggleSwitchTableViewCell *cell = (SCUToggleSwitchTableViewCell *)[wSelf.tableView cellForRowAtIndexPath:[wSelf.model absoluteIndexPathForRelativeIndexPath:indexPath]];

        [cell configureWithInfo:[wSelf.model modelObjectForIndexPath:indexPath]];

        if (wSelf.creationVC.add)
        {
            wSelf.navigationItem.rightBarButtonItem.enabled = [wSelf.model hasSelectedRows];
        }
    };
}

#pragma mark - Delegate

- (void)updateActiveState:(BOOL)isActive
{
    if (self.creationVC.add)
    {
        self.navigationItem.rightBarButtonItem.enabled = isActive;
    }
}

- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath updateBlock:(dispatch_block_t)update
{
    [self updateNumberOfChildrenBelowIndexPath:indexPath animated:YES updateBlock:update];
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *aboslutePath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:aboslutePath];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
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
