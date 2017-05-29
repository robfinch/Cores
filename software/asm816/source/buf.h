#pragma once

#include <string.h>
#include "MyString.h"

#ifndef _CTYPE
#include <ctype.h>
#include "ctypex.h"
#endif

namespace RTFClasses
{
	class Buf : public String
	{
		char *ptr;
	public:
		Buf(int sz) : String(sz) { ptr = buf(); };
		Buf(char *p, int n) : String(p,n) { ptr = buf(); };
		~Buf() { };
		size_t getSize() { return bufsz(); };
//		bool copy(Buf *p);
		void shift(int pos, int amt);
		bool insert(int pos, char *p, int len);
		//bool resize(int n);				// make the buffer larger
		bool enlarge(int n) {
				int nn = ndx();
				realloc(n+getSize(), true);
				moveTo(nn);
				return true; };
		void rewind() { ptr = buf(); };
		void write(char *);
		void writeln(char *);
		char *getPtr() { return (ptr); };
		int ndx() { return ptr - buf(); };
		int move(int n) { ptr += n; return ndx(); };
		int moveTo(int n) { ptr = &buf()[n]; return n; };
		void end() { ptr = buf() + getSize() - 1; };
		void clear() { ptr = buf(); memset(buf(), '\0', getSize()); }; // zeros out buffer
//		void set(char *p, size_t n) { buf = p; size = n; ptr = buf; };   // set data buffer
		void setptr(char *p) { ptr = p; };
		int peekCh() {
			if (ptr >= buf() + getSize() - 1)
				return 0;
			return (*ptr); };             // gets character without incrementing pointer
		int peekCh(int d);							// gets dth character forward
		int nextCh();                                // gets character and increments pointer
		void unNextCh() { if (ptr > buf()) --ptr; };   // Backs up pointer a character
		int nextNonSpace();                          // gets the next non space character
		int nextNonSpaceLF();                         // gets the next non space character excluding line feeds
		void skipSpaces();                           // increments pointer past spaces
		void skipSpacesLF();                          // increments pointer past spaces excluding line feeds
		int findLastNonSpace(int);
		int getIdentifier(char **s, char **e = NULL);	// gets a standard identifier string
		unsigned long getNumeric(char **, int);      // gets a numeric value
		int nextLn(char *, int);                     // gets next line from buffer
		void scanToEOL();
		bool isNext(const char *what, int len);			// look for string
	};
}

