#include "stdafx.h"

extern Finray::RayTracer rayTracer;
extern Finray::Color backGround;

using namespace Finray;

namespace Finray
{
void Ray::Trace(Color *c)
{
	double t, minT, normalDir;
	AnObject *minObjectPtr;
	AnObject *objectPtr;
	Vector point;
	Vector normal;
	AnObject *stack[100];
	int sp = 0;

	c->r = c->g = c->b = 0.0;
	if (rayTracer.recurseLevel > MAXRECURSELEVEL)
		return;
	minT = BIG;
	minObjectPtr = nullptr;
	objectPtr = rayTracer.objectList;
	while (objectPtr) {
		while (objectPtr) {
			if (objectPtr->Intersect(this, &t) > 0) {
				if ((t > EPSILON) && (t < minT)) {
					minT = t;
					minObjectPtr = objectPtr;
				}
			}
			if (objectPtr->obj) {
				stack[sp] = objectPtr;
				if (sp >= 98)
					throw gcnew Finray::FinrayException(ERR_TOOMANY_OBJECTS,0);
				sp++;
				objectPtr = objectPtr->obj;
			}
			else
				objectPtr = objectPtr->next;
		}
		if (sp > 0) {
			sp--;
			objectPtr = stack[sp];
			objectPtr = objectPtr->next;
		}
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

};
