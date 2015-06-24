//
//  SCUMediaRequestViewControllerModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaRequestViewControllerModel.h"
#import "SCUMediaDataModel.h"
#import "SCUMediaTabBarModel.h"
#import "SCUTextEntryAlert.h"
@import SDK;

@import Extensions;

typedef void(^SCUMediaRequestSearchCallback)(SAVMediaRequest *mediaRequest);

@interface SCUMediaRequestViewControllerModel ()

@property (nonatomic) SAVMediaRequestGenerator *mediaRequestGenerator;
@property (nonatomic) CBPPromise *outstandingMediaPromise;
@property (nonatomic) BOOL hasRequestedRoot;
@property (nonatomic) SCUMediaTabBarModel *tabBarModel;
@property (nonatomic) SAVService *service;
@property (nonatomic, getter = isSMS) BOOL sms;
@property (nonatomic) NSSet *smsAutomaticBackTitles;
@property (nonatomic) NSString *sceneGUID;

@end

@implementation SCUMediaRequestViewControllerModel

- (void)dealloc
{
    if (self.outstandingMediaPromise)
    {
        [[Savant control] cancelMediaRequest:self.outstandingMediaPromise];
    }
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];

    if (self)
    {
        self.service = service;
        self.mediaRequestGenerator = [SAVMediaRequestGenerator mediaRequestGeneratorFromService:service];
        self.sms = [self.service.serviceId containsString:@"LIVEMEDIAQUERY_SAVANTMEDIA"];

        if (self.isSMS)
        {
            self.smsAutomaticBackTitles = [NSSet setWithObjects:@"Play now", @"Play next", @"Replace queue", @"Add to queue", @"Add to playlist", nil];;
        }
    }

    return self;
}

- (void)sendRequestWithQuery:(NSDictionary *)query
{
    SAVWeakSelf;
    BOOL isSearch = [self handleSearch:query withCallback:^(SAVMediaRequest *mediaRequest){
        [wSelf sendMessage:mediaRequest
                 isSubmenu:NO
                  isTabBar:NO
                 indexPath:nil
             originalQuery:query
             ignoreResults:NO];
    }];

    if (!isSearch)
    {
        SAVMediaRequest *request = [self.mediaRequestGenerator mediaRequestFromNode:query];

        if ([request.query isEqualToString:@"doNothing"])
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate reachedLeaf];
            });
        }
        else
        {
            [self sendMessage:request
                    isSubmenu:NO
                     isTabBar:NO
                    indexPath:nil
                originalQuery:query
                ignoreResults:NO];
        }
    }
}

- (void)sendTabBarRequestWithQuery:(NSDictionary *)query
{
    SAVWeakSelf;
    BOOL isSearch = [self handleSearch:query withCallback:^(SAVMediaRequest *mediaRequest){
        [wSelf sendMessage:mediaRequest
                 isSubmenu:NO
                  isTabBar:YES
                 indexPath:nil
             originalQuery:query
             ignoreResults:NO];
    }];

    if (!isSearch)
    {
        [self sendMessage:[self.mediaRequestGenerator mediaRequestFromNode:query]
                isSubmenu:NO
                 isTabBar:YES
                indexPath:nil
            originalQuery:query
            ignoreResults:NO];
    }
}

- (void)sendSubmenuRequestWithQuery:(NSDictionary *)query indexPath:(NSIndexPath *)indexPath
{
    [self sendMessage:[self.mediaRequestGenerator mediaSubmenuRequestFromNode:query]
            isSubmenu:YES
             isTabBar:NO
            indexPath:indexPath
        originalQuery:query
        ignoreResults:NO];
}

- (void)sendBackCommand
{
    if (self.isSMS)
    {
        [self sendMessage:[self.mediaRequestGenerator backCommandWithLevel:1]
                isSubmenu:NO
                 isTabBar:NO
                indexPath:nil
            originalQuery:nil
            ignoreResults:NO];
    }
}

