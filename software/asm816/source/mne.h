#pragma once
#include "opa.h"

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.
=============================================================== */

namespace RTFClasses
{
	class Mne
	{
	// Do not add any non-public data members or virtual functions!
	public:
		const char *mne;			// base name of the mnemonic
		Opa *asms;
		int maxoperands;	// -1 = don't care
	};
}
