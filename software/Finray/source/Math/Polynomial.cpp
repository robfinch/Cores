/*******************************************************************************
 * Polynomial.cpp
 *
 * Most of this code was originally written by Alexander Enzmann and provided
 * for POV-Ray. It has been ported over with changes to Finray. Most
 * modifications are minor and hopefully don't break the math.
 *
 * The polynomial structure has been changed to a class, and storage for the
 * roots of the polynomial provided in the class.
 *
 *******************************************************************************/

#include "stdafx.h"

#ifndef FUDGE_FACTOR1
	#define FUDGE_FACTOR1 1.0e12
#endif
#ifndef FUDGE_FACTOR2
	#define FUDGE_FACTOR2 -1.0e-5
#endif
#ifndef FUDGE_FACTOR3
	#define FUDGE_FACTOR3 1.0e-7
#endif

/* Constants. */
const DBL TWO_M_PI_3  = 2.0943951023931954923084;
const DBL FOUR_M_PI_3 = 4.1887902047863909846168;

/* Max number of iterations. */
const int MAX_ITERATIONS = 50;

/* Smallest relative error we want. */
const DBL RELERROR = 1.0e-12;

const DBL MAX_DISTANCE = BIG;

Polynomial::Polynomial(int o)
{
	order = o;
	numroots = 0;
	memset(coeff,0,sizeof(coeff));
	memset(roots,0,sizeof(roots));
}

Polynomial::~Polynomial()
{
}

void Polynomial::Copy(Polynomial *u)
{
	memcpy(this, u, sizeof(Polynomial));
}


//   This code available from numerous sources was called polyeval.
//
//   Evaluate the value of a polynomial at the given value x.
//
//   The coefficients are stored in c in the following order:
//
//     c[0] + c[1] * x + c[2] * x ^ 2 + c[3] * x ^ 3 + ...
//
//     = c[0] + x (c[1] + x * (c[2] + x * (c[3] +....
//

DBL Polynomial::ValueAt(DBL x)
{
	int i;
	DBL val;

	val = coeff[order];
	for (i = order-1; i >= 0; i--)
		val = val * x + coeff[i];

	return (val);
}


// Reduce the order of the polynomial by eliminating leading elements where the
// coefficient is small enough.

inline int Polynomial::Reorder()
{
	for (; order > 0; order--) {
		if (fabs(coeff[order]) > SMALL_ENOUGH)
			break;
	}
	return order;
}

/*****************************************************************************
*
*   modp
*
* ORIGINAL AUTHOR
*
*   Alexander Enzmann
*   
*   Calculates the modulus of u(x) / v(x) leaving it in r.
*   It returns 0 if r(x) is a constant.
*
*   NOTE: This function assumes the leading coefficient of v is 1 or -1.
*
* CHANGES
*
*   Okt 1996 : Added bug fix by Heiko Eissfeldt. [DB]
*
******************************************************************************/

int Polynomial::modp(const Polynomial *u, const Polynomial *v, Polynomial *r)
{
	int k, j;

	r->Copy((Polynomial *)u);

	if (v->coeff[v->order] < 0.0)
	{
		for (k = u->order - v->order - 1; k >= 0; k -= 2)
		{
			r->coeff[k] = -r->coeff[k];
		}

		for (k = u->order - v->order; k >= 0; k--)
		{
			for (j = v->order + k - 1; j >= k; j--)
			{
				r->coeff[j] = -r->coeff[j] - r->coeff[v->order + k] * v->coeff[j - k];
			}
		}
	}
	else
	{
		for (k = u->order - v->order; k >= 0; k--)
		{
			for (j = v->order + k - 1; j >= k; j--)
			{
				r->coeff[j] -= r->coeff[v->order + k] * v->coeff[j - k];
			}
		}
	}

	// Changed here to invoke Reorder()
	if (v->order > 0) {
		r->order = v->order - 1;
		r->Reorder();
	}
	else
		r->order = 0;
	return (r->order);
}


/*****************************************************************************
*
* AUTHOR
*
*   Alexander Enzmann
*
******************************************************************************/

// Test to see if any coeffs are more than 6 orders of magnitude
// larger than the smallest.

