//
//  SCUDynamicButtonsCollectionViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDynamicButtonsCollectionViewModel.h"

#import "SCUEditableButtonsCollectionViewModelPrivate.h"
#import "SCUStandardCollectionViewCell.h"

@interface SCUDynamicButtonsCollectionViewModel ()

@property (nonatomic) id settingsObserver;
@property NSMutableArray *visibleObjects;
@property NSMutableArray *hiddenObjects;
@property (nonatomic) NSArray *customCommands;
@property (nonatomic, copy) NSArray *dataSource;
@property SAVService *genericService;

@end

@implementation SCUDynamicButtonsCollectionViewModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.genericService = [[SAVService alloc] initWithZone:service.zoneName component:nil logicalComponent:nil variantId:nil serviceId:@"SVC_GEN_GENERIC"];
        self.customCommands = service.customCommands;
        
        //SRS TODO: Put this in a loadData if necessary style method
        [self loadButtons];
    }
    
    return self;
}

- (void)dealloc
{
    [[SAVSettings userSettings] removeObserver:self.settingsObserver];
}

- (void)loadButtons
{
    [self parseSettings:self.serviceModel.dynamicCommands];

    if (!self.settingsObserver)
    {
        SAVWeakSelf;
        self.settingsObserver = [[SAVSettings userSettings] addObserverForKey:[[Savant data] orderingKeyForService:self.serviceModel.service]
                                                                   usingBlock:^(NSString *key, id setting) {
                                                                       [wSelf parseSettings:setting];
                                                                   }];
    }
}

- (void)parseSettings:(NSDictionary *)settings
{
    self.visibleObjects = [NSMutableArray arrayWithArray:settings[SAVShownObjectsArrayKey]];
    self.hiddenObjects = [NSMutableArray arrayWithArray:settings[SAVHiddenObjectsArrayKey]];

    self.modelObjects = [self.visibleObjects arrayByMappingBlock:^id(NSString *command) {
        NSString *localizedCommand = [SCUDynamicButtonsCollectionViewModel localizedCommand:command];

        NSMutableDictionary *newCommand = [NSMutableDictionary dictionary];

        newCommand[SCUDefaultCollectionViewCellKeyTitle] = localizedCommand;
        newCommand[SCUDefaultCollectionViewCellKeyModelObject] = command;

        return [newCommand copy];
    }];

    [self reloadData];
}

- (void)itemAtIndexPathTapped:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *request = modelObject[SCUDefaultCollectionViewCellKeyModelObject];

    if ([self.customCommands containsObject:request])
    {
        SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.genericService];
        serviceRequest.request = request;
        [self.serviceModel sendServiceRequest:serviceRequest];
    }
    else
    {
        [self.serviceModel sendCommand:modelObject[SCUDefaultCollectionViewCellKeyModelObject]];
    }
}

- (void)addTapped
{
    [self.delegate presentAddButtonsViewController];
}

- (BOOL)isPlusButtonEnabled
{
    return [self.hiddenObjects count] ? YES : NO;
}

- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

    NSString *command = modelObject[SCUDefaultCollectionViewCellKeyModelObject];

    [self.visibleObjects removeObject:command];
    [self.hiddenObjects addObject:command];

    NSMutableArray *mDataSource = [self.dataSource mutableCopy];
    [mDataSource removeObjectAtIndex:indexPath.row];
    self.dataSource = [mDataSource copy];

    return YES;
}

- (void)didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveOrdering];
}

- (void)itemAtIndexPath:(NSIndexPath *)indexPath movedToIndexPath:(NSIndexPath *)newIndexPath
{
    NSString *command = self.visibleObjects[indexPath.row];
    [self.visibleObjects removeObjectAtIndex:indexPath.row];
    [self.visibleObjects insertObject:command atIndex:newIndexPath.row];

    [self saveOrdering];
}

+ (NSString *)localizedCommand:(NSString *)command
{
    return NSLocalizedStringWithDefaultValue([command stringByAppendingString:@"-Command"], @"Command", [NSBundle mainBundle], command, @"Localized Service Command");
}

- (NSDictionary *)dynamicCommands
{
    return @{SAVShownObjectsArrayKey: self.visibleObjects, SAVHiddenObjectsArrayKey: self.hiddenObjects};
}

- (void)addButton:(NSDictionary *)button
{
    NSString *command = button[SCUDefaultCollectionViewCellKeyModelObject];

    NSMutableArray *modelObjects = [self.modelObjects mutableCopy];
    [modelObjects addObject:button];
    self.modelObjects = modelObjects;

    [self.visibleObjects addObject:command];
    [self.hiddenObjects removeObject:command];
}

- (void)saveOrdering
{
    [[Savant data] saveOrdering:self.dynamicCommands forService:self.serviceModel.service];
}

- (NSArray *)hiddenCommands
{
    return self.hiddenObjects;
}

@end
