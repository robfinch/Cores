// Much of this code based on code in POV-Ray
// (It's just a different implementation of the same math)
//
#include "stdafx.h"

namespace Finray {

Transform::Transform()
{
	matrix.Identity();
	inverse.Identity();
}

void Transform::Copy(Transform *t)
{
	memcpy(this, t, sizeof(Transform));
}

void Transform::CalcScaling(Vector vector)
{
	matrix.Identity();

	matrix.m[0][0] = vector.x;
	matrix.m[1][1] = vector.y;
	matrix.m[2][2] = vector.z;

	inverse.Identity();

	inverse.m[0][0] = 1.0 / vector.x;
	inverse.m[1][1] = 1.0 / vector.y;
	inverse.m[2][2] = 1.0 / vector.z;
}

void Transform::CalcTranslation(Vector vector)
{
	matrix.Identity();

	matrix.m[3][0] = vector.x;
	matrix.m[3][1] = vector.y;
	matrix.m[3][2] = vector.z;

	inverse.Identity();

	inverse.m[3][0] = -vector.x;
	inverse.m[3][1] = -vector.y;
	inverse.m[3][2] = -vector.z;
}

void Transform::CalcRotation(Vector vector)
{
	double cosx, cosy, cosz, sinx, siny, sinz;
	Matrix mat;
	Vector radianVector;

	radianVector = Vector::Scale (vector, PI/180.0);

	matrix.Identity();

	cosx = cos (radianVector.x);
	sinx = sin (radianVector.x);
	cosy = cos (radianVector.y);
	siny = sin (radianVector.y);
	cosz = cos (radianVector.z);
	sinz = sin (radianVector.z);

	matrix.m[1][1] = cosx;
	matrix.m[2][2] = cosx;
	matrix.m[1][2] = sinx;
	matrix.m[2][1] = 0.0 - sinx;

	inverse.Transpose(&matrix);

	mat.Identity();

	mat.m[0][0] = cosy;
	mat.m[2][2] = cosy;
	mat.m[0][2] = 0.0 - siny;
	mat.m[2][0] = siny;

	matrix.TimesA(&mat);

	mat.Transpose();

	inverse.TimesB(&mat);

	mat.Identity();

	mat.m[0][0] = cosz;
	mat.m[1][1] = cosz;
	mat.m[0][1] = sinz;
	mat.m[1][0] = 0.0 - sinz;

	matrix.TimesA(&mat);

	mat.Transpose();

	inverse.TimesB(&mat);
}

Vector Transform::TransPoint(Vector vector)
{
	int i;
	double answer_array[4];

	for (i = 0 ; i < 3 ; i++)
	{
		answer_array[i] = vector.x * matrix.m[0][i] +
		                  vector.y * matrix.m[1][i] +
		                  vector.z * matrix.m[2][i] + matrix.m[3][i];
	}
	return Vector(answer_array[0],answer_array[1],answer_array[2]);
}


Vector Transform::TransDirection(Vector vector)
{
	int i;
	double answer_array[4];

	for (i = 0 ; i < 3 ; i++)
	{
		answer_array[i] = vector.x * matrix.m[0][i] +
		                  vector.y * matrix.m[1][i] +
		                  vector.z * matrix.m[2][i];
	}
	return Vector(answer_array[0],answer_array[1],answer_array[2]);
}


Vector Transform::InvTransPoint(Vector vector)
{
	int i;
	double answer_array[4];

	for (i = 0 ; i < 3 ; i++)
	{
		answer_array[i] = vector.x * inverse.m[0][i] +
		                  vector.y * inverse.m[1][i] +
		                  vector.z * inverse.m[2][i] + inverse.m[3][i];
	}
	return Vector(answer_array[0],answer_array[1],answer_array[2]);
}

Vector Transform::InvTransDirection(Vector vector)
{
	int i;
	double answer_array[4];

	for (i = 0 ; i < 3 ; i++)
	{
		answer_array[i] = vector.x * inverse.m[0][i] +
		                  vector.y * inverse.m[1][i] +
		                  vector.z * inverse.m[2][i];
	}
	return Vector(answer_array[0],answer_array[1],answer_array[2]);
}

Vector Transform::TransNormal(Vector vector)
{
	return InvTransDirection(vector);
}

Vector Transform::InvTransNormal(Vector vector)
{
	return TransDirection(vector);
}

void Transform::LoadFromMatrix(Matrix *mat)
{
	int i;

	for (i = 0; i < 4; i++)
	{
		matrix.m[i][0] = mat->m[i][0];
		matrix.m[i][1] = mat->m[i][1];
		matrix.m[i][2] = mat->m[i][2];
		matrix.m[i][3] = mat->m[i][3];
	}

	mat->Inverse(&inverse);
}


//   Rotation about an arbitrary axis - formula from:
//
//   "Computational Geometry for Design and Manufacture", Faux & Pratt
//   NOTE: The angles for this transform are specified in radians.
//

void Transform::CalcAxisRotation(Vector AxisVect, double angle)
{
	double cosx, sinx;
	Vector V1;

	V1 = Vector::Normalize(AxisVect);

	matrix.Identity();

	cosx = cos(angle);
	sinx = sin(angle);

	matrix.m[0][0] = V1.x * V1.x + cosx * (1.0 - V1.x * V1.x);
	matrix.m[0][1] = V1.x * V1.y * (1.0 - cosx) + V1.z * sinx;
	matrix.m[0][2] = V1.x * V1.z * (1.0 - cosx) - V1.y * sinx;

	matrix.m[1][0] = V1.x * V1.y * (1.0 - cosx) - V1.z * sinx;
	matrix.m[1][1] = V1.y * V1.y + cosx * (1.0 - V1.y * V1.y);
	matrix.m[1][2] = V1.y * V1.z * (1.0 - cosx) + V1.x * sinx;

	matrix.m[2][0] = V1.x * V1.z * (1.0 - cosx) + V1.y * sinx;
	matrix.m[2][1] = V1.y * V1.z * (1.0 - cosx) - V1.x * sinx;
	matrix.m[2][2] = V1.z * V1.z + cosx * (1.0 - V1.z * V1.z);

	inverse.Transpose(&matrix);
}

void Transform::Compose(Transform *Additional_Transform)
{
	matrix.TimesA(&Additional_Transform->matrix);
	inverse.TimesB(&Additional_Transform->inverse);
}

void Transform::CalcCoordinate(Vector origin, Vector up, double radius, double length)
{
	Transform trans2;
	Vector tmpv = Vector(radius, radius, length);

	CalcScaling(tmpv);
	if (fabs(up.z) > 1.0 - EPSILON)	{
		tmpv = Vector(1.0, 0.0, 0.0);
		up.z = up.z < 0.0 ? -1.0 : 1.0;
	}
	else {
		tmpv = Vector(-up.y, up.x, 0.0);
	}
	trans2.CalcAxisRotation(tmpv, acos(up.z));
	Compose(&trans2);
	trans2.CalcTranslation(origin);
	Compose(&trans2);
}

};
