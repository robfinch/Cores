#include "stdafx.h"

extern FinitronClasses::NoiseGen noiseGen;

using namespace Finray;

namespace Finray {

Surface::Surface()
{
	color.r = 0.0;
	color.g = 0.0;
	color.b = 0.0;
	ambient.r = 0.0;
	ambient.g = 0.0;
	ambient.b = 0.0;
	diffuse = 0.0;
	brilliance = 0.0;
	specular = 0.0;
	roughness = 0.0;
	reflection = 0.0;
	ColorMethod = 0;
}

Surface::Surface(Surface *s)
{
	color.r = s->color.r;
	color.g = s->color.g;
	color.b = s->color.b;
	ambient = s->ambient;
	diffuse = s->diffuse;
	brilliance = s->brilliance;
	specular = s->specular;
	roughness = s->roughness;
	reflection = s->reflection;
	ColorMethod = s->ColorMethod;
}

void Surface::SetAttrib(float rd, float gn, float bl, Color a, float d, float b, float s, float ro, float r)
{
	color.r = rd;
	color.g = gn;
	color.b = bl;
	ambient = a;
	diffuse = d;
	brilliance = b;
	specular = s;
	roughness = ro;
	reflection = r;
}

Color Surface::GetColor(Vector point)
{
	Color c;
	double n;
	double r,g,b;
	int rb,gb,bb,ndx;
	static RTFClasses::Random *prand = nullptr;

	if (prand==nullptr)
		prand = RTFClasses::Random::srand(21);

	switch(ColorMethod) {
	case 0:	return color;
	case 1:
		n = noiseGen.Noise(point, 2.0, 2.0, 4);
		c = color;
		c.r += n;
		c.g += n;
		c.b += n;
		if (c.r > 1.0) c.r = 1.0;
		if (c.g > 1.0) c.g = 1.0;
		if (c.b > 1.0) c.b = 1.0;
		if (c.r < 0.0) c.r = 0.0;
		if (c.g < 0.0) c.g = 0.0;
		if (c.b < 0.0) c.b = 0.0;
		return c;
	case 2:
		r = fmod(point.x,1.0);
		if (fabs(r) > 0.5) rb = 4; else rb = 0;
		g = fmod(point.y,1.0);
		if (fabs(g) > 0.5) gb = 2; else gb = 0;
		b = fmod(point.z,1.0);
		if (fabs(b) > 0.5) bb = 1; else bb = 0;
		ndx = rb|gb|bb;
		switch(ndx) {
		case 0:	c.r = 0.0; c.g = 0.0; c.b = 0.0; break;
		case 1:	c.r = 0.0; c.g = 0.0; c.b = 1.0; break;
		case 2:	c.r = 0.0; c.g = 1.0; c.b = 0.0; break;
		case 3:	c.r = 0.0; c.g = 1.0; c.b = 1.0; break;
		case 4:	c.r = 1.0; c.g = 0.0; c.b = 0.0; break;
		case 5:	c.r = 1.0; c.g = 0.0; c.b = 1.0; break;
		case 6:	c.r = 1.0; c.g = 1.0; c.b = 0.0; break;
		case 7:	c.r = 1.0; c.g = 1.0; c.b = 1.0; break;
		}
		return c;
	case 255:
		c.r = (float)prand->rand(256) / 256.0;
		c.g = (float)prand->rand(256) / 256.0;
		c.b = (float)prand->rand(256) / 256.0;
		return c;
	}
}

};
