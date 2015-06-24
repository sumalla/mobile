
//##OBJCLEAN_SKIP##

@import Foundation;

#define TAR_BLOCKSIZE 512

#define TAR_LONGLIST_FILENAME @"././@LongLink"

//Error Defines
#define RPMTAR_ERROR_DOMAIN @"rpmTar" 

#define RPMTAR_ERROR_HEADER_BADSIZE 1000
#define RPMTAR_ERROR_HEADER_UNSUPPORTEDTARTYPE 1001
#define ERROR_HEADER_BADFILENAME 1002

#define RPMTAR_ERROR_LONGNAME_BADSIZE 2000
#define RPMTAR_ERROR_LONGNAME_BADFRAME 2001

#define RPMTAR_ERROR_FILEDATA_BADSIZE 3000
#define RPMTAR_ERROR_FILEDATA_BADFRAME 3001

/**
The following enum defines states for the state machine for reading in tar data. The state machine is as follows:

On start the next block is a header block.
If a header block and the file name is not TAR_LONGLIST_FILENAME then the next block is a data block
If a header block and the file name IS TAR_LONGLIST_FILENAME then the next block is a long name data block
If a long name data block the next block is a long name data block if the total bytes read are less then the length
If a long name data block the next block is a header block if the total bytes read are greater then the length
If a file data block the next block is a file data block if the total bytes read are less then the length
If a file data block the next block is a header block if the total bytes read are greater then the length

When the last file data block is read then reinitialize all internal variables and start on the next file
 
*/
typedef enum
    {
        TAR_HEADER_BLOCK = 0,
        TAR_LONGNAME_DATA_BLOCK,
        TAR_FILE_DATA_BLOCK,
    } rpm_tar_nextBlockType;

typedef struct tarHeaderStruct
{
    char    name[100];
    char    mode[8];
    char    uid[8];
    char    gid[8];
    char    size[12];
    char    mtime[12];
    char    chksum[8];
    char    linkflag;
    char    linkname[100];
    char    magic[8];
    char    uname[32];
    char    gname[32];
    char    devmajor[8];
    char    devminor[8];
    char    prefix[150];
} tarHeaderStruct;

/**
 \brief
 rpmTar handles the TAR (Tape Archive) format data received from the ROSIE Host Controller.
 
 All of the theme data from ROSIE is compressed into a single gzipped tar file to provide a 
 simpler way of getting all necessary data to the device in one transaction.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface rpmTar : NSObject 
{
    NSString *_outputPath;
    
    //The data for the current files header
    NSMutableData *_header;
    //The data for the long name
    NSMutableData *_longNameData;
    //The file data will be piped to the file
    NSFileHandle  *_file;
    
    //Info for the current file.
    NSString *_fileName;
    unsigned long _datasize;
    unsigned long _dataPos;//data position
    BOOL      _isDir;
    //This next flag is use to indicate we are looking at a new file.
    BOOL      _newFile;
    
    NSError *_error;
    
    rpm_tar_nextBlockType _currentState;
    
}
#pragma clang diagnostic pop
/**
 Initialize the object.
 @param path The full path to the desired output location
 @return Returns an instance of rpmTar.
 */
-(id)initWithOutputPath:(NSString*)path;
/**
 Process a 512-byte block of the tar file
 @param block A 512-byte block of data.  The only possible exception is the last block of the tarfile, which can be less than 512 bytes.
 */
-(BOOL)processBlock:(NSData*)block;
/**
 Returns the tar process error (if any)
 @return An NSError object or nil.
 */
-(NSError*)error;

@end

//##OBJCLEAN_ENDSKIP##