bool Polynomial::HasDifficultCoeffs()
{
	int i;
	bool flag = false;
	DBL t, biggest;

	biggest = fabs(coeff[order]);

	for (i = 0; i < order; i++)
	{
		t = fabs(coeff[i]);
		if (t > biggest)
			biggest = t;
	}

	// Everything is zero no sense in doing any more
	if (biggest == 0.0)
		return (flag);

	for (i = 0; i <= order; i++)
	{
		if (coeff[i] != 0.0)
		{
			if (fabs(biggest / coeff[i]) > FUDGE_FACTOR1)
			{
				coeff[i] = 0.0;
				flag = true;
			}
		}
	}
	return (flag);
}


// Compute the derivative of a polynomial.

void Polynomial::CalcDerivative(Polynomial *der)
{
	int ii;
	DBL f;

	der->order = order-1;
	f = fabs(coeff[order] * order);
	for (ii = 1; ii <= order; ii++)
		der->coeff[ii-1] = coeff[ii] * ii / f;
}


/*****************************************************************************
* ORIGINAL AUTHOR
*
*   Alexander Enzmann
*   
* DESCRIPTION
*
*   Build the sturmian sequence for a polynomial.
*
******************************************************************************/

int Polynomial::BuildSturm(Polynomial *sseq)
{
	DBL f;
	DBL *fp;
	Polynomial *sp;

	sseq[0].order = order;

	sseq[0].CalcDerivative(&sseq[1]);

	// construct the rest of the Sturm sequence
	for (sp = sseq + 2; modp(sp - 2, sp - 1, sp); sp++)
	{
		// reverse the sign and normalize
		f = -fabs(sp->coeff[sp->order]);
		for (fp = &sp->coeff[sp->order]; fp >= sp->coeff; fp--)
			*fp /= f;
	}

	// reverse the sign
	sp->coeff[0] = -sp->coeff[0];

	return (sp - sseq);
}

/*****************************************************************************
*
* AUTHOR
*
*   Alexander Enzmann
*   
******************************************************************************/

// Return the number of sign changes in the Sturm sequence in
// sseq at the value a.

int Polynomial::NumChanges(int np, Polynomial *sseq, DBL a)
{
	int changes;
	DBL f, lf;
	Polynomial *s;

	changes = 0;

	lf = sseq[0].ValueAt(a);
	for (s = sseq + 1; s <= sseq + np; s++)
	{
		f = s->ValueAt(a);
		if (lf == 0.0 || lf * f < 0)
			changes++;
		lf = f;
	}
	return (changes);
}


/*****************************************************************************
*
* AUTHOR
*
*   Alexander Enzmann
*   
******************************************************************************/

// Find out how many visible intersections there are.

int Polynomial::VisibleRoots(int np, const Polynomial *sseq, int *atzer, int  *atpos)
{
	int atposinf, atzero;
	const Polynomial *s;
	DBL f, lf;

	atposinf = atzero = 0;

	// changes at positve infinity
	lf = sseq[0].coeff[sseq[0].order];
	for (s = sseq + 1; s <= sseq + np; s++)
	{
		f = s->coeff[s->order];
		if (lf == 0.0 || lf * f < 0)
			atposinf++;
		lf = f;
	}

	// Changes at zero
	lf = sseq[0].coeff[0];
	for (s = sseq+1; s <= sseq + np; s++)
	{
		f = s->coeff[0];
		if (lf == 0.0 || lf * f < 0)
			atzero++;
		lf = f;
	}

	*atzer = atzero;
	*atpos = atposinf;

	return (atzero - atposinf);
}

/*****************************************************************************
*
* ORIGNAL AUTHOR
*
*   Alexander Enzmann
*
* PORTED to FINRAY By
*
*   Robert Finch
*
* DESCRIPTION
*
*   Close in on a root by using regula-falsa.
*
******************************************************************************/

