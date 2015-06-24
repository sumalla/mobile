//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2013 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2013 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2013 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Art Jacobson
//
// DESCRIPTION:
//
//====================================================================

//##OBJCLEAN_SKIP##

#import "RPMDiscoveryScanner.h"
@import Darwin.POSIX.arpa.inet;
#include <ifaddrs.h>
@import Darwin.POSIX.poll;

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/rpmFoundationExtensions.h>
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmGeneralUtils/MessagePack.h>
#else
#import "MessagePack.h"
#import "rpmSharedLogger.h"

#endif

@interface RPMDiscoveryScanner ()

@property (readwrite, copy) NSDictionary *previousEndpoints;
@property (readwrite, retain) NSMutableDictionary *currentEndpoints;
@property (readwrite, assign) NSThread *scannerThread;
@property (readwrite, assign) NSThread *delegateThread;
@property (readwrite, assign) BOOL shouldExit;

- (void)_startScan;
- (void)_scanLocalNetwork;
- (void)_scanAddress: (NSString*)address;
- (void)_processResponse: (NSDictionary*)response;
- (void)_stop;
- (void)_updateEndpointList;

@end

void discoveryScannerReadCallback(CFSocketRef s,
                                  CFSocketCallBackType callbackType,
                                  CFDataRef address,
                                  const void *data,
                                  void *info)
{
    @try
    {
        if (callbackType == kCFSocketDataCallBack)
        {
            NSMutableDictionary *response = [MessagePackParser parseData:(NSData *)data]; /* Yes, this is actually a CFDataRef. */
            
            if ([response isKindOfClass:[NSMutableDictionary class]])
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-align"
                struct sockaddr_in * serv_addr = (struct sockaddr_in *)CFDataGetBytePtr(address);
#pragma clang diagnostic pop
                
                NSString *ip = [NSString stringWithCString:inet_ntoa(serv_addr->sin_addr)
                                                  encoding:NSUTF8StringEncoding];
                
                if (ip)
                {
                    [response setObject:ip forKey:RPM_DISCOVERY_IP_KEY];
                    
                    RPMDiscoveryScanner *scanner = (RPMDiscoveryScanner*)info;
                    [scanner _processResponse:response];
                }
                else
                {
                    RPMLogErr(@"Discovery scanner could not parse ip");
                }
            }
            else
            {
                RPMLogErr(@"Discovery scanner could not parse scan response with object class: '%@'", [response class]);
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-exception-parameter"
    @catch (NSException *exception)
    {
        ;
    }
#pragma clang diagnostic pop
}

@implementation RPMDiscoveryScanner

@synthesize delegate=_delegate;
@synthesize previousEndpoints=_previousEndpoints;
@synthesize currentEndpoints=_currentEndpoints;
@synthesize scannerThread=_scannerThread;
@synthesize delegateThread=_delegateThread;
@synthesize shouldExit=_shouldExit;

- (void)dealloc
{
    [_previousEndpoints release];
    [_currentEndpoints release];
    [super dealloc];
}

- (void)startScan
{
    @synchronized (self)
    {
        if (!self.delegateThread)
        {
            self.delegateThread = [NSThread currentThread];
            [NSThread detachNewThreadSelector:@selector(_startScan) toTarget:self withObject:nil];
        }
    }
}

- (void)stopScan
{
    @synchronized (self)
    {
        if (self.delegateThread)
        {
            if (self.scannerThread)
            {
                [self performSelector:@selector(_stop)
                             onThread:self.scannerThread
                           withObject:nil
                        waitUntilDone:YES];

                self.scannerThread = nil;
            }

            self.previousEndpoints = nil;
            self.currentEndpoints = nil;
            self.delegateThread = nil;
        }
    }
}

- (void)_startScan
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    self.previousEndpoints = [NSDictionary dictionary];
    self.currentEndpoints = [NSMutableDictionary dictionary];
    
    self.scannerThread = [NSThread currentThread];
    
    struct sockaddr_in cliAddr;
    
    bzero((char*)&cliAddr,sizeof(cliAddr));
    cliAddr.sin_family = AF_INET;
    cliAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    cliAddr.sin_port = htons(0);
    
    _s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    bind(_s,(struct sockaddr *)&cliAddr,sizeof(cliAddr));
    int optVal = 1;
    setsockopt(_s, SOL_SOCKET, SO_BROADCAST, &optVal, sizeof(optVal));
    
    
    CFSocketContext socketContext;
    bzero(&socketContext, sizeof(socketContext));
    socketContext.info = self;
    
    _socketRef = CFSocketCreateWithNative(nil, _s, kCFSocketDataCallBack, discoveryScannerReadCallback, &socketContext);
    CFRunLoopSourceRef _runloopSourceRef = CFSocketCreateRunLoopSource(NULL, _socketRef, 1);
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop],
                       _runloopSourceRef,
                       kCFRunLoopCommonModes);
    CFRelease(_runloopSourceRef);
    
    [self _scanLocalNetwork];
    
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    
    while (!self.shouldExit)
    {
        [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    [pool release];
}

- (void)_stop
{
    self.shouldExit = YES;

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(_updateEndpointList)
                                               object:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(_scanLocalNetwork)
                                               object:nil];
    
    CFSocketInvalidate(_socketRef);
    CFRelease(_socketRef);
    _socketRef = NULL;
}

