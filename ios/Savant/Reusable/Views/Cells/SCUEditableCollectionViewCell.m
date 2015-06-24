//
//  SCUEditableCollectionViewCell.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEditableCollectionViewCell.h"

@import Extensions;

static NSString *defaultDeleteButtonImageName = @"defaultDeleteButton.png";
NSInteger const SCUButtonCollectionViewCellPlaceHolderTag = 74870001;

static NSInteger defaultDeleteButtonSize = 30;

@interface SCUEditableCollectionViewCell ()

@property (strong, nonatomic) UIButton *deleteButton;

- (void)deleteButtonPushed:(id)sender;

@end

@implementation SCUEditableCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{    
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

- (void)addDeleteButton
{
    if (!self.deleteButton)
    {
        if (self.deleteButtonSize.width < 1)
        {
            self.deleteButtonSize = CGSizeMake(defaultDeleteButtonSize, defaultDeleteButtonSize);
        }
        if (!self.deleteButtonImageName)
        {
            self.deleteButtonImageName = defaultDeleteButtonImageName;
        }
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.deleteButton setFrame:CGRectMake(self.frame.size.width - (self.deleteButtonSize.width), // * 3 / 4 ),
                                               0, //- (self.deleteButtonSize.height / 4),
                                               self.deleteButtonSize.width,
                                               self.deleteButtonSize.height)];
        [self.deleteButton addTarget:self action:@selector(deleteButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.deleteButton setImage:[UIImage imageNamed:self.deleteButtonImageName] forState:UIControlStateNormal];
        self.deleteButton.clipsToBounds = NO;
        self.clipsToBounds = NO;
        [self.deleteButton setAlpha:0];
        [self addSubview:self.deleteButton];
        [self.deleteButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin];
    }
}

- (void)setCellButton:(SCUButton *)cellButton
{
    [super setCellButton:cellButton];
    if (self.deleteButton.alpha > 0)
    {
        self.cellButton.userInteractionEnabled = NO;
    }
}

- (void)showDeleteButton:(BOOL)show
{
    if (show)
    {
        if (!self.deleteButton)
        {
            [self addDeleteButton];
            [self.deleteButton setEnabled:YES];
        }
        self.cellButton.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [self.deleteButton setAlpha:1];
                         }
                         completion:^(BOOL finished) {
                             self.deleteButton.hidden = NO;
                         }];
    }
    else
    {
        self.cellButton.userInteractionEnabled = YES;
        if (self.deleteButton)
        {
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 [self.deleteButton setAlpha:0];
                             }
             completion:^(BOOL finished) {
                 self.deleteButton.hidden = YES;
             }];
        }
    }
}

- (void)deleteButtonPushed:(id)sender
{
    [self.delegate removeCell:self];
}

- (void)setSelected:(BOOL)selected
{
    
}

- (void)setHighlighted:(BOOL)highlighted
{
    
}

- (void)configureWithInfo:(NSDictionary *)info andPlaceHolderView:(UIView *)phView
{
    if (phView)
    {
        [phView setFrame:CGRectMake(0, 0, self.cellButton.frame.size.width, self.cellButton.frame.size.height)];
        [self addSubview:phView];
        self.hidden = NO;
    }
    else
    {
        [super configureWithInfo:info];
        for (UIView *aView in self.subviews)
        {
            if (aView.tag == SCUButtonCollectionViewCellPlaceHolderTag)
            {
                [aView removeFromSuperview];
            }
        }
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.cellButton.userInteractionEnabled = NO;
}

@end
