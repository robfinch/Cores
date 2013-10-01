#pragma once

#include "String.h"
#include "buf.h"
#include "asmbuf.h"
#include "ListObject.h"

#include "sym.h"   // CHashBucket

#define NAME_MAX  32
#define MAX_MACRO_EXP   2048    // Maximum macro expansion

namespace RTFClasses
{
	class Macro : public ListObject
	{
	   String name;				// Input variable name
	   String body;
	   int nargs;              // number of arguments
	   int line;               // line symbol defined on
	   int file;               // file number symbol defined in
	   static int counter;
	public:
		static void zeroCounter() { counter = 0; };
		HashVal getHash() { return name.hashPJW(); };
		int cmp(Object *);
		int Nargs() { return nargs; };
		String getName() { return name; };
		int getLine() { return line; };
		int getFile() { return file; };
		void setBody(String bdy) { body = bdy; };
		void setName(char *nm) { name.copy(nm); };
		void setArgCount(int ac) { nargs = ac; };
		void setFileLine(int fl, int ln) { file = fl; line = ln; };
		char *initBody(String *[]);
		char *subParmList(String *[]);             // substitute parameter list into macro body
		char *subArg(char *, int, char *);
		char *getBody(String *[]);
		void sub(String *[], AsmBuf *, int, int, int);
		void write(FILE *);
		void print(FILE *);
	};
}
