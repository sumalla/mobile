//
//  SCUSchedulingCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingCell.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUSchedulingEditingViewController.h"

@interface SCUSchedulingCell () <SCUSchedulingEditingViewControllerDelegate>

@property (weak) UIView *editingView;

@end

@implementation SCUSchedulingCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:24];

        self.backgroundColor = [UIColor sav_colorWithRGBValue:0x1e1e1e alpha:.49];

        UIView *editingView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:editingView];
        self.editingView = editingView;
        self.editingView.hidden = YES;
        self.contentView.clipsToBounds = YES;

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                  views:@{@"textLabel": self.textLabel,
                                                                                          @"editingView": editingView}
                                                                                formats:@[@"|-(15)-[textLabel]-(15)-|",
                                                                                          @"|[editingView]|",
                                                                                          @"V:|[textLabel(53)][editingView]|"]]];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    self.editingViewController = [self.delegate editingViewControllerForCell:self];

    [self applySelectedSettings];
}

- (void)setEditingViewController:(SCUSchedulingEditingViewController *)editingViewController
{
    if (editingViewController != _editingViewController)
    {
        if (editingViewController)
        {
            [self.editingView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

            UIView *divider = [[UIView alloc] initWithFrame:CGRectZero];
            divider.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.2];
            [self.editingView addSubview:divider];

            [self.editingView sav_pinView:divider withOptions:SAVViewPinningOptionsCenterX|SAVViewPinningOptionsToTop];
            [self.editingView sav_setHeight:[UIScreen screenPixel] forView:divider isRelative:NO];
            [self.editingView sav_setWidth:1 forView:divider isRelative:YES];

            editingViewController.delegate = self;
            [self.editingView addSubview:editingViewController.view];
            [self.editingView sav_addFlushConstraintsForView:editingViewController.view];
            if ([UIDevice isPad])
            {
                [self.editingView sav_pinView:editingViewController.view withOptions:SAVViewPinningOptionsVertically];
            }
            else
            {
                [self.editingView sav_setHeight:[editingViewController estimatedHeight] forView:editingViewController.view isRelative:NO];
            }

            self.editingView.hidden = NO;
        }
        else
        {
            self.editingView.hidden = YES;
        }

        _editingViewController = editingViewController;
    }
}

- (void)applySelectedSettings
{
    self.editingView.userInteractionEnabled = self.selected;
    self.contentView.alpha = self.selected ? 1 : .4;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    [self applySelectedSettings];
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.editingViewController = nil;
}

#pragma mark - Editing View Controller Delegate

- (void)reloadData
{
    [self.delegate reloadDataForCell:self];
}

@end
