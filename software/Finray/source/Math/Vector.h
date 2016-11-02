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
	static Vector Mul(Vector a, Vector b) {
		Vector c;
		c.x = a.x * b.x;
		c.y = a.y * b.y;
		c.z = a.z * b.z;
		return c;
	};
	static Vector Div(Vector a, Vector b) {
		Vector c;
		c.x = a.x / b.x;
		c.y = a.y / b.y;
		c.z = a.z / b.z;
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
	static Vector AddScale(Vector a, Vector b, DBL k) {
		return (Vector::Add(a,Vector::Scale(b,k)));
	}
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
	static double Length(Vector a, Vector b) {
		return (Length(Sub(b,a)));
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
	double u;
	double v;
	Vector2d(double a, double b) { u = a; v = b; };
	Vector2d() { u = 0.0; v = 0.0; };
	static Vector2d Add(Vector2d a, Vector2d b) {
		Vector2d c;
		c.u = a.u + b.u;
		c.v = a.v + b.v;
		return c;
	};
	static Vector2d Sub(Vector2d a, Vector2d b) {
		Vector2d c;
		c.u = a.u - b.u;
		c.v = a.v - b.v;
		return c;
	};
	static Vector2d Neg(Vector2d a) {
		Vector2d c;
		c.u = -a.u;
		c.v = -a.v;
		return c;
	};
	static Vector2d Scale(Vector2d a, double k) {
		Vector2d c;
		c.u = a.u * k;
		c.v = a.v * k;
		return c;
	};
	static double Dot(Vector2d a, Vector2d b) {
		double d;
		d = a.u * b.u + a.v * b.v;
		return d;
	};
	static double Cross(Vector2d a, Vector2d b) {
		double d;
		d = a.u * b.v - a.v * b.u;
		return d;
	};
	static double Length(Vector2d a) {
		return sqrt(a.u*a.u + a.v*a.v);
	};
	static Vector2d Normalize(Vector2d a) {
		Vector2d b;
		double l = sqrt(a.u*a.u + a.v*a.v);
		b.u = a.u/l;
		b.v = a.v/l;
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

class Vector4d
{
public:
	double v[4];
	Vector4d(double a, double b, double c, double d) {
		v[0] = a;
		v[1] = b;
		v[2] = c;
		v[3] = d;
	};
	Vector4d() {memset(this, 0, sizeof(this)); };
	static Vector4d Add(Vector4d a, Vector4d b) {
		Vector4d c;
		c.v[0] = a.v[0] + b.v[0];
		c.v[1] = a.v[1] + b.v[1];
		c.v[2] = a.v[2] + b.v[2];
		c.v[3] = a.v[3] + b.v[3];
		return c;
	};
	static Vector4d Sub(Vector4d a, Vector4d b) {
		Vector4d c;
		c.v[0] = a.v[0] - b.v[0];
		c.v[1] = a.v[1] - b.v[1];
		c.v[2] = a.v[2] - b.v[2];
		c.v[3] = a.v[3] - b.v[3];
		return c;
	};
	static Vector4d Neg(Vector4d a) {
		Vector4d c;
		c.v[0] = -a.v[0];
		c.v[1] = -a.v[1];
		c.v[2] = -a.v[2];
		c.v[3] = -a.v[3];
		return c;
	};
	static Vector4d Scale(Vector4d a, double k) {
		Vector4d c;
		c.v[0] = a.v[0] * k;
		c.v[1] = a.v[1] * k;
		c.v[2] = a.v[2] * k;
		c.v[3] = a.v[3] * k;
		return c;
	};
	static double SumSqr(Vector4d a) {
		double d;
		d = a.v[0] * a.v[0] + a.v[1] * a.v[1] + a.v[2] * a.v[2] + a.v[3] * a.v[3];
		return d;
	}
	static double Dot(Vector4d a, Vector4d b) {
		double d;
		d = a.v[0] * b.v[0] + a.v[1] * b.v[1] + a.v[2] * b.v[2] + a.v[3] * b.v[3];
		return d;
	};
	static double Length(Vector4d a) {
		return sqrt(SumSqr(a));
	};
	static Vector4d Normalize(Vector4d a) {
		Vector4d b;
		double l = Length(a);
		b.v[0] = a.v[0]/l;
		b.v[1] = a.v[1]/l;
		b.v[2] = a.v[2]/l;
		b.v[3] = a.v[3]/l;
		return b;
	};
	static Vector4d Project(Vector4d A, Vector4d B) {
		return Vector4d::Scale(B,(Vector4d::Dot(A,A) / Vector4d::Dot(B,B)));
	};
	// Linear Interpolate
	static Vector4d Lerp(Vector4d a, Vector4d b, double k)
	{
		return Vector4d::Add(a,Vector4d::Scale(Vector4d::Sub(b,a),k));
	}
};


class Vector5d
{
public:
	double v[5];
	Vector5d(double a, double b, double c, double d, double e) {
		v[0] = a;
		v[1] = b;
		v[2] = c;
		v[3] = d;
		v[4] = e;
	};
	Vector5d() {memset(this, 0, sizeof(this)); };
	static Vector5d Add(Vector5d a, Vector5d b) {
		Vector5d c;
		c.v[0] = a.v[0] + b.v[0];
		c.v[1] = a.v[1] + b.v[1];
		c.v[2] = a.v[2] + b.v[2];
		c.v[3] = a.v[3] + b.v[3];
		c.v[4] = a.v[4] + b.v[4];
		return c;
	};
	static Vector5d Sub(Vector5d a, Vector5d b) {
		Vector5d c;
		c.v[0] = a.v[0] - b.v[0];
		c.v[1] = a.v[1] - b.v[1];
		c.v[2] = a.v[2] - b.v[2];
		c.v[3] = a.v[3] - b.v[3];
		c.v[4] = a.v[4] - b.v[4];
		return c;
	};
	static Vector5d Neg(Vector5d a) {
		Vector5d c;
		c.v[0] = -a.v[0];
		c.v[1] = -a.v[1];
		c.v[2] = -a.v[2];
		c.v[3] = -a.v[3];
		c.v[4] = -a.v[4];
		return c;
	};
	static Vector5d Scale(Vector5d a, double k) {
		Vector5d c;
		c.v[0] = a.v[0] * k;
		c.v[1] = a.v[1] * k;
		c.v[2] = a.v[2] * k;
		c.v[3] = a.v[3] * k;
		c.v[4] = a.v[4] * k;
		return c;
	};
	static double SumSqr(Vector5d a) {
		double d;
		d = a.v[0] * a.v[0] + a.v[1] * a.v[1] + a.v[2] * a.v[2] + a.v[3] * a.v[3] + a.v[4] * a.v[4];
		return d;
	}
	static double Dot(Vector5d a, Vector5d b) {
		double d;
		d = a.v[0] * b.v[0] + a.v[1] * b.v[1] + a.v[2] * b.v[2] + a.v[3] * b.v[3] + a.v[4] * b.v[4];
		return d;
	};
	static double Length(Vector5d a) {
		return sqrt(SumSqr(a));
	};
	static Vector5d Normalize(Vector5d a) {
		Vector5d b;
		double l = Length(a);
		b.v[0] = a.v[0]/l;
		b.v[1] = a.v[1]/l;
		b.v[2] = a.v[2]/l;
		b.v[3] = a.v[3]/l;
		b.v[4] = a.v[4]/l;
		return b;
	};
	static Vector5d Project(Vector5d A, Vector5d B) {
		return Vector5d::Scale(B,(Vector5d::Dot(A,A) / Vector5d::Dot(B,B)));
	};
	// Linear Interpolate
	static Vector5d Lerp(Vector5d a, Vector5d b, double k)
	{
		return Vector5d::Add(a,Vector5d::Scale(Vector5d::Sub(b,a),k));
	}
};


