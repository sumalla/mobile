//
//  SCUStyles.m
//
// This file was auto-generated using the style-js tool.
// Do not directly modify this file!
//

#import "SCUStyles.h"

@implementation SCUColors
+ (SCUColors *)shared
{
    static SCUColors* sharedColors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedColors = [[SCUColors alloc] init];
    });
    return sharedColors;
}

#pragma mark - General Colors

- (UIColor *)color01
{
    return [UIColor colorWithRed:1 green:0.372549 blue:0 alpha:1];
}
- (UIColor *)color02
{
    return [UIColor colorWithRed:0.717647 green:0.678431 blue:0.647059 alpha:1];
}
- (UIColor *)color03
{
    return [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
}
- (UIColor *)color03shade01
{
    return [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:1];
}
- (UIColor *)color03shade02
{
    return [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
}
- (UIColor *)color03shade03
{
    return [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1];
}
- (UIColor *)color03shade04
{
    return [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1];
}
- (UIColor *)color03shade05
{
    return [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1];
}
- (UIColor *)color03shade06
{
    return [UIColor colorWithRed:0.42 green:0.42 blue:0.42 alpha:1];
}
- (UIColor *)color03shade07
{
    return [UIColor colorWithRed:0.62 green:0.62 blue:0.62 alpha:1];
}
- (UIColor *)color03shade08
{
    return [UIColor colorWithRed:0.32 green:0.32 blue:0.32 alpha:1];
}
- (UIColor *)color04
{
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
}
- (UIColor *)color05
{
    return [UIColor colorWithRed:1 green:0.258824 blue:0.12549 alpha:1];
}
- (UIColor *)color06
{
    return [UIColor colorWithRed:0.976471 green:0.843137 blue:0 alpha:1];
}
- (UIColor *)color07
{
    return [UIColor colorWithRed:0.686275 green:0.8 blue:0 alpha:1];
}
- (UIColor *)color08
{
    return [UIColor colorWithRed:0.705882 green:0.905882 blue:0.980392 alpha:1];
}
- (UIColor *)color09
{
    return [UIColor colorWithRed:0.988235 green:0.521569 blue:0.137255 alpha:1];
}
- (UIColor *)color10
{
    return [UIColor colorWithRed:1 green:0.678431 blue:0.419608 alpha:1];
}
- (UIColor *)color11
{
    return [UIColor colorWithRed:0.796078 green:0.329412 blue:0.0509804 alpha:1];
}
- (UIColor *)color12
{
    return [UIColor colorWithRed:0.94902 green:0.454902 blue:0.156863 alpha:1];
}
- (UIColor *)color13
{
    return [UIColor colorWithRed:0.705882 green:0.905882 blue:0.980392 alpha:1];
}
- (UIColor *)color14
{
    return [UIColor colorWithRed:0.0196078 green:0.52549 blue:0.709804 alpha:1];
}
- (UIColor *)color15
{
    return [UIColor colorWithRed:0.0470588 green:0.6 blue:0.8 alpha:1];
}


@end

@implementation SCUCompactDimens

#pragma mark - General Colors

- (CGFloat)h1
{
    return 72;
}
- (CGFloat)h10
{
    return 14;
}
- (CGFloat)h11
{
    return 12;
}
- (CGFloat)h12
{
    return 10;
}
- (CGFloat)h2
{
    return 64;
}
- (CGFloat)h3
{
    return 48;
}
- (CGFloat)h4
{
    return 40;
}
- (CGFloat)h5
{
    return 36;
}
- (CGFloat)h6
{
    return 32;
}
- (CGFloat)h7
{
    return 24;
}
- (CGFloat)h8
{
    return 18;
}
- (CGFloat)h9
{
    return 17;
}
- (CGFloat)padding1
{
    return 1;
}
- (CGFloat)padding10
{
    return 40;
}
- (CGFloat)padding11
{
    return 50;
}
- (CGFloat)padding13
{
    return 60;
}
- (CGFloat)padding14
{
    return 3;
}
- (CGFloat)padding15
{
    return 6;
}
- (CGFloat)padding16
{
    return 15;
}
- (CGFloat)padding17
{
    return 25;
}
- (CGFloat)padding18
{
    return 45;
}
- (CGFloat)padding19
{
    return 70;
}
- (CGFloat)padding2
{
    return 2;
}
- (CGFloat)padding20
{
    return 80;
}
- (CGFloat)padding3
{
    return 4;
}
- (CGFloat)padding4
{
    return 8;
}
- (CGFloat)padding5
{
    return 12;
}
- (CGFloat)padding6
{
    return 16;
}
- (CGFloat)padding7
{
    return 30;
}
- (CGFloat)padding8
{
    return 32;
}
- (CGFloat)padding9
{
    return 35;
}

#pragma mark - global

- (CGFloat)globalMargin1
{
    return 16;
}
- (CGFloat)globalMargin2
{
    return 24;
}


@end

@implementation SCURegularDimens

#pragma mark - General Colors

- (CGFloat)h1
{
    return 72;
}
- (CGFloat)h10
{
    return 14;
}
- (CGFloat)h11
{
    return 12;
}
- (CGFloat)h12
{
    return 10;
}
- (CGFloat)h2
{
    return 64;
}
- (CGFloat)h3
{
    return 48;
}
- (CGFloat)h4
{
    return 40;
}
- (CGFloat)h5
{
    return 36;
}
- (CGFloat)h6
{
    return 32;
}
- (CGFloat)h7
{
    return 24;
}
- (CGFloat)h8
{
    return 18;
}
- (CGFloat)h9
{
    return 17;
}
- (CGFloat)padding1
{
    return 1;
}
- (CGFloat)padding10
{
    return 40;
}
- (CGFloat)padding11
{
    return 50;
}
- (CGFloat)padding13
{
    return 60;
}
- (CGFloat)padding14
{
    return 3;
}
- (CGFloat)padding15
{
    return 6;
}
- (CGFloat)padding16
{
    return 15;
}
- (CGFloat)padding17
{
    return 25;
}
- (CGFloat)padding18
{
    return 45;
}
- (CGFloat)padding19
{
    return 70;
}
- (CGFloat)padding2
{
    return 2;
}
- (CGFloat)padding20
{
    return 80;
}
- (CGFloat)padding3
{
    return 4;
}
- (CGFloat)padding4
{
    return 8;
}
- (CGFloat)padding5
{
    return 12;
}
- (CGFloat)padding6
{
    return 16;
}
- (CGFloat)padding7
{
    return 30;
}
- (CGFloat)padding8
{
    return 32;
}
- (CGFloat)padding9
{
    return 35;
}

#pragma mark - global

- (CGFloat)globalMargin1
{
    return 16;
}
- (CGFloat)globalMargin2
{
    return 24;
}


@end

@implementation SCUDimens

+ (SCUDimens *)dimens
{
    static SCUDimens* sharedDimens = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDimens = [[SCUDimens alloc] init];
    });
    return sharedDimens;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _compact = [[SCUCompactDimens alloc] init];
        _regular = [[SCURegularDimens alloc] init];
    }
    return self;
}

@end
