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

#define RPM_DISCOVERY_SERVER_PORT                           (9101)

#ifdef EMS
#define RPM_WEBSOCKET_SERVER_PORT                           (8080)
#else
#define RPM_WEBSOCKET_SERVER_PORT                           (9108)
#endif

#define RPM_WEBSOCKET_MSGPACK_DEFAULT                       (YES)

// Keys used by server
#define RPM_DISCOVERY_VERSION_KEY                           (@"version")
#define RPM_DISCOVERY_UID_KEY                               (@"UID")
#define RPM_DISCOVERY_NAME_KEY                              (@"name")
#define RPM_DISCOVERY_IP_KEY                                (@"ip")
#define RPM_DISCOVERY_PORT_KEY                              (@"port")
#define RPM_DISCOVERY_TYPE_KEY                              (@"type")
#define RPM_DISCOVERY_SCHEME_KEY                            (@"scheme")
#define RPM_DISCOVERY_HOMEID_KEY                            (@"homeId")
#define RPM_DISCOVERY_ONBOARD_KEY                           (@"onboardKey")
#define RPM_DISCOVERY_INTERFACEPROGRESS_KEY                 (@"interfaceProgress") // (0-100)

// Keys used by client
#define RPM_DISCOVERY_SERVICE_KEY                           (@"service")

#define RPM_DISCOVERY_CONTROL_SERVICE                       (@"_control_.ws")
#define RPM_ASYNC_SERVICEBASETYPE                           (@"_asy._tcp")
#define RPM_ASYNC_BROWSEDOMAIN                              (@"")

#define RPM_DISCOVERY_SCHEME_WEBSOCKET                      (@"ws")
#define RPM_DISCOVERY_SCHEME_SECURE_WEBSOCKET               (@"wss")

#define RPM_WEBSOCKET_FILEUPLOAD_TYPE                       (0x01)
#define RPM_WEBSOCKET_SECURITYCAM_TYPE                      (0x02)
#define RPM_WEBSOCKET_PROFILE_TYPE                          (0x03)
#define RPM_WEBSOCKET_USERINTERFACE_TYPE                    (0x04)
#define RPM_WEBSOCKET_MEDIADATABASEUPLOAD_TYPE              (0x05)
#define RPM_WEBSOCKET_SAVANTCAM_TYPE                        (0x06)
#define RPM_WEBSOCKET_MSGPACK_TYPE                          (0x80) // this type is reserved for use by msgpack

#define RPM_WEBSOCKET_MSGPACK_TYPE_CHECK(msgType) ((msgType & 0xF0) == RPM_WEBSOCKET_MSGPACK_TYPE)

#define RPM_WEBSOCKET_PUBLISH_RETRYTIMEOUT                  (1.0 + (fmodf(((float)arc4random())/10000.0, 3.5))) // 1 to 4.5 seconds
#define RPM_WEBSOCKET_MAXUNACKEDPINGS                       (10) // client
#define RPM_WEBSOCKET_CLIENTPINGPERIOD                      (2) // seconds

typedef enum {
    RPM_WS_NoSSL               = 0,
    RPM_WS_SSL                 = 1,
    RPM_WS_SSLAllowSelfSigned  = 2,
} RPMWebSocketClientSSL;

//-------------------------------------------------------------------
// Explicitly list all the enum values for easier porting to other
// SDKs (android)
//-------------------------------------------------------------------
typedef enum
{
    rpmDeviceClassUnknown = 0,
    rpmDeviceClassiPhone  = 1,
    rpmDeviceClassiPad    = 2,
    rpmDeviceClassSSR     = 3,
    rpmDeviceClassSUR     = 4,
} rpmDeviceClass_t;
