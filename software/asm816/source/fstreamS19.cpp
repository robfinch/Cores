//#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fstreamS19.h"

/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved.
	
	fstreamS19.cpp
		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

bool fstreamS19::open(char *fname, std::_Ios_Openmode md,
		  void (*pfn)(unsigned __int32 loc, unsigned __int8 byte)) {
	md |= ios::binary;
	m_nMode = md;
	m_nNdx = 0;
	m_nCheckSum = 0;
	m_nSRecCount = 0;
	m_nRecType = 0;
	if ((md & ios::in) == ios::in) {
		if (pfn == NULL)
			return false;
		m_pfnLoadMem = pfn;
	}
	fstream::open(fname, md);
//	fstream::open(fname, ios::in | ios::nocreate);
	return !fail();
};


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int fstreamS19::load(unsigned __int32 *pStartLoc)
{
	char tmpbuf[10];
	unsigned __int32 loc;
	int rcnt;
	int nbytes;
	unsigned __int8 byte;
	bool err = false;

	m_nSRecCount = 0;
	while (!eof()) {
		getline(m_buf, sizeof(m_buf));
		m_nNdx = 0;
		if (m_buf[0] != 'S') {
			err = true;
			continue;
		}
		// Process 'S' records
		switch(m_buf[1]) {
		case '1':
			tmpbuf[0] = m_buf[2];
			tmpbuf[1] = m_buf[3];
			tmpbuf[2] = '\0';
			nbytes = m_nCheckSum = strtol(tmpbuf, NULL, 16);
			// this is how much should have been read
			if (strlen(m_buf) != (unsigned)(nbytes * 2 + 4)) {
				err = true;
				continue;
			}
			tmpbuf[0] = m_buf[4];
			tmpbuf[1] = m_buf[5];
			tmpbuf[2] = m_buf[6];
			tmpbuf[3] = m_buf[7];
			tmpbuf[4] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nNdx = 8;
			if (!LoadMem(loc, nbytes)) {
				err = true;
				continue;
			}
			m_nRecType = S1;
			break;

		case '2':
			tmpbuf[0] = m_buf[2];
			tmpbuf[1] = m_buf[3];
			tmpbuf[2] = '\0';
			nbytes = m_nCheckSum = strtol(tmpbuf, NULL, 16);
			// this is how much should have been read
			if (strlen(m_buf) != (unsigned)(nbytes * 2 + 4)) {
				err = true;
				continue;
			}
			tmpbuf[0] = m_buf[4];
			tmpbuf[1] = m_buf[5];
			tmpbuf[2] = m_buf[6];
			tmpbuf[3] = m_buf[7];
			tmpbuf[4] = m_buf[8];
			tmpbuf[5] = m_buf[9];
			tmpbuf[6] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			m_nNdx = 10;
			if (!LoadMem(loc, nbytes)) {
				err = true;
				continue;
			}
			m_nRecType = S2;
			break;

		case '3':
			tmpbuf[0] = m_buf[2];
			tmpbuf[1] = m_buf[3];
			tmpbuf[2] = '\0';
			nbytes = m_nCheckSum = strtol(tmpbuf, NULL, 16);
			// this is how much should have been read
			if (strlen(m_buf) != (unsigned)(nbytes * 2 + 4)) {
				err = true;
				continue;
			}
			tmpbuf[0] = m_buf[4];
			tmpbuf[1] = m_buf[5];
			tmpbuf[2] = m_buf[6];
			tmpbuf[3] = m_buf[7];
			tmpbuf[4] = m_buf[8];
			tmpbuf[5] = m_buf[9];
			tmpbuf[6] = m_buf[10];
			tmpbuf[7] = m_buf[11];
			tmpbuf[8] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			m_nCheckSum += (loc >> 24) & 0xff;
			m_nNdx = 12;
			if (!LoadMem(loc, nbytes)) {
				err = true;
				continue;
			}
			m_nRecType = S3;
			break;

		// record count
		case '5':
			// ignore bad record
			if (m_buf[2] != '0' || m_buf[3] != '3')
				break;
			m_nCheckSum = 3;
			tmpbuf[0] = m_buf[4];
			tmpbuf[1] = m_buf[5];
			tmpbuf[2] = m_buf[6];
			tmpbuf[3] = m_buf[7];
			tmpbuf[4] = '\0';
			rcnt = strtoul(tmpbuf, NULL, 16);
			if (m_nSRecCount != rcnt) {
				err = true;
				continue;
			}
			m_nCheckSum += rcnt & 0xff;
			m_nCheckSum += (rcnt >> 8) & 0xff;
			// Get the checksum byte
			tmpbuf[0] = m_buf[8];
			tmpbuf[1] = m_buf[9];
			tmpbuf[2] = '\0';
			byte = (unsigned __int8)strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += byte;
			if ((m_nCheckSum & 0xff) != 0xff) {
				err = true;
				continue;
			}
			break;

		case '7':
			// record type mismatch ?
			if (m_nRecType != S3) {
				err = true;
				continue;
			}
			if (m_buf[2] != '0' || m_buf[3] != '5')
				break;
			m_nCheckSum = 5;
			strncpy(tmpbuf, &m_buf[4], 8);
			tmpbuf[8] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			if (pStartLoc)
				*pStartLoc = loc;
			// Get the checksum byte
			tmpbuf[0] = m_buf[12];
			tmpbuf[1] = m_buf[13];
			tmpbuf[2] = '\0';
			byte = (unsigned __int8)strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			m_nCheckSum += (loc >> 24) & 0xff;
			m_nCheckSum += byte;
			if ((m_nCheckSum & 0xff) != 0xff) {
				err = true;
				continue;
			}
			break;

		case '8':
			// record type mismatch ?
			if (m_nRecType != S2) {
				err = true;
				continue;
			}
			if (m_buf[2] != '0' || m_buf[3] != '4')
				break;
			m_nCheckSum = 4;
			strncpy(tmpbuf, &m_buf[4], 6);
			tmpbuf[6] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			if (pStartLoc)
				*pStartLoc = loc;
			// Get the checksum byte
			tmpbuf[0] = m_buf[10];
			tmpbuf[1] = m_buf[11];
			tmpbuf[2] = '\0';
			byte = (unsigned __int8) strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			m_nCheckSum += byte;
			if ((m_nCheckSum & 0xff) != 0xff) {
				err = true;
				continue;
			}
			break;

		case '9':
			// record type mismatch ?
			if (m_nRecType != S1) {
				err = true;
				continue;
			}
			if (m_buf[2] != '0' || m_buf[3] != '3')
				break;
			m_nCheckSum = 3;
			strncpy(tmpbuf, &m_buf[4], 4);
			tmpbuf[4] = '\0';
			loc = strtoul(tmpbuf, NULL, 16);
			if (pStartLoc)
				*pStartLoc = loc;
			// Get the checksum byte
			tmpbuf[0] = m_buf[8];
			tmpbuf[1] = m_buf[9];
			tmpbuf[2] = '\0';
			byte = (unsigned __int8)strtoul(tmpbuf, NULL, 16);
			m_nCheckSum += loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += byte;
			if ((m_nCheckSum & 0xff) != 0xff) {
				err = true;
				continue;
			}
			break;

		// ignore S4, S6 records (not implemented)
		case '0':
		case '4':
		case '6':
			break;

		// must be a bad record
		default:
			err = true;
		}
	}
	return !err;
}


