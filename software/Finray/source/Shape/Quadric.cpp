#include "stdafx.h"

namespace Finray {

AQuadric::AQuadric() : AnObject()
{
	A = B = C = D = E = 0.0;
	F = G = H = I = J = 0.0;
	type = OBJ_QUADRIC;
	CalcBoundingObject();
}

AQuadric::AQuadric(double a, double b, double c, double d, double e,
		double f, double g, double h, double i, double j) : AnObject()
{
	A = a; B = b; C = c; D = d; E = e;
	F = f; G = g; H = h; I = i; J = j;
	type = OBJ_QUADRIC;
	CalcBoundingObject();
}

IntersectResult *AQuadric::Intersect(Ray *ray)
{
	double Ac, Bc, Cc;
	double Xd = ray->dir.x;
	double Yd = ray->dir.y;
	double Zd = ray->dir.z;

	double Xo = ray->origin.x;
	double Yo = ray->origin.y;
	double Zo = ray->origin.z;

	double n;
	double d;
	double t;

	IntersectResult *r = nullptr;
	if (!BoundingIntersect(ray))
		return (r);

	Ac = A * SQUARE(Xd) + B * SQUARE(Yd) + C * SQUARE(Zd) + D * Xd * Yd + E * Xd * Zd + F * Yd * Zd;
	Bc = 2.0 * A * Xo * Xd + 2.0 * B * Yo * Yd + 2.0 * C * Zo * Zd +
		D * Xo * Yd + D * Yo * Xd + E * Xo * Zd + E * Zo * Xd +
		F * Yo * Zd + F * Zo * Yd + G * Xd + H * Yd + I * Zd;
	Cc = A * SQUARE(Xo) + B * SQUARE(Yo) + C * SQUARE(Zo) + D * Xo * Yo + E*Xo*Zo + F*Yo*Zo + G*Xo + H*Yo + I *Zo + J;

	n = -Bc - sqrt(SQUARE(Bc)- 4.0 * Ac * Cc);
	d = 2 * Ac;
	t = n/d;
	if (t <= EPSILON) {
		n = -Bc + sqrt(SQUARE(Bc)- 4.0 * Ac * Cc);
		t = n/d;
		if (t <= EPSILON)
			return (nullptr);
	}
	r = new IntersectResult;
	r->I[0].obj = this;
	r->I[0].T = t;
	r->I[0].P = Vector::AddScale(ray->origin, ray->dir, r->I[0].T);
	r->n = 1;
	return (r);
}

Vector AQuadric::Normal(Vector P)
{
	Vector N;

	N.x = 2.0*A*P.x + D*P.y + E*P.z + G;
	N.y = 2.0*B*P.y + D*P.x + F*P.z + H;
	N.z = 2.0*C*P.z + E*P.x + F*P.y + I;

	return Vector::Normalize(N);
}

void AQuadric::ToMatrix(Matrix *mat) const
{
	mat->Zero();

	mat->m[0][0] = A;
	mat->m[1][1] = B;
	mat->m[2][2] = C;
	mat->m[0][1] = D;
	mat->m[0][2] = E;
	mat->m[0][3] = G;
	mat->m[1][2] = F;
	mat->m[1][3] = H;
	mat->m[2][3] = I;
	mat->m[3][3] = J;
}

void AQuadric::FromMatrix(Matrix *mat)
{
	A = mat->m[0][0];
	B = mat->m[1][1];
	C = mat->m[2][2];
	D = mat->m[0][1] + mat->m[1][0];
	E = mat->m[0][2] + mat->m[2][0];
	G = mat->m[0][3] + mat->m[3][0];
	F = mat->m[1][2] + mat->m[2][1];
	H = mat->m[1][3] + mat->m[3][1];
	I = mat->m[2][3] + mat->m[3][2];
	J = mat->m[3][3];
}


void AQuadric::TransformX(Transform *tr)
{
	Matrix quadricMatrix, transformTransposed;

	ToMatrix(&quadricMatrix);
	quadricMatrix.TimesB(&tr->inverse);
	transformTransposed.Transpose(&tr->inverse);
	quadricMatrix.TimesA(&transformTransposed);
	FromMatrix(&quadricMatrix);
//	Recompute_BBox(&BBox, tr);
}

void AQuadric::RotXYZ(double ax, double ay, double az)
{
	Vector v;
	Transform T;
	v.x = ax;
	v.y = ay;
	v.z = az;
	T.CalcRotation(v);
	TransformX(&T);
}

void AQuadric::Translate(Vector v)
{
	Transform T;
	T.CalcTranslation(v);
	TransformX(&T);
}

void AQuadric::Scale(Vector v)
{
	Transform T;
	T.CalcScaling(v);
	TransformX(&T);
}

void AQuadric::Print() {
}


// Depending on the constants supplied the quadric may not be a closed
// object. Bounding object tests are disabled by supplying a sphere of
// infinite radius as the bound.

void AQuadric::CalcBoundingObject()
{
	center = Vector(0,0,0);
	radius = BIG;
	radius2 = SQUARE(BIG);
}

};
