/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	OpTable.cpp

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

#include <string.h>
#include "Op.h"
#include "OpTable.h"

// Search for a particular mnemonic in the table
Op *OpTable::find(char *mne)
{
	int dir;
	int high = size - 1;
	int low = 0;
	int ii = 0;
	int lastii = -1;

	// Do a binary search
	// the opcode tables should be in alphabetical order
	do
	{
		lastii = ii;
		ii = (high + low) / 2;
		dir = stricmp(mne, table[ii].mneu);
		if (dir==0)
			return &table[ii];
		else if (dir < 0)
			high = low;
		else
			low = high;
	}
	while (ii != lastii);

	// Now do a linear search, just in case the tables
	// aren't in order
	// should log this fact somewhere.
	for (ii = 0; ii < size; ii++)
	{
		dir = stricmp(mne, table[ii].mneu);
		if (dir==0)
			return &table[ii];
	}

	// Still couldn't find it.
	return 0;
}


