#include "stdafx.h"

extern Finray::RayTracer rayTracer;
using namespace Finray;

namespace Finray {

ALight::ALight(double X, double Y, double Z, float R, float G, float B)
{
	center.x = X;
	center.y = Y;
	center.z = Z;
	properties.color.r = R;
	properties.color.g = G;
	properties.color.b = B;
}

Finray::Color ALight::GetColor(AnObject *objPtr, Ray *ray, double distance)
{
	AnObject *shadowObjPtr;
	static Finray::Color _color;
	double distanceT;
	AnObject *stack[100];
	int sp;

	shadowObjPtr = rayTracer.objectList;
	while (shadowObjPtr) {
		while (shadowObjPtr) {
			if (shadowObjPtr != objPtr) {
				if (!shadowObjPtr->AntiIntersects(ray)) {
					if (shadowObjPtr->Intersect(ray, &distanceT) > 0) {
						if ((distanceT >  EPSILON) && distanceT < distance) {
							_color.r = _color.g = _color.b = 0.0;
							return (_color);
						}
					}
				}
			}
			if (shadowObjPtr->obj) {
				stack[sp] = shadowObjPtr;
				sp++;
				if (sp >= 99)
					throw gcnew Finray::FinrayException(ERR_TOOMANY_OBJECTS,0);
				shadowObjPtr = shadowObjPtr->obj;
			}
			else
				shadowObjPtr = shadowObjPtr->next;
		}
		if (sp > 0) {
			--sp;
			shadowObjPtr = stack[sp];
			shadowObjPtr = shadowObjPtr->next;
		}
	}
	return (properties.color);
}

double ALight::MakeRay(Vector point, Ray *ray)
{
	double distanceT;

	ray->origin = point;
	ray->dir = Vector::Sub(center,point);
	distanceT = Vector::Length(ray->dir);
	ray->dir = Vector::Normalize(ray->dir);
	return distanceT;
}

void ALight::RotX(double angle)
{
	center = Vector::RotX(center, angle);
}

void ALight::RotY(double angle)
{
	center = Vector::RotY(center, angle);
}

void ALight::RotZ(double angle)
{
	center = Vector::RotZ(center, angle);
}

};
