#include <stdio.h>
#include <stdlib.h>
#include "c:\projects\bcinc\fwstr.h"
#include <ctype.h>
#include "err.h"
#include "buf.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
=============================================================== */

#undef min
#define min(a,b)	((a) < (b) ? (a) : (b))

namespace RTFClasses
{

	//// construct a buffer
	//Buf::Buf(int sz)
	//{
	//	size = sz;
	//	buf = new char [sz+1];
	//	if (buf)
	//		clear();
	//}

	//Buf::Buf(char *p, int sz)
	//{
	//	size = sz;
	//	buf = new char [sz+1];
	//	if (buf)
	//	{
	//		clear();
	//		memcpy(buf, p, sz);
	//	}
	//}

	//// resize the buffer, preserving the original contents
	//bool Buf::resize(int sz)
	//{
	//	char *p = new char[sz+1];
	//	if (p)
	//	{
	//		memset(p, '\0', sz+1);
	//		memcpy(p, buf, min(size,sz));
	//		// reset pointer to same index so it looks the same
	//		ptr = p + (ptr-buf);
	//		if (ptr > &p[sz-1])
	//			ptr = &p[sz];
	//		// get rid of old buffer
	//		delete[] buf;
	//		buf = p;
	//		size = sz;
	//		return true;
	//	}
	//	return false;
	//}


	//bool Buf::copy(Buf *q)
	//{
	//	char *p = new char[q->size+1];
	//	if (p)
	//	{
	//		delete[] buf;
	//		buf = p;
	//		size = q->size;
	//		memcpy(p, q->buf, size);
	//		p[size]=0;
	//		ptr = buf;
	//		return true;
	//	}
	//	return false;
	//}


	// add more error checking here
	void Buf::shift(int pos, int amt)
	{
		// shift open space in destination buffer
		if (amt==0)
			return;
		if (amt > 0) {
			memmove(&buf()[pos+amt], &buf()[pos], getSize() - amt - pos);//-ndx());
			setlen(strlen(buf()));
		}
		else {
			memmove(&buf()[pos], &buf()[pos-amt], getSize() -pos);//- ndx());
			setlen(strlen(buf()));
		}
	}


	bool Buf::insert(int pos, char *p, int len)
	{
		if (pos + len < getSize())
		{
			memcpy(&buf()[pos], p, len);
			setlen(strlen(buf()));
			return true;
		}
		return false;
	}


	int Buf::peekCh(int d)
	{
		if (ptr + d < buf() + getSize())
			return ptr[d] & 0xff;
		return 0;
	}


	/* -----------------------------------------------------------------------------
		char *ptr;     - pointer to buffer to scan for identifier
		char **sptr;   - start of identifier (leading spaces skipped)
		char **eptr;   - just after end of identifier if found
		   
		Description:
			Gets an identifier from input.

		Returns:
			The length of the identifier (0 if not found)
	----------------------------------------------------------------------------- */

	int Buf::getIdentifier(char **sptr, char **eptr)
	{
		char *sp, *ep;

		skipSpacesLF();
		sp = ptr;
		if (IsFirstIdentChar(*ptr & 0xff))
			do { ptr++; } while(IsIdentChar(*ptr & 0xff));
		ep = ptr;
		if (eptr)
			*eptr = ep;
		if (sptr)
			*sptr = sp;
		return (ep - sp);
	}


	bool Buf::isNext(const char *what, int len)
	{
		int idlen;
		char *sptr;
		char *p;

		p = ptr;
		idlen = getIdentifier(&sptr);
		if (idlen == 0)	{
			setptr(p); // restore starting point
			return false;
		}

		if (idlen == len) {
			if (strnicmp(sptr, what, len)) {
				setptr(p);
				return false;
			}
		}
		else {
			setptr(p);
			return false;
		}
		return true;
	}

	   
/* -----------------------------------------------------------------------------
   char **eptr;   - just after end of identifier if found
   
   Description:
      Gets a numeric from input.

   Returns:
      (long) The value of the numeric
----------------------------------------------------------------------------- */

	unsigned long Buf::getNumeric(char **eptr, int base)
	{
		unsigned long value = 0;
		char *eeptr;

		value = strtoul(ptr, &eeptr, base);
		ptr = eeptr;
		if (eptr)
			*eptr = eeptr;
		return (value);
	}


	// Gets next character from a buffer
	int Buf::nextCh()
	{
		int ch;

		if (ptr>=buf()+getSize()-1)
			return 0;
		ch = *ptr & 0xff;
		if (*ptr)
			ptr++;
		return (ch);
	}

	// skips spaces in the buffer
	void Buf::skipSpaces()
	{
		int ch;

		do
		{
			ch = nextCh();
		} while (isspace(ch));
		if (ch != 0)
			unNextCh();
	}

	// skips spaces in the buffer
	void Buf::skipSpacesLF()
	{
		int ch;

		do
		{
			ch = nextCh() & 0xff;
		} while (isspace(ch)&&ch!='\n');
		if (ch!=0)
			unNextCh();
	}

	// skips to the next non space character
	int Buf::nextNonSpace()
	{
		int ch;

		do
		{
			ch = nextCh();
		} while (isspace(ch));
		return (ch);
	}


	// skips to the next non space character
	int Buf::nextNonSpaceLF()
	{
		int ch;

		do
		{
			ch = nextCh();
		} while (isspace(ch)&&ch!='\n');
		return (ch);
	}


	// Get the next line
	int Buf::nextLn(char *bp, int maxc)
	{
		int aa;

		aa = min(maxc, strcspn(ptr, "\r\n"));
		if (aa)
			strncpy(bp, ptr, aa);
		return (aa);
	}


	// writes a string to the current buffer position
	void Buf::write(char *str)
	{
		int len;

		len = strlen(str);
		strcpy(ptr, str);
		ptr += len;
		setlen(ndx()+len);
	}


	// writes a string to the current buffer position and appends a newline character
	void Buf::writeln(char *str)
	{
		int len;

		len = strlen(str);
		strcpy(ptr, str);
		ptr += len;
		strcpy(ptr, "\n");
		ptr++;
		setlen(ndx()+len);
	}

	void Buf::scanToEOL()
	{
		unsigned char ch;

		while(1)
		{
			ch = (unsigned char)nextCh();
			if (ch < 1 || ch == '\n' || ch==255)
				break;
		}
	}

	int Buf::findLastNonSpace(int n)
	{
		if (n > getSize())
			n = getSize();
		if (n < 0)
			return 0;
		while (n > 0 && isspace(buf()[n])) --n;
		return n;
	}

}
