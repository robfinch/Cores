#include "stdafx.h"

Expression::Expression()
{
	head = (TYP*)nullptr;
	tail = (TYP*)nullptr;
}

Function* Expression::MakeFunction(int symnum) {
	return (compiler.ff.MakeFunction(symnum));
};