bool Polynomial::regula_falsa(DBL a, DBL b)
{
	int its;
	DBL fa, fb, x, fx, lfx;

	fa = ValueAt(a);
	fb = ValueAt(b);

	if (fa * fb > 0.0)
		return (false);

	if (fabs(fa) < SMALL_ENOUGH)
	{
		roots[0] = a;
		return (true);
	}

	if (fabs(fb) < SMALL_ENOUGH)
	{
		roots[0] = b;
		return (true);
	}

	lfx = fa;
	for (its = 0; its < MAX_ITERATIONS; its++)
	{
		x = (fb * a - fa * b) / (fb - fa);

		fx = ValueAt(x);
		if (fabs(x) > RELERROR)
		{
			if (fabs(fx / x) < RELERROR)
			{
				roots[0] = x;
				return (true);
			}
		}
		else if (fabs(fx) < RELERROR)
		{
			roots[0] = x;
			return (true);
		}

		if (fa < 0)
		{
			if (fx < 0)
			{
				a = x;
				fa = fx;
				if ((lfx * fx) > 0)
					fb /= 2;
			}
			else
			{
				b = x;
				fb = fx;
				if ((lfx * fx) > 0)
					fa /= 2;
			}
		}
		else
		{
			if (fx < 0)
			{
				b = x;
				fb = fx;
				if ((lfx * fx) > 0)
					fa /= 2;
			}
			else
			{
				a = x;
				fa = fx;
				if ((lfx * fx) > 0)
					fb /= 2;
			}
		}

		// Check for underflow in the domain
		if (fabs(b-a) < RELERROR)
		{
			roots[0] = x;
			return (true);
		}
		lfx = fx;
	}
	return (false);
}


/*****************************************************************************
*
* FUNCTION
*
*   sbisect
*
* ORIGINAL AUTHOR
*
*   Alexander Enzmann
*
* PORT to FINRAY
*
*   Rob Finch
*   
* DESCRIPTION
*
*   Uses a bisection based on the sturm sequence for the polynomial
*   described in sseq to isolate intervals in which roots occur,
*   the roots are returned in the roots array in order of magnitude.
*
*   NOTE: This routine has one severe bug: When the interval containing the
*         root [min, max] has a root at one of its endpoints, as well as one
*         within the interval, the root at the endpoint will be returned
*         rather than the one inside.
*
******************************************************************************/

int Polynomial::sbisect(int np, Polynomial *sseq, DBL min_value, DBL max_value, int atmin, int  atmax, DBL *rts)
{
	DBL mid;
	int n1, n2, its, atmid;

	if ((atmin - atmax) == 1)
	{
		// first try using regula-falsa to find the root.
		if (sseq->regula_falsa(min_value, max_value)) {
			rts[0] = sseq->roots[0];
			return (1);
		}
		else
		{
			// That failed, so now find it by bisection

			for (its = 0; its < MAX_ITERATIONS; its++)
			{
				mid = (min_value + max_value) / 2;
				atmid = NumChanges(np, sseq, mid);

				/* The follow only happens if there is a bug.  And
				   unfortunately, there is. CEY 04/97 
				 */
				if ((atmid<atmax) || (atmid>atmin))
				{
					return(0);
				}

				if (fabs(mid) > RELERROR)
				{
					if (fabs((max_value - min_value) / mid) < RELERROR)
					{
						rts[0] = mid;
						return(1);
					}
				}
				else
				{
					if (fabs(max_value - min_value) < RELERROR)
					{
						rts[0] = mid;
						return(1);
					}
				}

				if ((atmin - atmid) == 0)
				{
					min_value = mid;
				}
				else
				{
					max_value = mid;
				}
			}

			// Bisection took too long - just return what we got
			rts[0] = mid;
			return(1);
		}
	}

	/* There is more than one root in the interval.
	   Bisect to find new intervals. */

	for (its = 0; its < MAX_ITERATIONS; its++)
	{
		mid = (min_value + max_value) / 2;
		atmid = NumChanges(np, sseq, mid);

		/* The follow only happens if there is a bug.  And
		   unfortunately, there is. CEY 04/97 
		 */
		if ((atmid<atmax) || (atmid>atmin))
		{
			return(0);
		}

		if (fabs(mid) > RELERROR)
		{
			if (fabs((max_value - min_value) / mid) < RELERROR)
			{
				rts[0] = mid;
				return (1);
			}
		}
		else
		{
			if (fabs(max_value - min_value) < RELERROR)
			{
				rts[0] = mid;
				return (1);
			}
		}

		n1 = atmin - atmid;
		n2 = atmid - atmax;

		if ((n1 != 0) && (n2 != 0))
		{
			n1 = sbisect(np, sseq, min_value, mid, atmin, atmid, rts);
			n2 = sbisect(np, sseq, mid, max_value, atmid, atmax, &rts[n1]);
			return (n1 + n2);
		}

		if (n1 == 0)
		{
			min_value = mid;
		}
		else
		{
			max_value = mid;
		}
	}

	// Took too long to bisect.  Just return what we got.
	rts[0] = mid;
	return (true);
}


