// Much of this code originated from POV-Ray
//
#include "stdafx.h"

namespace Finray {

const double ACone::tolerance = 1e-09;

ACylinder::ACylinder(Vector b, Vector a, double r) : ACone(b, a, r, r)
{
	type = OBJ_CYLINDER;
/*
	base = b;
	apex = a;
	baseRadius = r;
	apexRadius = r;
	next = nullptr;
	obj = nullptr;
	negobj = nullptr;
*/
	CalcTransform();
}

void ACylinder::CalcTransform()
{
	DBL len;
	Vector axis;

	axis = Vector::Sub(apex, base);
	len = Vector::Length(axis);

	if (len < EPSILON) {
		throw gcnew Finray::FinrayException(ERR_DEGENERATE,1);
	}
	else {
		axis = Vector::Scale(axis, 1.0/len);
		trans.CalcCoordinate(base, axis, apexRadius, len);
	}
	length = 0.0;
	CalcBoundingObject();
}


IntersectResult *ACylinder::Intersect(Ray *ray)
{
	int i = 0;
	DBL a, b, c, z, t1, t2, len;
	DBL d;
	Vector P, D;
	IntersectResult *r = nullptr;

	// Transform the ray into the cones space

	P = trans.InvTransPoint(ray->origin);
	D = trans.InvTransDirection(ray->dir);
	len = D.Length(D);
	D = Vector::Normalize(D);

	// Solve intersections with a cylinder

	a = D.x * D.x + D.y * D.y;

	if (a > EPSILON) {
		b = P.x * D.x + P.y * D.y;
		c = P.x * P.x + P.y * P.y - 1.0;
		d = b * b - a * c;

		if (d >= 0.0) {
			d = sqrt(d);
			t1 = (-b + d) / a;
			t2 = (-b - d) / a;
			z = P.z + t1 * D.z;
			if ((t1 > tolerance) && (t1 < BIG) && (z >= 0.0) && (z <= 1.0))
			{
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = t1/len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
				intersectedPart = ACone::BODY;
			}

			z = P.z + t2 * D.z;
			if ((t2 > tolerance) && (t2 < BIG) && (z >= 0.0) && (z <= 1.0))
			{
				if (r) {
					r->n = 2;
					r->I[1].obj = this;
					r->I[1].T = t2/len;
					r->I[1].P = Vector::AddScale(ray->origin, ray->dir, r->I[1].T);
				}
				else {
					r = new IntersectResult;
					r->I[0].obj = this;
					r->n = 1;
					r->I[0].T = t2/len;
					r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				}
				intersectedPart = ACone::BODY;
			}
		}
	}

	if (openApex && (fabs(D.z) > EPSILON))
	{
		d = (1.0 - P.z) / D.z;
		a = (P.x + d * D.x);
		b = (P.y + d * D.y);

		if (((SQUARE(a) + SQUARE(b)) <= 1.0) && (d > tolerance) && (d < BIG))
		{
			if (r) {
				r->I[r->n].T = d / len;
				r->I[r->n].obj = this;
				r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
				r->n++;
			}
			else {
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = d / len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
			}
			intersectedPart = APEX;
		}
	}
	if (openBase && (fabs(D.z) > EPSILON)) {
		d = (length - P.z) / D.z;
		a = (P.x + d * D.x);
		b = (P.y + d * D.y);

		if (((SQUARE(a) + SQUARE(b)) <= 1.0)
			&& (d > tolerance) && (d < BIG))
		{
			if (r) {
				r->I[r->n].T = d / len;
				r->I[r->n].obj = this;
				r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
				r->n++;
			}
			else {
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = d / len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
			}
			intersectedPart = ACone::BASE;
		}
	}
	return (r);
}


ACone::ACone(Vector b, Vector a, DBL rb, DBL ra) : AnObject()
{
	type = OBJ_CONE;
	base = b;
	apex = a;
	baseRadius = rb;
	apexRadius = ra;
	usesTransform = true;
	CalcTransform();
}

void ACone::CalcCylinderTransform()
{
	DBL tmpf;
	Vector axis;

	axis = Vector::Sub(apex, base);
	tmpf = Vector::Length(axis);

	if (tmpf < EPSILON) {
		throw gcnew Finray::FinrayException(ERR_DEGENERATE,0);
	}
	else
	{
		axis = Vector::Scale(axis, 1.0/tmpf);
		trans.CalcCoordinate(base, axis, apexRadius, tmpf);
	}
	length = 0.0;
	CalcBoundingObject();
}


void ACone::CalcTransform()
{
	DBL tlen, len, tmpf;
	Vector tmpv, axis, origin;

	/* Process the primitive specific information */

	/* Find the axis and axis length */

	axis = Vector::Sub(apex, base);
	len = Vector::Length(axis);

	if (len < EPSILON) {
		throw gcnew Finray::FinrayException(ERR_DEGENERATE,0);
	}
	else {
		axis = Vector::Normalize(axis);
	}
	/* we need to trap that case first */
	if (fabs(apexRadius - baseRadius) < EPSILON)
	{
		/* What we are dealing with here is really a cylinder */
		type = OBJ_CYLINDER;
		CalcCylinderTransform();
		return;
	}

	// Want the bigger end at the top
	if (apexRadius < baseRadius)
	{
		tmpv = base;
		base = apex;
		apex = tmpv;
		tmpf = baseRadius;
		baseRadius = apexRadius;
		apexRadius = tmpf;
		axis = Vector::Scale(axis,-1.0);
	}
	/* apex & base are different, yet, it might looks like a cylinder */
	tmpf = baseRadius * len / (apexRadius - baseRadius);
	origin = Vector::Scale(axis, tmpf);
	origin = Vector::Sub(base, origin);

	tlen = tmpf + len;
	/* apex is always bigger here */
	if (((apexRadius - baseRadius)*len/tlen) < EPSILON)
	{
		/* What we are dealing with here is really a cylinder */
		type = OBJ_CYLINDER;
		CalcCylinderTransform();
		return;
	}

	length = tmpf / tlen;
	/* Determine alignment */
	trans.CalcCoordinate(origin, axis, apexRadius, tlen);
	CalcBoundingObject();
}

void ACone::RotXYZ(DBL ax, DBL ay, DBL az)
{
	Vector v;
	Transform T;
	v.x = ax;
	v.y = ay;
	v.z = az;
	T.CalcRotation(v);
	TransformX(&T);
}

void ACone::Translate(Vector v)
{
	Transform T;
	T.CalcTranslation(v);
	TransformX(&T);
}

void ACone::Scale(Vector v)
{
	Transform T;
	T.CalcScaling(v);
	TransformX(&T);
}

void ACone::Scale(DBL ax, DBL ay, DBL az)
{
	Vector v;
	Transform T;
	v.x = ax;
	v.y = ay;
	v.z = az;
	T.CalcScaling(v);
	TransformX(&T);
}

Vector ACone::Normal(Vector p)
{
	Vector res = trans.InvTransPoint(p);

	if (intersectedPart==BASE) {
		res = Vector(0.0,0.0,-1.0);
	}
	else if (intersectedPart==APEX) {
		res = Vector(0.0,0.0,1.0);
	}
	else {
		if (type==OBJ_CYLINDER)
			res.z = 0.0;
		else
			res.z = -res.z;
	}
	return (Vector::Normalize(trans.TransNormal(res)));
}

IntersectResult *ACone::Intersect(Ray *ray)
{
	int i = 0;
	DBL a, b, c, z, t1, t2, len;
	DBL d;
	Vector P, D;
	IntersectResult *r = nullptr;

	if (!BoundingIntersect(ray))
		return (r);

	/* Transform the ray into the cones space */

	P = trans.InvTransPoint(ray->origin);
	D = trans.InvTransDirection(ray->dir);

	len = D.Length(D);
	D = Vector::Normalize(D);

	/* Solve intersections with a cone */

	a = D.x * D.x + D.y * D.y - D.z * D.z;
	b = D.x * P.x + D.y * P.y - D.z * P.z;
	c = P.x * P.x + P.y * P.y - P.z * P.z;

	if (fabs(a) < EPSILON)
	{
		if (fabs(b) > EPSILON)
		{
			/* One intersection */
			t1 = -0.5 * c / b;
			z = P.z + t1 * D.z;
			if ((t1 > tolerance) && (t1 < BIG) && (z >= length) && (z <= 1.0))
			{
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = t1/len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
				intersectedPart = BODY;
			}
		}
	}
	else
	{
		/* Check hits against the side of the cone */

		d = b * b - a * c;
		if (d >= 0.0)
		{
			d = sqrt(d);
			t1 = (-b - d) / a;
			t2 = (-b + d) / a;
			z = P.z + t1 * D.z;
			if ((t1 > tolerance) && (t1 < BIG) && (z >= length) && (z <= 1.0))
			{
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = t1/len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
				intersectedPart = BODY;
			}

			z = P.z + t2 * D.z;
			if ((t2 > tolerance) && (t2 < BIG) && (z >= length) && (z <= 1.0))
			{
				if (r) {
					r->I[r->n].obj = this;
					r->I[r->n].T = t2/len;
					r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
					r->n++;
				}
				else {
					r = new IntersectResult;
					r->I[0].obj = this;
					r->I[0].T = t2/len;
					r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
					r->n = 1;
				}
				intersectedPart = BODY;
			}
		}
	}

	if (openApex && (fabs(D.z) > EPSILON))
	{
		d = (1.0 - P.z) / D.z;
		a = (P.x + d * D.x);
		b = (P.y + d * D.y);

		if (((SQUARE(a) + SQUARE(b)) <= 1.0) && (d > tolerance) && (d < BIG))
		{
			if (r) {
				r->I[r->n].obj = this;
				r->I[r->n].T = d / len;
				r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
				r->n++;
			}
			else {
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = d / len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
			}
			intersectedPart = APEX;
		}
	}

	if (openBase && (fabs(D.z) > EPSILON))
	{
		d = (length - P.z) / D.z;
		a = (P.x + d * D.x);
		b = (P.y + d * D.y);

		if ((SQUARE(a) + SQUARE(b)) <= (SQUARE(length))
			&& (d > tolerance) && (d < BIG))
		{
			if (r) {
				r->I[r->n].obj = this;
				r->I[r->n].T = d/len;
				r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
				r->n++;
			}
			else {
				r = new IntersectResult;
				r->I[0].obj = this;
				r->I[0].T = d / len;
				r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
				r->n = 1;
			}
			intersectedPart = BASE;
		}
	}
	return (r);
}

void ACone::CalcCenter()
{
	center = Vector::Add(apex,base);
	center = Vector::Scale(center,0.5);
}

void ACone::CalcRadius()
{
	DBL d1,d2;
	Vector axis;

	axis = Vector::Sub(apex, base);
	d1 = Vector::Length(axis) / 2.0; 
	d2 = baseRadius > apexRadius ? baseRadius : apexRadius;
	radius = sqrt((d1*d1) + (d2*d2)) + EPSILON;
	radius2 = SQUARE(radius);
}

void ACone::CalcBoundingObject()
{
	CalcCenter();
	CalcRadius();
}

};
