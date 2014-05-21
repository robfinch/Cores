#include <stdio.h>
#include <string.h>
#include "SOut.h"
#include "asm24.h"

/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/* ---------------------------------------------------------------
--------------------------------------------------------------- */
void CSOut::putb(unsigned int byte)
{
	unsigned __int32 loc;

	if (ndx == 0)
	{
		memset(buf, '\0', sizeof(buf));
		loc = (CurrentArea == CODE_AREA) ? ProgramCounter.val : DataCounter.val;
		if (loc <= 0xffff) {	// 2 byte address
			CheckSum = loc & 0xff;
			CheckSum += (loc >> 8) & 0xff;
			sprintf(buf, "S1  %04X", (__int16)loc);
			ndx = 8;
			RecType = S1;
		}
		else if (loc <= 0xffffff) {	// 3 byte address
			CheckSum = loc & 0xff;
			CheckSum += (loc >> 8) & 0xff;
			CheckSum += (loc >> 16) & 0xff;
			sprintf(buf, "S2  %06lX", loc);
			ndx = 10;
			RecType = S2;
		}
		else {	// 4 byte address
			CheckSum = loc & 0xff;
			CheckSum += (loc >> 8) & 0xff;
			CheckSum += (loc >> 16) & 0xff;
			CheckSum += (loc >> 24) & 0xff;
			sprintf(buf, "S3  %08lX", loc);
			ndx = 12;
			RecType = S3;
		}
	}
	sprintf(&buf[ndx], "%02X", byte);
	ndx += 2;
	CheckSum += byte;
	if (ndx >= 74)
	{
		buf[2] = '2';
		buf[3] = '4';
		CheckSum += 36;
		sprintf(&buf[ndx], "%02X\n", (~CheckSum) & 0xff);
		ndx = 0;
		fprintf(fp, buf);
		s3Count++;
	}
}


/* ---------------------------------------------------------------
		Flush S-file output buffer. Used when the section
	changes or the file is closed.
--------------------------------------------------------------- */
void CSOut::flush(void)
{
    char tmp[3];

	// Complete current buffer
	if (ndx > 0)
	{
		sprintf(tmp, "%02X", (ndx - 4 + 2)/2);	// + 2 for checksum
		buf[2] = tmp[0];
		buf[3] = tmp[1];
		CheckSum += (ndx - 4 + 2)/2;
		sprintf(&buf[ndx], "%02X\n", (~CheckSum) & 0xff);
		fprintf(fp, buf);
		s3Count++;
		ndx = 0;
	}

	if (s3Count > 0) {
		// Output count record. There is a max count of two byte value
		// for S5 record format. If we go over this we don't bother to
		// output the record.
		if (s3Count <= 65535)
		{
			CheckSum = s3Count & 0xff;
			CheckSum += (s3Count >> 8) & 0xff;
			CheckSum += 3;
			fprintf(fp, "S503%04X%02X\n", s3Count, (~CheckSum) & 0xff);
		}
		s3Count = 0;
	}
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int CSOut::open(char *fname)
{
	ndx = 0;
	CheckSum = 0;
	s3Count = 0;
	if ((fp = fopen(fname, "wb")) == NULL)
	{
		err(jbFatalErr, E_OPEN, fname);
		return 0;
	}
	return 1;
}


/* ---------------------------------------------------------------
		Flush S-file output buffer
--------------------------------------------------------------- */
void CSOut::close(void)
{
	flush();
	// Output terminator record
	switch(RecType) {
	case S1:
		CheckSum = StartAddress & 0xff;
		CheckSum += (StartAddress >> 8) & 0xff;
		CheckSum += 3;
		fprintf(fp, "S903%04X%02X\n", (__int16)StartAddress, (~CheckSum) & 0xff);
		break;
	case S2:
		CheckSum = StartAddress & 0xff;
		CheckSum += (StartAddress >> 8) & 0xff;
		CheckSum += (StartAddress >> 16) & 0xff;
		CheckSum += 4;
		fprintf(fp, "S804%06lX%02X\n", (__int32)StartAddress, (~CheckSum) & 0xff);
		break;
	case S3:
	default:
		CheckSum = StartAddress & 0xff;
		CheckSum += (StartAddress >> 8) & 0xff;
		CheckSum += (StartAddress >> 16) & 0xff;
		CheckSum += (StartAddress >> 24) & 0xff;
		CheckSum += 5;
		fprintf(fp, "S705%08lX%02X\n", StartAddress, (~CheckSum) & 0xff);
	}
	fclose(fp);
}
