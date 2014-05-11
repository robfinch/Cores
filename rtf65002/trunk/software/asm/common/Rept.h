#pragma once

#include "String.h"
#include "buf.h"
#include "asmbuf.h"
#include "ListObject.h"
#include "macro.h"

#include "sym.h"   // CHashBucket

namespace RTFClasses
{
	class Rept : public Macro
	{
	public:
	   int count;
	   int sptr;
	public:
		HashVal getHash() { 
			HashVal h;
			h.delta = 1;
			h.hash = getCounter();
			return h;
		};
		int cmp(Object *);
		int getCount() { return count; };
		void setCount(int cnt) { count = cnt; };
		void sub(String *[], AsmBuf *, int, int, int);
		void print(FILE *);
	};
}
