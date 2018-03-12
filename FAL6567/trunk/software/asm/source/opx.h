#pragma once
#include "opa.h"

/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved.

	opx.h

		Please read the Licensing Agreement included in
	license.html. Use of this file is subject to the
	license agreement.

	You are free to use and modify this code for non-commercial
	or evaluation purposes.
	
	If you do modify the code, please state the origin and
	note that you have modified the code.

=============================================================== */

typedef struct _tagOpx
{
	char *mne;
	Opa *asms;
	int maxoperands;
} Opx;
