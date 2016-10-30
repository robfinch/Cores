#pragma once

namespace Finray {

class Matrix
{
public:
	double m[4][4];
	void Zero();
	void Identity();
	void Swap(int, int, int, int);
	void Transpose();
	void Transpose(Matrix *);
	void TimesA(Matrix *);
	void TimesB(Matrix *);
	void Inverse(Matrix *);
};

// A transform is just a pair of matricies, the normal matrix and it's inverse
class Transform
{
public:
	Matrix matrix;
	Matrix inverse;
	Transform();
	void Copy(Transform *t);
	void CalcScaling(Vector vector);
	void CalcTranslation(Vector vector);
	void CalcRotation(Vector vector);
	void CalcCoordinate(Vector origin, Vector up, double radius, double length);
	void CalcAxisRotation(Vector AxisVect, double angle);
	Vector TransPoint(Vector vector);
	Vector TransDirection(Vector vector);
	Vector TransNormal(Vector vector);
	Vector InvTransPoint(Vector vector);
	Vector InvTransNormal(Vector vector);
	Vector InvTransDirection(Vector vector);
	void Compose(Transform *Additional_Transform);
	void LoadFromMatrix(Matrix *mat);
};

};
