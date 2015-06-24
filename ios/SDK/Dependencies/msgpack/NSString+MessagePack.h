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
// AUTHOR: M. Silva
//
// DESCRIPTION:
//
//====================================================================

//##OBJCLEAN_SKIP##

@import Foundation;

@interface NSString (NSString_MessagePack)

// Packs the receiver's data into message pack data
- (NSData*)messagePack;

@end

//##OBJCLEAN_ENDSKIP##
