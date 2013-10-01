#include <stdio.h>
#include <string.h>
#include <time.h>
#include "MyString.h"
#include "Debug.h"

namespace RTFClasses
{
	void Debug::log(String msg)
	{
		FILE *fp;
		String pt;
		char buf[128];
		String dt, tm;

		pt = path;
		if (stricmp(&(pt.buf()[pt.len()-4]), ".exe")==0)
			pt.mid(0, pt.len()-4);
		pt += "_log@";
		dt = String(_strdate(buf));
		tm = String(_strtime(buf));
		dt.replace('/','-');
		pt += dt;

		fp = fopen(pt.buf(), "a+");
		tm += ' ';
		tm += msg;
		tm += "\r\n";
		fputs(tm.buf(), fp);
		fclose(fp);
	}
}

