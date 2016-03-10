#include "stdafx.h"

namespace Finray {

void Transform::CalcScaling(const Vector vector)
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

void Transform::CalcTranslation(const Vector vector)
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

void Transform::CalcRotation(const Vector vector)
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

};
