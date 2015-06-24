//
//  SCUCaptureRoomCell.m
//  SavantController
//
//  Created by Stephen Silber on 12/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButton.h"
#import "SCUCaptureRoomCell.h"

NSString *const SCUCaptureRoomCellKeyChevronDirection = @"SCUCaptureRoomCellKeyChevronDirection";

@interface SCUCaptureRoomCell ()

@property (nonatomic) SCUButton *chevronButton;

@end

@implementation SCUCaptureRoomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.chevronButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"chevron-up"]];
        self.chevronButton.color = [[SCUColors shared] color03shade07];
        self.chevronButton.selectedBackgroundColor = [UIColor clearColor];
        self.chevronButton.frame = CGRectMake(0, 0, 50, 60);
        
        self.accessoryView = self.chevronButton;

    }
    
    return self;
}

- (void)setChevronDirection:(SCUCaptureRoomCellChevronDirection)direction
{
    NSString *imageName = (direction == SCUCaptureRoomCellChevronDirectionUp) ? @"chevron-up" : @"chevron-down";
    self.chevronButton.image = [UIImage imageNamed:imageName];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    if (info[SCUCaptureRoomCellKeyChevronDirection])
    {
        [self setChevronDirection:[info[SCUCaptureRoomCellKeyChevronDirection] integerValue]];
    }
    
}

@end
