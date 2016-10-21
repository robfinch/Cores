#pragma once
// Polynomials are represented by co-efficients in the following order:
//
//     c[n] * x ^ n + c[n-1] * x ^ (n-1) + ... + c[1] * x + c[0] = 0

// A coefficient smaller than SMALL_ENOUGH is considered to be zero (0.0).
#ifndef DBL
#define DBL		double
#endif
const DBL SMALL_ENOUGH = 1.0e-10;
const int MAX_ORDER = 35;

class Polynomial
{
public:
	int order;
	int numroots;
	DBL coeff[MAX_ORDER+1];
	DBL roots[MAX_ORDER+1];
private:
	static int NumChanges(int np, Polynomial *sseq, DBL a);
	static int VisibleRoots(int np, const Polynomial *sseq, int *atzer, int  *atpos);
	bool regula_falsa(DBL a, DBL b);
	int sbisect(int np, Polynomial *sseq, DBL min_value, DBL  max_value, int atmin, int  atmax, DBL *rts);
	int BuildSturm(Polynomial *sseq);
	bool HasDifficultCoeffs();
	bool Solve2(DBL epsilon, bool sturm);
	int polysolve();
public:
	Polynomial() { order = 0; };
	Polynomial(int o);
	~Polynomial();
	void Copy(Polynomial *);
	static int modp(const Polynomial *u, const Polynomial *v, Polynomial *r);
	DBL ValueAt(DBL x);
	void CalcDerivative(Polynomial *);
	int Reorder();
	int SolveQuartic();
	int SolveQuadratic();
	int SolveCubic();
	int Solve(DBL epsilon, bool sturm);
};

