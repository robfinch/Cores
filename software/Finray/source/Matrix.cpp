#include "stdafx.h"

namespace Finray
{

void Matrix::Zero()
{
	memset(this, 0, sizeof(Matrix));
}

void Matrix::Identity()
{
	int nn;

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

};

