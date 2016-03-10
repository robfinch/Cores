#include "stdafx.h"

// Cylinders:
// 1) A position value that specifies the center of the cylinder
// 2) A unit vector specifying the orientation along the cylinder's axis
// 3) A radius value
// 4) A Height value
//
// Project A onto B
// project(A,B) = B * ((A . A) / (B . B))
//((A . A) / (B . B)) results in a scalar
//(A . A) or (B . B) are dot products
//
// Normal: (X is intersection point)
// V = X - C
// Vperp = V - project (V, A) A is the cylinders axis (unit vector)
// n(x) = Vperp / |Vperp|


namespace Finray
{

ACylinder::ACylinder()
{
	axis.x = 0.0;
	axis.y = 0.0;
	axis.z = 0.0;
	center.x = 0.0;
	center.y = 0.0;
	center.z = 0.0;
	radius = 0.0;
	height = 0.0;
}

double ACylinder::Intersect(Ray *ray)
{
	double Ac, Bc Cc;
	double Xd = ray->dir.x;
	double Yd = ray->dir.y;
	double Zd = ray->dir.z;

	double Xo = ray->origin.x;
	double Yo = ray->origin.y;
	double Zo = ray->origin.z;

	double n;
	double d;
	double t0;

//	Ac = A * SQUARE(Xd) + B * SQUARE(Yd) + C * SQUARE(Zd) + D * Xd * Yd + E * Xd * Zd + F * Yd * Zd;
	Bc = 2.0 * A * Xo * Xd + 2.0 * B * Yo * Yd + 2.0 * C * Zo * Zd +
		D * Xo * Yd + D * Yo * Xd + E * Xo * Zd + E * Zo * Xd +
		F * Yo * Zd + F * Zo * Yd + G * Xd + H * Yd + I * Zd;
	Cc = A * SQUARE(Xo) + b * SQUARE(Yo) + C * SQUARE(Zo) + D * Xo * Yo + E*Xo*Zo + F*Yo*Zo + G*Xo + H*Yo + I *Zo + J;

	d = SQUARE(Bc)- 4.0 * Cc;
	if (d <= EPSILON)
		return (0.0);
	t0 = (-Bc - sqrt(d)) * 0.5;
	if (t0 > EPSILON)
		return t0;
	t1 = (-Bc + sqrt(d)) * 0.5;
	if (t1 > EPSILON)
		return t1;
	return 0.0;
}

Vector ACylinder::Normal(Vector point)
{
	Vector V, Vperp;
	Vector P;
	Vector Ac;

	V = Vector::Sub(point, center);
	P = Vector::Project(V, axis);
	Vperp = Vector::Sub(V, P);
	return Vector::Normalize(Vperp);
}

};