/*****************************************************************************
*
* AUTHOR
*
*   Alexander Enzmann
*   
* DESCRIPTION
*
*   Solve the quadratic equation:
*
*     x[0] * x^2 + x[1] * x + x[2] = 0.
*
*   The value returned by this function is the number of real roots.
*   The roots themselves are returned in y[0], y[1].
*
******************************************************************************/

int Polynomial::SolveQuadratic()
{
	DBL d, t, a, b, c;

	a = coeff[2];
	b = -coeff[1];
	c = coeff[0];

	if (a == 0.0)
	{
		if (b == 0.0)
			return(0);
		roots[0] = c / b;
		return numroots = 1;
	}

	// normalize the coefficients
	b /= a;
	c /= a;
	a  = 1.0;

	d = b * b - 4.0 * a * c;

	/* Treat values of d around 0 as 0. */

	if ((d > -SMALL_ENOUGH) && (d < SMALL_ENOUGH))
	{
		roots[0] = 0.5 * b / a;
		return numroots = 1;
	}
	else
	{
		if (d < 0.0)
			return numroots = 0;
	}

	d = sqrt(d);

	t = 2.0 * a;

	roots[0] = (b + d) / t;
	roots[1] = (b - d) / t;

	return numroots = 2;
}

/*****************************************************************************
*
* AUTHOR
*
*   Alexander Enzmann
*   
* DESCRIPTION
*
*
*   Solve the cubic equation:
*
*     x[0] * x^3 + x[1] * x^2 + x[2] * x + x[3] = 0.
*
*   The result of this function is an integer that tells how many real
*   roots exist.  Determination of how many are distinct is up to the
*   process that calls this routine.  The roots that exist are stored
*   in (y[0], y[1], y[2]).
*
*   NOTE: This function relies very heavily on trigonometric functions and
*         the square root function.  If an alternative solution is found
*         that does not rely on transcendentals this code will be replaced.
*
******************************************************************************/
//     c[3] * x^3 + c[2] * x^2 + c[1] * x + c[0] = 0.

int Polynomial::SolveCubic()
{
	DBL Q, R, Q3, R2, sQ, d, an, theta;
	DBL A2, a0, a1, a2, a3;

	a0 = coeff[3];

	if (a0 == 0.0)
		return(SolveQuadratic());
	else
	{
		if (a0 != 1.0)
		{
			a1 = coeff[2] / a0;
			a2 = coeff[1] / a0;
			a3 = coeff[0] / a0;
		}
		else
		{
			a1 = coeff[2];
			a2 = coeff[1];
			a3 = coeff[0];
		}
	}

	A2 = a1 * a1;

	Q = (A2 - 3.0 * a2) / 9.0;

	/* Modified to save some multiplications and to avoid a floating point
	   exception that occured with DJGPP and full optimization. [DB 8/94] */

	R = (a1 * (A2 - 4.5 * a2) + 13.5 * a3) / 27.0;

	Q3 = Q * Q * Q;

	R2 = R * R;

	d = Q3 - R2;

	an = a1 / 3.0;

	if (d >= 0.0)
	{
		/* Three real roots. */

		d = R / sqrt(Q3);

		theta = acos(d) / 3.0;

		sQ = -2.0 * sqrt(Q);

		roots[0] = sQ * cos(theta) - an;
		roots[1] = sQ * cos(theta + TWO_M_PI_3) - an;
		roots[2] = sQ * cos(theta + FOUR_M_PI_3) - an;

		return numroots = 3;
	}
	else
	{
		sQ = pow(sqrt(R2 - Q3) + fabs(R), 1.0 / 3.0);

		if (R < 0)
			roots[0] = (sQ + Q / sQ) - an;
		else
			roots[0] = -(sQ + Q / sQ) - an;

		return numroots = 1;
	}
}


