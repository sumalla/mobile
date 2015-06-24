//
//  SCUTVOverlayTableViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowTableViewModel.h"
#import "SCUServiceViewModel.h"
#import "SCUOverflowCell.h"
#import "SCUDefaultTableViewCell.h"

@import SDK;

@interface SCUOverflowTableViewModel ()

@property (nonatomic) SCUServiceViewModel *serviceModel;
@property (nonatomic) id settingsObserver;
@property NSMutableArray *visibleObjects;
@property NSMutableArray *hiddenObjects;
@property (nonatomic) NSArray *customCommands;
@property (nonatomic, copy) NSArray *dataSource;
@property SAVService *genericService;
@property NSDictionary *iconMapping;
@property SAVCoalescedTimer *timer;

@end

static NSString *const SCUTVOverflowTableViewModelKeyAddButton = @"SCUTVOverflowTableViewModelKeyAddButton";
static NSString *const SCUTVOverflowTableViewModelKeyTimer = @"SCUTVOverflowTableViewModelKeyTimer";

@implementation SCUOverflowTableViewModel

- (void)dealloc
{
    [self.timer invalidate];
    [[SAVSettings userSettings] removeObserver:self.settingsObserver];
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    
    if (self)
    {
        self.serviceModel = [[SCUServiceViewModel alloc] initWithService:service];
        self.genericService = [[SAVService alloc] initWithZone:service.zoneName component:nil logicalComponent:nil variantId:nil serviceId:@"SVC_GEN_GENERIC"];
        self.customCommands = service.customCommands;
        
        self.timer = [[SAVCoalescedTimer alloc] init];
        self.timer.timeInverval = 0.25;
        
        NSError *e = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"OverflowIcons" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        self.iconMapping = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&e];
        
        if (e)
        {
            NSLog(@"Error parsing overflow icons: %@", [e localizedDescription]);
        }
    
        [self loadButtons];
    }
    
    return self;
}

- (void)loadButtons
{
    [self parseSettings:self.serviceModel.dynamicCommands];
}

- (NSArray *)permanentlyHiddenCommands
{
    return @[@"Guide", @"LastChannel", @"MyDVR", @"List"];
}

- (void)parseSettings:(NSDictionary *)settings
{
    self.visibleObjects = [NSMutableArray arrayWithArray:settings[SAVShownObjectsArrayKey]];
    self.hiddenObjects = [NSMutableArray arrayWithArray:settings[SAVHiddenObjectsArrayKey]];
    
    [self.visibleObjects removeObjectsInArray:[self permanentlyHiddenCommands]];
    [self.hiddenObjects removeObjectsInArray:[self permanentlyHiddenCommands]];
    
    if (self.adding)
    {
        self.dataSource = [self.hiddenObjects arrayByMappingBlock:^id(NSString *command) {
            
            NSString *localizedCommand = [SCUOverflowTableViewModel localizedCommand:command];
            
            NSMutableDictionary *newCommand = [NSMutableDictionary dictionary];
            
            newCommand[SCUOverflowCellKeyTitle] = localizedCommand;
            newCommand[SCUDefaultTableViewCellKeyModelObject] = command;
            
            if (self.iconMapping[command])
            {
                newCommand[SCUOverflowCellKeyImage] = [UIImage sav_imageNamed:self.iconMapping[command] tintColor:[self tintColorForCommand:command]];
            }
            
            return [newCommand copy];
        }];
    }
    else
    {
        self.dataSource = [self.visibleObjects arrayByMappingBlock:^id(NSString *command) {

            NSString *localizedCommand = [SCUOverflowTableViewModel localizedCommand:command];
            
            NSMutableDictionary *newCommand = [NSMutableDictionary dictionary];
            
            newCommand[SCUOverflowCellKeyTitle] = localizedCommand;

            if (self.iconMapping[command])
            {
                newCommand[SCUOverflowCellKeyImage] = [UIImage sav_imageNamed:self.iconMapping[command] tintColor:[self tintColorForCommand:command]];
            }

            newCommand[SCUDefaultTableViewCellKeyModelObject] = command;
            
            return [newCommand copy];
        }];

        self.dataSource = [self.dataSource arrayByAddingObject:[self addButton]];
    }
}

- (UIColor *)tintColorForCommand:(NSString *)command
{
    if ([command isEqualToString:@"Red"])
    {
        return [UIColor redColor];
    }
    if ([command isEqualToString:@"Blue"])
    {
        return [UIColor blueColor];
    }
    if ([command isEqualToString:@"Green"])
    {
        return [UIColor greenColor];
    }
    if ([command isEqualToString:@"Yellow"])
    {
        return [UIColor yellowColor];
    }

    return [[SCUColors shared] color04];
}

