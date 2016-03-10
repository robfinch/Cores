#include "stdafx.h"

extern Finray::RayTracer rayTracer;

namespace Finray {

ASphere::ASphere()
{
	type = OBJ_SPHERE;
	center.x = center.y = center.z = 0;
	radius = 0;
	radius2 = 0;
	obj = nullptr;
	next = nullptr;
}

ASphere::ASphere(double X, double Y, double Z, double R)
{
	type = OBJ_SPHERE;
	center.x = X;
	center.y = Y;
	center.z = Z;
	radius = R;
	radius2 = SQUARE(R);
	obj = nullptr;
	next = nullptr;
}

int ASphere::Intersect(Ray *ray, double *T)
{
	double B, C, Discrim, t0, t1;

	// Don't need to calculate A since ray is a unit vector
	B = 2 * ((ray->dir.x * (ray->origin.x - center.x))
			+(ray->dir.y * (ray->origin.y - center.y))
			+(ray->dir.z * (ray->origin.z - center.z)));
	C =   SQUARE(ray->origin.x - center.x)
		+ SQUARE(ray->origin.y - center.y)
		+ SQUARE(ray->origin.z - center.z)
		- radius2;

	Discrim = (SQUARE(B) - 4 * C);
	if (Discrim <= EPSILON)
		return 0;

	Discrim = sqrt(Discrim);
	t0 = (-B-Discrim) * 0.5;
	if (t0 > EPSILON) {
		*T = t0;
		return 1;
	}
	t1 = (-B+Discrim) * 0.5;
	if (t1 > EPSILON) {
		*T = t1;
		return 1;
	}
	return 0;
}

Vector ASphere::Normal(Vector point)
{
	return Vector::Normalize(Vector::Sub(point, center));
}

void ASphere::RotX(double angle)
{
	center = Vector::RotX(center, angle);
}

void ASphere::RotY(double angle)
{
	center = Vector::RotY(center, angle);
}

void ASphere::RotZ(double angle)
{
	center = Vector::RotZ(center, angle);
}

void ASphere::Print()
{
}

};
