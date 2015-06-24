//
//  SCUOverflowTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 2/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowTableViewController.h"
#import "SCUOverflowAnimationController.h"
#import "SCUOverflowAddViewController.h"
#import "SCUOverflowAddButtonTableViewController.h"
#import "SCUOverflowTableViewModel.h"
#import "SCUOverflowCell.h"

@interface SCUOverflowTableViewController () <SCUOverflowViewDelegate, SCUOverflowPresentationDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic) SCUOverflowTableViewModel *model;
@property (nonatomic) UITableViewCell *addButtonCell;
@property (nonatomic) SAVService *service;
@property (nonatomic) UILongPressGestureRecognizer *gesture;

@end

@implementation SCUOverflowTableViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self)
    {
        self.model = [[SCUOverflowTableViewModel alloc] initWithService:service];
        self.model.delegate = self;
        
        self.service = service;
        
        self.tableView.rowHeight = [UIDevice isPhone] ? 60 : 70;
        [self updateContentInsetAnimated:NO];
        
        self.gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.tableView addGestureRecognizer:self.gesture];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;    
    [self updateContentInsetAnimated:NO];
}

- (void)updateContentInset
{
    // SRS TODO: Fix this hack
    CGFloat top = [UIDevice isPad] ? 44 : 64;
    if ((CGRectGetHeight(self.tableView.frame) - [self currentContentHeight]) > top)
    {
        top = (CGRectGetHeight(self.tableView.frame) - [self currentContentHeight]);
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0);
}

- (void)updateContentInsetAnimated:(BOOL)animated
{
    if (animated)
    {
        SAVWeakSelf;
        [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:15 options:0 animations:^{
            [wSelf updateContentInset];
        } completion:nil];
    }
    else
    {
        [self updateContentInset];
    }
}

- (CGFloat)currentContentHeight
{
    return ([self.tableView numberOfRowsInSection:0] * self.tableView.rowHeight);
}

- (void)doneTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUOverflowCell class] forCellType:0];
}

- (void)reloadData
{
    [self.tableView reloadData];
    [self updateContentInsetAnimated:NO];
}

- (void)setReorderEnabled:(BOOL)reorderEnabled
{
    _reorderEnabled = reorderEnabled;
    self.gesture.enabled = _reorderEnabled;
}

- (void)presentAddButtonViewController
{
    SCUOverflowAddButtonTableViewController *addTableViewController = [[SCUOverflowAddButtonTableViewController alloc] initWithService:self.service andModel:self.model];
    SCUOverflowAddViewController *addButtonViewController = [[SCUOverflowAddViewController alloc] initWithService:self.service
                                                                                               andTableViewController:addTableViewController
                                                                                                    forViewController:self.parentViewController];
    
    addButtonViewController.delegate = self;
    
    self.model.adding = YES;
    
    if ([UIDevice isPad])
    {
        addButtonViewController.modalPresentationStyle = UIModalPresentationCustom;
        addButtonViewController.transitioningDelegate = self;
        [self presentViewController:addButtonViewController animated:YES completion:nil];
        return;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addButtonViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    NSIndexPath *addButton = [self.model indexPathForAddButton];

    CGRect addButtonRect = [self.tableView rectForRowAtIndexPath:addButton];

    BOOL isBeyondBounds = NO;

    if (location.y + (self.tableView.rowHeight / 2) > CGRectGetMinY(addButtonRect))
    {
        isBeyondBounds = YES;
    }
    
    static UIView *snapshot = nil;
    static NSIndexPath *sourceIndexPath = nil;
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            if (indexPath && !isBeyondBounds)
            {
                sourceIndexPath = indexPath;
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                snapshot = [self customSnapshotFromView:cell];
                
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                [self.tableView addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.0, 1.0);
                    snapshot.alpha = 0.98;
                    cell.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    cell.hidden = YES;
                    
                }];
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            if (indexPath && ![indexPath isEqual:sourceIndexPath] && !isBeyondBounds)
            {
                [self.model moveItemAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                sourceIndexPath = indexPath;
            }
            break;
        }
            
        default:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            cell.hidden = NO;
            cell.alpha = 0.0;
            
            [UIView animateWithDuration:0.25 animations:^{
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 1.0;
            } completion:^(BOOL finished) {
                cell.alpha = 1.0;
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
            }];
            
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL addButton = [indexPath isEqual:[self.model indexPathForAddButton]];
    
    [self.model selectItemAtIndexPath:indexPath];
    
    if (!addButton)
    {
        if ([self.delegate respondsToSelector:@selector(willDismissTableViewControllerWithCancelled:)])
        {
            [self.delegate willDismissTableViewControllerWithCancelled:NO];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (self.model.isAddButtonEnabled)
    {
        [self presentAddButtonViewController];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    if (![indexPath isEqual:[self.model indexPathForAddButton]] && !self.model.isAdding)
    {
        style = UITableViewCellEditingStyleDelete;
    }
    
    return style;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ![indexPath isEqual:[self.model indexPathForAddButton]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.model deleteItemAtIndexPath:indexPath];
        [self removeRowAtIndexPath:indexPath animated:YES];
        
        [self.tableView reloadRowsAtIndexPaths:@[[self.model indexPathForAddButton]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == (NSInteger)self.model.dataSource.count)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
    } completion:^ (BOOL finished) {
        [self updateContentInsetAnimated:YES];
    }];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateContentInsetAnimated:YES];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:[self.model indexPathForAddButton]])
    {
        SCUOverflowCell *cell = (SCUOverflowCell *)c;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.disabled = !self.model.isAddButtonEnabled;
    }
    else
    {
        c.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)willDismissViewControllerWithCancelled:(BOOL)cancel
{
    if ([self.delegate respondsToSelector:@selector(willDismissTableViewControllerWithCancelled:)])
    {
        [self.delegate willDismissTableViewControllerWithCancelled:NO];
    }
}

#pragma mark - UIViewController animation

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    return [[SCUOverflowAnimationController alloc] init];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[SCUOverflowAnimationController alloc] initWithReverse:YES];
}

#pragma mark -- Service and Table Models

- (SCUServiceViewModel *)serviceViewModel
{
    SCUOverflowTableViewModel *model = (SCUOverflowTableViewModel *)self.tableViewModel;
    return model.serviceModel;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

#pragma mark - Helper methods

- (UIView *)customSnapshotFromView:(UIView *)inputView
{
    UIImage *image = [inputView sav_rasterizedImage];
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.opacity = 0.75;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}

@end