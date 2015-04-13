#include "StdAfx.h"
#include "clsKeyboard.h"


clsKeyboard::clsKeyboard(void)
{
	scancode = 0;
	status = 0;
	sp = sizeof(stack);
}


clsKeyboard::~clsKeyboard(void)
{
}
