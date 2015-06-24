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


#import "mfiSharedCocoaExtensions.h"

//##OBJCLEAN_SKIP##


@implementation NSMutableData (mfiPodCocoaNSMutableDataExtensions)

//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(void)appendByte:(unsigned char)data
{
    [self appendBytes:&data length:sizeof(data)];
}

//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(void)appendShort:(unsigned short)data
{
    [self appendByte:(data & 0xff00) >> 8];
    [self appendByte:(data & 0x00ff) >> 0];
}


//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(void)appendLong:(unsigned long)data
{
    [self appendByte:(data & 0xff000000) >> 24];
    [self appendByte:(data & 0x00ff0000) >> 16];
    [self appendByte:(data & 0x0000ff00) >> 8];
    [self appendByte:(data & 0x000000ff) >> 0];
}

@end



@implementation NSData (mfiPodCocoaNSDataExtensions)

//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(unsigned char)getByte:(unsigned int)byteIndex
{
    return ((unsigned char *)[self bytes])[byteIndex];
}

//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(unsigned short)getShort:(unsigned long)byteIndex
{
    unsigned long rtn = 0;
    
    rtn += (unsigned long)[self getByte:(unsigned int)byteIndex++] << 8;
    rtn += (unsigned long)[self getByte:(unsigned int)byteIndex++] << 0;
    
    return rtn;
}

//---------------------------------------------------------------
//
//	 Description
//
//	 Return Value
//
//	 Caveats
//
//	 Arguments
//
//
//---------------------------------------------------------------
-(unsigned long)getLong:(unsigned long)byteIndex
{
    unsigned long rtn = 0;
    
    rtn = (unsigned long)[self getByte:(unsigned int)byteIndex++] << 24;
    rtn += (unsigned long)[self getByte:(unsigned int)byteIndex++] << 16;
    rtn += (unsigned long)[self getByte:(unsigned int)byteIndex++] << 8;
    rtn += (unsigned long)[self getByte:(unsigned int)byteIndex++] << 0;
    
    return rtn;
}

@end

//##OBJCLEAN_ENDSKIP##
