//
//  SCUSpinnerTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUProgressTableViewCell.h"

@import Extensions;

NSString *const SCUProgressTableViewCellKeyAccessoryType = @"SCUProgressTableViewCellKeyAccessoryType";

@interface SCUProgressTableViewCell ()

@property (nonatomic) UIActivityIndicatorView *spinnerView;

@end

@implementation SCUProgressTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.spinnerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.spinnerView.color = [[SCUColors shared] color04];
        self.spinnerView.hidden = YES;
        [self.contentView addSubview:self.spinnerView];

        NSDictionary *views = @{@"spinner": self.spinnerView};

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:nil
                                                                                  views:views
                                                                                formats:@[@"spinner.centerY = super.centerY",
                                                                                          @"spinner.right = super.right - 12"]]];
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self hideSpinner];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    SCUProgressTableViewCellAccessoryType accessoryType = [info[SCUProgressTableViewCellKeyAccessoryType] unsignedIntegerValue];

    switch (accessoryType)
    {
        case SCUProgressTableViewCellAccessoryTypeNone:
        {
            self.accessoryType = UITableViewCellAccessoryNone;
            [self hideSpinner];
            break;
        }
        case SCUProgressTableViewCellAccessoryTypeSpinner:
        {
            self.accessoryType = UITableViewCellAccessoryNone;
            [self showSpinner];
            break;
        }
        case SCUProgressTableViewCellAccessoryTypeCheckmark:
        {
            self.accessoryType = UITableViewCellAccessoryCheckmark;
            [self hideSpinner];
            break;
        }
    }
}

- (void)showSpinner
{
    self.spinnerView.hidden = NO;
    [self.spinnerView startAnimating];
}

- (void)hideSpinner
{
    [self.spinnerView stopAnimating];
    self.spinnerView.hidden = YES;
}

@end
