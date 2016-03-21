#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Subroutines in this file take care of temporary variable management */

#define SWIDTH 8
#define REGION_MAX 128	/* The maximum number of stack elements that can be
									used for temporaries. */
#define MARK	-1			/* Marks cells that are in use but are not the
									first cell of the region */
typedef int CELL;			/* In-use (Region) map is an array of these */

int tmpVarSpace();
void tmpFreeAll();
void tmpReset();
int tmpAlloc(int);
void tmpFree(int);

static CELL Region[REGION_MAX];
static CELL *HighWaterMark = Region;

/* ---------------------------------------------------------------------------
   Description :
      Allocate a portion of the temporary variable region of the required
	size, expanding the tmp-region size if necessary. Return the offset in
	bytes from the start of the rvalue region to the first cell of the
	temporary. 0 is returned if no space is available, and an error message is
	also printed in this situation. This way the code-generation can go on as
	if space had been found without having to worry about testing for errors.
	(Bad code is generated, but so what?)
--------------------------------------------------------------------------- */

int tmpAlloc(int size)
{
	CELL *start, *p;
	int i;

	if (size == 0)
		printf("INTERNAL, tmpAlloc: zero length region requested.\n");

	// Round size to smallest size of stack element
	//---------------------------------------------
	if (size % SWIDTH)
		size = size + SWIDTH - (size % SWIDTH);
	size /= SWIDTH;

	// Seach for an empty area big enough to contain the temp.
	//--------------------------------------------------------
	for (start = Region; start < HighWaterMark;)
	{
		for (i = size, p = start; --i >= 0 && !*p; ++p)
			;
		if (i >= 0)
			start = p+1;
		else
			break;
	}

	if (start < HighWaterMark)
		p = start;
	else
	{
		if ((HighWaterMark + size) > (Region + REGION_MAX))	// No room
		{
			printf("Expression too complex, break into smaller pieces.\n");
			return 0;
		}
		p = HighWaterMark;
		HighWaterMark += size;
	}
	for(*p = size; --size > 0; *++p = MARK)	/* 1st cell =size. Others = MARK) */
		;

	return ((start - Region)*SWIDTH);
}


/* ---------------------------------------------------------------------------
   Description :
      Release a temporary var.; offset should have been returned from
   tmp_alloc().
--------------------------------------------------------------------------- */

void tmpFree(int offset)
{
	CELL *p = Region + offset/SWIDTH;
	int size;

	if (p < Region || p > HighWaterMark || !*p || *p == MARK)
		printf("INTERNAL, tmpFree: Bad offset (%d)\n", offset);
	else
		for (size = *p; --size >= 0; *p++ = 0)
			;
}


/* ---------------------------------------------------------------
	Description :
		Reset everything back to the virgin state, including
	the HighWater mark. This routine should be called just
	before a subroutine body is processed, when the prefix is
	output. See also: tmpFreeall().
--------------------------------------------------------------- */

void tmpReset()
{
	tmpFreeAll();
	HighWaterMark = Region;
}


/* ---------------------------------------------------------------
	Description :
		Free all temporaries currently in use (without modifying
	the high-water mark). This subroutine should be called
	after processing arithmetic statements to clean up any
	temporaries still kicking around (there is usually at least
	one).
--------------------------------------------------------------- */

void tmpFreeAll()
{
	memset(Region, 0, sizeof(Region));
}


/* ---------------------------------------------------------------
	Description :
		Return the total cumulative size of the temporary
	variable region in stack elements, not bytes. This number
	can be used as an argument to the link instruction.
	
	Returns :
		Size in stack elements of temporary variable area.
--------------------------------------------------------------- */

int tmpVarSpace()
{
	return (HighWaterMark - Region)*SWIDTH;
}