- (void)nextButtonPressed
{
    [self.sceneDelegate next];
}

- (void)sendQueueDeleteRequestWithQuery:(NSDictionary *)query
{
    SAVMediaRequest *request = [self.mediaRequestGenerator mediaRequestFromNode:query];
    request.query = @"deleteFromQueue";
    [self sendMessage:request isSubmenu:NO isTabBar:NO indexPath:nil originalQuery:nil ignoreResults:YES];
}

#pragma mark - View life cycle

- (void)viewDidAppear
{
    if (!self.hasRequestedRoot)
    {
        if (self.sceneDelegate && !self.sceneGUID)
        {
            self.mediaRequestGenerator.addSceneKey = YES;
            self.sceneGUID = [NSString stringWithFormat:@"savantqueue%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];

            SAVMediaRequest *request = [self.mediaRequestGenerator mediaRequest];
            request.query = @"TrainPreset";
            request.arguments = @{@"GUID": self.sceneGUID};
            [self sendMessage:request isSubmenu:NO isTabBar:NO indexPath:nil originalQuery:nil ignoreResults:YES];
        }

        self.hasRequestedRoot = YES;
        [self requestRoot];
    }
}

#pragma mark -

- (void)requestRoot
{
    SAVMediaRequest *request = self.mediaRequestGenerator.initialMenu;

    if (self.isNowPlaying)
    {
        request.query = @"nowPlaying";
    }

    [self sendMessage:request
            isSubmenu:NO
             isTabBar:NO
            indexPath:nil
        originalQuery:nil
        ignoreResults:NO];
}

- (void)sendMessage:(SAVMediaRequest *)request isSubmenu:(BOOL)isSubmenu isTabBar:(BOOL)isTabBar indexPath:(NSIndexPath *)indexPath originalQuery:(NSDictionary *)originalQuery ignoreResults:(BOOL)ignoreResults
{
    if (ignoreResults)
    {
        [[Savant control] sendMediaRequest:request];
        return;
    }

    if (self.outstandingMediaPromise)
    {
        [[Savant control] cancelMediaRequest:self.outstandingMediaPromise];
        self.outstandingMediaPromise = nil;
    }

    if (isTabBar)
    {
        [self.delegate presentTabBarLoadingIndicatorWithTitle:request.title];
    }

    self.outstandingMediaPromise = [[Savant control] sendMediaRequest:request];
    self.outstandingMediaPromise.callbackQueue = dispatch_get_main_queue();

    if (self.isSMS && [self.smsAutomaticBackTitles containsObject:originalQuery[SCUMediaModelKeyTitle]])
    {
        [self.delegate popNavigationController];
    }

    SAVWeakSelf;
    self.outstandingMediaPromise.successBlock = ^(NSArray *results) {

        BOOL handleScenes = NO;
        BOOL handleNavigation = NO;

        SAVStrongWeakSelf;
        if ([results count])
        {
            BOOL parseResults = YES;

            if ([results count] == 1)
            {
                NSDictionary *queryDict = [results firstObject];
                NSString *query = queryDict[SCUMediaModelKeyQuery];
                if ([query isEqualToString:@"showAlert"])
                {
                    [sSelf handleSMSSearch:queryDict];
                    return;
                }
                else if ([query isEqualToString:@"navigateToRoot"])
                {
                    [sSelf.delegate navigateToRoot];

                    handleScenes = YES;
                    parseResults = NO;
                    sSelf.hasRequestedRoot = NO;

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [sSelf.delegate reachedLeaf];

                        if (sSelf.sceneDelegate)
                        {
                            [sSelf.sceneDelegate reachedLeaf];
                        }
                    });
                }
            }

            if (parseResults)
            {
                SCUMediaPresentationStyle style = SCUMediaPresentationStyleTable;

                if (isSubmenu)
                {
                    style = SCUMediaPresentationStyleSubmenu;
                }

                if ([results count])
                {
                    NSDictionary *modelObject = [results firstObject];
                    NSString *displayType = modelObject[@"DisplayType"];

                    if ([displayType isEqualToString:@"BottomBar"] && !sSelf.sceneDelegate)
                    {
                        style = SCUMediaPresentationStyleTabBar;
                    }
                }

                if (style == SCUMediaPresentationStyleTabBar && !sSelf.sceneDelegate)
                {
                    SCUMediaTabBarModel *tabBarModel = [[SCUMediaTabBarModel alloc] initWithModelObjects:results mediaRequestModel:sSelf];
                    [sSelf.delegate presentTabBarWithModel:tabBarModel];
                    [tabBarModel transition];
                    sSelf.tabBarModel = tabBarModel;
                }
                else
                {
                    SCUMediaDataModel *tableModel = [[SCUMediaDataModel alloc] initWithModelObjects:results mediaModel:sSelf service:sSelf.service];
                    tableModel.scene = sSelf.sceneDelegate ? YES : NO;
                    [sSelf.delegate presentViewControllerWithPresentationStyle:style model:tableModel title:request.title];
                }
            }
        }
        else
        {
            handleScenes = YES;

            //-------------------------------------------------------------------
            // Terrible and fragile handling of account switching :-(
            //-------------------------------------------------------------------
            if (sSelf.isSMS && [request.title hasPrefix:@"Switch to "] && [[request.title componentsSeparatedByString:@" "] count] == 3)
            {
                [sSelf.delegate navigateToRoot];
                sSelf.hasRequestedRoot = NO;
            }
            else
            {
                handleNavigation = YES;
            }
        }

        if (handleScenes)
        {
            for (SAVService *service in sSelf.sceneDelegate.serviceGroup.services)
            {
                SAVSceneService *sceneService = [sSelf.sceneDelegate.sceneObject sceneServiceForService:service];

                if (sSelf.isSMS)
                {
                    if (sSelf.sceneGUID)
                    {
                        SAVMediaRequest *smsRecallRequest = [request copy];
                        smsRecallRequest.query = @"RecallQueue";
                        smsRecallRequest.arguments = @{@"QueueName": sSelf.sceneGUID};
                        sceneService.mediaNode = [smsRecallRequest dictionaryRepresentation];
                    }
                }
                else
                {
                    sceneService.mediaNode = [request dictionaryRepresentation];
                }
            }
        }

        if (handleNavigation)
        {
            [sSelf.delegate reachedLeaf];

            if (sSelf.sceneDelegate)
            {
                [sSelf.sceneDelegate reachedLeaf];
            }
        }

        sSelf.outstandingMediaPromise = nil;
    };
}

