//
//  SCUTVOverlayAddButtonTableViewController.m
//  SavantController
//
//  Created by Stephen Silber on 2/3/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowAddButtonTableViewController.h"
#import "SCUOverflowTableViewModel.h"
#import "SCUOverflowCell.h"

@interface SCUOverflowAddButtonTableViewController () <SCUOverflowAddViewDelegate>

@property (nonatomic) SCUOverflowTableViewModel *model;

@end

@implementation SCUOverflowAddButtonTableViewController

- (instancetype)initWithService:(SAVService *)service andModel:(SCUOverflowTableViewModel *)model
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.model = model;
        self.model.addDelegate = self;
        [self setReorderEnabled:NO];
        
        [self.model loadButtons];
        
        self.title = NSLocalizedString(@"Menu", nil);
        
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(doneTapped:)];
        done.tintColor = [[SCUColors shared] color01];
        
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = done;
    }
    
    return self;
}

- (void)updateContentInsetAnimated:(BOOL)animated
{
    ;
}

- (void)setAdding:(BOOL)adding
{
    self.model.adding = adding;
}

- (void)doneTapped:(id)sender
{
    [self popViewController];
}

- (id<SCUDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [[SCUColors shared] color03shade01];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.model selectItemAtIndexPath:indexPath];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUOverflowCell class] forCellType:0];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)popViewController
{
    self.model.adding = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
