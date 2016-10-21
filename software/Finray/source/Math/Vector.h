#include "stdafx.h"

#define Vector3d	Vector

class Vector
{
public:
	double x;
	double y;
	double z;
	Vector(double a, double b, double c) { x = a; y = b; z = c; };
	Vector() { x = 0.0; y = 0.0; z = 0.0; };
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
	static double SumSqr(Vector a) {
		double d;
		d = a.x * a.x + a.y * a.y + a.z * a.z;
		return d;
	}
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
	// Linear Interpolate
	static Vector Lerp(Vector a, Vector b, double k)
	{
		return Vector::Add(a,Vector::Scale(Vector::Sub(b,a),k));
	}
};


class Vector2d
{
public:
	double x;
	double y;
	Vector2d(double a, double b) { x = a; y = b; };
	Vector2d() { x = 0.0; y = 0.0; };
	static Vector2d Add(Vector2d a, Vector2d b) {
		Vector2d c;
		c.x = a.x + b.x;
		c.y = a.y + b.y;
		return c;
	};
	static Vector2d Sub(Vector2d a, Vector2d b) {
		Vector2d c;
		c.x = a.x - b.x;
		c.y = a.y - b.y;
		return c;
	};
	static Vector2d Neg(Vector2d a) {
		Vector2d c;
		c.x = -a.x;
		c.y = -a.y;
		return c;
	};
	static Vector2d Scale(Vector2d a, double k) {
		Vector2d c;
		c.x = a.x * k;
		c.y = a.y * k;
		return c;
	};
	static double Dot(Vector2d a, Vector2d b) {
		double d;
		d = a.x * b.x + a.y * b.y;
		return d;
	};
	static double Cross(Vector2d a, Vector2d b) {
		double d;
		d = a.x * b.y - a.y * b.x;
		return d;
	};
	static double Length(Vector2d a) {
		return sqrt(a.x*a.x + a.y*a.y);
	};
	static Vector2d Normalize(Vector2d a) {
		Vector2d b;
		double l = sqrt(a.x*a.x + a.y*a.y);
		b.x = a.x/l;
		b.y = a.y/l;
		return b;
	};
	static Vector2d Project(Vector2d A, Vector2d B) {
		return Vector2d::Scale(B,(Vector2d::Dot(A,A) / Vector2d::Dot(B,B)));
	};
	// Linear Interpolate
	static Vector2d Lerp(Vector2d a, Vector2d b, double k)
	{
		return Vector2d::Add(a,Vector2d::Scale(Vector2d::Sub(b,a),k));
	}
};

