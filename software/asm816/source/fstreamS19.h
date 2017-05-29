/* ===============================================================
	(C) 2001 Bird Computer
	All rights reserved.
	
	S19.h
		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */
#ifndef FSTREAMS19_H
#define FSTREAMS19_H

#include <ios>
#include <fstream>

#define S1	1
#define S2	2
#define S3	3
using namespace std;

class fstreamS19 : public fstream
{
	int m_nMode;
	char m_buf[80];
	__int8 m_nNdx;
	int m_nCheckSum;
	int m_nSRecCount;
	int m_nRecType;	// type of last record output S1, S2, or S3
	void (*m_pfnLoadMem)(unsigned __int32 loc, unsigned __int8 byte);
	bool LoadMem(unsigned __int32, int);
public:
	bool open(char *fname,  std::_Ios_Openmode  mode,
		void (*pfnLoadMem)(unsigned __int32 loc, unsigned __int8 byte)=NULL);
	void close(unsigned __int32 StartAddress = 0);
	void flush();
	void putb(unsigned __int32 location, unsigned int byte);
	int load(unsigned __int32 *StartLoc);
};

#endif
