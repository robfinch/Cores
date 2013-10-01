#pragma once

#include <stdio.h>
#include "MyString.h"

namespace RTFClasses
{
	class Debug
	{
		int level;
		String path;
	public:
		Debug() { level = 1; };
		Debug(int n, String p) { level = n; path = p; };
		void set(int n, String p) { level = n; path = p; };
		void log(String s);
		void log1(String s) { if (level >= 1) log(s); };
		void log2(String s) { if (level >= 2) log(s); };
		void log3(String s) { if (level >= 3) log(s); };
		void log4(String s) { if (level >= 4) log(s); };
		void log5(String s) { if (level >= 5) log(s); };
	};
}
