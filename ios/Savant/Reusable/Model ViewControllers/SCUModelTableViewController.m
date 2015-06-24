//
//  SCUModelTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUSwipeCell.h"

@interface SCUModelTableViewController () <SCUSwipeCellDelegate>

@property SAVKVORegistration *contentSize;

@end

@implementation SCUModelTableViewController

- (instancetype)init
{
    self = [super initWithStyle:[self preferredTableViewStyle]];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delaysContentTouches = NO;

    //-------------------------------------------------------------------
    // This is the worst.
    //-------------------------------------------------------------------
    for (UIScrollView *view in [self.tableView sav_allSubviews])
    {
        if ([NSStringFromClass([view class]) isEqualToString:@"UITableViewWrapperView"])
        {
            if ([view isKindOfClass:[UIScrollView class]])
            {
                view.delaysContentTouches = NO;
            }
            
            break;
        }
    }

    // This is a hack to fix iOS 8 not respecting appearance
    UIColor *backgroundColor = [[UITableView appearance] backgroundColor];
    if (backgroundColor)
    {
        self.tableView.backgroundColor = backgroundColor;
    }

    [self.tableView sav_registerClass:[SCUDefaultTableViewCell class] forCellType:0];

    self.tableView.rowHeight = [self defaultRowHeight];

    if ([self respondsToSelector:@selector(registerCells)])
    {
        [self registerCells];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([[self tableViewModel] respondsToSelector:@selector(loadDataIfNecessary)])
    {
        [[self tableViewModel] loadDataIfNecessary];
    }
    
    [super viewWillAppear:animated];

    if ([[self tableViewModel] respondsToSelector:@selector(viewWillAppear)])
    {
        [[self tableViewModel] viewWillAppear];
    }

    SAVWeakSelf;
    self.contentSize = [[SAVKVORegistration alloc] initWithObserver:self
                                                             target:self.tableView
                                                         selector:@selector(contentSize)
                                                          handler:^(NSDictionary *changeDictionary) {
                                                              wSelf.preferredContentSize = wSelf.tableView.contentSize;
                                                          }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[self tableViewModel] respondsToSelector:@selector(viewDidAppear)])
    {
        [[self tableViewModel] viewDidAppear];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([[self tableViewModel] respondsToSelector:@selector(viewWillDisappear)])
    {
        [[self tableViewModel] viewWillDisappear];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if ([[self tableViewModel] respondsToSelector:@selector(viewDidDisappear)])
    {
        [[self tableViewModel] viewDidDisappear];
    }
}

- (void)reconfigureCells
{
    for (NSInteger i = 0; i < [[self tableViewModel] numberOfItemsInSection:0]; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        id cell = [self.tableView cellForRowAtIndexPath:indexPath];
        NSUInteger type = [[self tableViewModel] cellTypeForIndexPath:indexPath];

        if ([self respondsToSelector:@selector(configureCell:withType:indexPath:)])
        {
            [self configureCell:cell withType:type indexPath:indexPath];
        }

        if ([[self tableViewModel] respondsToSelector:@selector(configureCell:withType:indexPath:)])
        {
            [[self tableViewModel] configureCell:cell withType:type indexPath:indexPath];
        }
    }
}

#pragma mark - Methods to subclass

- (UITableViewStyle)preferredTableViewStyle
{
    return UITableViewStyleGrouped;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (CGFloat)defaultRowHeight
{
    return 44;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self tableViewModel] numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self tableViewModel] numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger type = [[self tableViewModel] cellTypeForIndexPath:indexPath];

    NSString *identifier = [NSString stringWithFormat:@"%lu", (unsigned long)type];

    SCUDefaultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

    UIView *selectedBackgroundView = [[[cell class] appearance] selectedBackgroundView];

    if (selectedBackgroundView && cell.selectedBackgroundView == selectedBackgroundView)
    {
        //-------------------------------------------------------------------
        // This is the worst.
        //-------------------------------------------------------------------
        UIView *selectedBackgroundViewCopy = [UIView sav_viewWithColor:selectedBackgroundView.backgroundColor];
        cell.selectedBackgroundView = selectedBackgroundViewCopy;
    }

    [cell configureWithInfo:[[self tableViewModel] modelObjectForIndexPath:indexPath]];

    if ([self respondsToSelector:@selector(configureCell:withType:indexPath:)])
    {
        [self configureCell:cell withType:type indexPath:indexPath];
    }

    if ([[self tableViewModel] respondsToSelector:@selector(configureCell:withType:indexPath:)])
    {
        [[self tableViewModel] configureCell:cell withType:type indexPath:indexPath];
    }

    cell.numberOfRowsInSection = [[self tableViewModel] numberOfItemsInSection:indexPath.section];
    cell.indexPath = indexPath;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;

    if ([[self tableViewModel] respondsToSelector:@selector(titleForHeaderInSection:)])
    {
        title = [[self tableViewModel] titleForHeaderInSection:section];
    }

    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = nil;

    if ([[self tableViewModel] respondsToSelector:@selector(titleForFooterInSection:)])
    {
        title = [[self tableViewModel] titleForFooterInSection:section];
    }

    return title;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *titles = nil;

    if ([[self tableViewModel] respondsToSelector:@selector(sectionIndexTitles)])
    {
        titles = [[self tableViewModel] sectionIndexTitles];
    }

    return titles;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([self.tableView respondsToSelector:@selector(headerTypeForSection:)])
    {
        NSUInteger type = [[self tableViewModel] headerTypeForSection:section];

        if ([self respondsToSelector:@selector(configureHeader:withType:section:)])
        {
            [self configureHeader:view withType:type section:section];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger section = index;

    if ([[self tableViewModel] respondsToSelector:@selector(sectionForSectionIndexTitleAtIndex:)])
    {
        section = [[self tableViewModel] sectionForSectionIndexTitleAtIndex:index];
    }

    return section;
}

#pragma mark - SCUSwipeCellDelegate methods

- (BOOL)tableView:(UITableView *)tableView shouldAllowSwipeForIndexPath:(NSIndexPath *)indexPath
{
    BOOL allowSwiping = YES;

    if ([[self tableViewModel] respondsToSelector:@selector(shouldAllowSwipingForIndexPath:)])
    {
        allowSwiping = [[self tableViewModel] shouldAllowSwipingForIndexPath:indexPath];
    }

    return allowSwiping;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if ([[self tableViewModel] respondsToSelector:@selector(commitDeleteForIndexPath:)])
        {
            [[self tableViewModel] commitDeleteForIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView buttonWasTappedAtIndex:(NSUInteger)buttonIndex inCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self tableViewModel] respondsToSelector:@selector(buttonWasTappedAtIndex:atIndexPath:)])
    {
        [[self tableViewModel] buttonWasTappedAtIndex:buttonIndex atIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;

    if ([[self tableViewModel] respondsToSelector:@selector(canDeleteIndexPath:)])
    {
        canDelete = [[self tableViewModel] canDeleteIndexPath:indexPath];
    }

    return canDelete;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableViewModel respondsToSelector:@selector(shouldDeselectRowAtIndexPath:)])
    {
        if ([self.tableViewModel shouldDeselectRowAtIndexPath:indexPath])
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    if ([self.tableViewModel respondsToSelector:@selector(selectItemAtIndexPath:)])
    {
        [[self tableViewModel] selectItemAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tableViewModel respondsToSelector:@selector(accessoryButtonTappedAtIndexPath:)])
    {
        [self.tableViewModel accessoryButtonTappedAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self respondsToSelector:@selector(heightForCellWithType:)])
    {
        return [self heightForCellWithType:[[self tableViewModel] cellTypeForIndexPath:indexPath]];
    }
    else
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];;
    }
}

@end
