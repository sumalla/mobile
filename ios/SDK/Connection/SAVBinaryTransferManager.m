//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2014 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2014 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2014 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

#import "SAVBinaryTransferManager.h"
#import "SAVControl.h"
#import "SAVControlPrivate.h"
#import "rpmTar.h"
#import "RPMCommunicationConstants.h"
#import "rpmSharedLogger.h"
#import "Savant.h"
@import Extensions;
#import <zlib.h>

@protocol TGZProgressDelegate <NSObject>

- (void)didReceiveDecompressionUpdate:(float)progress;

@end

@interface NSFileManager (TGZ)

- (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withTargzPath:(NSString *)targz delegate:(id<TGZProgressDelegate>)delegate error:(NSError *__autoreleasing*)error;

@end

@interface SAVDownload : NSObject

@property (nonatomic) NSFileHandle *fileHandle;
@property (nonatomic) NSString *path;
@property (nonatomic) NSUInteger fileSize;
@property (nonatomic) NSUInteger bytesReceived;

@end

@implementation SAVDownload

@end

@interface SAVBinaryTransferManager () <TGZProgressDelegate>

@property (nonatomic) NSMutableDictionary *downloadForIdentifier;
@property (nonatomic) BOOL configDownloadInProgress;
@property (nonatomic) NSMutableDictionary *cameraImages;
@property (nonatomic) NSMutableDictionary *binaryTransfers;
@property (nonatomic) NSMutableDictionary *pathDownloads;

@end

@implementation SAVBinaryTransferManager

- (id)init
{
    self = [super init];

    if (self)
    {
        self.downloadForIdentifier = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)updateDownloadWithIdentifier:(NSString *)identifier data:(NSData *)data expectedLength:(NSUInteger)expectedLength complete:(BOOL)complete type:(NSUInteger)type
{
    switch (type)
    {
        case RPM_WEBSOCKET_FILEUPLOAD_TYPE:
        {
            if ([identifier isEqual:SAVMESSAGE_CONFIG_PATH])
            {
                [self handleConfigDownloadWithIdentifier:identifier data:data expectedLength:expectedLength complete:complete];
            }
            else
            {
                [self handleBinaryTransferWithIdentifier:identifier data:data expectedLength:expectedLength complete:complete];
            }

            break;
        }
        case RPM_WEBSOCKET_SECURITYCAM_TYPE:
        case RPM_WEBSOCKET_SAVANTCAM_TYPE:
        {
            [self handleCameraTransferWithIdentifier:identifier data:data expectedLength:expectedLength complete:complete];
            break;
        }
        default:
            RPMLogErr(@"Received a binary message with unexpected type: '%02lx'", (unsigned long)type);
            break;
    }
}

- (void)invalidate
{
    for (NSString *identifier in self.downloadForIdentifier)
    {
        SAVDownload *download = self.downloadForIdentifier[identifier];
        [download.fileHandle closeFile];
    }
}

#pragma mark - TGZProgressDelegate

- (void)didReceiveDecompressionUpdate:(float)progress
{
    dispatch_async_main(^{
        [[Savant control] connectionDidReceiveConfigurationDownloadUpdate:progress isInstalling:YES];

        if (progress >= 1)
        {
            [self.configDelegate transferManagerDidFinishUntarringConfig:self];
        }
    });
}

#pragma mark -

- (void)handleConfigDownloadWithIdentifier:(NSString *)identifier data:(NSData *)data expectedLength:(NSUInteger)expectedLength complete:(BOOL)complete
{
    if (!self.configDownloadInProgress)
    {
        self.configDownloadInProgress = YES;

        dispatch_async_main(^{
            [[Savant control] connectionDidStartConfigurationDownload];
        });

        SAVDownload *download = self.downloadForIdentifier[identifier];

        if (download)
        {
            [download.fileHandle closeFile];
        }

        download = [[SAVDownload alloc] init];
        download.fileSize = expectedLength;
        self.downloadForIdentifier[identifier] = download;

        download.path = [NSTemporaryDirectory() stringByAppendingPathComponent:identifier];

        if ([[NSFileManager defaultManager] fileExistsAtPath:download.path])
        {
            [[NSFileManager defaultManager] removeItemAtPath:download.path error:nil];
        }
        [[NSFileManager defaultManager] createFileAtPath:download.path contents:nil attributes:nil];
        download.fileHandle = [NSFileHandle fileHandleForWritingAtPath:download.path];
    }

    SAVDownload *download = self.downloadForIdentifier[identifier];
    download.bytesReceived += [data length];
    [download.fileHandle writeData:data];

    dispatch_async_main(^{
        [[Savant control] connectionDidReceiveConfigurationDownloadUpdate:((float)download.bytesReceived / (float)download.fileSize) isInstalling:NO];
    });

    if (complete)
    {
        self.configDownloadInProgress = NO;

        SAVDownload *iDownload = self.downloadForIdentifier[identifier];
        [iDownload.fileHandle synchronizeFile];
        [iDownload.fileHandle closeFile];

        NSString *outputPath = [[Savant control] systemPathForUID:[Savant control].currentSystem.hostID];

        [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:outputPath withTargzPath:iDownload.path delegate:self error:nil];

        if ([[NSFileManager defaultManager] fileExistsAtPath:iDownload.path])
        {
            [[NSFileManager defaultManager] removeItemAtPath:iDownload.path error:nil];
        }

        [self.downloadForIdentifier removeObjectForKey:identifier];
    }
}

- (void)handleBinaryTransferWithIdentifier:(NSString *)identifier data:(NSData *)data expectedLength:(NSUInteger)expectedLength complete:(BOOL)complete
{
    if (!identifier)
    {
        //-------------------------------------------------------------------
        // CBP TODO: Fix.
        //-------------------------------------------------------------------
        return;
    }

    if (!self.binaryTransfers)
    {
        self.binaryTransfers = [NSMutableDictionary dictionary];
    }

    NSMutableData *transferData = self.binaryTransfers[identifier];
    SAVDownload *transferDownload = self.pathDownloads[identifier];

    if (transferData)
    {
        [transferData appendData:data];
    }
    else if (transferDownload)
    {
        [transferDownload.fileHandle writeData:data];
        transferDownload.bytesReceived += [data length];
    }
    else
    {
        NSString *filePath = nil;

        for (id<ConnectionBinaryTransferDelegate> observer in [Savant control].binaryTransferObservers)
        {
            if ([observer respondsToSelector:@selector(filePathForBinaryTransferWithIdentifier:)])
            {
                filePath = [observer filePathForBinaryTransferWithIdentifier:identifier];

                if (filePath)
                {
                    break;
                }
            }
        }

        if (filePath)
        {
            if (!self.pathDownloads)
            {
                self.pathDownloads = [NSMutableDictionary dictionary];
            }

            SAVDownload *download = self.pathDownloads[identifier];

            if (download)
            {
                [download.fileHandle synchronizeFile];
                [download.fileHandle closeFile];
            }

            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }

            [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];

            download = [[SAVDownload alloc] init];
            download.path = filePath;
            download.fileSize = expectedLength;
            download.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            self.pathDownloads[identifier] = download;

            [download.fileHandle writeData:data];
            download.bytesReceived += [data length];
        }
        else
        {
            transferData = [NSMutableData dataWithData:data];
            self.binaryTransfers[identifier] = transferData;
        }

        dispatch_async_main(^{
            for (id<ConnectionBinaryTransferDelegate> observer in [Savant control].binaryTransferObservers)
            {
                if ([observer respondsToSelector:@selector(didStartBinaryTransferForIdentifier:withSize:)])
                {
                    [observer didStartBinaryTransferForIdentifier:identifier withSize:expectedLength];
                }
            }
        });
    }

    if (complete)
    {
        if (transferData)
        {
            dispatch_async_main(^{
                for (id<ConnectionBinaryTransferDelegate> observer in [Savant control].binaryTransferObservers)
                {
                    if ([observer respondsToSelector:@selector(didFinishBinaryTransferWithData:forIdentifier:)])
                    {
                        [observer didFinishBinaryTransferWithData:transferData forIdentifier:identifier];
                    }
                }
            });
        }
        else if (transferDownload)
        {
            [transferDownload.fileHandle synchronizeFile];
            [transferDownload.fileHandle closeFile];
            
            dispatch_async_main(^{
                for (id<ConnectionBinaryTransferDelegate> observer in [Savant control].binaryTransferObservers)
                {
                    if ([observer respondsToSelector:@selector(didFinishBinaryTransferWithFilePath:forIdentifier:)])
                    {
                        [observer didFinishBinaryTransferWithFilePath:transferDownload.path forIdentifier:identifier];
                    }
                }
            });
        }

        [self.binaryTransfers removeObjectForKey:identifier];
        [self.pathDownloads removeObjectForKey:identifier];
    }
}

- (void)handleCameraTransferWithIdentifier:(NSString *)camera data:(NSData *)chunk expectedLength:(NSUInteger)expectedLength complete:(BOOL)complete
{
    id <CameraFetchDelegate> observer = [[Savant control].cameraObservers objectForKey:camera];

    if (observer)
    {
        if (!self.cameraImages)
        {
            self.cameraImages = [[NSMutableDictionary alloc] init];
        }

        if (!self.cameraImages[camera])
        {
            self.cameraImages[camera] = [chunk mutableCopy];
        }
        else
        {
            [self.cameraImages[camera] appendData:chunk];
        }

        if (complete)
        {
            NSData *imageData = [self.cameraImages[camera] copy];
            dispatch_async_main(^{
                [observer didReceiveImageData:imageData forSession:camera];
            });

            [self.cameraImages removeObjectForKey:camera];
        }
    }
}

@end

@implementation NSFileManager (TGZ)

- (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withTargzPath:(NSString *)targz delegate:(id<TGZProgressDelegate>)delegate error:(NSError *__autoreleasing*)error
{
    @autoreleasepool
    {
        rpmTar *untar = [[rpmTar alloc] initWithOutputPath:path];

        if (![self fileExistsAtPath:targz])
        {
            return NO;
        }

        FILE *pFile = fopen([targz UTF8String], "rb");
        fseek (pFile, 0, SEEK_END);
        long gzSize = ftell(pFile);
        fclose (pFile);

        gzFile infile = gzopen([targz UTF8String], "rb");

        if (!infile)
        {
            return NO;
        }

        char buffer[10240];

        while ((gzread(infile, buffer, sizeof(buffer))) > 0)
        {
            @autoreleasepool
            {
                NSData *bigTarBlock = [NSData dataWithBytes:buffer length:sizeof(buffer)];

                for (unsigned int offset = 0; offset < sizeof(buffer); offset = offset + TAR_BLOCKSIZE)
                {
                    NSData *tarBlock = [bigTarBlock subdataWithRange: NSMakeRange(offset, TAR_BLOCKSIZE)];
                    if (![untar processBlock:tarBlock])
                    {
                        gzclose(infile);
                        return NO;
                    }
                }
            }


            long offset = gzoffset(infile);
            float progress = (float)offset / (float)gzSize;

            if (progress == 1)
            {
                progress = (float).999;
            }

            [delegate didReceiveDecompressionUpdate:progress];
        }

        [delegate didReceiveDecompressionUpdate:1];
        
        gzclose(infile);
    }
    
    return YES;
}

@end