/* ---------------------------------------------------------------
		Updates memory with the contents of the S19 buffer.
--------------------------------------------------------------- */
bool fstreamS19::LoadMem(unsigned __int32 loc, int nbytes)
{
	char tmpbuf[3];
	unsigned __int8 byte;

	m_nSRecCount++;
	for (; m_nNdx < nbytes * 2 + 2; ) {
		tmpbuf[0] = m_buf[m_nNdx++];
		tmpbuf[1] = m_buf[m_nNdx++];
		tmpbuf[2] = '\0';
		byte = (unsigned __int8)strtoul(tmpbuf, NULL, 16);
		m_nCheckSum += byte;
		(*m_pfnLoadMem)(loc, byte);
		loc++;
	}
	// Get the checksum byte
	tmpbuf[0] = m_buf[m_nNdx++];
	tmpbuf[1] = m_buf[m_nNdx++];
	tmpbuf[2] = '\0';
	byte = (unsigned __int8)strtoul(tmpbuf, NULL, 16);
	m_nCheckSum += byte;
	return ((m_nCheckSum & 0xff) == 0xff);
}


//	Flush S-file output buffer
void fstreamS19::close(unsigned __int32 StartAddress)
{
	char buf[90];

	// if in input mode, a simple close will do
	if ((m_nMode & ios::in) == ios::in) {
		fstream::close();
		return;
	}
	// output mode
	flush();
	// Output terminator record
	switch(m_nRecType) {
	case S1:
		m_nCheckSum = StartAddress & 0xff;
		m_nCheckSum += (StartAddress >> 8) & 0xff;
		m_nCheckSum += 3;
		sprintf(buf, "S903%04X%02X\n", (__int16)StartAddress, (~m_nCheckSum) & 0xff);
		write(buf, strlen(buf));
		break;
	case S2:
		m_nCheckSum = StartAddress & 0xff;
		m_nCheckSum += (StartAddress >> 8) & 0xff;
		m_nCheckSum += (StartAddress >> 16) & 0xff;
		m_nCheckSum += 4;
		sprintf(buf, "S804%06lX%02X\n", (__int32)StartAddress, (~m_nCheckSum) & 0xff);
		write(buf, strlen(buf));
		break;
	case S3:
	default:
		m_nCheckSum = StartAddress & 0xff;
		m_nCheckSum += (StartAddress >> 8) & 0xff;
		m_nCheckSum += (StartAddress >> 16) & 0xff;
		m_nCheckSum += (StartAddress >> 24) & 0xff;
		m_nCheckSum += 5;
		sprintf(buf, "S705%08lX%02X\n", StartAddress, (~m_nCheckSum) & 0xff);
		write(buf, strlen(buf));
	}
	fstream::close();
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
void fstreamS19::putb(unsigned __int32 loc, unsigned int byte)
{
	if (m_nNdx == 0)
	{
		memset(m_buf, '\0', sizeof(m_buf));
		if (loc <= 0xffff) {	// 2 byte address
			m_nCheckSum = loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			sprintf(m_buf, "S1  %04X", (__int16)loc);
			m_nNdx = 8;
			m_nRecType = S1;
		}
		else if (loc <= 0xffffff) {	// 3 byte address
			m_nCheckSum = loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			sprintf(m_buf, "S2  %06lX", loc);
			m_nNdx = 10;
			m_nRecType = S2;
		}
		else {	// 4 byte address
			m_nCheckSum = loc & 0xff;
			m_nCheckSum += (loc >> 8) & 0xff;
			m_nCheckSum += (loc >> 16) & 0xff;
			m_nCheckSum += (loc >> 24) & 0xff;
			sprintf(m_buf, "S3  %08lX", loc);
			m_nNdx = 12;
			m_nRecType = S3;
		}
	}
	sprintf(&m_buf[m_nNdx], "%02X", byte);
	m_nNdx += 2;
	m_nCheckSum += byte;
	if (m_nNdx >= 74)
	{
		m_buf[2] = '2';
		m_buf[3] = '4';
		m_nCheckSum += 36;
		sprintf(&m_buf[m_nNdx], "%02X\n", (~m_nCheckSum) & 0xff);
		m_nNdx = 0;
		write(m_buf, strlen(m_buf));
		m_nSRecCount++;
	}
}


/* ---------------------------------------------------------------
		Flush S-file output buffer. Used when the section
	changes or the file is closed.
--------------------------------------------------------------- */
void fstreamS19::flush(void)
{
    char tmp[90];

	// Complete current buffer
	if (m_nNdx > 0)
	{
		sprintf(tmp, "%02X", (m_nNdx - 4 + 2)/2);	// + 2 for checksum
		m_buf[2] = tmp[0];
		m_buf[3] = tmp[1];
		m_nCheckSum += (m_nNdx - 4 + 2)/2;
		sprintf(&m_buf[m_nNdx], "%02X\n", (~m_nCheckSum) & 0xff);
		write(m_buf, strlen(m_buf));
		m_nSRecCount++;
		m_nNdx = 0;
	}

	if (m_nSRecCount > 0) {
		// Output count record. There is a max count of two byte value
		// for S5 record format. If we go over this we don't bother to
		// output the record.
		if (m_nSRecCount <= 65535)
		{
			m_nCheckSum = m_nSRecCount & 0xff;
			m_nCheckSum += (m_nSRecCount >> 8) & 0xff;
			m_nCheckSum += 3;
			sprintf(tmp, "S503%04X%02X\n", m_nSRecCount, (~m_nCheckSum) & 0xff);
			write(tmp, strlen(tmp));
		}
		m_nSRecCount = 0;
	}
}


