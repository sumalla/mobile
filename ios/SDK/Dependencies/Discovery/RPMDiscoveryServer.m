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

#include <arpa/inet.h>
#include <unistd.h>
#import "RPMDiscoveryServer.h"
#import "RPMCommunicationConstants.h"

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/MessagePack.h>
#import <rpmGeneralUtils/rpmUtils.h>
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmStateManagement/rpmStateReceiver.h>
#else
#import "rpmSharedLogger.h"
#import "MessagePack.h"
#endif

uint32_t const RPM_CURRENT_DISCOVERY_VERSION = 2;

@interface RPMDiscoveryServer ()

- (void)_startServer;
- (void)stateCenterStatesUpdated:(NSDictionary *)stateValuesDict;

@property NSUInteger interfaceLaunchProgressStateValue;

@end

@implementation RPMDiscoveryServer

@synthesize UID = _UID;
@synthesize name = _name;
@synthesize port = _port;
@synthesize type = _type;
@synthesize scheme = _scheme;
@synthesize interfaceLaunchProgressStateValue = _interfaceLaunchProgressStateValue;

- (id)initWithUID:(NSString *)uid
             port:(NSUInteger)port
             name:(NSString *)name
           scheme:(NSString *)scheme
{
    self = [super init];
    if (self)
    {
        _UID = [[uid uppercaseString] retain];
        _name = [name retain];
        _port = port;
#ifdef GNUSTEP
        _type = rpmDiscovery_Linux;
#else
        _type = rpmDiscovery_OSX;
#endif
        _scheme = scheme;
    }
    return self;
}

- (void)invalidate
{
    _shouldExit = YES;

    close(_socket);
    _socket = -1;

}

- (void)dealloc
{
    [_UID release];
    [_name release];
    [_scheme release];
    [_interfaceLaunchProgressStateName release];

    [super dealloc];
}

- (void)startServer
{
    [NSThread detachNewThreadSelector:@selector(_startServer)
                             toTarget:self
                           withObject:nil];
    
#if !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS)
    _interfaceLaunchProgressStateName = [[NSString alloc] initWithFormat:@"global.%@.InterfaceLaunchProgress", [RPMUtils fullSystemName]];
    [[rpmStateReceiver sharedReceiver] initCommunications];
    [[rpmStateReceiver sharedReceiver] addStateChangeObserver:self];
    [[rpmStateReceiver sharedReceiver] registerStatesToStateCenters:[NSArray arrayWithObject:_interfaceLaunchProgressStateName]];
    [self stateCenterStatesUpdated:[[rpmStateReceiver sharedReceiver] stateValues]];
#endif
}

- (void)_startServer
{
    _serverThread = [NSThread currentThread];
    [_serverThread setName:@"RPMDiscoveryServer"];
    
    // Bind to a port
    struct sockaddr_in serv_addr;
    
    bzero((char *)&serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(RPM_DISCOVERY_SERVER_PORT);
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    
    _socket = -1;
    
    while (!_shouldExit)
    {
        _socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (_socket == -1)
        {
            sleep(10);
            continue;
        }
        
        int reuse = 1;
        setsockopt(_socket, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
        
        RPMLogInfo(@"Binding UDP to %d", RPM_DISCOVERY_SERVER_PORT);
        
        if (bind(_socket, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == 0)
        {
            break;
        }
        else
        {
            RPMLogErr(@"%@ could not bind to port %d %@", self, RPM_DISCOVERY_SERVER_PORT, [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil]);
            close(_socket);
            sleep(10);
            continue;
        }
    }
    
    while (!_shouldExit)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        char msg[512];
        unsigned int cliLen;
        int flags;
        ssize_t n;
        bzero(msg, 512);
        
        flags = 0;
        
        struct sockaddr_in cliAddr;
        cliLen = sizeof(cliAddr);
        n = recvfrom(_socket, msg, 512, flags, (struct sockaddr *)&cliAddr, &cliLen);
        if (n < 0)
        {
            printf("cannot receive data \n");
            continue;
        }
        NSData *receivedData = [NSData dataWithBytes:msg
                                              length:(NSUInteger)n];
        
        NSDictionary *receivedMessage = [MessagePackParser parseData:receivedData];
        RPMLogDebug(@"Received message: %@", receivedMessage);
        
        if (![[receivedMessage objectForKey:RPM_DISCOVERY_SERVICE_KEY] isEqualToString:RPM_DISCOVERY_CONTROL_SERVICE])
        {
            RPMLogErr(@"Expected %@, but found %@", RPM_DISCOVERY_CONTROL_SERVICE, [receivedMessage objectForKey:RPM_DISCOVERY_SERVICE_KEY]);
            [pool release];
            continue;
        }
        
        NSMutableDictionary *scanResponse = [NSMutableDictionary dictionary];
        
        [scanResponse setObject:[NSNumber numberWithInteger:RPM_CURRENT_DISCOVERY_VERSION]
                         forKey:RPM_DISCOVERY_VERSION_KEY];
        
        [scanResponse setObject:self.UID
                         forKey:RPM_DISCOVERY_UID_KEY];
        
        [scanResponse setObject:[NSNumber numberWithUnsignedInt:_type]
                         forKey:RPM_DISCOVERY_TYPE_KEY];
        
        [scanResponse setObject:[NSNumber numberWithUnsignedInteger:_port]
                         forKey:RPM_DISCOVERY_PORT_KEY];
        
        [scanResponse setObject:_name
                         forKey:RPM_DISCOVERY_NAME_KEY];
        
        [scanResponse setObject:_scheme
                         forKey:RPM_DISCOVERY_SCHEME_KEY];
        
        [scanResponse setObject:[NSNumber numberWithUnsignedInteger:self.interfaceLaunchProgressStateValue]
                         forKey:RPM_DISCOVERY_INTERFACEPROGRESS_KEY];
        
        NSData *dataToSend = [MessagePackPacker pack:scanResponse];
        
        n = sendto(_socket, [dataToSend bytes], [dataToSend length], flags,(struct sockaddr *)&cliAddr, cliLen);
        if (n < 0)
        {
            RPMLogErr(@"Got error: %s", strerror(errno));
        }
        else
        {
            RPMLogDebug(@"Sent %@", scanResponse);
        }
        
        [pool release];
    }
}

- (void)stateCenterStatesUpdated:(NSDictionary *)stateValuesDict
{
    NSNumber *interfaceProgress = [stateValuesDict objectForKey:_interfaceLaunchProgressStateName];
    
    if (interfaceProgress)
    {
        self.interfaceLaunchProgressStateValue = [interfaceProgress unsignedIntegerValue];
    }
}

@end
