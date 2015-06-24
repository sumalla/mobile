//
//  SCUMediaTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaTableViewController.h"
#import "SCUMediaDataModel.h"
#import "SCUMediaTableViewCell.h"
#import "SCUMediaHeaderView.h"
#import "SCUMediaMessageTableViewCell.h"

@import Extensions;

@interface SCUMediaTableViewController () <SCUMediaDataModelDelegate>

@property (nonatomic) SCUMediaDataModel *model;

@end

@implementation SCUMediaTableViewController

- (instancetype)initWithModel:(SCUMediaDataModel *)mediaModel
{
    self = [super init];

    if (self)
    {
        self.model = mediaModel;
        self.model.delegate = self;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.sectionIndexColor = [[SCUColors shared] color04];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [[UITableView appearanceWhenContainedIn:[self class], nil] setSeparatorColor:[UIColor clearColor]];
    
    [self.tableView registerClass:[SCUMediaHeaderView class] forHeaderFooterViewReuseIdentifier:@"0"];
}

#pragma mark - SCUMediaDataModelDelegate methods

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)addCheckmarkAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.model.scene)
    {
        [self.tableView reloadData];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
    }

}

- (void)setArtwork:(UIImage *)artwork forIndexPath:(NSIndexPath *)indexPath
{
    SCUMediaTableViewCell *cell = (SCUMediaTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setArtworkImage:artwork];
}

#pragma mark - Methods to subclass

- (UITableViewStyle)preferredTableViewStyle
{
    return UITableViewStylePlain;
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUMediaTableViewCell class] forCellType:0];
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    c.backgroundColor = [[SCUColors shared] color03shade01];
    if ([self.model hasArtworkForIndexPath:indexPath])
    {
        SCUMediaTableViewCell *mediaCell = (SCUMediaTableViewCell *)c;
        [mediaCell setArtworkImage:[self.model artworkForIndexPath:indexPath]];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"0"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [tableView sav_heightForText:[self.model modelObjectForIndexPath:indexPath][SCUMediaModelKeyTitle] font:[UIFont fontWithName:@"Gotham-Book" size:17]];

    if ([[self.model modelObjectForIndexPath:indexPath][SCUMediaModelKeyIsTextfield] boolValue])
    {
        height = [tableView sav_heightForText:[self.model modelObjectForIndexPath:indexPath][SCUMediaModelKeyTitle] font:[UIFont systemFontOfSize:18]];
    }
    
    if ([self.model modelObjectForIndexPath:indexPath][SCUMediaModelKeyArtworkURL])
    {
        height = ([UIDevice isPad]) ? 120 : 80;
    }

    return height;
}

@end
