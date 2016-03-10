#include "stdafx.h"

using namespace Finray;

namespace Finray {

Surface::Surface()
{
	color.r = 0.0;
	color.g = 0.0;
	color.b = 0.0;
	ambient = 0.0;
	diffuse = 0.0;
	brilliance = 0.0;
	specular = 0.0;
	roughness = 0.0;
	reflection = 0.0;
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
}

void Surface::SetAttrib(float rd, float gn, float bl, float a, float d, float b, float s, float ro, float r)
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

};
