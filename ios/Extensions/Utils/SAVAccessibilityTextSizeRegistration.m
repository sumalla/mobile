//
//  SAVAccessibilityTextSizeRegistration.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 12/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVAccessibilityTextSizeRegistration.h"

@interface SAVAccessibilityTextSizeRegistration ()

@property (nonatomic) id<NSObject> registration;

@end

@implementation SAVAccessibilityTextSizeRegistration

+ (UIFont *)fontWithName:(NSString *)family accessibilitySize:(NSString *)size
{
    return [UIFont fontWithName:family size:[UIFont preferredFontForTextStyle:size].pointSize];
}

- (void)dealloc
{
    if (self.registration)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.registration];
    }
}

- (instancetype)initWithChangeHandler:(dispatch_block_t)changeHandler
{
    NSParameterAssert(changeHandler);
    self = [super init];

    if (self)
    {
        self.registration = [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            changeHandler();
        }];
    }

    return self;
}

@end
