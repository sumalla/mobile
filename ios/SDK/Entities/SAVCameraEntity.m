//
//  SAVCameraEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVCameraEntity.h"
#import "SAVServiceRequest.h"
#import "rpmSharedLogger.h"
#import "SAVControl.h"
#import "SAVMessages.h"
@import Extensions;
#import "RPMSecurityCameraFetcher.h"
#import "rpmThreadUtils.h"
#import "Savant.h"

@interface SAVCameraEntity () <CameraFetchDelegate, RPMSecurityCameraFetcherDelegate, SystemStatusDelegate>

@property RPMSecurityCameraFetcher *previewFetcher;
@property RPMSecurityCameraFetcher *fullscreenFetcher;
@property NSHashTable *observers;

@property (nonatomic) BOOL connectedRemotely;

@property SAVCameraEntityFetchState previewFetchState;
@property SAVCameraEntityFetchState fullscreenFetchState;

@end

@implementation SAVCameraEntity

static NSUInteger livingCameraCount;

static NSThread *cameraThread = nil;

+ (NSThread *)sharedCameraThread
{
    if (!cameraThread || cameraThread.isCancelled)
    {
        cameraThread = [rpmThreadUtils runningThread];
        cameraThread.name = @"SAVCameraEntity Fetch";
    }

    return cameraThread;
}

+ (void)stopSharedThread
{
    [rpmThreadUtils stopThread:cameraThread];
    cameraThread = nil;
}

- (void)dealloc
{
    [self stopPreviewStream];
    [self stopFullscreenStream];

    livingCameraCount--;

    if (!livingCameraCount)
    {
        [SAVCameraEntity stopSharedThread];
    }

    [[Savant control] removeSystemStatusObserver:self];
}