#ifdef TEST_SOLVER
/*****************************************************************************
*
* FUNCTION
*
*   solve_quartic
*
* INPUT
*   
* OUTPUT
*   
* RETURNS
*   
* AUTHOR
*
*   Alexander Enzmann
*
* DESCRIPTION
*
*   The old way of solving quartics algebraically.
*   This is an adaptation of the method of Lodovico Ferrari (Circa 1731).
*
* CHANGES
*
*   -
*
******************************************************************************/

int Polynomial::SolveQuartic()
{
	Polynomial cubic(3);
	DBL a0, a1, y, d1, x1, t1, t2;
	DBL c0, c1, c2, c3, c4, d2, q1, q2;
	int i;

	c0 = coeff[4];

	if (c0 != 1.0)
	{
		c1 = coeff[3] / c0;
		c2 = coeff[2] / c0;
		c3 = coeff[1] / c0;
		c4 = coeff[0] / c0;
	}
	else
	{
		c1 = coeff[3];
		c2 = coeff[2];
		c3 = coeff[1];
		c4 = coeff[0];
	}

	/* The first step is to take the original equation:

	     x^4 + b*x^3 + c*x^2 + d*x + e = 0

	   and rewrite it as:

	     x^4 + b*x^3 = -c*x^2 - d*x - e,

	   adding (b*x/2)^2 + (x^2 + b*x/2)y + y^2/4 to each side gives a
	   perfect square on the lhs:

	     (x^2 + b*x/2 + y/2)^2 = (b^2/4 - c + y)x^2 + (b*y/2 - d)x + y^2/4 - e

	   By choosing the appropriate value for y, the rhs can be made a perfect
	   square also.  This value is found when the rhs is treated as a quadratic
	   in x with the discriminant equal to 0.  This will be true when:

	     (b*y/2 - d)^2 - 4.0 * (b^2/4 - c*y)*(y^2/4 - e) = 0, or

	     y^3 - c*y^2 + (b*d - 4*e)*y - b^2*e + 4*c*e - d^2 = 0.

	   This is called the resolvent of the quartic equation.  */

	a0 = 4.0 * c4;

	cubic.coeff[3] = 1.0;
	cubic.coeff[2] = -1.0 * c2;
	cubic.coeff[1] = c1 * c3 - a0;
	cubic.coeff[0] = a0 * c2 - c1 * c1 * c4 - c3 * c3;

	i = cubic.Solve();

	if (i > 0)
	{
		y = cubic.roots[0];
	}
	else
	{
		return(0);
	}

	/* What we are left with is a quadratic squared on the lhs and a
	   linear term on the right.  The linear term has one of two signs,
	   take each and add it to the lhs.  The form of the quartic is now:

	     a' = b^2/4 - c + y,    b' = b*y/2 - d, (from rhs quadritic above)

	     (x^2 + b*x/2 + y/2) = +sqrt(a'*(x + 1/2 * b'/a')^2), and
	     (x^2 + b*x/2 + y/2) = -sqrt(a'*(x + 1/2 * b'/a')^2).

	   By taking the linear term from each of the right hand sides and
	   adding to the appropriate part of the left hand side, two quadratic
	   formulas are created.  By solving each of these the four roots of
	   the quartic are determined.
	*/

	i = 0;

	a0 = c1 / 2.0;
	a1 = y / 2.0;

	t1 = a0 * a0 - c2 + y;

	if (t1 < 0.0)
	{
		if (t1 > FUDGE_FACTOR2)
		{
			t1 = 0.0;
		}
		else
		{
			/* First Special case, a' < 0 means all roots are complex. */

			return(0);
		 }
	 }

	if (t1 < FUDGE_FACTOR3)
	{
		/* Second special case, the "x" term on the right hand side above
		   has vanished.  In this case:

		     (x^2 + b*x/2 + y/2) = +sqrt(y^2/4 - e), and
		     (x^2 + b*x/2 + y/2) = -sqrt(y^2/4 - e).  */

		t2 = a1 * a1 - c4;

		if (t2 < 0.0)
		{
			return(0);
		}

		x1 = 0.0;
		d1 = sqrt(t2);
	}
	else
	{
		x1 = sqrt(t1);
		d1 = 0.5 * (a0 * y - c3) / x1;
	}

	/* Solve the first quadratic */

	q1 = -a0 - x1;
	q2 = a1 + d1;
	d2 = q1 * q1 - 4.0 * q2;

	if (d2 >= 0.0)
	{
		d2 = sqrt(d2);

		roots[0] = 0.5 * (q1 + d2);
		roots[1] = 0.5 * (q1 - d2);

		i = 2;
	}

	/* Solve the second quadratic */

	q1 = q1 + x1 + x1;
	q2 = a1 - d1;
	d2 = q1 * q1 - 4.0 * q2;

	if (d2 >= 0.0)
	{
		d2 = sqrt(d2);

		roots[i++] = 0.5 * (q1 + d2);
		roots[i++] = 0.5 * (q1 - d2);
	}

	return(i);
}
#else
/*****************************************************************************
*
* FUNCTION
*
*   solve_quartic
*
* INPUT
*   
* OUTPUT
*   
* RETURNS
*   
* AUTHOR
*
*   Alexander Enzmann
*
* DESCRIPTION
*
*   Solve a quartic using the method of Francois Vieta (Circa 1735).
*
* CHANGES
*
*   -
*
******************************************************************************/

