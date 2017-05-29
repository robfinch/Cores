#pragma once

#include <stdio.h>
#include <io.h>   // for open, close

// Object record types
#define T_BIND       0x02
#define T_COMMENT    0x08
#define T_EXTERN     0x03
#define T_IDATA      0x01
#define T_LINENO     0x09
#define T_MFCTR      0x0A
#define T_MEND       0x06
#define T_NAME       0x05
#define T_PUBLIC     0x04
#define T_START      0x07
#define T_VDATA      0x00

#define A_CODE       0x00
#define A_DATA       0x01
#define A_ABSSHORT   0x02
#define A_ABSLONG    0x03


// Object file output class
class ObjFile
{
   unsigned char type;        // type of object record
   int length;                // length of remainder of record
   char buf[2048];            // output buffer

   int fh;
public:
   int open(char *filename, int amode, int pmode) { return (fh = ::open(filename, amode, pmode)); };
   int close() { return (::close(fh)); };
   int read();
   int uWrite(int, const char *, int);                // unbuffered write
   int bWrite(int, const char *, int);                // buffered write
   void clearBuf() { length = 0; };             // clear buffer
   int getLength() { return (length); };
   int flush();
   int checkSum();               // calculate checksum of data buffer
};


