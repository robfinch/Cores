#include "stdafx.h"
extern Finray::RayTracer rayTracer;

namespace Finray {

APlane::APlane() : AnObject()
{
	type = OBJ_PLANE;
	normal.x = 0;
	normal.y = 0;
	normal.z = 0;
	distance = 0;
	center = Vector(0,0,0);
	radius = BIG;
	radius2 = (SQUARE(BIG));
}

APlane::APlane(double A, double B, double C, double D) : AnObject()
{
	type = OBJ_PLANE;
	normal.x = A;
	normal.y = B;
	normal.z = C;
	distance = -D;
	normal = Vector::Normalize(normal);
	center = normal;
	radius = BIG;
	radius2 = (SQUARE(BIG));
}

int APlane::Intersect(Ray *ray, double *T)
{
	double Vd, Vo;

	Vd = Vector::Dot(normal, ray->dir);
	if (Vd <= EPSILON)
		return (0);

	Vo = Vector::Dot(normal,ray->origin);
	Vo += distance;
	Vo *= -1.0;

	*T = Vo/Vd;
	if (*T < 0.0)
		return (0);
	return (1);
}

Vector APlane::Normal(Vector point)
{
	return normal;
}

void APlane::RotX(double angle)
{
	normal = Vector::RotX(normal, angle);
}

void APlane::RotY(double angle)
{
	normal = Vector::RotY(normal, angle);
}

void APlane::RotZ(double angle)
{
	normal = Vector::RotZ(normal, angle);
}

void Print()
{
}

};
