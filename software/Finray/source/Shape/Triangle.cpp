#include "stdafx.h"

// Triangle math for intersection point implemented from Dan Sunday's article
// http://geomalgorithms.com/a06-_intersect-2.html

namespace Finray {

ATriangle::ATriangle(Vector pt1, Vector pt2, Vector pt3) : AnObject()
{
	type = OBJ_TRIANGLE;
	p1 = pt1;
	p2 = pt2;
	p3 = pt3;
	Init();
	CalcBoundingObject();
}

ATriangle::ATriangle() : AnObject()
{
	type = OBJ_TRIANGLE;
	p1 = Vector(0,0,0);
	p2 = Vector(1,0,0);
	p3 = Vector(1,1,0);
	Init();
	CalcBoundingObject();
}

void ATriangle::Init()
{
	type = OBJ_TRIANGLE;
	CalcNormal();
	CalcCentroid();
}

bool ATriangle::InternalSide(Vector pt1, Vector pt2, Vector a, Vector b)
{
	Vector cp1, cp2;
	Vector c, d, e;

	c = Vector::Sub(b,a);
	d = Vector::Sub(pt1,a);
	e = Vector::Sub(pt2,a);
	cp1 = Vector::Cross(c,d);
	cp2 = Vector::Cross(c,e);
	if (Vector::Dot(cp1,cp2) > EPSILON)
		return (true);
	return (false);
}

bool ATriangle::PointInTriangle(Vector p)
{
	return (InternalSide(p, p1, p2, p3)
		&& InternalSide(p, p2, p1, p3)
		&& InternalSide(p, p3, p1, p2));
}

bool ATriangle::IsInside(Vector p)
{
	return (PointInTriangle(p) ^ inverted);
}

void ATriangle::CalcNormal()
{
	u = Vector::Sub(p2,p1);
	v = Vector::Sub(p3,p1);
	uu = Vector::Dot(u,u);
	uv = Vector::Dot(u,v);
	vv = Vector::Dot(v,v);
	D = uv * uv - uu * vv;
	unnormal = Vector::Cross(u,v);
	normal = Vector::Normalize(unnormal);
}

// Return
// -1: triangle is degenerate ( a point or a segment)
//  0: no intersect
//  1: intersect in unique point
//  2: are in same plane
//
IntersectResult *ATriangle::Intersect(Ray *ray)
{
	Vector w, w0, I;
	DBL r,a,b;
	DBL wu, wv;
	DBL s, t;
	IntersectResult *res = nullptr;
	Vector rd, ro;

	if (!BoundingIntersect(ray))
		return(res);

	rd = ray->dir;
	ro = ray->origin;

	if (abs(normal.x) < EPSILON && abs(normal.y) < EPSILON && abs(normal.z) < EPSILON)
		throw gcnew Finray::FinrayException(ERR_DEGENERATE,2);
//	if (normal.x == 0.0 && normal.y == 0.0 && normal.z == 0.0)
//		return (nullptr);//-1;	// triangle is degenerate

	w0 = Vector::Sub(ro, p1);
	a = -Vector::Dot(unnormal,w0);
	b = Vector::Dot(unnormal,rd);
	if (fabs(b) < EPSILON) {
		if (fabs(a) < EPSILON) {		// ray lines in triangle plane
			res = new IntersectResult;
			res->n = 1;
			res->I[0].obj = this;
			res->I[0].T = Vector::Length(w0);
			res->I[0].P = p1;
			res->I[0].part = 1;
			return (res);//2;	// return 2;
		}
		return (nullptr);
	}

	// Get intersection point of ray within triangle plane
	r = a / b;
	if (r < 0.0)		// ray goes away from the triangle
		return (nullptr);

	I = Vector::AddScale(ro, rd, r);

	// Is I inside T ?
	w = Vector::Sub(I,p1);
	wu = Vector::Dot(w,u);
	wv = Vector::Dot(w,v);
	
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
	res->I[0].P = Vector::AddScale(ro, rd, res->I[0].T);
	res->n = 1;
	return (res);	//1	// I is in T
}

void ATriangle::RotX(DBL a)
{
	p1 = Vector::RotX(p1, a);
	p2 = Vector::RotX(p2, a);
	p3 = Vector::RotX(p3, a);
	Init();
}

void ATriangle::RotY(DBL a)
{
	p1 = Vector::RotY(p1, a);
	p2 = Vector::RotY(p2, a);
	p3 = Vector::RotY(p3, a);
	Init();
}

void ATriangle::RotZ(DBL a)
{
	p1 = Vector::RotZ(p1, a);
	p2 = Vector::RotZ(p2, a);
	p3 = Vector::RotZ(p3, a);
	Init();
}

Vector ATriangle::Normal(Vector p)
{
	return (normal);
}

// The normal should remain the same
void ATriangle::Translate(Vector p)
{
	Vector d1 = Vector::Sub(p1,center);
	Vector d2 = Vector::Sub(p2,center);
	Vector d3 = Vector::Sub(p3,center);
	center = Vector::Add(center,p);
	p1 = Vector::Add(center,d1);
	p2 = Vector::Add(center,d2);
	p3 = Vector::Add(center,d3);
	Init();
}

void ATriangle::Scale(Vector p)
{
	p1.x = p1.x * p.x;
	p2.x = p2.x * p.x;
	p3.x = p3.x * p.x;

	p1.y = p1.y * p.y;
	p2.y = p2.y * p.y;
	p3.y = p3.y * p.y;

	p1.z = p1.z * p.z;
	p2.z = p2.z * p.z;
	p3.z = p3.z * p.z;

	Init();
	CalcBoundingObject();
}

void ATriangle::CalcCentroid()
{
	center = Vector::Add(p1,p2);
	center = Vector::Add(p3,center);
	center = Vector::Scale(center,0.33333333333333333333);
}

void ATriangle::CalcBoundingObject()
{
	DBL d1,d2,d3;
	
	d1 = Vector::Length(Vector::Sub(p1,center));
	d2 = Vector::Length(Vector::Sub(p2,center));
	d3 = Vector::Length(Vector::Sub(p3,center));
	radius = d1;
	radius = fabs(d2) > radius ? fabs(d2) : radius;
	radius = fabs(d3) > radius ? fabs(d3) : radius;
	radius += EPSILON;
	radius2 = SQUARE(radius);
}

};
