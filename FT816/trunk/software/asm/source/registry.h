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
		Registry(const char *k, int hive = 0x80000001);	// HKEY_CURRENT_USER
		int create();
		int write(const char *vname, int vtype, void *data, int cbData );
		int read(const char *vname, void *d, int n);
		bool check(const char *vname, const char *v);		// check key value
	};
}

