//
//  SCUMediaTabBarModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaTabBarModel.h"
#import "SCUButton.h"
#import "SCUMediaRequestViewControllerModel.h"
#import "SCUMediaDataModel.h"

@import Extensions;

static NSString *const SCUMediaKeyDisplayType = @"DisplayType";
static NSString *const SCUMediaDisplayTypeBottomBar = @"BottomBar";

@interface SCUMediaTabBarModel ()

@property (nonatomic) NSArray *modelObjects;
@property (nonatomic) NSArray *items;
@property (nonatomic, weak) SCUMediaRequestViewControllerModel *mediaRequestModel;
@property (nonatomic) NSInteger lastTappedIndex;

@end

@implementation SCUMediaTabBarModel

+ (BOOL)modelObjectsRequestTabBar:(NSArray *)modelObjects
{
    BOOL requestTabBar = NO;

    NSDictionary *firstObject = [modelObjects firstObject];

    if ([firstObject[SCUMediaKeyDisplayType] isEqualToString:SCUMediaDisplayTypeBottomBar] && [[self parseModelObjects:modelObjects] count])
    {
        requestTabBar = YES;
    }

    return requestTabBar;
}

- (instancetype)initWithModelObjects:(NSArray *)modelObjects mediaRequestModel:(SCUMediaRequestViewControllerModel *)mediaRequestModel
{
    self = [super init];

    if (self)
    {
        self.lastTappedIndex = -1;
        self.mediaRequestModel = mediaRequestModel;
        self.modelObjects = [[self class] parseModelObjects:modelObjects];
        self.items = [self parseModelObjectsIntoItems:self.modelObjects];
    }

    return self;
}

- (void)transition
{
    SCUButton *button = (SCUButton *)[self.items firstObject];
    [self handleLMQCommand:button];
}

#pragma mark - 

+ (NSArray *)parseModelObjects:(NSArray *)modelObjects
{
    return [modelObjects filteredArrayUsingBlock:^BOOL(NSDictionary *modelObject) {
        return ![modelObject[@"Hidden"] boolValue];
    }];
}

- (NSArray *)parseModelObjectsIntoItems:(NSArray *)modelObjects
{
    NSMutableArray *items = [NSMutableArray array];

    [modelObjects enumerateObjectsUsingBlock:^(NSDictionary *modelObject, NSUInteger idx, BOOL *stop) {

        SCUButton *button = [[SCUButton alloc] initWithTitle:modelObject[@"Title"]];
        button.color = [[SCUColors shared] color04];
        button.selectedColor = [[SCUColors shared] color01];
        button.backgroundColor = [UIColor clearColor];
        button.selectedBackgroundColor = [UIColor clearColor];
        button.tag = (NSInteger)idx;
        button.target = self;
        button.releaseAction = @selector(handleLMQCommand:);

        [items addObject:button];
    }];
    
    return [items copy];
}

- (void)handleLMQCommand:(SCUButton *)button
{
    if (button.tag != self.lastTappedIndex || [SCUMediaDataModel isSearchNode:self.modelObjects[button.tag]])
    {
        for (SCUButton *button in self.items)
        {
            button.selected = NO;
        }

        button.selected = YES;

        [self.mediaRequestModel sendTabBarRequestWithQuery:self.modelObjects[button.tag]];

        self.lastTappedIndex = button.tag;
    }
}

@end
