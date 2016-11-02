#include "stdafx.h"

FinitronClasses::NoiseGen noiseGen;

namespace Finray {

ABox::ABox(Vector pt1, Vector d) : AnObject()
{
	int nn;
	ATriangle *o;
	Vector pt2, pt3, pt4, pt5, pt6, pt7, pt8;

	type = OBJ_BOX;

	lowerLeft = pt1;
	upperRight = Vector::Add(pt1, d);

	maxLength = fabs(d.x) > fabs(d.y) ? fabs(d.x) : fabs(d.y);
	maxLength = maxLength > fabs(d.z) ? maxLength : fabs(d.z);

	for (nn = 0; nn < 12; nn++) {
		o = new ATriangle();
		tri[nn] = o;
		o->next = obj;
		obj = o;
	}

	pt2 = Vector::Add(pt1,Vector(d.x,0,0));
	pt3 = Vector::Add(pt1,Vector(d.x,0,d.z));
	pt4 = Vector::Add(pt1,d);
	pt5 = Vector::Add(pt1,Vector(d.x,d.y,0));
	pt6 = Vector::Add(pt1,Vector(0,d.y,0));
	pt7 = Vector::Add(pt1,Vector(0,d.y,d.z));
	pt8 = Vector::Add(pt1,Vector(0,0,d.z));
	corner[0] = pt1;
	corner[1] = pt2;
	corner[2] = pt3;
	corner[3] = pt4;
	corner[4] = pt5;
	corner[5] = pt6;
	corner[6] = pt7;
	corner[7] = pt8;

	// right
	tri[0]->p1 = pt2;
	tri[0]->p2 = pt3;
	tri[0]->p3 = pt4;
	tri[1]->p1 = pt4;
	tri[1]->p2 = pt5;
	tri[1]->p3 = pt2;
	// front
	tri[2]->p1 = pt1;
	tri[2]->p2 = pt2;
	tri[2]->p3 = pt5;
	tri[3]->p1 = pt5;
	tri[3]->p2 = pt6;
	tri[3]->p3 = pt1;
	//left
	tri[4]->p1 = pt1;
	tri[4]->p2 = pt8;
	tri[4]->p3 = pt7;
	tri[5]->p1 = pt7;
	tri[5]->p2 = pt6;
	tri[5]->p3 = pt1;
	// back face
	tri[6]->p1 = pt8;
	tri[6]->p2 = pt3;
	tri[6]->p3 = pt4;
	tri[7]->p1 = pt4;
	tri[7]->p2 = pt7;
	tri[7]->p3 = pt8;
	// bottom
	tri[8]->p1 = pt1;
	tri[8]->p2 = pt2;
	tri[8]->p3 = pt3;
	tri[9]->p1 = pt3;
	tri[9]->p2 = pt8;
	tri[9]->p3 = pt1;
	// top
	tri[10]->p1 = pt6;
	tri[10]->p2 = pt5;
	tri[10]->p3 = pt4;
	tri[11]->p1 = pt4;
	tri[11]->p2 = pt7;
	tri[11]->p3 = pt6;

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	/*
	o = (ATriangle *)obj;
	while (o) {
		o->Init();
		o->CalcBoundingObject();
		o = (ATriangle *)o->next;
	}
	*/
	CalcBoundingObject();
}

ABox::ABox() : AnObject()
{
	int nn;
	Vector pt1,pt2,pt3,pt4,pt5,pt6,pt7,pt8;
	ATriangle *o;

	type = OBJ_BOX;

	maxLength = 1.0;

	lowerLeft = Vector(0,0,0);
	upperRight = Vector(1,1,1);

	for (nn = 0; nn < 12; nn++) {
		o = new ATriangle();
		tri[nn] = o;
		o->next = obj;
		obj = o;
	}
	pt1 = Vector(1,0,0);
	pt2 = Vector(1,0,1);
	pt3 = Vector(1,1,1);
	pt4 = Vector(1,1,0);
	pt5 = Vector(0,0,0);
	pt6 = Vector(0,0,1);
	pt7 = Vector(0,1,1);
	pt8 = Vector(0,1,0);
	corner[0] = pt1;
	corner[1] = pt2;
	corner[2] = pt3;
	corner[3] = pt4;
	corner[4] = pt5;
	corner[5] = pt6;
	corner[6] = pt7;
	corner[7] = pt8;

	// right
	tri[0]->p1 = pt1;
	tri[0]->p2 = pt2;
	tri[0]->p3 = pt3;
	tri[1]->p1 = pt1;
	tri[1]->p2 = pt3;
	tri[1]->p3 = pt4;
	// front
	tri[2]->p1 = pt1;
	tri[2]->p2 = pt4;
	tri[2]->p3 = pt5;
	tri[3]->p1 = pt5;
	tri[3]->p2 = pt4;
	tri[3]->p3 = pt8;
	//left
	tri[4]->p1 = pt5;
	tri[4]->p2 = pt6;
	tri[4]->p3 = pt7;
	tri[5]->p1 = pt7;
	tri[5]->p2 = pt8;
	tri[5]->p3 = pt5;
	// back face
	tri[6]->p1 = pt2;
	tri[6]->p2 = pt6;
	tri[6]->p3 = pt3;
	tri[7]->p1 = pt3;
	tri[7]->p2 = pt6;
	tri[7]->p3 = pt7;
	// bottom
	tri[8]->p1 = pt5;
	tri[8]->p2 = pt1;
	tri[8]->p3 = pt2;
	tri[9]->p1 = pt5;
	tri[9]->p2 = pt2;
	tri[9]->p3 = pt6;
	// top
	tri[10]->p1 = pt8;
	tri[10]->p2 = pt4;
	tri[10]->p3 = pt3;
	tri[11]->p1 = pt3;
	tri[11]->p2 = pt7;
	tri[11]->p3 = pt8;

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	/*
	o = (ATriangle *)obj;
	while (o) {
		o->Init();
		o->CalcBoundingObject();
		o = (ATriangle *)o->next;
	}
	*/
	CalcBoundingObject();
}

ABox::ABox(double x, double y, double z) : AnObject()
{
	int nn;
	Vector pt1,pt2,pt3,pt4,pt5,pt6,pt7,pt8;
	ATriangle *o;

	type = OBJ_BOX;
	obj = nullptr;
	next = nullptr;
	negobj = nullptr;

	lowerLeft = Vector(0.0,0.0,0.0);
	upperRight = Vector(x,y,z);

	maxLength = fabs(x) > fabs(y) ? fabs(x) : fabs(y);
	maxLength = maxLength > fabs(z) ? maxLength : fabs(z);

	for (nn = 0; nn < 12; nn++) {
		o = new ATriangle();
		tri[nn] = o;
		o->next = obj;
		obj = o;
	}

	pt1 = Vector(x,0,0);
	pt2 = Vector(x,0,z);
	pt3 = Vector(x,y,z);
	pt4 = Vector(x,y,0);
	pt5 = Vector(0,0,0);
	pt6 = Vector(0,0,z);
	pt7 = Vector(0,y,z);
	pt8 = Vector(0,y,0);
	corner[0] = pt1;
	corner[1] = pt2;
	corner[2] = pt3;
	corner[3] = pt4;
	corner[4] = pt5;
	corner[5] = pt6;
	corner[6] = pt7;
	corner[7] = pt8;

	// right
	tri[0]->p1 = pt1;
	tri[0]->p2 = pt2;
	tri[0]->p3 = pt3;
	tri[1]->p1 = pt1;
	tri[1]->p2 = pt3;
	tri[1]->p3 = pt4;
	// front
	tri[2]->p1 = pt1;
	tri[2]->p2 = pt4;
	tri[2]->p3 = pt5;
	tri[3]->p1 = pt5;
	tri[3]->p2 = pt4;
	tri[3]->p3 = pt8;
	//left
	tri[4]->p1 = pt5;
	tri[4]->p2 = pt6;
	tri[4]->p3 = pt7;
	tri[5]->p1 = pt7;
	tri[5]->p2 = pt8;
	tri[5]->p3 = pt5;
	// back face
	tri[6]->p1 = pt2;
	tri[6]->p2 = pt6;
	tri[6]->p3 = pt3;
	tri[7]->p1 = pt3;
	tri[7]->p2 = pt6;
	tri[7]->p3 = pt7;
	// bottom
	tri[8]->p1 = pt5;
	tri[8]->p2 = pt1;
	tri[8]->p3 = pt2;
	tri[9]->p1 = pt5;
	tri[9]->p2 = pt2;
	tri[9]->p3 = pt6;
	// top
	tri[10]->p1 = pt8;
	tri[10]->p2 = pt4;
	tri[10]->p3 = pt3;
	tri[11]->p1 = pt3;
	tri[11]->p2 = pt7;
	tri[11]->p3 = pt8;

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	/*
	o = (ATriangle *)obj;
	while (o) {
		o->Init();
		o->CalcBoundingObject();
		o = (ATriangle *)o->next;
	}
	*/
	CalcBoundingObject();
}

IntersectResult *ABox::Intersect(Ray *ray)
{
	int nn;
	IntersectResult *ir;
	IntersectResult *r = nullptr;

	if (BoundingIntersect(ray)) {
		for (nn = 0; nn < 12; nn++) {
			ir = tri[nn]->Intersect(ray);
			if (ir) {
				if (ir->n > 0) {
					if (r==nullptr)
						r = new IntersectResult(12);
					r->pI[r->n] = ir->I[0];
					r->pI[r->n].obj = this;
					r->pI[r->n].part = nn;
					r->n++;
				}
				delete ir;
			}
		}
	}
	return (r);
}

Vector ABox::Normal(Vector v) {
	int nn;

	for (nn = 0; nn < 12; nn++) {
		if (tri[nn]->IsInside(v))
			return tri[nn]->Normal(v);
	}
	return Vector(1,0,0);
};
/*
{
	return triangles[intersectedTriangle].Normal(v);
}
*/
void ABox::RotX(double a)
{
	int nn;

	Transform T;
	T.CalcRotation(Vector(a,0.0,0.0));
	trans.Compose(&T);

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->RotX(a);
	}
	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	// Recompute bounding object
	// Rotating the object does not change the size of the bounding radius.
	for (nn = 0; nn < 8; nn++)
		corner[nn] = Vector::RotX(corner[nn],a);
	center = Vector::RotX(center,a);
}

