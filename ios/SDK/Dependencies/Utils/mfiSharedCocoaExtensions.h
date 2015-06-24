//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2011 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is Intellectual Property of Savant Systems LLC. 770
// Main St. Osterville Ma. 02655, and contains proprietary and confidential
// information, trade secrets and other Intellectual Property of Savant Systems
// LLC. All rights, title and copyrights are owned by Savant Systems LLC.
//
// Any unauthorized use, including but not limited to, examination, copying,
// disassembling, de-compiling, reverse engineering, transfer, disclosure to
// others, publication or removal of any notice or restriction contained herein
// in any form is expressly prohibited.
//
//====================================================================
//
// AUTHOR: M. Silva
//
// DESCRIPTION: basic extensions used for message packing/unpacking
//
//====================================================================

//##OBJCLEAN_SKIP##

#if (defined(TARGET_OS_MAC) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

@interface NSMutableData (mfiPodCocoaNSMutableDataExtensions)

-(void)appendByte:(unsigned char)data;
-(void)appendShort:(unsigned short)data;
-(void)appendLong:(unsigned long)data;
@end

@interface NSData (mfiPodCocoaNSDataExtensions)
-(unsigned char)getByte:(unsigned int)byteIndex;
-(unsigned short)getShort:(unsigned long)byteIndex;
-(unsigned long)getLong:(unsigned long)byteIndex;

@end

//##OBJCLEAN_ENDSKIP##
