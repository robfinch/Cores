#include "stdafx.h"

extern Finray::RayTracer rayTracer;

namespace Finray {

AnObject::AnObject()
{
	type = OBJ_OBJECT;
	obj = nullptr;
	negobj = nullptr;
	next = nullptr;
	lights = nullptr;
	boundingObject = nullptr;
	doReflections = true;
	doShadows = true;
	doImage = true;
	usesTransform = false;
	inverted = false;
}

int AnObject::Print(AnObject *obj) {
	return 1;
}

Color AnObject::Shade(Ray *ray, Vector normal, Vector point, Finray::Color *pColor)
{
	float _specular, _diffuse;
	DBL k, distanceT;
	Ray lightRay;
	Ray reflectedRay, refractedRay;
	ALight *lightSrcPtr;
	Finray::Color lightColor, newColor;
	Finray::Color clr;

	k = Vector::Dot(ray->dir,normal);
	k *= -2.0f;

	reflectedRay.origin = point;
	reflectedRay.dir = Vector::Scale(normal,k);
	reflectedRay.dir = Vector::Add(reflectedRay.dir,ray->dir);
	/*
	reflectedRay.dir.x = k * normal.x + ray->dir.x;
	reflectedRay.dir.y = k * normal.y + ray->dir.y;
	reflectedRay.dir.z = k * normal.z + ray->dir.z;
	*/
	clr = GetColor(point);
	pColor->r = clr.r * properties.ambient.r;
	pColor->g = clr.g * properties.ambient.g;
	pColor->b = clr.b * properties.ambient.b;
	lightSrcPtr = rayTracer.lightList;
	while (lightSrcPtr) {
		distanceT = lightSrcPtr->MakeRay(point, &lightRay);
		lightColor = lightSrcPtr->GetColor(rayTracer.objectList,this,&lightRay,distanceT);
		_diffuse = (float)Vector::Dot(normal, lightRay.dir);
		if ((_diffuse > 0.0) && properties.diffuse > 0.0) {
			_diffuse = pow(_diffuse,properties.brilliance) * properties.diffuse;
			pColor->r += (lightColor.r * clr.r * _diffuse);
			pColor->g += (lightColor.g * clr.g * _diffuse);
			pColor->b += (lightColor.b * clr.b * _diffuse);
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
	if (doReflections) {
		k = properties.reflection;
		if (k > 0.0) {
			rayTracer.recurseLevel++;
				reflectedRay.Trace(&newColor);
			pColor->r += newColor.r * (float)k;
			pColor->g += newColor.g * (float)k;
			pColor->b += newColor.b * (float)k;
			rayTracer.recurseLevel--;
		}
	}
	return *pColor;
}

/*
void AnObject::SetAttrib(float rd, float gr, float bl, Color a, float d, float b, float s, float ro, float r)
{
	properties.SetAttrib(rd, gr, bl, a, d, b, s, ro, r);
}
*/
void AnObject::RotXYZ(double ax, double ay, double az)
{
	AnObject *o;

	switch(type) {
	case OBJ_CONE:		return ((ACone *)this)->RotXYZ(ax,ay,az);
	case OBJ_CYLINDER:	return ((ACylinder *)this)->RotXYZ(ax,ay,az);
	case OBJ_INTERSECTION:
		o = obj;
		while (o) {
			o->RotXYZ(ax,ay,az);
			o = o->next;
		}
		break;
	default:
		RotX(ax);
		RotY(ay);
		RotZ(az);
		o = obj;
		while (o) {
			o->RotXYZ(ax,ay,az);
			o = o->next;
		}
	}
}

void AnObject::Translate(Vector a)
{
	AnObject *o;

	o = obj;
	while (o) {
		o->Translate(a);
		o = o->next;
	}
}

void AnObject::Scale(Vector v)
{
	AnObject *o;

	o = obj;
	while (o) {
		o->Scale(v);
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
	IntersectResult *r;

	o = negobj;
	while(o) {
		if (o->negobj) {
			if (o->negobj->AntiIntersects(ray)) {
				return (true);
			}
		}
		if (r = o->Intersect(ray)) {
			delete r;
			return (true);
		}
		o = o->next;
	}
	return (false);
}

IntersectResult *AnObject::Intersect(Ray *r)
{
	switch(type) {
	case OBJ_BOX:		return ((ABox *)this)->Intersect(r);
	case OBJ_SPHERE:	return ((ASphere *)this)->Intersect(r);
	case OBJ_TORUS:		return ((ATorus *)this)->Intersect(r);
	case OBJ_PLANE:		return ((APlane *)this)->Intersect(r);
	case OBJ_TRIANGLE:	return ((ATriangle *)this)->Intersect(r);
	case OBJ_QUADRIC:	return ((AQuadric *)this)->Intersect(r);
	case OBJ_CONE:		return ((ACone *)this)->Intersect(r);
	case OBJ_CUBE:		return ((ABox *)this)->Intersect(r);
	case OBJ_CYLINDER:	return ((ACylinder *)this)->Intersect(r);
	default:	return nullptr;
	}
}

bool AnObject::BoundingIntersect(Ray *ray)
{
	double B, C, Discrim, t0, t1;
	Vector P, D;

	if (usesTransform) {
		P = trans.InvTransPoint(ray->origin);
		D = trans.InvTransDirection(ray->dir);
	}
	else {
		P = ray->origin;
		D = ray->dir;
	}

	// Don't need to calculate A since ray is a unit vector
	B = 2 * ((D.x * (P.x - center.x))
			+(D.y * (P.y - center.y))
			+(D.z * (P.z - center.z)));
	C =   SQUARE(P.x - center.x)
		+ SQUARE(P.y - center.y)
		+ SQUARE(P.z - center.z)
		- radius2;

	Discrim = (SQUARE(B) - 4 * C);
	if (Discrim <= EPSILON)
		return (false);

	Discrim = sqrt(Discrim);
	t0 = (-B-Discrim) * 0.5;
	if (t0 > EPSILON) {
		return (true);
	}
	t1 = (-B+Discrim) * 0.5;
	if (t1 > EPSILON) {
		return (true);
	}
	return (false);
}

/*
Color AnObject::GetColor(Vector point)
{
	Color color;
	Color v;
/*
	if (properties.variance.r != 0
		|| properties.variance.g != 0
		|| properties.variance.b != 0
		) {
		v = Color(
			(float)RTFClasses::Random::dbl()*properties.variance.r,
			(float)RTFClasses::Random::dbl()*properties.variance.g,
			(float)RTFClasses::Random::dbl()*properties.variance.b);
	}
	else

		v = Color(0,0,0);
	color = properties.color;
	color = Color::Add(color,v);
	return color;
};
*/

bool AnObject::IsContainer()
{
	return type==OBJ_OBJECT || type==OBJ_BOX || type==OBJ_CUBE;
}

void AnObject::SetTexture(Texture *tx)
{
	properties.Copy(tx);
}

};
