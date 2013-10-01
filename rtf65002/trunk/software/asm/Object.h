#pragma once

#include "Archive.h"
#include "HashVal.h"

namespace RTFClasses
{
	class Object
	{
	public:
		Object() {};
		virtual ~Object() {};
		// persistence support
		virtual store(Archive &arc) {};
		virtual load(Archive &arc) {};
		virtual HashVal getHash() { HashVal a = {0,0}; return a; };
		virtual int cmp(Object *o) { return 0; };	// throw an exception
	};
}