int Polynomial::SolveQuartic()
{
	Polynomial cubic(3);
	DBL roots[3];
	DBL c12, z, p, q, q1, q2, r, d1, d2;
	DBL c0, c1, c2, c3, c4;
	int i;

	/* Make sure the quartic has a leading coefficient of 1.0 */

	c0 = coeff[4];

	if (c0 != 1.0)
	{
		c1 = coeff[3] / c0;
		c2 = coeff[2] / c0;
		c3 = coeff[1] / c0;
		c4 = coeff[0] / c0;
	}
	else
	{
		c1 = coeff[3];
		c2 = coeff[2];
		c3 = coeff[1];
		c4 = coeff[0];
	}

	/* Compute the cubic resolvant */

	c12 = c1 * c1;
	p = -0.375 * c12 + c2;
	q = 0.125 * c12 * c1 - 0.5 * c1 * c2 + c3;
	r = -0.01171875 * c12 * c12 + 0.0625 * c12 * c2 - 0.25 * c1 * c3 + c4;

	cubic.coeff[3] = 1.0;
	cubic.coeff[2] = -0.5 * p;
	cubic.coeff[1] = -r;
	cubic.coeff[0] = 0.5 * r * p - 0.125 * q * q;

	i = cubic.SolveCubic();

	if (i > 0)
	{
		z = cubic.roots[0];
	}
	else
	{
		return(0);
	}

	d1 = 2.0 * z - p;

	if (d1 < 0.0)
	{
		if (d1 > -SMALL_ENOUGH)
		{
			d1 = 0.0;
		}
		else
		{
			return(0);
		}
	}

	if (d1 < SMALL_ENOUGH)
	{
		d2 = z * z - r;

		if (d2 < 0.0)
		{
			return(0);
		}

		d2 = sqrt(d2);
	}
	else
	{
		d1 = sqrt(d1);
		d2 = 0.5 * q / d1;
	}

	/* Set up useful values for the quadratic factors */

	q1 = d1 * d1;
	q2 = -0.25 * c1;

	i = 0;

	/* Solve the first quadratic */

	p = q1 - 4.0 * (z - d2);

	if (p == 0)
	{
		roots[0] = -0.5 * d1 - q2;
		i = 1;
	}
	else
	{
		if (p > 0)
		{
			p = sqrt(p);
			roots[0] = -0.5 * (d1 + p) + q2;
			roots[1] = -0.5 * (d1 - p) + q2;
			i = 2;
		}
	}

	/* Solve the second quadratic */

	p = q1 - 4.0 * (z + d2);

	if (p == 0)
	{
		roots[i] = 0.5 * d1 - q2;
		i++;
	}
	else
	{
		if (p > 0)
		{
			p = sqrt(p);
			roots[i] = 0.5 * (d1 + p) + q2;
			i++;
			roots[i] = 0.5 * (d1 - p) + q2;
			i++;
		}
	}

	return(i);
}
#endif


/*****************************************************************************
*
* ORIGINAL AUTHOR
*
*   Alexander Enzmann
*   
* DESCRIPTION
*
*   Root solver based on the Sturm sequences for a polynomial.
*
* CHANGES
*
*   Okt 1996 : Added bug fix by Heiko Eissfeldt. [DB]
*
******************************************************************************/

