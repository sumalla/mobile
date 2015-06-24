//
//  InterfaceController.m
//  Savant WatchKit Extension
//
//  Created by Cameron Pulsford on 3/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "InterfaceController.h"
#import "SDKInterfaceControllerPrivate.h"
#import "SceneRow.h"
@import SDK;

@interface InterfaceController() <StateDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (nonatomic) SAVDISRequestGenerator *generator;
@property (nonatomic) NSArray *feedbackNames;
@property (nonatomic, copy) NSArray *identifiers;
@property (nonatomic) NSUInteger numberOfRooms;
@property (nonatomic) NSString *queuedIdentifier;

@end

@implementation InterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"dashboard"];
}

- (BOOL)cachedDataAvailable
{
    return self.identifiers ? YES : NO;
}

- (void)didDeactivate
{
    [[Savant states] unregisterForStates:self.feedbackNames forObserver:self];

    [super didDeactivate];

    self.feedbackNames = nil;
    self.hasConnected = NO;
    self.queuedIdentifier = nil;
}

- (void)showTable
{
    [self.table setHidden:NO];
    [self.reconnectIcon setHidden:YES];
    [self.statusLabel setHidden:YES];
}

- (void)showStatusLabelWithText:(NSString *)text
{
    [super showStatusLabelWithText:text];
    [self.table setHidden:YES];
}

- (void)connectionIsReady
{
    if (!self.hasConnected)
    {
        self.feedbackNames = [self.generator feedbackStringsWithStateNames:@[@"scenes"]];
        [[Savant states] registerForStates:self.feedbackNames forObserver:self];
    }

    [super connectionIsReady];

    self.numberOfRooms = [[[Savant data] allRoomIds] count];

    if (self.queuedIdentifier)
    {
        [self applySceneWithIdentifier:self.queuedIdentifier];
        self.queuedIdentifier = nil;
    }
}

#pragma mark - StateDelegate

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    if ([feedback.stateName isEqualToString:@"scenes"])
    {
        [self loadScenes:[feedback value]];
    }
}

- (void)loadScenes:(NSArray *)scenes
{
    NSMutableArray *identifiers = [NSMutableArray array];

    if ([scenes count])
    {
        [self showTable];
        [self.table setNumberOfRows:(NSInteger)[scenes count] withRowType:@"Scene"];

        [scenes enumerateObjectsUsingBlock:^(NSDictionary *sceneDict, NSUInteger idx, BOOL *stop) {
            SAVScene *scene = [[SAVScene alloc] init];

            NSMutableDictionary *mSceneDict = [sceneDict mutableCopy];
            [mSceneDict removeObjectForKey:@"imageKey"];
            [scene applySettings:mSceneDict];

            if (scene && scene.name)
            {
                [identifiers addObject:scene.identifier];
            }

            NSUInteger roomCount = [scene.tags count];
            NSString *roomText = nil;

            if (roomCount == self.numberOfRooms)
            {
                roomText = NSLocalizedString(@"Whole home", nil);
            }
            else
            {
                switch (roomCount)
                {
                    case 0:
                        roomText = NSLocalizedString(@"No rooms", nil);
                        break;
                    case 1:
                        roomText = [scene.tags firstObject];
                        break;
                    default:
                        roomText = [NSString stringWithFormat:NSLocalizedString(@"%@ +%lu", nil), [scene.tags firstObject], roomCount - 1];
                        break;
                }
            }

            SceneRow *row = [self.table rowControllerAtIndex:(NSInteger)idx];
            [row.sceneNameLabel setText:scene.name];
            [row.roomLabel setText:[roomText uppercaseString]];
        }];
    }
    else
    {
        [self showStatusLabelWithText:NSLocalizedString(@"Create scenes in your Savant App. Activate them from your watch.", nil)];
    }

    self.identifiers = identifiers;
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    NSString *identifier = self.identifiers[(NSUInteger)rowIndex];

    if (identifier)
    {
        if ([Savant control].isConnectedToSystem)
        {
            [self applySceneWithIdentifier:identifier];
        }
        else
        {
            self.queuedIdentifier = identifier;
        }
    }
}

#pragma mark - Helpers

- (void)applySceneWithIdentifier:(NSString *)identifier
{
    SAVDISRequest *applyScene = [self.generator request:@"ApplyScene" withArguments:@{@"id": identifier}];
    [[Savant control] sendMessage:applyScene];
}

@end
