//
//  SCUSceneFadeTimeViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneFadeTimeViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneFadeTimeDataSource.h"
#import "SCUSecondsPickerCell.h"
#import "SCUSecondsPickerView.h"
#import "SCUButton.h"

@interface SCUSceneFadeTimeViewController ()

@property SCUSceneFadeTimeDataSource *model;
@property SAVScene *editingScene;

@end

@implementation SCUSceneFadeTimeViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        self.editingScene = scene;
        self.model = [[SCUSceneFadeTimeDataSource alloc] initWithScene:[scene copy] andService:service];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Schedule", nil);
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(popViewControllerCanceled)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneEditing)];
    self.navigationItem.rightBarButtonItem.tintColor = [[SCUColors shared] color01];

    SCUButton *removeSchedule = [[SCUButton alloc] initWithTitle:[NSLocalizedString(@"Remove Fade Time", nil) uppercaseString]];
    removeSchedule.borderWidth = 1;
    removeSchedule.cornerRadius = 4;
    removeSchedule.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:14];
    removeSchedule.color = [[SCUColors shared] color01];
    removeSchedule.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.7];
    removeSchedule.borderColor = [[SCUColors shared] color03shade02];
    removeSchedule.backgroundColor = nil;
    removeSchedule.selectedBackgroundColor = nil;
    removeSchedule.target = self;
    removeSchedule.releaseAction = @selector(removeFadeTime);

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
    [footerView addSubview:removeSchedule];
    [footerView sav_pinView:removeSchedule withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsCenterX];
    [footerView sav_setWidth:.9 forView:removeSchedule isRelative:YES];

    self.tableView.tableFooterView = footerView;
    self.tableView.rowHeight = 60;
}

- (void)removeFadeTime
{
    self.editingScene.fadeTime = 0;

    [self popViewController];
}

- (void)doneEditing
{
    [self.editingScene applySettings:[self.model.scene dictionaryRepresentation]];

    [self popViewController];
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUSecondsPickerCell class] forCellType:1];
}

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    switch (type)
    {
        case 1:
            return 162;
        default:
            return self.tableView.rowHeight;
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == 1)
    {
        SCUSecondsPickerCell *cell = (SCUSecondsPickerCell *)c;

        [cell.pickerView setValue:self.model.scene.fadeTime animated:NO];

        SAVWeakSelf;
        cell.pickerView.handler = ^(CGFloat seconds){
            wSelf.model.scene.fadeTime = seconds;
            [wSelf.model prepareData];
            [wSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        };
    }
}

@end
