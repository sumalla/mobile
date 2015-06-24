/*
**  MD5.h
**
**  Copyright (c) 2002
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

//##OBJCLEAN_SKIP##

#ifndef _Pantomime_H_MD5
#define _Pantomime_H_MD5
@import Foundation;

#define word32 unsigned int

struct MD5Context {
        word32 buf[4];
        word32 bits[2];
        unsigned char in[64];
};

void MD5Init(struct MD5Context *context);
void MD5Update(struct MD5Context *context, unsigned char const *buf,
               unsigned len);
void MD5Final(unsigned char digest[16], struct MD5Context *context);
void MD5Transform(word32 buf[4], word32 const in[16]);

/*
 * This is needed to make RSAREF happy on some MS-DOS compilers.
 */
typedef struct MD5Context MD5_CTX;

void md5_hmac(unsigned char *digest,
              const unsigned char* text, int text_len,
              const unsigned char* key, int key_len);


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface MD5 : NSObject
{
  NSString *string;
  NSData *data;

  BOOL hasComputedDigest;
  unsigned char digest[16];
}
#pragma clang diagnostic pop

- (id) initWithString: (NSString *) theString
             encoding: (int) theEncoding;
- (id) initWithData: (NSData *) theData;

- (void) computeDigest;
- (NSData *) digest;
- (NSString *) digestAsString;
- (NSString *) hmacAsStringUsingPassword: (NSString *) thePassword;
+ (NSString*) computeDigestForDirectory: (NSString*)directoryPath
                         excludingFiles: (NSArray*)filesToExclude
                        excludingExtensions:(NSArray *)extensionsToExclude;
+ (NSString*) computeDigestForDirectory: (NSString*)directoryPath
                         excludingFiles: (NSArray*)filesToExclude;
+ (NSString*) computeDigestForFile: (NSString*)filePath;

@end

#endif // _Pantomime_H_MD5

//##OBJCLEAN_ENDSKIP##
