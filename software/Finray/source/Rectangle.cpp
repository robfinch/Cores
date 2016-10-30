#include "stdafx.h"

namespace Finray {

ARectangle::ARectangle(Vector a, Vector b, Vector c, Vector d) : AnObject()
{
	p1 = a;
	p2 = b;
	p3 = c;
	p4 = d;
}

// The normals determined by cross products of any three point in a
// rectangle (rhombus) should all be the same. If they're not then
// the four points aren't all in the same plane.

void ARectangle::CalcNormal()
{
	Vector norm1, norm2;
	Vector u = Vector::Sub(p2,p1);
	Vector w = Vector::Sub(p3,p1);
	Vector x = Vector::Sub(p4,p1);
	norm1 = Vector::Cross(u,w);
	norm2 = Vector::Cross(u,x);
	norm1 = Vector::Normalize(norm1);
	norm2 = Vector::Normalize(norm2);
	if (abs(norm1.x) - abs(norm2.x) > EPSILON)
		throw gcnew Finray::FinrayException(ERR_NONPLANER,0);
	if (abs(norm1.y) - abs(norm2.y) > EPSILON)
		throw gcnew Finray::FinrayException(ERR_NONPLANER,0);
	if (abs(norm1.z) - abs(norm2.z) > EPSILON)
		throw gcnew Finray::FinrayException(ERR_NONPLANER,0);
	normal = norm1;
}

void ARectangle::RotX(double a)
{
	p1 = Vector::RotX(p1, a);
	p2 = Vector::RotX(p2, a);
	p3 = Vector::RotX(p3, a);
	p4 = Vector::RotX(p4, a);
	CalcNormal();
}

void ARectangle::RotY(double a)
{
	p1 = Vector::RotY(p1, a);
	p2 = Vector::RotY(p2, a);
	p3 = Vector::RotY(p3, a);
	p4 = Vector::RotY(p4, a);
	CalcNormal();
}

void ARectangle::RotZ(double a)
{
	p1 = Vector::RotZ(p1, a);
	p2 = Vector::RotZ(p2, a);
	p3 = Vector::RotZ(p3, a);
	p4 = Vector::RotZ(p4, a);
	CalcNormal();
}

// Return
// -1: triangle is degenerate ( a point or a segment)
//  0: no intersect
//  1: intersect in unique point
//  2: are in same plane
//
IntersectResult *ARectangle::Intersect(Ray *ray)
{
	Vector u, v, w, x, w0, I;
	double r,a,b;
	double uu, uv, vv, wu, wv, D;
	double s, t;
	IntersectResult *res = nullptr;

	if (normal.x < EPSILON && normal.y < EPSILON && normal.z < EPSILON)
		return (nullptr);//-1;	// triangle is degenerate

	w0 = Vector::Sub(ray->origin, p1);
	a = -Vector::Dot(normal,w0);
	b = Vector::Dot(normal,ray->dir);
	if (abs(b) < EPSILON) {
		if (a==0.0)	{	// ray lines in rectangle plane
			res = new IntersectResult;
			res->I[0].obj = this;
			return (res); //2;	// return 2;
		}
		return (nullptr);
	}

	u = Vector::Sub(p2,p1);
	v = Vector::Sub(p3,p1);
	x = Vector::Sub(p4,p1);

	// Get intersection point of ray within rectangle plane
	r = a / b;
	if (r < 0.0)		// ray goes away from the triangle
		return (nullptr);

	I = Vector::Add(ray->origin, Vector::Scale(ray->dir, r));

	// Is I inside T1 ?
	uu = Vector::Dot(u,u);
	uv = Vector::Dot(u,v);
	vv = Vector::Dot(v,v);
	w = Vector::Sub(I,p1);
	wu = Vector::Dot(w,u);
	wv = Vector::Dot(w,v);
	D = uv * uv - uu * vv;
	
	// Get and test parametric co-ords
	s = (uv * wv - vv * wu) / D;
	if (s < 0.0 || s > 1.0) // I is outside of T
		goto j1;
	t = (uv * wu - uu * wv) / D;
	if (t < 0.0 || (s+t) > 1.0)	// I is outside of T
		goto j1;
	res = new IntersectResult;
	res->I[0].obj = this;
	res->I[0].T = r;
	res->n = 1;
	return (res);//1;		// I is in T
j1:
	// Is I inside T2 ?
	uv = Vector::Dot(u,x);
	vv = Vector::Dot(x,x);
	wv = Vector::Dot(w,x);
	D = uv * uv - uu * vv;
	
	// Get and test parametric co-ords
	s = (uv * wv - vv * wu) / D;
	if (s < 0.0 || s > 1.0) // I is outside of T
		return (nullptr);
	t = (uv * wu - uu * wv) / D;
	if (t < 0.0 || (s+t) > 1.0)	// I is outside of T
		return (nullptr);
	res = new IntersectResult;
	res->I[0].obj = this;
	res->I[0].T = r;
	res->n = 1;
	return (res);//1;		// I is in T
}

Vector ARectangle::Normal(Vector p)
{
	return normal;
}


};
