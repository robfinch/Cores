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

APlane::APlane(DBL A, DBL B, DBL C, DBL D) : AnObject()
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

IntersectResult *APlane::Intersect(Ray *ray)
{
	Vector rd, ro;
	DBL Vd, Vo;
	DBL T;
	IntersectResult *r;

	if (usesTransform) {
		rd = trans.InvTransDirection(ray->dir);
		ro = trans.InvTransPoint(ray->origin);
	}
	else {
		rd = ray->dir;
		ro = ray->origin;
	}

	Vd = Vector::Dot(normal, rd);
	if (Vd <= EPSILON)
		return (nullptr);

	Vo = Vector::Dot(normal,ro);
	Vo += distance;
	Vo *= -1.0;

	T = Vo/Vd;
	if (T < 0.0)
		return (nullptr);
	r = new IntersectResult;
	r->n = 1;
	r->I[0].T = T;
	r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
	r->I[0].obj = this;
	return (r);
}

bool APlane::IsInside(Vector point)
{
	DBL temp;

	if (usesTransform)
		point = trans.InvTransPoint(point);
	temp = Vector::Dot(point, normal);
	return (inverted ? (temp + distance) > EPSILON: (temp + distance) < EPSILON);
}

Vector APlane::Normal(Vector point)
{
	Vector res;

	if (usesTransform) {
		res = trans.TransNormal(normal);
		return (Vector::Normalize(res));
	}
	return (normal);
}

void APlane::Translate(Vector v)
{
	if (usesTransform) {
		Transform T;
		T.CalcTranslation(v);
		trans.Compose(&T);
	}
	else {
		Vector t;

		t = Vector::Mul(normal, v);
		distance -= t.x + t.y + t.z;
	}
}

void APlane::Rotate(Vector rv)
{
	if (usesTransform) {
		Transform T;
		T.CalcRotation(rv);
		trans.Compose(&T);
		return;
	}
	RotX(rv.x);
	RotY(rv.y);
	RotZ(rv.z);
}

void APlane::RotX(DBL angle)
{
	normal = Vector::RotX(normal, angle);
}

void APlane::RotY(DBL angle)
{
	normal = Vector::RotY(normal, angle);
}

void APlane::RotZ(DBL angle)
{
	normal = Vector::RotZ(normal, angle);
}

void APlane::Scale(Vector sc)
{
	DBL len;

	if (usesTransform) {
		Transform T;
		T.CalcScaling(sc);
		trans.Compose(&T);
		return;
	}
	normal = Vector::Div(normal, sc);
	len = Vector::Length(normal);
	normal = Vector::Scale(normal,1.0/len);
	distance /= len;
}

void APlane::Invert()
{
	normal = Vector::Scale(normal,-1.0);
	distance *= -1.0;
}

void Print()
{
}

};
