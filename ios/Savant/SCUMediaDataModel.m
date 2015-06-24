//
//  SCUMediaModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaDataModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUIndexedCollation.h"
#import "SCUProgressTableViewCell.h"
#import "SCUTextFieldListener.h"
#import "SCUMediaRequestViewControllerModel.h"
@import SDK;

@import Extensions;

NSString *const SCUMediaModelKeyTitle = @"Title";
NSString *const SCUMediaModelKeySubtitle = @"Sub title";
NSString *const SCUMediaModelKeyHasSubmenu = @"Has submenu";
NSString *const SCUMediaModelKeyIsTextfield = @"Is Textfield";
NSString *const SCUMediaModelKeyArtworkURL = @"Associated URL";
NSString *const SCUMediaModelKeyQuery = @"Query";
NSString *const SCUMediaModelKeyQueryArguments = @"Query arguments";
NSString *const SCUMediaModelKeyCurrentIndex = @"Current Index";

static NSString *SCUMediaModelKeySectionKey = @"Section Key";
static NSString *SCUMediaModelKeyAcceptsText = @"Accepts text";
static NSString *SCUMediaModelKeySearchText = @"search";


typedef NS_ENUM(NSUInteger, SCUMediaDataModelCellAction)
{
    SCUMediaDataModelCellActionSelect,
    SCUMediaDataModelCellActionSearch
};

@interface SCUMediaDataModel ()

@property (nonatomic) NSArray *dataSource;
@property (nonatomic) SCUIndexedCollation *collation;
@property (nonatomic) NSIndexPath *tappedIndexPath;
@property (nonatomic, weak) SCUMediaRequestViewControllerModel *mediaModel;
@property (nonatomic) SAVService *service;
@property (nonatomic) NSMutableDictionary *artwork;
@property (nonatomic) UIImage *noArtworkImage;

@end

@implementation SCUMediaDataModel

+ (BOOL)isSearchNode:(NSDictionary *)query
{
    return [query[SCUMediaModelKeyQuery] isEqualToString:@"search"] || [query[SCUMediaModelKeyAcceptsText] boolValue];
}

- (instancetype)initWithModelObjects:(NSArray *)modelObjects mediaModel:(SCUMediaRequestViewControllerModel *)mediaModel service:(SAVService *)service
{
    self = [super init];
    
    if (self)
    {
        self.service = service;
        self.noArtworkImage = [[UIImage imageNamed:@"No_Album_Art"] scaleToSize:CGSizeMake(100, 100)];

        NSDictionary *firstObject = [modelObjects firstObject];

        if (firstObject[SCUMediaModelKeySectionKey] && [modelObjects count] > 10)
        {
            self.collation = [[SCUIndexedCollation alloc] init];
            self.dataSource = [self.collation preparedModelObjectsFromArray:modelObjects trimmed:YES usingBlock:^NSString *(NSDictionary *modelObject) {
                return modelObject[SCUMediaModelKeyTitle];
            }];
        }
        else
        {
            self.dataSource = @[modelObjects];
        }

        self.mediaModel = mediaModel;
    }

    return self;
}

- (void)stopLoadingIndicator
{
    if (self.tappedIndexPath)
    {
        NSIndexPath *tempIndexPath = self.tappedIndexPath;
        self.tappedIndexPath = nil;
        [self.delegate reloadIndexPath:tempIndexPath];
        [self.delegate addCheckmarkAtIndexPath:tempIndexPath];
    }
}

- (UIImage *)artworkForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *artworkURL = modelObject[SCUMediaModelKeyArtworkURL];

    return self.artwork[artworkURL] ?: self.noArtworkImage;
}