- (BOOL)handleSearch:(NSDictionary *)query withCallback:(SCUMediaRequestSearchCallback)callback
{
    BOOL isSearch = [SCUMediaDataModel isSearchNode:query];

    if (isSearch)
    {
        NSString *title = NSLocalizedString(@"Search", nil);
        NSString *message = NSLocalizedString(@"Enter your search term.", nil);
        NSString *confirmTitle = NSLocalizedString(@"Search", nil);

        if ([query[SCUMediaModelKeyTitle] isEqualToString:@"Save queue as playlist..."])
        {
            title = NSLocalizedString(@"New Playlist", nil);
            message = NSLocalizedString(@"Enter a name for this new playlist.", nil);
            confirmTitle = NSLocalizedString(@"Create", nil);
        }

        SCUTextEntryAlert *alert = [[SCUTextEntryAlert alloc] initWithTitle:title
                                                                    message:message
                                                              textEntryType:SCUTextEntryAlertFieldTypeDefault
                                                               buttonTitles:@[NSLocalizedString(@"Cancel", nil), confirmTitle]];

        SAVWeakVar(alert, sAlert);
        alert.callback = ^(NSUInteger buttonIndex) {

            if (buttonIndex == 0)
            {
                callback([self.mediaRequestGenerator mediaRequestFromNode:query]);
            }
            else
            {
                NSString *searchTerm = [sAlert textForFieldWithType:SCUTextEntryAlertFieldTypeDefault];
                callback([self.mediaRequestGenerator mediaRequestFromNode:query withSearchTerm:searchTerm]);
            }
        };

        [alert show];
    }

    return isSearch;
}

