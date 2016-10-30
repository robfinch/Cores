#include "stdafx.h"

namespace Finray
{

void Matrix::Zero()
{
	memset(this, 0, sizeof(Matrix));
}

void Matrix::Identity()
{
	memset(this, 0, sizeof(Matrix));
	m[0][0] = 1.0;
	m[1][1] = 1.0;
	m[2][2] = 1.0;
	m[3][3] = 1.0;
}

void Matrix::Swap(int a0, int a1, int b0, int b1)
{
	double c;
	c = m[a0][a1]; m[a0][a1]=m[b0][b1]; m[b0][b1] = c;
}

void Matrix::Transpose()
{
	Swap(0,1,1,0);
	Swap(0,2,2,0);
	Swap(1,2,2,1);
	Swap(2,3,3,2);
	Swap(3,0,0,3);
	Swap(3,1,1,3);
}

void Matrix::Transpose(Matrix *mat)
{
	int ii,jj;

	for (ii = 0; ii < 4; ii++) {
		for (jj = 0; jj < 4; jj++) {
			m[ii][jj] = mat->m[jj][ii];
		}
	}
}

void Matrix::TimesA(Matrix *mat)
{
	double t0, t1, t2, t3;

	t0 = m[0][0];
	t1 = m[0][1];
	t2 = m[0][2];
	t3 = m[0][3];
	m[0][0] = t0 * mat->m[0][0] + t1 * mat->m[1][0] + t2 * mat->m[2][0] + t3 * mat->m[3][0];
	m[0][1] = t0 * mat->m[0][1] + t1 * mat->m[1][1] + t2 * mat->m[2][1] + t3 * mat->m[3][1];
	m[0][2] = t0 * mat->m[0][2] + t1 * mat->m[1][2] + t2 * mat->m[2][2] + t3 * mat->m[3][2];
	m[0][3] = t0 * mat->m[0][3] + t1 * mat->m[1][3] + t2 * mat->m[2][3] + t3 * mat->m[3][3];

	t0 = m[1][0];
	t1 = m[1][1];
	t2 = m[1][2];
	t3 = m[1][3];
	m[1][0] = t0 * mat->m[0][0] + t1 * mat->m[1][0] + t2 * mat->m[2][0] + t3 * mat->m[3][0];
	m[1][1] = t0 * mat->m[0][1] + t1 * mat->m[1][1] + t2 * mat->m[2][1] + t3 * mat->m[3][1];
	m[1][2] = t0 * mat->m[0][2] + t1 * mat->m[1][2] + t2 * mat->m[2][2] + t3 * mat->m[3][2];
	m[1][3] = t0 * mat->m[0][3] + t1 * mat->m[1][3] + t2 * mat->m[2][3] + t3 * mat->m[3][3];

	t0 = m[2][0];
	t1 = m[2][1];
	t2 = m[2][2];
	t3 = m[2][3];
	m[2][0] = t0 * mat->m[0][0] + t1 * mat->m[1][0] + t2 * mat->m[2][0] + t3 * mat->m[3][0];
	m[2][1] = t0 * mat->m[0][1] + t1 * mat->m[1][1] + t2 * mat->m[2][1] + t3 * mat->m[3][1];
	m[2][2] = t0 * mat->m[0][2] + t1 * mat->m[1][2] + t2 * mat->m[2][2] + t3 * mat->m[3][2];
	m[2][3] = t0 * mat->m[0][3] + t1 * mat->m[1][3] + t2 * mat->m[2][3] + t3 * mat->m[3][3];

	t0 = m[3][0];
	t1 = m[3][1];
	t2 = m[3][2];
	t3 = m[3][3];
	m[3][0] = t0 * mat->m[0][0] + t1 * mat->m[1][0] + t2 * mat->m[2][0] + t3 * mat->m[3][0];
	m[3][1] = t0 * mat->m[0][1] + t1 * mat->m[1][1] + t2 * mat->m[2][1] + t3 * mat->m[3][1];
	m[3][2] = t0 * mat->m[0][2] + t1 * mat->m[1][2] + t2 * mat->m[2][2] + t3 * mat->m[3][2];
	m[3][3] = t0 * mat->m[0][3] + t1 * mat->m[1][3] + t2 * mat->m[2][3] + t3 * mat->m[3][3];
}

void Matrix::TimesB(Matrix *mat)
{
	double t0, t1, t2, t3;

	t0 = m[0][0];
	t1 = m[1][0];
	t2 = m[2][0];
	t3 = m[3][0];
	m[0][0] = mat->m[0][0] * t0 + mat->m[0][1] * t1 + mat->m[0][2] * t2 + mat->m[0][3] * t3;
	m[1][0] = mat->m[1][0] * t0 + mat->m[1][1] * t1 + mat->m[1][2] * t2 + mat->m[1][3] * t3;
	m[2][0] = mat->m[2][0] * t0 + mat->m[2][1] * t1 + mat->m[2][2] * t2 + mat->m[2][3] * t3;
	m[3][0] = mat->m[3][0] * t0 + mat->m[3][1] * t1 + mat->m[3][2] * t2 + mat->m[3][3] * t3;

	t0 = m[0][1];
	t1 = m[1][1];
	t2 = m[2][1];
	t3 = m[3][1];
	m[0][1] = mat->m[0][0] * t0 + mat->m[0][1] * t1 + mat->m[0][2] * t2 + mat->m[0][3] * t3;
	m[1][1] = mat->m[1][0] * t0 + mat->m[1][1] * t1 + mat->m[1][2] * t2 + mat->m[1][3] * t3;
	m[2][1] = mat->m[2][0] * t0 + mat->m[2][1] * t1 + mat->m[2][2] * t2 + mat->m[2][3] * t3;
	m[3][1] = mat->m[3][0] * t0 + mat->m[3][1] * t1 + mat->m[3][2] * t2 + mat->m[3][3] * t3;

	t0 = m[0][2];
	t1 = m[1][2];
	t2 = m[2][2];
	t3 = m[3][2];
	m[0][2] = mat->m[0][0] * t0 + mat->m[0][1] * t1 + mat->m[0][2] * t2 + mat->m[0][3] * t3;
	m[1][2] = mat->m[1][0] * t0 + mat->m[1][1] * t1 + mat->m[1][2] * t2 + mat->m[1][3] * t3;
	m[2][2] = mat->m[2][0] * t0 + mat->m[2][1] * t1 + mat->m[2][2] * t2 + mat->m[2][3] * t3;
	m[3][2] = mat->m[3][0] * t0 + mat->m[3][1] * t1 + mat->m[3][2] * t2 + mat->m[3][3] * t3;

	t0 = m[0][3];
	t1 = m[1][3];
	t2 = m[2][3];
	t3 = m[3][3];
	m[0][3] = mat->m[0][0] * t0 + mat->m[0][1] * t1 + mat->m[0][2] * t2 + mat->m[0][3] * t3;
	m[1][3] = mat->m[1][0] * t0 + mat->m[1][1] * t1 + mat->m[1][2] * t2 + mat->m[1][3] * t3;
	m[2][3] = mat->m[2][0] * t0 + mat->m[2][1] * t1 + mat->m[2][2] * t2 + mat->m[2][3] * t3;
	m[3][3] = mat->m[3][0] * t0 + mat->m[3][1] * t1 + mat->m[3][2] * t2 + mat->m[3][3] * t3;
}

void Matrix::Inverse(Matrix *r)
{
	double d00, d01, d02, d03;
	double d10, d11, d12, d13;
	double d20, d21, d22, d23;
	double d30, d31, d32, d33;
	double m00, m01, m02, m03;
	double m10, m11, m12, m13;
	double m20, m21, m22, m23;
	double m30, m31, m32, m33;
	double D;

	m00 = m[0][0];  m01 = m[0][1];  m02 = m[0][2];  m03 = m[0][3];
	m10 = m[1][0];  m11 = m[1][1];  m12 = m[1][2];  m13 = m[1][3];
	m20 = m[2][0];  m21 = m[2][1];  m22 = m[2][2];  m23 = m[2][3];
	m30 = m[3][0];  m31 = m[3][1];  m32 = m[3][2];  m33 = m[3][3];

	d00 = m11*m22*m33 + m12*m23*m31 + m13*m21*m32 - m31*m22*m13 - m32*m23*m11 - m33*m21*m12;
	d01 = m10*m22*m33 + m12*m23*m30 + m13*m20*m32 - m30*m22*m13 - m32*m23*m10 - m33*m20*m12;
	d02 = m10*m21*m33 + m11*m23*m30 + m13*m20*m31 - m30*m21*m13 - m31*m23*m10 - m33*m20*m11;
	d03 = m10*m21*m32 + m11*m22*m30 + m12*m20*m31 - m30*m21*m12 - m31*m22*m10 - m32*m20*m11;

	d10 = m01*m22*m33 + m02*m23*m31 + m03*m21*m32 - m31*m22*m03 - m32*m23*m01 - m33*m21*m02;
	d11 = m00*m22*m33 + m02*m23*m30 + m03*m20*m32 - m30*m22*m03 - m32*m23*m00 - m33*m20*m02;
	d12 = m00*m21*m33 + m01*m23*m30 + m03*m20*m31 - m30*m21*m03 - m31*m23*m00 - m33*m20*m01;
	d13 = m00*m21*m32 + m01*m22*m30 + m02*m20*m31 - m30*m21*m02 - m31*m22*m00 - m32*m20*m01;

	d20 = m01*m12*m33 + m02*m13*m31 + m03*m11*m32 - m31*m12*m03 - m32*m13*m01 - m33*m11*m02;
	d21 = m00*m12*m33 + m02*m13*m30 + m03*m10*m32 - m30*m12*m03 - m32*m13*m00 - m33*m10*m02;
	d22 = m00*m11*m33 + m01*m13*m30 + m03*m10*m31 - m30*m11*m03 - m31*m13*m00 - m33*m10*m01;
	d23 = m00*m11*m32 + m01*m12*m30 + m02*m10*m31 - m30*m11*m02 - m31*m12*m00 - m32*m10*m01;

	d30 = m01*m12*m23 + m02*m13*m21 + m03*m11*m22 - m21*m12*m03 - m22*m13*m01 - m23*m11*m02;
	d31 = m00*m12*m23 + m02*m13*m20 + m03*m10*m22 - m20*m12*m03 - m22*m13*m00 - m23*m10*m02;
	d32 = m00*m11*m23 + m01*m13*m20 + m03*m10*m21 - m20*m11*m03 - m21*m13*m00 - m23*m10*m01;
	d33 = m00*m11*m22 + m01*m12*m20 + m02*m10*m21 - m20*m11*m02 - m21*m12*m00 - m22*m10*m01;

	D = m00*d00 - m01*d01 + m02*d02 - m03*d03;

	if (D == 0.0)
	{
		throw gcnew Finray::FinrayException(ERR_SINGULAR_MATRIX,0);
	}

	r->m[0][0] =  d00/D; r->m[0][1] = -d10/D;  r->m[0][2] =  d20/D; r->m[0][3] = -d30/D;
	r->m[1][0] = -d01/D; r->m[1][1] =  d11/D;  r->m[1][2] = -d21/D; r->m[1][3] =  d31/D;
	r->m[2][0] =  d02/D; r->m[2][1] = -d12/D;  r->m[2][2] =  d22/D; r->m[2][3] = -d32/D;
	r->m[3][0] = -d03/D; r->m[3][1] =  d13/D;  r->m[3][2] = -d23/D; r->m[3][3] =  d33/D;
}

};

