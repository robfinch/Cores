#pragma once
#include "clsDevice.h"

class clsSevenSeg : public clsDevice
{
public:
	unsigned int dat;
public:
	bool IsSelected(unsigned int ad);
	void Write(unsigned int ad, unsigned int dat);
};

