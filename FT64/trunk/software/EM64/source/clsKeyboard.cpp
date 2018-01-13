#include "StdAfx.h"
#include "clsKeyboard.h"


clsKeyboard::clsKeyboard(void)
{
	scancode = 0;
	status = 0;
	head = tail = 0;
}


clsKeyboard::~clsKeyboard(void)
{
}
