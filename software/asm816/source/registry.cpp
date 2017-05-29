#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include "String.h"
#include "registry.h"
#include <math.h>

namespace RTFClasses
{
	// Create object.
	Registry::Registry(const char *rk, int hv)
	{
		hive = hv;
		strncpy(rootKey, rk, sizeof(rootKey));
	}


	// write some key to the registry
	int Registry::write(const char *vname, int vtype, void *data, int cbData )
	{
		HKEY hKey;
		int ret;

		if ((ret = ::RegOpenKeyEx((HKEY)hive, rootKey, 0, KEY_WRITE, &hKey))==ERROR_SUCCESS)
		{
			ret = ::RegSetValueEx(hKey, vname, 0, (DWORD)vtype, (const BYTE *)data, (DWORD)cbData);
			::RegCloseKey(hKey);
		}
		return ret;
	}


	// read a key
	int Registry::read(const char *vname, void *d, int n)
	{
		HKEY hKey;
		BYTE data [1024];
		DWORD cbData = 1024;
		DWORD vtype;
		int ret;
        
		memset(data, 0, sizeof(data));
		memset(d, 0, n);
		if ((ret = ::RegOpenKeyEx((HKEY)hive, rootKey, 0, KEY_READ, &hKey))==ERROR_SUCCESS)
		{
			::RegQueryValueEx(hKey, vname, 0, &vtype, data, &cbData);
			::RegCloseKey(hKey);
			memcpy(d, data, cbData < n ? cbData : n);
		}
		return ret;
	}


	// Check if a particular key has a particular value
	bool Registry::check(const char *vname, const char *v)
	{
		char d[1000];

		if (read(vname, (void *)d, sizeof(d))!=ERROR_SUCCESS)
			return false;
		return strcmp(d, v)==0;
	}


	// create a key
	int Registry::create()
	{
		HKEY hKey;
		DWORD res;
		int ret;

		ret = ::RegCreateKeyEx((HKEY)hive, rootKey, 0, 0, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0, &hKey, &res);
		::RegCloseKey(hKey);
		return ret;
	}
}