- (NSDictionary *)addButton
{
    return @{SCUOverflowCellKeyTitle: NSLocalizedString(@"Add Button", nil),//, uppercaseString],
             SCUTVOverflowTableViewModelKeyAddButton: @(YES),
             SCUOverflowCellKeyImage: [[UIImage sav_imageNamed:@"VolumePlus" tintColor:[[SCUColors shared] color03shade07]] scaleToSize:CGSizeMake(24, 24)]};
}

- (void)setAdding:(BOOL)adding
{
    if (_adding != adding)
    {
        _adding = adding;
        
        [self saveOrdering];
        
        [self loadButtons];
        
        if (adding)
        {
            [self.addDelegate reloadData];
        }
        else
        {
            [self.delegate reloadData];
        }
    }
}

+ (NSString *)localizedCommand:(NSString *)command
{
    return NSLocalizedStringWithDefaultValue([command stringByAppendingString:@"-Command"], @"Command", [NSBundle mainBundle], command, @"Localized Service Command");
}

- (NSDictionary *)dynamicCommands
{
    return @{SAVShownObjectsArrayKey: self.visibleObjects, SAVHiddenObjectsArrayKey: self.hiddenObjects};
}

- (NSIndexPath *)indexPathForAddButton
{
    if (!self.isAdding)
    {
        for (NSInteger row = self.dataSource.count - 1; row >= 0; row--)
        {
            NSDictionary *info = self.dataSource[row];
            if ([info[SCUTVOverflowTableViewModelKeyAddButton] boolValue])
            {
                return [NSIndexPath indexPathForRow:row inSection:0];
            }
        }
    }

    return nil;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *dataSource = self.dataSource.mutableCopy;
    NSDictionary *temp = dataSource[toIndexPath.row];
    dataSource[toIndexPath.row] = dataSource[fromIndexPath.row];
    dataSource[fromIndexPath.row] = temp;
    
    NSDictionary *old = self.visibleObjects[fromIndexPath.row];
    self.visibleObjects[fromIndexPath.row] = self.visibleObjects[toIndexPath.row];
    self.visibleObjects[toIndexPath.row] = old;
    
    [self saveOrdering];
    
    self.dataSource = [dataSource copy];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:[self indexPathForAddButton]] && self.isAddButtonEnabled)
    {
        self.adding = YES;
        return;
    }
    
    if (self.isAdding)
    {
        [self addItemAtIndexPath:indexPath];
        return;
    }

    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *request = modelObject[SCUDefaultTableViewCellKeyModelObject];
    
    if ([self.customCommands containsObject:request])
    {
        SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.genericService];
        serviceRequest.request = request;
        [self.serviceModel sendServiceRequest:serviceRequest];
    }
    else
    {
        NSString *command = modelObject[SCUDefaultTableViewCellKeyModelObject];
        [self.serviceModel sendCommand:command];
    }
}

- (BOOL)isAddButtonEnabled
{
    return [self.hiddenObjects count] ? YES : NO;
}

- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    
    NSString *command = modelObject[SCUDefaultTableViewCellKeyModelObject];
    
    [self.visibleObjects removeObject:command];
    [self.hiddenObjects addObject:command];
    
    NSMutableArray *mDataSource = [self.dataSource mutableCopy];
    [mDataSource removeObjectAtIndex:indexPath.row];
    self.dataSource = [mDataSource copy];
    
    [self didDeleteItemAtIndexPath:indexPath];
    
    return YES;
}

- (void)didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self saveOrdering];
}

- (BOOL)addItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    
    NSString *command = modelObject[SCUDefaultTableViewCellKeyModelObject];
    
    [self.visibleObjects addObject:command];
    [self.hiddenObjects removeObject:command];
    [self saveOrdering];

    NSMutableArray *mDataSource = [self.dataSource mutableCopy];
    [mDataSource removeObjectAtIndex:indexPath.row];
    self.dataSource = [mDataSource copy];
    

    [self didAddItemAtIndexPath:indexPath];
    
    return YES;
}

- (void)didAddItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isAddButtonEnabled)
    {
        [self.addDelegate popViewController];
    }
    else
    {
        [self.addDelegate removeRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)saveOrdering
{
    [[Savant data] saveOrdering:[self dynamicCommands] forService:self.serviceModel.service];
}

@end