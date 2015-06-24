
//
//  UIFont+Gotham.m
//  Prototype
//
//  Created by Nathan Trapp on 2/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Extensions;

@implementation UIFont (Gotham)

+ (void)load
{
    SAVReplaceClassMethodWithMethod([self class], @selector(systemFontOfSize:), @selector(scu_regularFontWithSize:));
    SAVReplaceClassMethodWithMethod([self class], @selector(boldSystemFontOfSize:), @selector(scu_boldFontWithSize:));
    SAVReplaceClassMethodWithMethod([self class], @selector(fontWithName:size:), @selector(scu_fontWithName:size:));
    SAVReplaceClassMethodWithMethod([self class], @selector(preferredFontForTextStyle:), @selector(scu_preferredFontForTextStyle:));
    SAVReplaceMethodWithBlock(self, NSSelectorFromString(@"_scaledValueForValue:"), ^(UIFont *font, CGFloat value){
        return value;
    });
}

+ (UIFont *)scu_preferredFontForTextStyle:(NSString *)style
{
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Medium",
                                  UIFontDescriptorSizeAttribute: @17
                                  },
                          
                          UIFontTextStyleSubheadline: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @12
                                  },
                          
                          UIFontTextStyleBody: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @17
                                  },
                          
                          UIFontTextStyleCaption1: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @12
                                  },
                          
                          UIFontTextStyleCaption2: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @11
                                  },
                          
                          UIFontTextStyleFootnote: @{
                                  UIFontDescriptorNameAttribute: @"Gotham-Light",
                                  UIFontDescriptorSizeAttribute: @13
                                  }
                          };
    });
    
    return [[self class] scu_fontWithName:fontSizeTable[style][UIFontDescriptorNameAttribute] size:[fontSizeTable[style][UIFontDescriptorSizeAttribute] floatValue]];
}

+ (UIFont *)scu_regularFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Gotham-Light" size:size];
}

+ (UIFont *)scu_boldFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:@"Gotham-Medium" size:size];
}

+ (UIFont *)scu_fontWithName:(NSString *)name size:(CGFloat)size
{
    name = [name stringByReplacingOccurrencesOfString:@"HelveticaNeue" withString:@"Gotham"];
    
    return [[self class] scu_fontWithName:name size:size]; // call original
}

@end