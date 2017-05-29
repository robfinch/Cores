#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include "err.h"
#include "HashVal.h"
#include "sym.h"
#include "Assembler.h"
#include "Counter.h"

namespace RTFClasses
{
	// Define symbol. Value is assigned the current section counter.

	void Symbol::define(int ocls)
	{
		// Set section and offset value
		base = theAssembler.getCurrentArea();
		value = theAssembler.getCounter().val;
		if ((unsigned long)value < (unsigned)0x8000L || (unsigned)value >= (unsigned)0xffff8000L) {
			_long = false;
			size = 'H';
		}
		else {
			_long = true;
			size = 'W';
		}
		oclass = ocls;
		if (ocls==PUB)
			_extern = false;
		if (ocls==EXT)
			_extern = true;
		line = theAssembler.getCurLinenum();
		file = theAssembler.getCurFilenum();
		defined = 1;
		label = 1;
	}


	// Compare two symbols.
	bool Symbol::equals(Symbol *b) {
		if (b == NULL)
			return false;
		return name==b->name;
	}

	int Symbol::cmp(Object *ps)
	{
		int r;
		int l1, l2;
		Symbol *ts;

		//printf("Comparing: %s to %s\r\n", (char *)name.buf(),(char *)((Symbol *)ps)->name.buf());
		ts = (Symbol*)ps;
		r = strcmp((char *)name.buf(), (char *)((Symbol *)ps)->name.buf());
		//printf("result: %d\r\n", r);
//		if (r==0) getchar();
		if (r==0) {
			l1 = strlen((char *)name.buf());
			l2 = strlen((char *)((Symbol *)ps)->name.buf());
			if (l1 > l2) return 1;
			if (l1==l2) return 0;
			return -1;
		}
		return r;
	}

	// Print a single symbol.

	void Symbol::print(FILE *fp)
	{
		fprintf(fp, "%c %-32.32s %3.3s  %4.4s   %c   %08lX%08lX   %5d   %s", phaseErr ? '*' : ' ', name.buf(), oclassstr(oclass),
		basestr(base), size, (__int32)(value >> 32), (__int32)(value & 0xffffffff), line, theAssembler.File[file].name.buf());
	}

	int Symbol::print2(FILE *fp)
	{
		fprintf(fp, "%s    16'h%04lX", name.buf(), (__int32)(value & 0xffff));
		return 1;
	}

	const char *Symbol::oclassstr(int n) const
	{
	static const char *str[5] = {
		"NON\0", "PUB\0", "PRI\0", "COM\0", "EXT\0"
	};
	return (n < 5 && n >= 0) ? str[n] : (char *)"<?>";
	}

	const char *Symbol::basestr(int n) const
	{
	static const char *str[4] = {
		"DATA\0", "CODE\0", "BSS\0", "NONE\0" };
		return (n < 4 && n >= 0) ? str[n] : (char *)"<?>";
	}
}


