#include "stdafx.h"

extern Finray::RayTracer rayTracer;
extern Finray::Color backGround;

using namespace Finray;

namespace Finray
{
void Ray::Trace(Color *c)
{
	double normalDir;
	AnObject *objectPtr;
	Vector point;
	Vector normal;

	c->r = c->g = c->b = 0.0;
	if (rayTracer.HitRecurseLimit())
		return;
	minT = BIG;
	minObjectPtr = nullptr;
	objectPtr = rayTracer.objectList;
	while (objectPtr) {
		Test(objectPtr);
		objectPtr = objectPtr->next;
	}
	// If nothing intersected
	if (minT >= BIG) {
		c->r = backGround.r;
		c->g = backGround.g;
		c->b = backGround.b;
		return;
	}
	point.x = minT * dir.x + origin.x;
	point.y = minT * dir.y + origin.y;
	point.z = minT * dir.z + origin.z;
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

	if (o->obj) {
		o2 = o->obj;
		while (o2) {
			Test(o2);
			o2 = o2->next;
		}
	}
	if (o->BoundingIntersect(this) <= 0)
		return;
	if (!o->AntiIntersects(this)) {
		if (o->Intersect(this, &t) > 0) {
			if ((t > EPSILON) && (t < minT)) {
				minT = t;
				minObjectPtr = o;
			}
		}
	}
}

};
