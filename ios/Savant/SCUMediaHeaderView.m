//
//  SCUMediaHeaderView.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaHeaderView.h"

@import Extensions;

@interface SCUMediaHeaderView ()

@property (nonatomic) SAVKVORegistration *textLabelRegistration;

@end

@implementation SCUMediaHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textLabel.textColor = [[SCUColors shared] color04];

        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundView = backgroundView;

        SAVWeakSelf;
        self.textLabelRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:self.textLabel selector:@selector(text) handler:^(NSDictionary *changeDictionary) {
            SAVStrongWeakSelf;

            id new = changeDictionary[@"new"];

            if ([new isKindOfClass:[NSString class]])
            {
                NSString *text = (NSString *)new;

                if ([text length])
                {
                    sSelf.backgroundView = nil;
                    sSelf.contentView.backgroundColor = [[SCUColors shared] color03shade01];
                }
            }

        }];
    }

    return self;
}

@end
