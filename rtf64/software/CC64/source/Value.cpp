#include "stdafx.h"

Value *Value::MakeNew()
{
	Value* p;
	p = (Value*)allocx(sizeof(Value));
	ZeroMemory(p, sizeof(Value));
	return (p);
}

