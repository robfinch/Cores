#include "stdafx.h"

extern Finray::RayTracer rayTracer;

namespace Finray {

AnObject::AnObject()
{
	type = OBJ_OBJECT;
	obj = nullptr;
	negobj = nullptr;
	next = nullptr;
}

int AnObject::Print(AnObject *obj) {
	return 1;
}

Color AnObject::Shade(Ray *ray, Vector normal, Vector point, Finray::Color *pColor)
{
	float _specular, _diffuse;
	double k, distanceT;
	Ray lightRay;
	Ray reflectedRay, refractedRay;
	ALight *lightSrcPtr;
	Finray::Color lightColor, newColor;

	k = Vector::Dot(ray->dir,normal);
	k *= -2.0f;

	reflectedRay.origin = point;
	reflectedRay.dir.x = k * normal.x + ray->dir.x;
	reflectedRay.dir.y = k * normal.y + ray->dir.y;
	reflectedRay.dir.z = k * normal.z + ray->dir.z;

	pColor->r = properties.color.r * properties.ambient.r;
	pColor->g = properties.color.g * properties.ambient.g;
	pColor->b = properties.color.b * properties.ambient.b;
	lightSrcPtr = rayTracer.lightList;
	while (lightSrcPtr) {
		distanceT = lightSrcPtr->MakeRay(point, &lightRay);
		lightColor = lightSrcPtr->GetColor(this,&lightRay,distanceT);
		_diffuse = (float)Vector::Dot(normal, lightRay.dir);
		if ((_diffuse > 0.0) && properties.diffuse > 0.0) {
			_diffuse = pow(_diffuse,properties.brilliance) * properties.diffuse;
			pColor->r += (lightColor.r * properties.color.r * _diffuse);
			pColor->g += (lightColor.g * properties.color.g * _diffuse);
			pColor->b += (lightColor.b * properties.color.b * _diffuse);
		}
		_specular = (float)Vector::Dot(reflectedRay.dir, lightRay.dir);
		if ((_specular > 0.0) && (properties.specular > 0.0)) {
			_specular = pow(_specular, properties.roughness) * properties.specular;
			pColor->r += (lightColor.r * _specular);
			pColor->g += (lightColor.g * _specular);
			pColor->b += (lightColor.b * _specular);
		}
		lightSrcPtr = (ALight *)lightSrcPtr->next;
	}
	k = properties.reflection;
	if (k > 0.0) {
		rayTracer.recurseLevel++;
		reflectedRay.Trace(&newColor);
		pColor->r += newColor.r * (float)k;
		pColor->g += newColor.g * (float)k;
		pColor->b += newColor.b * (float)k;
		rayTracer.recurseLevel--;
	}
	return *pColor;
}

void AnObject::SetAttrib(float rd, float gr, float bl, Color a, float d, float b, float s, float ro, float r)
{
	properties.SetAttrib(rd, gr, bl, a, d, b, s, ro, r);
}

void AnObject::RotXYZ(double ax, double ay, double az)
{
	AnObject *o;

	RotX(ax);
	RotY(ay);
	RotZ(az);
	o = obj;
	while (o) {
		o->RotXYZ(ax,ay,az);
		o = o->next;
	}
}

void AnObject::Translate(double ax, double ay, double az)
{
	AnObject *o;

	o = obj;
	while (o) {
		o->Translate(ax,ay,az);
		o = o->next;
	}
}

/*
bool AnObject::Intersects(Ray *ray, double *d) {
	AnObject *o;
	double d1;
	int nn, jj;

	*d = BIG;
	o = posobj;
	while(o) {
		if ((jj = o->Intersect(ray, &d1)) <= 0)
			return false;
		if (d1 < *d)
			*d = d1;
		nn = max(nn,jj);
		o = o->next;
	}
	return true;
}
*/
bool AnObject::AntiIntersects(Ray *ray) {
	AnObject *o;
	double d;

	o = negobj;
	while(o) {
		if (o->negobj) {
			if (o->negobj->AntiIntersects(ray)) {
				return true;
			}
		}
		if (o->Intersect(ray, &d) > 0)
			return true;
		o = o->next;
	}
	return false;
}

int AnObject::Intersect(Ray *r, double *d)
{
	switch(type) {
	case OBJ_SPHERE:	return ((ASphere *)this)->Intersect(r,d);
	case OBJ_PLANE:		return ((APlane *)this)->Intersect(r,d);
	case OBJ_TRIANGLE:	return ((ATriangle *)this)->Intersect(r,d);
	case OBJ_QUADRIC:	return ((AQuadric *)this)->Intersect(r,d);
	case OBJ_CONE:		return ((ACone *)this)->Intersect(r,d);
	case OBJ_CYLINDER:	return ((ACylinder *)this)->Intersect(r,d);
	default:	return 0;
	}
}

};