void ABox::RotY(double a)
{
	int nn;

	Transform T;
	T.CalcRotation(Vector(0.0,a,0.0));
	trans.Compose(&T);

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->RotY(a);
	}
	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	// Recompute bounding object
	// Rotating the object does not change the size of the bounding radius.
	for (nn = 0; nn < 8; nn++)
		corner[nn] = Vector::RotY(corner[nn],a);
	center = Vector::RotY(center,a);
}

void ABox::RotZ(double a)
{
	int nn;

	Transform T;
	T.CalcRotation(Vector(0.0,0.0,a));
	trans.Compose(&T);

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->RotZ(a);
	}
	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	// Recompute bounding object
	// Rotating the object does not change the size of the bounding radius.
	for (nn = 0; nn < 8; nn++)
		corner[nn] = Vector::RotZ(corner[nn],a);
	center = Vector::RotZ(center,a);
}

void ABox::Translate(Vector p)
{
	int nn;
	Vector dir;

	Transform T;
	T.CalcTranslation(p);
	trans.Compose(&T);

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Translate(p);
	}
	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}

	// Recompute bounding object
	// Translating the object does not change the size of the bounding radius.
	dir = Vector::Sub(p,center);
	for (nn = 0; nn < 8; nn++)
		corner[nn] = Vector::Add(corner[nn],dir);
	center = p;
}

