//
//  SCUFanButtonsTableViewCell.m
//  SavantController
//
//  Created by Stephen Silber on 2/25/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUFanButtonsTableViewCell.h"
#import "SCUButton.h"

@interface SCUFanButtonsTableViewCell ()

@property (nonatomic) SCUButton *offButton;
@property (nonatomic) SCUButton *lowButton;
@property (nonatomic) SCUButton *mediumButton;
@property (nonatomic) SCUButton *highButton;
@property (nonatomic) NSArray *buttons;

@end

NSString *const SCUFanButtonsTableViewCellKeySelectedButton = @"SCUFanButtonsTableViewCellKeySelectedButton";

@implementation SCUFanButtonsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.offButton    = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"OFF", nil)];
        self.lowButton    = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"LOW", nil)];
        self.mediumButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"MED", nil)];
        self.highButton   = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"HIGH", nil)];
        
        self.buttons = @[self.offButton, self.lowButton, self.mediumButton, self.highButton];
        
        for (SCUButton *button in self.buttons)
        {
            button.backgroundColor = [[SCUColors shared] color03shade03];
            button.borderColor = [[SCUColors shared] color03shade04];
            button.borderWidth = [UIScreen screenPixel];
            button.selectedBackgroundColor = [[SCUColors shared] color01];
            
            button.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        }
        
        SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
        configuration.distributeEvenly = YES;
        configuration.interSpace = 6;
        
        UIView *containerView = [UIView sav_viewWithEvenlyDistributedViews:self.buttons withConfiguration:configuration];
        [self.contentView addSubview:containerView];
        [self.contentView sav_addFlushConstraintsForView:containerView withPadding:6.0];

    }
    
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    self.textLabel.text = nil;
    
    if (info[SCUFanButtonsTableViewCellKeySelectedButton])
    {
        for (NSInteger i = 0; i < (long)self.buttons.count; i++)
        {
            SCUButton *button = (SCUButton *)self.buttons[i];
            button.backgroundColor = (i == [info[SCUFanButtonsTableViewCellKeySelectedButton] integerValue]) ? [[SCUColors shared] color03shade06] : [[SCUColors shared] color03shade04];
        }
    }
}

@end
