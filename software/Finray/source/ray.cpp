#include "stdafx.h"

extern Finray::RayTracer rayTracer;

using namespace Finray;

namespace Finray
{

void Ray::TestList(AnObject *obj)
{
	if (obj==nullptr)
		return;
	while (obj) {
		if (obj->IsContainer())
			TestList(obj->obj);
		else
			Test(obj);
		obj = obj->next;
	}
}

void Ray::Trace(Color *c)
{
	double normalDir;
	Vector point;
	Vector normal;

	c->r = c->g = c->b = 0.0;
	if (rayTracer.HitRecurseLimit())
		return;
	minT = BIG;
	minObjectPtr = nullptr;
	TestList(rayTracer.objectList);
	// If nothing intersected
	if (minT >= BIG) {
		*c = rayTracer.backGround;
		return;
	}
	point = Vector::Scale(dir, minT);
	point = Vector::Add(point, origin);
	normal = minObjectPtr->Normal(point);
	normalDir = Vector::Dot(normal,dir);
	if (normalDir > 0.0)
		normal = Vector::Neg(normal);
	minObjectPtr->Shade(this, normal, point, c);
}

void Ray::Test(AnObject *o)
{
	double t;
	AnObject *o2;

	if (o==nullptr)
		return;
	if (o->BoundingIntersect(this) <= 0)
		return;
	if (!o->AntiIntersects(this)) {
		if (o2 = o->Intersect(this, &t)) {	// > 0
			if ((t > EPSILON) && (t < minT)) {
				minT = t;
				minObjectPtr = o2;
			}
		}
	}
}

};