- (void)handleSMSSearch:(NSDictionary *)queryDict
{
    NSDictionary *arguments = queryDict[SCUMediaModelKeyQueryArguments];
    NSString *cancelButtonTitle = arguments[@"cancelButtonTitle"];
    NSArray *otherButtonTitles = arguments[@"otherButtonTitles"];
    NSString *title = queryDict[@"Title"];
    NSString *type = arguments[@"type"];
    NSArray *actions = arguments[@"actions"];
    NSString *realQuery = arguments[@"realQuery"];

    NSMutableArray *buttonTitles = [NSMutableArray array];

    if (cancelButtonTitle)
    {
        [buttonTitles addObject:cancelButtonTitle];
    }

    if ([otherButtonTitles count])
    {
        if ([otherButtonTitles count] == 1 && [[otherButtonTitles firstObject] isEqualToString:@"Search"])
        {
            NSString *buttonText = @"Search";

            if ([title sav_containsString:@"enter" options:NSCaseInsensitiveSearch] &&
                ([title sav_containsString:@"account" options:NSCaseInsensitiveSearch] ||
                 [title sav_containsString:@"email" options:NSCaseInsensitiveSearch] ||
                 [title sav_containsString:@"user" options:NSCaseInsensitiveSearch] ||
                 [title sav_containsString:@"password" options:NSCaseInsensitiveSearch]))
            {
                buttonText = @"Sign In";

                if ([title sav_containsString:@"submit" options:NSCaseInsensitiveSearch])
                {
                    buttonText = @"Submit";
                }
            }

            [buttonTitles addObject:buttonText];
        }
        else
        {
            [buttonTitles addObjectsFromArray:otherButtonTitles];
        }
    }

    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

    for (NSUInteger i = 0; i < [otherButtonTitles count]; i++)
    {
        [indexSet addIndex:i + 1];
    }

    if ([type isEqualToString:@"input"])
    {
        SCUTextEntryAlertFieldType entryType = SCUTextEntryAlertFieldTypeDefault;

        if ([title sav_containsString:@"password" options:NSCaseInsensitiveSearch])
        {
            entryType = SCUTextEntryAlertFieldTypeSecure;
        }

        SCUTextEntryAlert *alert = [[SCUTextEntryAlert alloc] initWithTitle:@""
                                                                    message:title
                                                              textEntryType:entryType
                                                               buttonTitles:buttonTitles];

        alert.primaryButtons = indexSet;

        SAVWeakVar(alert, wAlert);
        SAVWeakSelf;
        alert.callback = ^(NSUInteger buttonIndex) {

            SAVStrongWeakSelf;
            if (buttonIndex == 0)
            {
                if ([actions count])
                {
                    NSString *action = [actions firstObject];
                    NSDictionary *dictionary = @{SCUMediaModelKeyQuery: action};
                    [sSelf sendRequestWithQuery:dictionary];

                    if (sSelf.isSMS && [action containsString:@"CANCEL"])
                    {
                        [sSelf.delegate navigateToRoot];
                        [sSelf requestRoot];
                        return;
                    }
                }

                [sSelf.delegate reachedLeaf];
            }
            else
            {
                NSString *inputText = [wAlert textForFieldWithType:entryType];
                NSMutableDictionary *args = [arguments mutableCopy];
                args[@"search"] = inputText;
                args[@"buttonIndex"] = @(buttonIndex);
                NSDictionary *dictionary = @{SCUMediaModelKeyQueryArguments: args,
                                             SCUMediaModelKeyQuery: realQuery};

                [sSelf sendRequestWithQuery:dictionary];
            }
        };
        
        [alert show];
    }
}

@end