int Polynomial::polysolve()
{
	Polynomial sseq[MAX_ORDER+1];
	DBL min_value, max_value;
	int i, nroots, np, atmin, atmax;

	// Put the coefficients into the top of the stack.
	sseq[0].order = order;
	for (i = 0; i <= order; i++)
		sseq[0].coeff[i] = coeff[i] / coeff[order];

	// Build the Sturm sequence
	np = BuildSturm(&sseq[0]);

	// Get the total number of visible roots
	if ((nroots = VisibleRoots(np, sseq, &atmin, &atmax)) == 0)
		return (0);

	// Bracket the roots
	min_value = 0.0;
	max_value = MAX_DISTANCE;

	atmin = NumChanges(np, sseq, min_value);
	atmax = NumChanges(np, sseq, max_value);

	nroots = atmin - atmax;

	if (nroots == 0)
		return (0);

	// perform the bisection.
	return(sbisect(np, sseq, min_value, max_value, atmin, atmax, roots));
}


// Root elimination helper method.
//
// Returns true if the order of the polynomial was reduced and solved.
// This function is restricted to reducing the polynomial by only a
// single level.

bool Polynomial::Solve2(DBL epsilon, bool sturm)
{
	static int level = 0;
	int nn;

	if (epsilon > 0.0 && level==0) {
		level++;
		if ((coeff[1] != 0.0) && (fabs(coeff[0]/coeff[1]) < epsilon)) {
			Polynomial p(order-1);
			for (nn = 0; nn < order; nn++)
				p.coeff[nn] = coeff[nn+1];
			numroots = p.Solve(epsilon,sturm);
			for (nn = 0; nn < numroots; nn++)
				roots[nn] = p.roots[nn];
			level--;
			return (true);
		}
		level--;
	}
	return (false);
}

/*****************************************************************************
*
* FUNCTION
*
*   Solve() (Originally: Solve_Polynomial)
*
* RETURNS
*
*   int - number of roots found
*   
* ORIGINAL AUTHOR
*
*   Dieter Bayer
*   
* DESCRIPTION
*
*   Solve the polynomial equation
*
*     c[n] * x ^ n + c[n-1] * x ^ (n-1) + ... + c[1] * x + c[0] = 0
*
*   If the equation has a root r, |r| < epsilon, this root is eliminated
*   and the equation of order n-1 will be solved. This will avoid the problem
*   of "surface acne" in (most) cases while increasing the speed of the
*   root solving (polynomial's order is reduced by one).
*
*   WARNING: This function can only be used for polynomials if small roots
*   (i.e. |x| < epsilon) are not needed. This is the case for ray/object
*   intersection tests because only intersecions with t > 0 are valid.
*
*   NOTE: Only one root at x = 0 will be eliminated.
*
*   NOTE: If epsilon = 0 no roots will be eliminated.
*
*
*   The method and idea for root elimination was taken from:
*
*     Han-Wen Nienhuys, "Polynomials", Ray Tracing News, July 6, 1994,
*     Volume 7, Number 3
*
*
* CHANGES
*
*   Jul 1994 : Creation.
*
******************************************************************************/
//     c[n] * x ^ n + c[n-1] * x ^ (n-1) + ... + c[1] * x + c[0] = 0

int Polynomial::Solve(DBL epsilon, bool sturm)
{
	numroots = 0;
	Reorder();
	switch(order) {
	case 0:	break;	// Constant

	// We know that coeff[1] is non-zero here because the polynomial was reordered
	// eliminating small leading coefficients.
	case 1:	
		roots[0] = -coeff[0] / coeff[1];
		numroots = 1;
		break;

	case 2:
		SolveQuadratic();
		break;

	case 3:
		// Root elimination?
		if (Solve2(epsilon,sturm))
			break;
		// Solve cubic polynomial.
		if (sturm)
			numroots = polysolve();
		else
			SolveCubic();
		break;

	case 4:
		if (Solve2(epsilon,sturm))
			break;

		// Test for difficult coeffs.
		if (HasDifficultCoeffs())
			sturm = true;

		// Solve quartic polynomial.
		if (sturm)
			numroots = polysolve();
		else
			SolveQuartic();
		break;

	// Solve n-th order polynomial.
	default:
		if (Solve2(epsilon,sturm))
			break;
		numroots = polysolve();
		break;
	}
	return (numroots);
}