- (SAVEntity *)initWithRoomName:(NSString *)room zoneName:(NSString *)zone service:(SAVService *)service
{
    self = [super initWithRoomName:room zoneName:zone service:service];
    if (self)
    {
        livingCameraCount++;

        self.observers = [NSHashTable weakObjectsHashTable];

        [[Savant control] addSystemStatusObserver:self];
    }
    return self;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    switch (event)
    {
        case SAVEntityEvent_ZoomIn:
            serviceRequest.request = @"ZoomIn";
            break;
        case SAVEntityEvent_ZoomOut:
            serviceRequest.request = @"ZoomOut";
            break;
        case SAVEntityEvent_TiltUp:
            serviceRequest.request = @"TiltUp";
            break;
        case SAVEntityEvent_TiltDown:
            serviceRequest.request = @"TiltDown";
            break;
        case SAVEntityEvent_PanLeft:
            serviceRequest.request = @"PanLeft";
            break;
        case SAVEntityEvent_PanRight:
            serviceRequest.request = @"PanRight";
            break;
        case SAVEntityEvent_IrisOpen:
            serviceRequest.request = @"IrisOpen";
            break;
        case SAVEntityEvent_IrisClose:
            serviceRequest.request = @"IrisClose";
            break;
        default:
            RPMLogErr(@"Unexpected event type for Camera entity %ld", (long)event);
            break;
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (void)startPreviewStream
{
    if (self.previewFetchState == SAVCameraEntityFetchState_Stopped)
    {
        [self performSelector:@selector(createPreviewFetcher)
                     onThread:[SAVCameraEntity sharedCameraThread]
                   withObject:nil
                waitUntilDone:YES];

        [self.previewFetcher fetchWithFrequency:@60 forObserver:self];

        self.previewFetchState = SAVCameraEntityFetchState_Local;

        //-------------------------------------------------------------------
        // If we're connected remotely, start the remote stream immediately
        //-------------------------------------------------------------------
        if (self.connectedRemotely)
        {
            [self startRemoteStreamForScale:SAVCameraEntityScale_Preview];
        }
    }
}

- (void)createPreviewFetcher
{
    if (!self.previewFetcher)
    {
        self.previewFetcher = [[RPMSecurityCameraFetcher alloc] initWithPath:[self.previewURL absoluteString] cameraName:[NSString stringWithFormat:@"%@-%@", self.service.component, self.service.logicalComponent]];
    }
}

- (void)stopPreviewStream
{
    if (self.previewFetchState != SAVCameraEntityFetchState_Stopped)
    {
        [self.previewFetcher stopFetchingForObserver:self];

        //-------------------------------------------------------------------
        // If we're fetching remotely, stop the remote stream
        //-------------------------------------------------------------------
        if (self.previewFetchState == SAVCameraEntityFetchState_Remote)
        {
            [self stopRemoteStreamForScale:SAVCameraEntityScale_Preview];
        }

        self.previewFetchState = SAVCameraEntityFetchState_Stopped;
    }
}

- (void)startFullscrenStream
{
    //-------------------------------------------------------------------
    // Only start fetching if fetching is currently stopped.
    //-------------------------------------------------------------------
    if (self.fullscreenFetchState == SAVCameraEntityFetchState_Stopped)
    {
        [self performSelector:@selector(createFullscreenFetcher)
                     onThread:[SAVCameraEntity sharedCameraThread]
                   withObject:nil
                waitUntilDone:YES];

        [self.fullscreenFetcher fetchWithFrequency:@60 forObserver:self];

        self.fullscreenFetchState = SAVCameraEntityFetchState_Local;

        //-------------------------------------------------------------------
        // If we're connected remotely, start the remote stream immediately
        //-------------------------------------------------------------------
        if (self.connectedRemotely)
        {
            [self startRemoteStreamForScale:SAVCameraEntityScale_Fullscreen];
        }
    }
}

- (void)createFullscreenFetcher
{
    if (!self.fullscreenFetcher)
    {
        self.fullscreenFetcher = [[RPMSecurityCameraFetcher alloc] initWithPath:[self.fullscreenURL absoluteString] cameraName:[NSString stringWithFormat:@"%@-%@", self.service.component, self.service.logicalComponent]];
    }
}

- (void)stopFullscreenStream
{
    if (self.fullscreenFetchState != SAVCameraEntityFetchState_Stopped)
    {
        [self.fullscreenFetcher stopFetchingForObserver:self];

        //-------------------------------------------------------------------
        // If we're fetching remotely, stop the remote stream
        //-------------------------------------------------------------------
        if (self.fullscreenFetchState == SAVCameraEntityFetchState_Remote)
        {
            [self stopRemoteStreamForScale:SAVCameraEntityScale_Fullscreen];
        }

        self.fullscreenFetchState = SAVCameraEntityFetchState_Stopped;
    }
}

- (SAVCameraStreamRequest *)cameraStreamRequestForAction:(SAVCameraStreamAction)action
{
    SAVCameraStreamRequest *request = nil;

    if (self.service.component && self.service.logicalComponent)
    {
        request = [[SAVCameraStreamRequest alloc] init];
        request.action = action;
        request.component = self.service.component;
        request.logicalComponent = self.service.logicalComponent;
    }

    return request;
}

- (SAVCameraEntityFormat)formatFromString:(NSString *)formatString
{
    SAVCameraEntityFormat format = SAVCameraEntityFormat_Unknown;

    NSString *lcFormat = [formatString lowercaseString];

    if ([lcFormat isEqualToString:@"mjpg"] || [lcFormat isEqualToString:@"mjpeg"])
    {
        format = SAVCameraEntityFormat_MJPG;
    }
    else if ([lcFormat isEqualToString:@"jpg"])
    {
        format = SAVCameraEntityFormat_JPG;
    }

    //-------------------------------------------------------------------
    // TODO: Handle H264 formats
    //-------------------------------------------------------------------

    return format;
}

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    SAVEntityType type = SAVEntityType_Unknown;

    if ([typeString isEqualToString:@"PTZ"])
    {
        type = SAVEntityType_PTZ;
    }
    else if ([typeString isEqualToString:@"Fixed"])
    {
        type = SAVEntityType_Fixed;
    }

    return type;
}

- (SAVCameraEntityFetchState)fetchStateForScale:(SAVCameraEntityScale)scale
{
    SAVCameraEntityFetchState state = SAVCameraEntityFetchState_Unknown;

    if (scale & SAVCameraEntityScale_Fullscreen)
    {
        state = self.fullscreenFetchState;
    }

    if (scale & SAVCameraEntityScale_Preview)
    {
        state = self.previewFetchState;
    }

    return state;
}

- (SAVCameraEntityScale)scaleFromFetcher:(RPMSecurityCameraFetcher *)fetcher
{
    SAVCameraEntityScale scale = SAVCameraEntityScale_Preview | SAVCameraEntityScale_Fullscreen;

    if (fetcher == self.previewFetcher)
    {
        scale = SAVCameraEntityScale_Preview;
    }
    else if (fetcher == self.fullscreenFetcher)
    {
        scale = SAVCameraEntityScale_Fullscreen;
    }

    return scale;
}

#pragma mark - Internal

/**
 *  Starting the remote stream increments a reference count on the host, this can be done multiple times.
 */
- (void)startRemoteStreamForScale:(SAVCameraEntityScale)scale
{
    if ((scale & SAVCameraEntityScale_Fullscreen) && (self.fullscreenFetchState == SAVCameraEntityFetchState_Local))
    {
        self.fullscreenFetchState = SAVCameraEntityFetchState_Remote;
        self.previewFetchState = SAVCameraEntityFetchState_Remote;

        [self sendStartFullscreenRemoteStream];
    }
    else if ((scale & SAVCameraEntityScale_Preview) && (self.previewFetchState == SAVCameraEntityFetchState_Local))
    {
        self.previewFetchState = SAVCameraEntityFetchState_Remote;

        [self sendStartPreviewRemoteStream];
    }
}

- (void)sendStartFullscreenRemoteStream
{
    if ([Savant control].isConnectedToSystem)
    {
        RPMLogInfo(@"Start remote stream for camera %@", self.label);
        SAVCameraStreamRequest *request = [self cameraStreamRequestForAction:SAVCameraStreamAction_StartFetch];
        request.large = YES;
        request.frequency = self.fullscreenFramerate;
        
        if (request)
        {
            [[Savant control] sendMessage:request];
        }
    }
}

- (void)sendStartPreviewRemoteStream
{
    if ([Savant control].isConnectedToSystem)
    {
        RPMLogInfo(@"Start remote preview stream for camera %@", self.label);
        SAVCameraStreamRequest *request = [self cameraStreamRequestForAction:SAVCameraStreamAction_StartFetch];
        request.frequency = self.previewFramerate;

        if (request)
        {
            [[Savant control] sendMessage:request];
        }
    }
}

/**
 *  Stopping the remote stream decrements a reference count on the host. The stream will continue until this reaches zero.
 */
- (void)stopRemoteStreamForScale:(SAVCameraEntityScale)scale
{
    BOOL sendStop = NO;

    if ((scale & SAVCameraEntityScale_Fullscreen) && (self.fullscreenFetchState == SAVCameraEntityFetchState_Remote))
    {
        self.fullscreenFetchState = SAVCameraEntityFetchState_Local;
        sendStop = YES;
    }

    if ((scale & SAVCameraEntityScale_Preview) && (self.previewFetchState == SAVCameraEntityFetchState_Remote))
    {
        self.previewFetchState = SAVCameraEntityFetchState_Local;

        if (self.fullscreenFetchState != SAVCameraEntityFetchState_Remote)
        {
            sendStop = YES;
        }
    }


    if (sendStop)
    {
        if (self.previewFetchState == SAVCameraEntityFetchState_Remote)
        {
            [self sendStartPreviewRemoteStream];
        }
        else
        {
            [self sendStopRemoteStream];
        }
    }
}

- (void)sendStopRemoteStream
{
    if ([Savant control].isConnectedToSystem)
    {
        RPMLogInfo(@"Stop remote stream for camera %@", self.label);
        SAVCameraStreamRequest *request = [self cameraStreamRequestForAction:SAVCameraStreamAction_StopFetch];
        if (request)
        {
            [[Savant control] sendMessage:request];
        }
    }
}

- (void)receivedImage:(NSData *)imageData scale:(SAVCameraEntityScale)scale
{
    UIImage *cameraImage = [[UIImage alloc] initWithData:imageData];
    if (cameraImage)
    {
        for (id <SAVCameraEntityDelegate> ob in self.observers)
        {
            [ob receivedImage:cameraImage ofScale:scale fromEntity:self];
        }
    }
}

#pragma mark - RPMSecurityCameraFetcher Delegate

- (void)didReceiveImageData:(NSData *)imageData fromFetcher:(RPMSecurityCameraFetcher *)fetcher
{
    dispatch_async_main(^{
        SAVCameraEntityScale scale = [self scaleFromFetcher:fetcher];

        [self stopRemoteStreamForScale:scale];

        //-------------------------------------------------------------------
        // Only send updates from local fetcher to local clients
        //-------------------------------------------------------------------
        if ([self fetchStateForScale:scale] == SAVCameraEntityFetchState_Local)
        {
            [self receivedImage:imageData scale:scale];
            [fetcher transferCompleteForObserver:self];
        }
    });
}

- (void)failedToFetchImageDataFromFetcher:(RPMSecurityCameraFetcher *)fetcher
{
    dispatch_async_main(^{
        [self startRemoteStreamForScale:[self scaleFromFetcher:fetcher]];
    });
}

- (BOOL)waitForTransferCompletion
{
    return YES;
}

#pragma mark - Camera Fetch Delegate

- (NSString *)registeredName
{
    //-------------------------------------------------------------------
    // TODO: register with component-logicalComponent
    //-------------------------------------------------------------------
    return [self.service.component stringByAppendingFormat:@"-%@", self.service.logicalComponent];
}

- (void)didReceiveImageData:(NSData *)imageData forSession:(NSString *)sesion
{
    //-------------------------------------------------------------------
    // Only send updates from websocket if we're fetching remotely
    //-------------------------------------------------------------------
    if (([self fetchStateForScale:SAVCameraEntityScale_Preview] == SAVCameraEntityFetchState_Remote) ||
        ([self fetchStateForScale:SAVCameraEntityScale_Fullscreen] == SAVCameraEntityFetchState_Remote))
    {
        [self receivedImage:imageData scale:SAVCameraEntityScale_Preview | SAVCameraEntityScale_Fullscreen];
    }
}

#pragma mark - SystemStatusObserver

- (void)connectionDidChangeToState:(SAVConnectionState)state
{
    switch (state)
    {
        case SAVConnectionStateNotConnected:
        case SAVConnectionStateLocal:
            self.connectedRemotely = NO;
            break;
        case SAVConnectionStateCloud:
            self.connectedRemotely = YES;
            break;
    }
}

#pragma mark - Observers

- (void)addObserver:(id <SAVCameraEntityDelegate>)observer
{
    [self.observers addObject:observer];

    if ([self.observers count])
    {
        [[Savant control] addCameraObserver:self];
    }
}

- (void)removeObserver:(id <SAVCameraEntityDelegate>)observer
{
    [self.observers removeObject:observer];

    if (![self.observers count])
    {
        [[Savant control] removeCameraObserver:self];
    }
}

#pragma mark - Properties

- (void)setConnectedRemotely:(BOOL)connectedRemotely
{
    if (connectedRemotely != _connectedRemotely)
    {
        _connectedRemotely = connectedRemotely;

        if (connectedRemotely)
        {
            [self startRemoteStreamForScale:SAVCameraEntityScale_Preview | SAVCameraEntityScale_Fullscreen];
        }
        else
        {
            [self stopRemoteStreamForScale:SAVCameraEntityScale_Preview | SAVCameraEntityScale_Fullscreen];
        }
    }
}

- (BOOL)hasPTZ
{
    return (self.type == SAVEntityType_PTZ);
}

@end