void ABox::Scale(Vector p)
{
	int nn;

	Transform T;
	T.CalcScaling(p);
	trans.Compose(&T);

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Scale(p);
	}
	for (nn = 0; nn < 12; nn++) {
		tri[nn]->Init();
		tri[nn]->CalcBoundingObject();
	}
	// Recompute bounding object
	for (nn = 0; nn < 8; nn++) {
		corner[nn].x *= p.x;
		corner[nn].y *= p.y;
		corner[nn].z *= p.z;
	}
	CalcBoundingObject();
}

/*
void ABox::SetTexture(Texture *tx)
{
	properties.Copy(tx);
//	for (nn = 0; nn < 12; nn++) {
//		tri[nn]->SetTexture(tx);
//	}
}
*/
/*
void ABox::SetColor(Color c)
{
	int nn;

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->SetColor(c);
	}
}
*/

void ABox::SetVariance(Color v)
{
	int nn;

	for (nn = 0; nn < 12; nn++) {
		tri[nn]->SetColorVariance(v);
	}
}


// The center of the box is the average point of all the corners.
//
Vector ABox::CalcCenter()
{
	int nn;

	center = Vector(0,0,0);
	for (nn = 0; nn < 8; nn++)
		center = Vector::Add(center,corner[nn]);
	center = Vector::Scale(center,1.0/8.0);
	return (center);
}

// The radius of a surrounding sphere is the distance from the center of the
// box to the farthest corner.

DBL ABox::CalcRadius()
{
	int nn;
	DBL d;

	radius = 0.0;
	for (nn = 0; nn < 8; nn++) {
		d = Vector::Length(corner[nn],center);
		if (d > radius) radius = d;
	}
	radius += EPSILON;
	radius2 = SQUARE(radius);
	return (radius);
}


// The bounding object is just a sphere large enough to extend just beyond the
// farthest corner from the center of the box.

void ABox::CalcBoundingObject()
{
	CalcCenter();
	CalcRadius();
}


// The center of the box is maintained in global co-ordinates so there is no
// need to use an inverse transform to translate the ray into the boxes 
// co-ordinate system.

// However this bounding intersect is causing a problem (the box is clipped
// by an arc. Disabling this intersect by always returning true causes the
// box to come out correctly.


bool ABox::BoundingIntersect(Ray *ray)
{
	DBL B, C, Discrim, t0, t1;
	Vector P, D;

	return (true);
	P = ray->origin;
	D = ray->dir;

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


// This is the only method that relies on transforms. The initial
// transform is setup so there is no translation of the point. So
// we don't need to test usesTransform.

bool ABox::IsInside(Vector P)
{
	P = trans.InvTransPoint(P);
	if (P.x < lowerLeft.x || P.x > upperRight.x)
		return (inverted);
	if (P.y < lowerLeft.y || P.y > upperRight.y)
		return (inverted);
	if (P.z < lowerLeft.z || P.z > upperRight.z)
		return (inverted);
	return (!inverted);
}

};
