//
//  SCUSecurityCameraModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityCameraModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUInterface.h"
#import "SCUCameraCollectionViewCell.h"
#import "SCUBackgroundHandler.h"

@interface SCUSecurityCameraModel () <SAVCameraEntityDelegate, SystemStatusDelegate>

@property NSArray *cameraEntities;
@property NSArray *dataSource;

@property NSMutableSet *streamingEntities;

@property NSMapTable *lastImage;

@property (weak) SAVCameraEntity *fullScreenEntity;

@end

@implementation SCUSecurityCameraModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (service)
    {
        self.cameraEntities = [[SavantControl sharedControl].data cameraEntities:[SCUInterface sharedInstance].currentRoom.roomId zone:nil service:nil];

        self.streamingEntities = [NSMutableSet set];
        self.lastImage = [NSMapTable weakToStrongObjectsMapTable];

        [self prepareDataSource];


    }
    return self;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    if (self.fullScreenEntity)
    {
        [self stopStreaming:self.fullScreenEntity];
        [self.fullScreenEntity stopFullscreenStream];
        self.fullScreenEntity = nil;
    }

    [[SavantControl sharedControl] addSystemStatusObserver:self];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];

    for (SAVCameraEntity *entity in [self.streamingEntities copy])
    {
        [self stopStreaming:entity];
    }

    [[SavantControl sharedControl] removeSystemStatusObserver:self];
}

- (void)prepareDataSource
{
    NSDictionary *camerasByZone = [self camerasByZone];
    NSMutableArray *mutableDataSource = [NSMutableArray array];

    for (NSString *zoneName in camerasByZone)
    {
        [mutableDataSource addObject:@{SCUDefaultCollectionViewCellKeyModelObject: camerasByZone[zoneName],
                                       SCUDefaultCollectionViewCellKeyTitle: zoneName}];
    }

    self.dataSource = [mutableDataSource copy];
}

- (NSDictionary *)camerasByZone
{
    NSMutableDictionary *camerasByZone = [NSMutableDictionary dictionary];

    for (SAVCameraEntity *entity in self.cameraEntities)
    {
        NSMutableArray *roomArray = camerasByZone[entity.zoneName];

        if (!roomArray)
        {
            roomArray = [NSMutableArray array];
            camerasByZone[entity.zoneName] = roomArray;
        }

        [roomArray addObject:entity];

    }

    return [camerasByZone copy];
}

- (NSIndexPath *)indexPathForEntity:(SAVCameraEntity *)entity
{
    NSIndexPath *indexPath = nil;

    for (NSIndexPath *index in [self.delegate.visibleIndexes copy])
    {
        SAVCameraEntity *testEntity = [self modelObjectForIndexPath:index];

        if ([testEntity isEqual:entity])
        {
            indexPath = index;
            break;
        }
    }

    return indexPath;
}

#pragma mark - Streaming

- (void)startStreaming:(SAVCameraEntity *)entity
{
    if ([SavantControl sharedControl].isConnectedToSystem)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopStreaming:) object:entity];

        if (![self.streamingEntities containsObject:entity])
        {
            [entity startPreviewStream];
            [entity addObserver:self];
            [self.streamingEntities addObject:entity];
        }
    }
}

- (void)stopStreaming:(SAVCameraEntity *)entity
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopStreaming:) object:entity];

    [self.streamingEntities removeObject:entity];
    [self.lastImage removeObjectForKey:entity];
    [self receivedImage:nil ofScale:SAVCameraEntityScale_Preview fromEntity:entity];
    [entity stopPreviewStream];
    [entity removeObserver:self];
}

#pragma mark - SAVCameraEntity Delegate

- (void)receivedImage:(UIImage *)image ofScale:(SAVCameraEntityScale)scale fromEntity:(SAVCameraEntity *)entity
{
    NSIndexPath *indexPath = [self indexPathForEntity:entity];

    if (indexPath)
    {
        [self.delegate receivedImage:image ofScale:scale forIndexPath:indexPath];
    }

    [self.lastImage setObject:image forKey:entity];
}

#pragma mark - Connection Delegate

- (void)connectionDidChangeToState:(SAVConnectionState)state
{
    switch (state)
    {
        case SAVConnectionStateNotConnected:
        {
            for (SAVCameraEntity *entity in [self.streamingEntities copy])
            {
                [self stopStreaming:entity];
            }

            if (self.fullScreenEntity)
            {
                [self.fullScreenEntity stopFullscreenStream];
            }

            break;
        }
        case SAVConnectionStateCloud:
        case SAVConnectionStateLocal:
        {
            for (NSIndexPath *indexPath in [self.delegate visibleIndexes])
            {
                [self willBegingDisplayingItemAtIndexPath:indexPath];
                [self didBegingDisplayingItemAtIndexPath:indexPath];
            }

            if (self.fullScreenEntity)
            {
                [self.fullScreenEntity startFullscrenStream];
            }

            break;
        }
    }
}

#pragma mark - CollectionViewModel Protocol

- (void)willBegingDisplayingItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self startStreaming:[self modelObjectForIndexPath:indexPath]];
}

- (void)didBegingDisplayingItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVCameraEntity *entity = [self modelObjectForIndexPath:indexPath];

    if ([self.lastImage objectForKey:entity])
    {
        [self receivedImage:[self.lastImage objectForKey:entity] ofScale:SAVCameraEntityScale_Preview fromEntity:entity];
    }
}

- (void)didEndDisplayingItemAtIndexPath:(NSIndexPath *)indexPath
{
    SAVCameraEntity *entity = [self modelObjectForIndexPath:indexPath];

    if (![self.lastImage objectForKey:entity])
    {
        [self stopStreaming:entity];
    }
    else
    {
        [self performSelector:@selector(stopStreaming:) withObject:entity afterDelay:10];
    }
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.fullScreenEntity = [self modelObjectForIndexPath:indexPath];

    [self.fullScreenEntity startFullscrenStream];
}

- (SAVCameraEntity *)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    return self.dataSource[indexPath.section][SCUDefaultCollectionViewCellKeyModelObject][indexPath.item];
}

- (id)modelObjectForSection:(NSInteger)section
{
    return self.dataSource[section];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (NSInteger)numberOfSections
{
    return [self.dataSource count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource[section][SCUDefaultCollectionViewCellKeyModelObject] count];
}

@end