- (BOOL)hasArtworkForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasArtwork = NO;

    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    NSString *artworkURL = modelObject[SCUMediaModelKeyArtworkURL];

    if (!self.artwork)
    {
        self.artwork = [NSMutableDictionary dictionary];
    }

    if (artworkURL)
    {
        hasArtwork = YES;

        SAVWeakSelf;
        [[Savant images] imageForKey:artworkURL
                                                         type:SAVImageTypeLMQThumbnailArtwork
                                                         size:SAVImageSizeOriginal
                                                      blurred:NO
                                         requestingIdentifier:self
                                          componentIdentifier:self.service.component
                                            completionHandler:^(UIImage *image, BOOL isDefault) {
                                                wSelf.artwork[artworkURL] = image;
                                                [wSelf.delegate setArtwork:image forIndexPath:indexPath];
                                            }];
    }

    return hasArtwork;
}

#pragma mark - SCUViewModel methods

- (void)viewWillAppear
{
    [super viewWillAppear];

    [self.mediaModel.delegate resetNavigationDelegate];

    if (self.tappedIndexPath)
    {
        NSIndexPath *indexPath = self.tappedIndexPath;
        self.tappedIndexPath = nil;
        [self.delegate reloadIndexPath:indexPath];
    }
}

#pragma mark - SCUDataSourceModel methods

- (BOOL)isFlat
{
    return NO;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[self _modelObjectForIndexPath:indexPath] mutableCopy];

    if ([indexPath isEqual:self.tappedIndexPath])
    {
        modelObject[SCUProgressTableViewCellKeyAccessoryType] = @(SCUProgressTableViewCellAccessoryTypeSpinner);
    }

    if (self.isScene)
    {
        [modelObject removeObjectForKey:SCUMediaModelKeyHasSubmenu];
    }

    return modelObject;
}

- (id)modelObjectForSection:(NSInteger)section
{
    NSString *title = [self titleForHeaderInSection:section];

    if (!title)
    {
        title = @"";
    }

    return @{SCUDefaultTableViewCellKeyTitle: title};
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return self.collation.sectionTitles[section];
}

- (NSArray *)sectionIndexTitles
{
    return self.collation.sectionIndexTitles;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self _cellTypeForIndexPath:indexPath] == SCUMediaDataModelCellActionSelect)
    {
        [self.mediaModel sendRequestWithQuery:[self modelObjectForIndexPath:indexPath]];

        if (self.tappedIndexPath)
        {
            NSIndexPath *oldTappedIndexPath = self.tappedIndexPath;
            self.tappedIndexPath = nil;
            [self.delegate reloadIndexPath:oldTappedIndexPath];
        }
        
        NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];

        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [NSString stringWithFormat:NSLocalizedString(@"Title: %@\nSource: %@\nGUID: %@", nil), modelObject[@"Title"], modelObject[@"Query arguments"][@"source"], modelObject[@"Query arguments"][@"guid"]];

        self.tappedIndexPath = indexPath;
        [self.delegate reloadIndexPath:indexPath];
    }
}

- (void)accessoryButtonTappedAtIndexPath:(NSIndexPath *)indexPath
{
    [self.mediaModel sendSubmenuRequestWithQuery:[self modelObjectForIndexPath:indexPath] indexPath:indexPath];
}

- (NSInteger)sectionForSectionIndexTitleAtIndex:(NSInteger)sectionTitleIndex
{
    return [self.collation sectionForSectionIndexTitleAtIndex:sectionTitleIndex];
}

- (BOOL)canDeleteIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];
    return [modelObject[@"Can Delete"] boolValue];
}

- (void)commitDeleteForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *query = [self _modelObjectForIndexPath:indexPath];
    [self.mediaModel sendQueueDeleteRequestWithQuery:query];
    NSMutableArray *dataSource = self.dataSource[indexPath.section];
    [dataSource removeObjectAtIndex:indexPath.row];
    [self.delegate deleteItemAtIndexPath:indexPath];
}

#pragma mark -

- (NSUInteger)_cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    //-------------------------------------------------------------------
    // CBP TODO: Update
    //-------------------------------------------------------------------
    return SCUMediaDataModelCellActionSelect;
}

@end
