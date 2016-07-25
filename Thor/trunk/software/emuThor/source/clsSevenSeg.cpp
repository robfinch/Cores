#include "stdafx.h"

bool clsSevenSeg::IsSelected(unsigned int ad)
{
	return (ad & 0xFFFFFFF0)==0xFFDC0080;
}

void clsSevenSeg::Write(unsigned int ad, unsigned int dt)
{
	if (IsSelected(ad))
		dat = dt;
}
