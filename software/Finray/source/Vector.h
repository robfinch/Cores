#include "stdafx.h"

class Vector
{
public:
	double x;
	double y;
	double z;
	static Vector Add(Vector a, Vector b) {
		Vector c;
		c.x = a.x + b.x;
		c.y = a.y + b.y;
		c.z = a.z + b.z;
		return c;
	};
	static Vector Sub(Vector a, Vector b) {
		Vector c;
		c.x = a.x - b.x;
		c.y = a.y - b.y;
		c.z = a.z - b.z;
		return c;
	};
	static Vector Neg(Vector a) {
		Vector c;
		c.x = -a.x;
		c.y = -a.y;
		c.z = -a.z;
		return c;
	};
	static Vector Scale(Vector a, double k) {
		Vector c;
		c.x = a.x * k;
		c.y = a.y * k;
		c.z = a.z * k;
		return c;
	};
	static double Dot(Vector a, Vector b) {
		double d;
		d = a.x * b.x + a.y * b.y + a.z * b.z;
		return d;
	};
	static Vector Cross(Vector a, Vector b) {
		Vector c;

		c.x = a.y * b.z - a.z * b.y;
		c.y = a.z * b.x - a.x * b.z;
		c.z = a.x * b.y - a.y * b.x;
		return c;
	};
	static double Length(Vector a) {
		return sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
	};
	static Vector Normalize(Vector a) {
		Vector b;
		double l = sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
		b.x = a.x/l;
		b.y = a.y/l;
		b.z = a.z/l;
		return b;
	};
	static Vector Project(Vector A, Vector B) {
		return Vector::Scale(B,(Vector::Dot(A,A) / Vector::Dot(B,B)));
	};
	static Vector RotX(Vector pt, double angle)
	{
		angle = angle * PI / 180.0;
		double y = pt.y * cos(angle) - pt.z * sin(angle);
		double z = pt.y * sin(angle) + pt.z * cos(angle);
		pt.y = y;
		pt.z = z;
		return pt;
	}
	static Vector RotY(Vector pt, double angle)
	{
		angle = angle * PI / 180.0;
		double x = pt.x * cos(angle) - pt.z * sin(angle);
		double z = pt.x * sin(angle) + pt.z * cos(angle);
		pt.x = x;
		pt.z = z;
		return pt;
	}
	static Vector RotZ(Vector pt, double angle)
	{
		angle = angle * PI / 180.0;
		double x = pt.x * cos(angle) - pt.y * sin(angle);
		double y = pt.x * sin(angle) + pt.y * cos(angle);
		pt.x = x;
		pt.y = y;
		return pt;
	}
};

