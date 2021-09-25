#include "stdafx.h"

Object::Object()
{
	magic = 0;
	size = 0;
	typenum = 0;
	id = 0;
	state = 0;
	scavangeCount = 0;
	owningMap = 0;
	pad1 = 0;
	pad2 = 0;
	usedInMap = 0;
	forwardingAddress = nullptr;
	finalizer = nullptr;
}
