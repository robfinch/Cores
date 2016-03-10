
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
};

class Transform
{
public:
	Matrix matrix;
	Matrix inverse;
	void CalcScaling(const Vector vector);
	void CalcTranslation(const Vector vector);
	void CalcRotation(const Vector vector);
};

};
