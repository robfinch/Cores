#include "stdafx.h"

namespace Finray {

ASphere::ASphere() : AnObject()
{
	type = OBJ_SPHERE;
	center.x = center.y = center.z = 0;
	radius = 1;
	radius2 = 1;
}

ASphere::ASphere(Vector P, double R) : AnObject()
{
	type = OBJ_SPHERE;
	center = P;
	radius = R;
	radius2 = SQUARE(R);
}

ASphere::ASphere(double X, double Y, double Z, double R)  : AnObject()
{
	type = OBJ_SPHERE;
	center.x = X;
	center.y = Y;
	center.z = Z;
	radius = R;
	radius2 = SQUARE(R);
}

// Detect intersection of ray with sphere.

IntersectResult *ASphere::Intersect(Ray *ray)
{
	DBL B, C, Discrim, t0, t1, len;
	IntersectResult *r = nullptr;
	Vector ro, rd;

	if (usesTransform) {
		ro = trans.InvTransPoint(ray->origin);
		rd = trans.InvTransDirection(ray->dir);
		len = Vector::Length(rd);
		rd = Vector::Scale(rd, 1.0/len);
	}
	else {
		ro = ray->origin;
		rd = ray->dir;
	}

	// Don't need to calculate A since ray is a unit vector
	B = 2 * ((rd.x * (ro.x - center.x))
			+(rd.y * (ro.y - center.y))
			+(rd.z * (ro.z - center.z)));
	C =   SQUARE(ro.x - center.x)
		+ SQUARE(ro.y - center.y)
		+ SQUARE(ro.z - center.z)
		- radius2;

	Discrim = (SQUARE(B) - 4 * C);
	if (Discrim <= EPSILON)
		return (nullptr);

	Discrim = sqrt(Discrim);
	t0 = (-B-Discrim) * 0.5;
	t1 = (-B+Discrim) * 0.5;
	if (t0 > EPSILON || t1 > EPSILON) {
		r = new IntersectResult;
		r->I[0].obj = this;
	}
	if (t0 > EPSILON) {
		if (usesTransform)
			r->I[0].T = t0 / len;
		else
			r->I[0].T = t0;
		r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
		r->n = 1;
	}
	if (t1 > EPSILON) {
		if (usesTransform)
			r->I[r->n].T = t1/len;
		else
			r->I[r->n].T = t1;
		r->I[r->n].obj = this;
		r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
		r->n++;
	}
	return (r);
}

Vector ASphere::Normal(Vector point)
{
	if (usesTransform) {
		Vector np = trans.InvTransPoint(point);
		Vector result = Vector::Sub(np,center);
		result = trans.TransNormal(result);
		return (Vector::Normalize(result));
	}
	else
		return (Vector::Normalize(Vector::Sub(point, center)));
}

void ASphere::RotX(DBL angle)
{
	if (usesTransform) {
		Transform T;
		Vector v(angle,0.0,0.0);
		T.CalcRotation(v);
		TransformX(&T);
	}
	else
		center = Vector::RotX(center, angle);
}

void ASphere::RotY(double angle)
{
	if (usesTransform) {
		Transform T;
		Vector v(0.0,angle,0.0);
		T.CalcRotation(v);
		TransformX(&T);
	}
	else
		center = Vector::RotY(center, angle);
}

void ASphere::RotZ(double angle)
{
	if (usesTransform) {
		Transform T;
		Vector v(0.0,0.0,angle);
		T.CalcRotation(v);
		TransformX(&T);
	}
	else
		center = Vector::RotZ(center, angle);
}

void ASphere::Translate(Vector v)
{
	if (usesTransform) {
		Transform T;
		T.CalcTranslation(v);
		TransformX(&T);
	}
	else {
		center = Vector::Add(center,v);
	}
}

void ASphere::Scale(Vector p)
{
	if (p.x != p.y || p.x != p.z || p.y != p.z)
	{
		if (!usesTransform) {
			Transform T;
			T.CalcTranslation(center);
			center.x = center.y = center.z = 0.0;
			usesTransform = true;
		}
		Transform T;
		T.CalcScaling(p);
		TransformX(&T);
	}
	else {
		if (usesTransform) {
			Transform T;
			T.CalcScaling(p);
			TransformX(&T);
		}
		else {
			radius = radius * Vector::Length(p);
			radius2 = SQUARE(radius);
		}
	}
}


bool ASphere::IsInside(Vector point)
{
	Vector t;
	DBL tt;

	if (usesTransform) {
		point = trans.InvTransPoint(point);
	}
	t = Vector::Sub(center,point);
	tt = Vector::Dot(t,t);
	return (inverted ? tt > radius2 : tt < radius2);
}


void ASphere::Print()
{
}

};
