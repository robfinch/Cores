#include "stdafx.h"

namespace Finray
{

	
Pigment::Pigment()
{
	cm = nullptr;
	gradient = Vector(0.0,0.0,0.0);
}

Pigment::~Pigment()
{
	if (cm)
		delete cm;
}

}
