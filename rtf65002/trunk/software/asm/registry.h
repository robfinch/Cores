#pragma once

/* ===============================================================
	(C) 2006  Robert Finch
	All rights reserved.

	registry.h
=============================================================== */

namespace RTFClasses
{
	class Registry
	{
		char rootKey[1024];
		int hive;
	public:
		Registry(char *k, int hive = 0x80000001);	// HKEY_CURRENT_USER
		int create();
		int write(char *vname, int vtype, void *data, int cbData );
		int read(char *vname, void *d, int n);
		bool check(char *vname, char *v);		// check key value
	};
}

