//
//  SCUDiscreteShadesTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURelativeShadesTableViewCell.h"

@interface SCURelativeShadesTableViewCell ()

@property (nonatomic) SCUButton *closeButton;
@property (nonatomic) SCUButton *stopButton;
@property (nonatomic) SCUButton *openButton;

@end

@implementation SCURelativeShadesTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.closeButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Close", nil)];
        self.stopButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Stop", nil)];
        self.openButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Open", nil)];

        NSArray *buttons = @[self.closeButton, self.stopButton, self.openButton];

        for (SCUButton *button in buttons)
        {
            button.borderWidth = [UIScreen screenPixel];
            button.borderColor = [[SCUColors shared] color03shade04];
            button.backgroundColor = [[SCUColors shared] color03shade03];
        }

        SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
        config.distributeEvenly = YES;
        config.interSpace = 4;

        UIView *buttonView = [UIView sav_viewWithEvenlyDistributedViews:buttons withConfiguration:config];
        [self.contentView addSubview:buttonView];
        [self.contentView sav_addFlushConstraintsForView:buttonView withPadding:4];

        self.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
    [super configureWithInfo:info];
    self.textLabel.text = nil;
}

@end
