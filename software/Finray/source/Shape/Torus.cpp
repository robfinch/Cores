#include "stdafx.h"

#define MAX_DISTANCE	BIG

namespace Finray
{

/* Minimal depth for a valid intersection. */

const DBL DEPTH_TOLERANCE = 1.0e-4;

/* Tolerance used for order reduction during root finding. */

const DBL ROOT_TOLERANCE = 1.0e-4;

ATorus::ATorus(DBL majorRadius, DBL minorRadius)
{
	type = OBJ_TORUS;
	usesTransform = true;
	MajorRadius = majorRadius;
	MinorRadius = minorRadius;
	CalcBoundingObject();
}

IntersectResult *ATorus::Intersect(Ray *ray)
{
	DBL len;
	DBL y1, y2, r1, r2, R2;
	DBL k1, k2;
	DBL Py2, Dy2, PDy2;
	DBL DistanceP, Closer;
	Vector P, D;
	Polynomial c(4);
	int i,n;
	IntersectResult *r = nullptr;

	// Transform the ray into the torus space.

	P = trans.InvTransPoint(ray->origin);
	D = trans.InvTransDirection(ray->dir);
	len = D.Length(D);
	D = Vector::Normalize(D);

	i = 0;

	y1 = -MinorRadius;
	y2 =  MinorRadius;

	if ( MajorRadius < MinorRadius )
		r1 = 0;
	else {
		r1 = MajorRadius - MinorRadius;
		r1 = r1 * r1;
	}

	r2 = MajorRadius + MinorRadius;
	r2 = r2 * r2;

	// First check for a thick cylinder hit. If it the ray doesn't intersect the
	// thick cylinder, then it doesn't intersect the torus.
	if (TestThickCylinder(P, D, y1, y2, r1, r2))
	{
		// Move P close to bounding sphere to have more precise root calculation.
		// Bounding sphere radius is R + r, we add r once more to ensure
		// that P is safely outside sphere.
		radius = MajorRadius + MinorRadius + MinorRadius;
		radius2 = SQUARE(radius);
		DistanceP = Vector::Dot(P,P); // Distance is currently squared.
		Closer = 0.0;
		if (DistanceP > radius2)
		{
			DistanceP = sqrt(DistanceP); // Now real distance.
			Closer = DistanceP - radius;
			P = Vector::Add(P, Vector::Scale(D, Closer));
		}

		R2   = SQUARE(MajorRadius);
		r2   = SQUARE(MinorRadius);

		Py2 = SQUARE(P.y);
		Dy2 = SQUARE(D.y);
		PDy2 = P.y * D.y;

		k1   = SQUARE(P.x) + SQUARE(P.z) + Py2 - R2 - r2;
		k2   = P.x * D.x + P.z * D.z + PDy2;

		c.coeff[4] = 1.0;
		c.coeff[3] = 4.0 * k2;
		c.coeff[2] = 2.0 * (k1 + 2.0 * (k2 * k2 + R2 * Dy2));
		c.coeff[1] = 4.0 * (k2 * k1 + 2.0 * R2 * PDy2);
		c.coeff[0] = k1 * k1 + 4.0 * R2 * (Py2 - r2);

//		n = c.Solve(Test_Flag(this, STURM_FLAG), ROOT_TOLERANCE);
		n = c.Solve(ROOT_TOLERANCE, true);

		if (n)
			r = new IntersectResult;
		while(n--) {
			r1 = (c.roots[n] + Closer) / len;
			r->I[r->n].T = r1;
			r->I[r->n].P = Vector::AddScale(ray->origin, ray->dir, r->I[r->n].T);
			r->I[r->n].obj = this;
			r->n++;
			//Depth[i++] = r1;
		}
	}
	return (r);
}

/*****************************************************************************
*
* FUNCTION
*
*   TestThickCylinder
*
* INPUT
*
*   P  - Ray initial
*   D  - Ray direction
*   h1 - Height 1
*   h2 - Height 2
*   r1 - Square of inner radius
*   r2 - Square of outer radius
*   
* OUTPUT
*   
* RETURNS
*
*   int - true, if hit
*   
* AUTHOR
*
*   Dieter Bayer
*   
* DESCRIPTION
*
*   Test if a given ray defined in the lathe's coordinate system
*   intersects a "thick" cylinder (rotated about y-axis).
*
* CHANGES
*
*   Jun 1994 : Creation.
*
******************************************************************************/

bool ATorus::TestThickCylinder(const Vector P, const Vector D, double h1, double h2, double r1, double r2) const
{
	DBL a, b, c, d;
	DBL u, v, k, r, h;

	if (fabs(D.y) < EPSILON)
	{
		if ((P.y < h1) || (P.y > h2))
		{
			return(false);
		}
	}
	else
	{
		/* Intersect ray with the cap-plane. */

		k = (h2 - P.y) / D.y;

		u = P.x + k * D.x;
		v = P.z + k * D.z;

		if ((k > EPSILON) && (k < MAX_DISTANCE))
		{
			r = u * u + v * v;

			if ((r >= r1) && (r <= r2))
			{
				return(true);
			}
		}

		/* Intersectionersect ray with the base-plane. */

		k = (h1 - P.y) / D.y;

		u = P.x + k * D.x;
		v = P.z + k * D.z;

		if ((k > EPSILON) && (k < MAX_DISTANCE))
		{
			r = u * u + v * v;

			if ((r >= r1) && (r <= r2))
			{
				return(true);
			}
		}
	}

	a = D.x * D.x + D.z * D.z;

	if (a > EPSILON)
	{
		/* Intersect with outer cylinder. */

		b = P.x * D.x + P.z * D.z;

		c = P.x * P.x + P.z * P.z - r2;

		d = b * b - a * c;

		if (d >= 0.0)
		{
			d = sqrt(d);

			k = (-b + d) / a;

			if ((k > EPSILON) && (k < MAX_DISTANCE))
			{
				h = P.y + k * D.y;

				if ((h >= h1) && (h <= h2))
				{
					return(true);
				}
			}

			k = (-b - d) / a;

			if ((k > EPSILON) && (k < MAX_DISTANCE))
			{
				h = P.y + k * D.y;

				if ((h >= h1) && (h <= h2))
				{
					return(true);
				}
			}
		}

		/* Intersect with inner cylinder. */

		c = P.x * P.x + P.z * P.z - r1;

		d = b * b - a * c;

		if (d >= 0.0)
		{
			d = sqrt(d);

			k = (-b + d) / a;

			if ((k > EPSILON) && (k < MAX_DISTANCE))
			{
				h = P.y + k * D.y;

				if ((h >= h1) && (h <= h2))
				{
					return(true);
				}
			}

			k = (-b - d) / a;

			if ((k > EPSILON) && (k < MAX_DISTANCE))
			{
				h = P.y + k * D.y;

				if ((h >= h1) && (h <= h2))
				{
					return(true);
				}
			}
		}
	}

	return(false);
}

bool ATorus::IsInside(Vector P)
{
	DBL r, r2;

	// Transform the point into the torus space.

	P = trans.InvTransPoint(P);
	r  = sqrt(SQUARE(P.x) + SQUARE(P.z));
	r2 = SQUARE(P.y) + SQUARE(r - MajorRadius);
	return ((r2 <= SQUARE(MinorRadius)) ^ inverted);
}

Vector ATorus::Normal(Vector P)
{
	DBL dist;
	Vector N, M;

	// Transform the point into the torus space.

	P = trans.InvTransPoint(P);

	/* Get normal from derivatives. */

	dist = sqrt(P.x * P.x + P.z * P.z);

	if (dist > EPSILON)
	{
		M.x = MajorRadius * P.x / dist;
		M.y = 0.0;
		M.z = MajorRadius * P.z / dist;
	}
	else
	{
		M = Vector(0.0, 0.0, 0.0);
	}

	N = Vector::Sub(P, M);

	// Transform the normal out of the torus space.
	N = trans.TransNormal(N);

	return (Vector::Normalize(N));
}


void ATorus::Translate(Vector v)
{
	Transform T;
	T.CalcTranslation(v);
	trans.Compose(&T);
}

void ATorus::Rotate(Vector v)
{
	Transform T;
	T.CalcRotation(v);
	trans.Compose(&T);
}

void ATorus::RotXYZ(double ax, double ay, double az)
{
	Vector v;
	Transform T;
	v.x = ax;
	v.y = ay;
	v.z = az;
	T.CalcRotation(v);
	trans.Compose(&T);
}

void ATorus::Scale(Vector v)
{
	Transform T;
	T.CalcScaling(v);
	trans.Compose(&T);
}

void ATorus::CalcBoundingObject()
{
	radius = MajorRadius + MinorRadius;
	radius2 = SQUARE(radius);
}

}
