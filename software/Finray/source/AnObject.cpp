#include "stdafx.h"

extern Finray::RayTracer rayTracer;

namespace Finray {

AnObject::AnObject()
{
	type = OBJ_OBJECT;
	obj = nullptr;
	next = nullptr;
}

int AnObject::Print(AnObject *obj) {
	return 1;
}

Color AnObject::Shade(Ray *ray, Vector normal, Vector point, Finray::Color *pColor)
{
	float _ambient, _diffuse, _specular;
	double k, distanceT;
	Ray lightRay;
	Ray reflectedRay;
	ALight *lightSrcPtr;
	Finray::Color lightColor, newColor;

	k = Vector::Dot(ray->dir,normal);
	k *= -2.0f;

	reflectedRay.origin = point;
	reflectedRay.dir.x = k * normal.x + ray->dir.x;
	reflectedRay.dir.y = k * normal.y + ray->dir.y;
	reflectedRay.dir.z = k * normal.z + ray->dir.z;

	_ambient = properties.ambient;
	pColor->r = properties.color.r * _ambient;
	pColor->g = properties.color.g * _ambient;
	pColor->b = properties.color.b * _ambient;
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
		pColor->r += newColor.r * k;
		pColor->g += newColor.g * k;
		pColor->b += newColor.b * k;
		rayTracer.recurseLevel--;
	}
	return *pColor;
}

void AnObject::SetAttrib(float rd, float gr, float bl, float a, float d, float b, float s, float ro, float r)
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

};
