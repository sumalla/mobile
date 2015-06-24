//
//  UITableView+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UITableView+SAVExtensions.h"

@implementation UITableView (SAVExtensions)

- (void)sav_performUpdates:(dispatch_block_t)updates
{
    [self beginUpdates];

    if (updates)
    {
        updates();
    }

    [self endUpdates];
}

- (void)sav_registerClass:(Class)cellClass forCellType:(NSUInteger)cellType
{
    [self registerClass:cellClass forCellReuseIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)cellType]];
}

- (void)sav_scrollToTop
{
    self.contentOffset = CGPointMake(0, 0 - self.contentInset.top);
}

- (CGFloat)sav_heightForText:(NSString *)text font:(UIFont *)font
{
	return [self sav_heightForText:text attributes:@{NSFontAttributeName: font}];
}

- (CGFloat)sav_heightForText:(NSString *)text attributes:(NSDictionary *)attributes
{
	NSAssert(([text isKindOfClass:[NSString class]] || [text isKindOfClass:[NSMutableString class]]), @"Parameter: text is not an NSString.");
	NSParameterAssert(attributes);
	
	CGFloat height = self.rowHeight;
	
	CGRect frame = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)
									  options:NSStringDrawingUsesLineFragmentOrigin
								   attributes:attributes
									  context:nil];
	
	height += CGRectGetHeight(frame);
	
	return height;
}

- (void)setSav_separatorStyle:(UITableViewCellSeparatorStyle)sav_separatorStyle
{
    self.separatorStyle = sav_separatorStyle;
}

- (UITableViewCellSeparatorStyle)sav_separatorStyle
{
    return self.separatorStyle;
}

@end
