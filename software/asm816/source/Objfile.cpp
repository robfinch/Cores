#include <stdio.h>
#include <io.h>
#include <ctype.h>
#include "objfile.h"
#include "Assembler.h"

/* ===============================================================
	(C) 2000 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/* -----------------------------------------------------------------------------
   objfile.cpp
   
   Description :
      Routines for outputing object records.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   int CheckSum();
   
   Description :
      Calculates the checksum of the output buffer.
   Returns :
      Checksum of the buffer.
----------------------------------------------------------------------------- */

int ObjFile::checkSum()
{
   int x, CheckSum;

   for (CheckSum = x = 0; x < length; x++)
      CheckSum += buf[x];
   return (CheckSum & 0xff);
}


/* -----------------------------------------------------------------------------
   void uWrite(int type, char *buf, int length);
   int type;   - type of object record to write
   char *buf;  - pointer to buffer containing data section of record
   int length; - length of the data section

   Description :
      Unbuffered write operation to object file. Outputs an object data
   record immediately. Calculates checksum for record.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

int ObjFile::uWrite(int ptype, const char *pdata, int plength)
{
   int count;
   
   type = (unsigned char)ptype;        // set record type,
   length = plength;                   // record length,
   memcpy(buf, pdata, length);         // data area,
   buf[length] = (char)~checkSum();    // and checksum byte
   count = write(fh, this, length+6);  // Write out object buffer
   return (count);
}


/* -----------------------------------------------------------------------------
   int bWrite(int type, char *buf, int length);
   int type;   - type of object record to write
   char *buf;  - pointer to buffer containing data section of record
   int length; - length of the data section

   Description :
      Buffered write operation to object file. Output of an object data
   record is delayed until either the output type changes, or the output
   buffer is full. Calculates checksum for record.

   Returns :
      1 - if the output buffer was full.

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

int ObjFile::bWrite(int ptype, const char *pdata, int plength)
{
   int retval = 0;
   
   if (ptype != type  ||  length + plength > sizeof(buf) - 1)
   {
      flush();
      type = ptype;
      retval = 1;
   }
   memcpy(&buf[length], pdata, plength);
   length += plength;
   return (retval);
}


/* -----------------------------------------------------------------------------
   read();
   
   Description :
      Reads an object record.

   Returns:
      number of characters read
      -1 for a read error
      -2 for a checksum error
----------------------------------------------------------------------------- */

int ObjFile::read()
{
   int count;

   count = ::read(fh, this, 5);    // read record header
   if (count != 5)
      return (count);

   if (length < sizeof(buf))
   {
      count = ::read(fh, buf, length);   // read remainder of record
      if (count != length)
         return (count);
      if (checkSum() + buf[length] != 0)  
         return (-2);            // checksum error
   }
   return (-3);      // length > sizeof(buf)
}


/* -----------------------------------------------------------------------------
   int flush()

   Description :
      Flushes object buffer by writing any data present to output file.

   Returns :
      number of bytes written to file
      0 - if no write occurred
      -1 on write error
----------------------------------------------------------------------------- */

int ObjFile::flush()
{
   int count;

   count = length;
   if (length)
   {
      buf[length] = (char)~checkSum();
      count = write(fh, this, length+6);
      length = 0;
   }
   return (count);
}

