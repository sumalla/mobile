//
//  SCUDefaultCollectionViewCell.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultCollectionViewCell.h"

NSString *const SCUDefaultCollectionViewCellKeyTitle = @"SCUDefaultTableViewCellKeyTitle";
NSString *const SCUDefaultCollectionViewCellKeyModelObject = @"SCUDefaultTableViewCellKeyModelObject";

@interface SCUDefaultCollectionViewCell ()

@property (nonatomic) UILabel *textLabel;

@end

@implementation SCUDefaultCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel = [[UILabel alloc] init];
        [self.contentView addSubview:self.textLabel];
        self.textLabel.textColor = [[SCUColors shared] color04];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.textLabel.text = info[SCUDefaultCollectionViewCellKeyTitle];
}

@end
