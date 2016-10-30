#include "stdafx.h"

extern Finray::RayTracer rayTracer;
using namespace Finray;

namespace Finray {

ALight::ALight(double X, double Y, double Z, float R, float G, float B) : AnObject()
{
	center.x = X;
	center.y = Y;
	center.z = Z;
	if (properties.pigment==nullptr)
		properties.pigment = new Pigment;
	properties.pigment->color.r = R;
	properties.pigment->color.g = G;
	properties.pigment->color.b = B;
}

Finray::Color ALight::GetColor(AnObject *so, AnObject *objPtr, Ray *ray, DBL distance)
{
	AnObject *shadowObjPtr, *o;
	Finray::Color clr, _color;
	IntersectResult *r;
	DBL distanceT;

	shadowObjPtr = so;
	while (shadowObjPtr) {
		switch (shadowObjPtr->type) {
		// For an intersection object all objects must return an intersection
		// with the ray (the color black). As soon as one object does not
		// intersect there is no shadow.
		case OBJ_INTERSECTION:
			o = shadowObjPtr->obj;
			while (o) {
				clr = GetColor(o, objPtr, ray, distance);
				if (!clr.IsBlack()) {
					goto j1;
				}
				o = o->next;
			}
			clr.r = clr.g = clr.b = 0.0;
			return (clr);
		case OBJ_BOX:
		case OBJ_CUBE:
		case OBJ_UNION:
			o = shadowObjPtr->obj;
			while (o) {
				clr = GetColor(o, objPtr, ray, distance);
				if (clr.IsBlack()) {
					return (clr);
				}
				o = o->next;
			}
			break;
		case OBJ_OBJECT:
			if (shadowObjPtr->obj) {
				o = shadowObjPtr->obj;
				while (o) {
					clr = GetColor(o, objPtr, ray, distance);
					if (clr.IsBlack()) {
						return (clr);
					}
					o = o->next;
				}
				break;
			}
			break;
		default:
			if (shadowObjPtr->type==OBJ_SPHERE)
				r = r;
			if (shadowObjPtr != objPtr) {
				if (shadowObjPtr->boundingObject) {
					r = shadowObjPtr->boundingObject->Intersect(ray);
					if (r==nullptr) {
						return (properties.color);
					}
					delete r;
				}
				if (shadowObjPtr->doShadows) {
					r = shadowObjPtr->Intersect(ray);
					if (r) {
						distanceT = r->I[0].T;
						delete r;
						if ((distanceT >  EPSILON) && distanceT < distance) {
							_color.r = _color.g = _color.b = 0.0;
							return (_color);
						}
					}
				}
			}
		}
j1:
		shadowObjPtr = shadowObjPtr->next;
	}
	return (properties.pigment->color);
}

/*
Finray::Color ALight::GetColor(AnObject *objPtr, Ray *ray, double distance)
{
	AnObject *shadowObjPtr;
	static Finray::Color _color;
	DBL distanceT;
	AnObject *stack[100];
	int sp;
	IntersectResult *r;

	shadowObjPtr = rayTracer.objectList;
	while (shadowObjPtr) {
		while (shadowObjPtr) {
			if (shadowObjPtr != objPtr) {
				if (shadowObjPtr->boundingObject) {
					r = shadowObjPtr->boundingObject->Intersect(ray);
					if (r==nullptr) {
						goto j1;
					}
					delete r;
				}
				if (!shadowObjPtr->AntiIntersects(ray) && shadowObjPtr->doShadows) {
					r = shadowObjPtr->Intersect(ray);
					if (r) {
						distanceT = r->I[0].T;
						delete r;
						if ((distanceT >  EPSILON) && distanceT < distance) {
							_color.r = _color.g = _color.b = 0.0;
							return (_color);
						}
					}
				}
			}
j1:
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
*/
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