- (void)_scanLocalNetwork
{
    struct ifaddrs *ifap;
    struct ifaddrs *ifa;
    struct sockaddr_in *sa;
    struct sockaddr_in *sn;
    getifaddrs(&ifap);
    
    for (ifa=ifap; ifa; ifa = (struct ifaddrs *)ifa->ifa_next)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-align"
        sa = (struct sockaddr_in *)ifa->ifa_addr;
        sn = (struct sockaddr_in *)ifa->ifa_netmask;
#pragma clang diagnostic pop
        if (sa->sin_family != AF_INET)
            continue;
        if(ifa->ifa_name == NULL)
            continue;
        if(strcmp(ifa->ifa_name,"lo0") == 0)
            continue;
        if(ifa->ifa_addr == NULL)
            continue;
        
        //--------------------------------------------------------------------
        // Compute broadcast address for the subnet
        //--------------------------------------------------------------------
        sn->sin_addr.s_addr = ~sn->sin_addr.s_addr | sa->sin_addr.s_addr;
        NSString *broadcastAddress = [NSString stringWithFormat: @"%s", inet_ntoa(sn->sin_addr)];
        [self _scanAddress:broadcastAddress];
    }
    
    freeifaddrs(ifap);
    
    if (!self.shouldExit)
    {
        [self performSelector:_cmd withObject:nil afterDelay:5.0];
    }
    
    [self performSelector:@selector(_updateEndpointList) withObject:nil afterDelay:0.5];
}

- (void)_scanAddress: (NSString*)address
{
    struct sockaddr_in  hostAddress;
    bzero((char*)&hostAddress,sizeof(hostAddress));
    
    //--------------------------------------------------------------------
    // Interperet host as ipv4 address
    //--------------------------------------------------------------------
    hostAddress.sin_addr.s_addr = inet_addr([address cStringUsingEncoding:NSASCIIStringEncoding]);
    hostAddress.sin_family = AF_INET;
    hostAddress.sin_port = htons(RPM_DISCOVERY_SERVER_PORT);
    
    NSDictionary *scanMessage = [NSDictionary dictionaryWithObject:@"_control_.ws" forKey:@"service"];
    NSData *dataToSend = [MessagePackPacker pack:scanMessage];
    
    sendto(_s, [dataToSend bytes], [dataToSend length], 0, (struct sockaddr *)&hostAddress, sizeof(hostAddress));
}

- (void)_processResponse: (NSDictionary*)response
{
    NSString *address = [NSString stringWithFormat:@"%@:%@", [response objectForKey: RPM_DISCOVERY_IP_KEY], [response objectForKey: RPM_DISCOVERY_PORT_KEY]];
    [self.currentEndpoints setObject:response forKey:address];
}

- (void)_updateEndpointList
{
    //-------------------------------------------------------------------
    // Find new/updated endpoints.
    //-------------------------------------------------------------------
    for (NSString *address in self.currentEndpoints)
    {
        NSDictionary *currentEndpoint = [self.currentEndpoints objectForKey:address];
        NSDictionary *previousEndpoint = [self.previousEndpoints objectForKey:address];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(lostSavantEndpoint:) object:previousEndpoint];
        
        if (!previousEndpoint)
        {
            if ([self.delegate respondsToSelector:@selector(foundSavantEndpoint:)])
            {
                [self.delegate performSelector:@selector(foundSavantEndpoint:)
                                      onThread:self.delegateThread
                                    withObject:[[currentEndpoint retain] autorelease]
                                 waitUntilDone:NO];
            }
        }
        else if (![currentEndpoint isEqualToDictionary:previousEndpoint])
        {
            if ([self.delegate respondsToSelector:@selector(updatedSavantEndpoint:)])
            {
                [self.delegate performSelector:@selector(updatedSavantEndpoint:)
                                      onThread:self.delegateThread
                                    withObject:[[currentEndpoint retain] autorelease]
                                 waitUntilDone:NO];
            }
        }
    }
    
    //-------------------------------------------------------------------
    // Find lost instances.
    //-------------------------------------------------------------------
    for (NSString *address in self.previousEndpoints)
    {
        if (![self.currentEndpoints objectForKey:address])
        {
            if ([self.delegate respondsToSelector:@selector(lostSavantEndpoint:)])
            {
                NSDictionary *endpoint = [self.previousEndpoints objectForKey:address];
                
                [self performSelector:@selector(lostSavantEndpoint:) withObject:[[endpoint retain] autorelease] afterDelay:0.7];
            }
        }
    }
    
    self.previousEndpoints = self.currentEndpoints; // this is a copy property.
    [self.currentEndpoints removeAllObjects];
}

- (void)lostSavantEndpoint:(NSDictionary*)endpoint
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:endpoint];
    [self.delegate performSelector:@selector(lostSavantEndpoint:)
                          onThread:self.delegateThread
                        withObject:endpoint
                     waitUntilDone:NO];
}

@end

//##OBJCLEAN_ENDSKIP##
