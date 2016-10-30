#pragma once

namespace Finray
{
class Pigment
{
public:
	Color color;
	ColorMap *cm;
	Vector3d gradient;
public:
	Pigment();
	~Pigment();
};

}
