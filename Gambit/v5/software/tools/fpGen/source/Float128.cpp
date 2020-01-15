
#include "float128.h"
#include "stdio.h"

Float128::Float128(Float128 *a)
{
	int nn;

	for (nn = 0; nn < FLT128_WORDS; nn++)
		man[nn] = a->man[nn];
	exp = a->exp;
	sign = a->sign;
}

// Check if mantissas are equal

bool Float128::ManEQ(Float128 *a, Float128 *b)
{
	int nn;

	for (nn = FLT128_WORDS-1; nn >= 0; nn--) {
		if (a->man[nn]!=b->man[nn])
			return (false);
	}
	return (true);
}

bool Float128::ManGT(Float128 *a, Float128 *b)
{
	int nn;

	for (nn = FLT128_WORDS-1; nn >= 0; nn--) {
		if (a->man[nn] > b->man[nn])
			return (true);
		else if (a->man[nn] < b->man[nn])
			return (false);
	}
	return (false);
}

// Does nothing but shift mantissa left. Zeros are shited in at the low end.

void Float128::ShiftManLeft()
{
	int nn;
	unsigned __int32 c[FLT128_WORDS];

	for (nn = 0; nn < FLT128_WORDS; nn++) {
		c[nn] = (man[nn] >> 31) & 1;
	}
	man[0] <<= 1;
	for (nn = 1; nn < FLT128_WORDS; nn++) {
		man[nn] <<= 1;
		man[nn] |= c[nn-1];
	}
}

// Does nothing but shift mantissa right.

void Float128::ShiftManRight()
{
	int nn;
	unsigned __int32 c[FLT128_WORDS];

	for (nn = 0; nn < FLT128_WORDS; nn++) {
		c[nn] = (man[nn] & 1) << 31;
	}
	man[FLT128_WORDS-1] >>= 1;
	for (nn = FLT128_WORDS-2; nn >= 0; nn--) {
		man[nn] >>= 1;
		man[nn] |= c[nn+1];
	}
}

void Float128::Normalize(Float128 *a)
{
	int nn;

	for(nn = 0; nn < FLT128_WORDS*32-1; nn++) {
		if (a->man[FLT128_WORDS-1] & 0xC0000000)
			break;
		if (a->exp==0)	// Denormal
			break;
		a->ShiftManLeft();
		a->exp = a->exp - 1;
	}
}

// Denormalization used for addition / subtraction.

void Float128::Denormalize(unsigned __int16 xp)
{
	if (exp >= xp)
		return;
	if (xp - exp > FLT128_WORDS*32-1) {
		exp = xp;
		Zeroman();
		return;
	}
	while(exp < xp) {
		ShiftManRight();
		exp++;
	}
}

// Used after an addition in event of a new bit generated.
void Float128::Denorm1()
{
	ShiftManRight();
	man[FLT128_WORDS-1] |= 0x40000000;
	exp++;
	// Check for infinity
	if (exp & 0x8000) {
		exp = infxp;
		Zeroman();
	}
}

// Does nothing but add the mantissas.
// Return true if a new bit was generated.

bool Float128::AddMan(Float128 *s, Float128 *a, Float128 *b)
{
	int nn;
	unsigned __int64 sum[FLT128_WORDS];
	unsigned __int64 c;

	c = 0;
	for (nn = 0; nn < FLT128_WORDS; nn++) {
		sum[nn] = (unsigned __int64)a->man[nn] + (unsigned __int64)b->man[nn] + c;
		c = (sum[nn] >> 32) & 1;
	}
	for (nn = 0; nn < FLT128_WORDS; nn++) {
		s->man[nn] = (unsigned __int32)sum[nn];
	}
	return ((sum[FLT128_WORDS-1] & 0x80000000)!=0);
}

// Does nothing but subtract the mantissas.

bool Float128::SubMan(Float128 *d, Float128 *a, Float128 *b)
{
	int nn;
	unsigned __int64 sum[FLT128_WORDS];
	unsigned __int64 c;

	c = 0;
	for (nn = 0; nn < FLT128_WORDS; nn++) {
		sum[nn] = (unsigned __int64)a->man[nn] - (unsigned __int64)b->man[nn] - c;
		c = (sum[nn] >> 32) & 1;
	}
	for (nn = 0; nn < FLT128_WORDS; nn++) {
		d->man[nn] = (unsigned __int32)sum[nn];
	}
	return ((sum[FLT128_WORDS-1] & 0x80000000)!=0);
}


// Add also used for subtract

void Float128::Add(Float128 *s, Float128 *a, Float128 *b)
{
	Float128 *a1 = new Float128(a);
	Float128 *b1 = new Float128(b);
	bool addsub = a1->sign ^ b1->sign;	// 0 = add, 1=subtract
	bool xa_gt_xb = a1->exp > b1->exp;
	bool a_gt_b = xa_gt_xb || ManGT(a1,b1);
	bool resZero = addsub && a->exp==b->exp && ManEQ(a,b);

	if (a->IsNaN()) {
		Assign(s,a);
		return;
	}
	if (b->IsNaN()) {
		Assign(s,b);
		return;
	}

	if (resZero) {
		s->exp = 0;
		s->Zeroman();
		return;
	}

	// Infinity minus infinity is a NaN
	if (addsub) {
		if (a->IsInfinite() && b->IsInfinite()) {
			s->exp = infxp;
			s->Zeroman();
			s->man[FLT128_WORDS-1] = 0x40000000;	// Querying NaN
			s->man[FLT128_WORDS/2-1] = 0x80000000;	// Code 1
			return;
		}
	}
	// Infinity plus infinity is infinity
	else if (a->IsInfinite() && b->IsInfinite()) {
		s->sign = a->sign;
		s->exp = infxp;
		s->Zeroman();
		return;
	}

	a1 = new Float128(a);
	b1 = new Float128(b);
	if (a1->exp > b1->exp)
		b1->Denormalize(a1->exp);
	else if (a1->exp < b1->exp)
		a1->Denormalize(b1->exp);

	// Exponents are now the same
	// If the signs are different we really want a subtract
	if (addsub) {
		if (a_gt_b) {
			SubMan(s, a1,b1);
			s->exp = a1->exp;
		}
		else {
			SubMan(s, b1,a1);
			s->exp = b1->exp;
		}
		Normalize(s);
	}
	else {
		s->exp = a1->exp;
		if (AddMan(s,a1,b1))
			s->Denorm1();
	}
	delete a1;
	delete b1;
}

void Float128::Div(Float128 *q, Float128 *a, Float128 *b)
{
	int nn;
	Float128 *a1;
	Float128 *b1;
	int a_dn, b_dn;
	a_dn = a->exp==0;
	b_dn = b->exp==0;
	__int32 xp = (a->exp|a_dn) - (b->exp|b_dn) + bias;
	q->sign = a->sign ^ b->sign;

	if (a->IsNaN()) {
		Assign(q,a);
		return;
	}
	if (b->IsNaN()) {
		Assign(q,b);
		return;
	}

	// Check for zero divide by zero
	// or infinity divide by infinity
	if ((a->IsZero() && b->IsZero()) || (a->IsInfinite() && b->IsInfinite())) {
		q->exp = infxp;
		q->Zeroman();
		q->man[FLT128_WORDS-1] = 0x40000000;	// Querying NaN
		q->man[FLT128_WORDS/2] = a->IsZero();
		q->man[FLT128_WORDS/2-1] = b->IsZero() << 31;
		return;
	}

	// Divide by infinity
	if (b->IsInfinite()) {
		q->exp = 0;
		q->Zeroman();
		return;
	}

	// Divide by zero ?
	if (b->IsZero()) {
		q->exp = infxp;
		q->Zeroman();
		return;
	}

	if (a->IsZero()) {
		q->Zeroman();
		q->exp = 0;
		return;
	}

	if (xp > 0x7fff) {
		q->exp = infxp;
		q->Zeroman();
		return;
	}

	a1 = new Float128(a);
	b1 = new Float128(b);
	q->Zeroman();
	for (nn = 0; nn < FLT128_WORDS*32-1; nn++) {
		q->ShiftManLeft();
		if (ManGE(a1,b)) {
			SubMan(a1,a1,b);
			q->man[0] |= 1;
		}
		a1->ShiftManLeft();
	}
	q->exp = xp;
	Normalize(q);
	delete a1;
	delete b1;
}


void Float128::Mul(Float128 *p, Float128 *a, Float128 *b)
{
	int nn;
	Float128 *a1;
	Float128 *b1;
	int a_dn, b_dn;
	a_dn = a->exp==0;
	b_dn = b->exp==0;
	__int32 xp = (a->exp|a_dn) + (b->exp|b_dn) - bias + 1;

	p->sign = a->sign ^ b->sign;

	if (a->IsNaN()) {
		Assign(p,a);
		return;
	}
	if (b->IsNaN()) {
		Assign(p,b);
		return;
	}

	// Check for infinity times zero.
	if ((a->IsZero() && b->IsInfinite()) || (a->IsInfinite() && b->IsZero())) {
		p->exp = infxp;
		p->Zeroman();
		p->man[FLT128_WORDS-1] = 0x40000000;	// Querying NaN
		p->man[FLT128_WORDS/2] = 0x00000002;
		return;
	}

	// Check for multiply by zero
	if (a->IsZero() || b->IsZero()) {
		p->Zeroman();
		p->exp = 0;
		return;
	}

	// Check for multiply by infinity
	if (a->IsInfinite() || b->IsInfinite()) {
		p->exp = infxp;
		p->Zeroman();
		return;
	}

	// Infinity reached ?
	if (xp & 0x8000) {
		p->exp = infxp;
		p->Zeroman();
		return;
	}

	a1 = new Float128(a);
	b1 = new Float128(b);
	p->Zeroman();
	for (nn = 0; nn < FLT128_WORDS*32/2; nn++)
		b1->ShiftManRight();
	for (nn = 0; nn < FLT128_WORDS*32/2; nn++) {
		if (a1->man[FLT128_WORDS/2-1] & 0x80000000) {
			if (AddMan(p, p, b1))		// Can't generate a new bit
				;// printf("bit gen");	// during multiply
		}
		a1->ShiftManRight();
		b1->ShiftManLeft();
	}
	p->exp = xp;
	Normalize(p);
	delete a1;
	delete b1;
}

void Float128::IntToFloat(Float128 *d, __int64 i)
{
	unsigned __int16 wd;
	unsigned __int16 lz;
	bool sign = i < 0;

	d->Zeroman();
	if (i==0) {
		d->exp = 0;
		d->sign = false;
		return;
	}
	if (sign)
		i = -i;
	for (lz = 0; (i & 0x8000000000000000LL)==0; lz++)
		i <<= 1;
	wd = 128 + bias - 1 - lz - 64;
	d->exp = wd;
	d->sign = sign;
	d->man[FLT128_WORDS-1] = (unsigned __int64) i >> 33;
	d->man[FLT128_WORDS-2] = ((i >> 1) & 0xFFFFFFFFLL);
	d->man[FLT128_WORDS-3] = ((i & 1) << 31);
}

void Float128::FloatToInt(__int64 *i, Float128 *a)
{
	Float128 *a1 = new Float128(a);
	bool overflow = a1->exp - bias > 63;
	bool underflow = a1->exp < bias - 1;
	int shamt = 63 - (a1->exp - bias);
	unsigned __int64 t;

	if (overflow) {
		a1->man[FLT128_WORDS-1] = 0x3FFFFFFF;
		a1->man[FLT128_WORDS-2] = 0xFFFFFFFF;
		a1->man[FLT128_WORDS-3] = 0xFFFFFFFF;
	}
	else if (underflow) {
		a1->Zeroman();
	}
	else if (shamt > FLT128_WORDS*32-1) {
		a1->Zeroman();
	}
	else if (shamt < 0) {
	}
	else {
		while(shamt) {
			a1->ShiftManRight();
			shamt--;
		}
	}
	if (a1->man[FLT128_WORDS-4] & 0x08000) {
		t = a1->man[FLT128_WORDS-4];
		t += 0x10000;
		if (t & 0x100000000) {
			a1->man[FLT128_WORDS-3]++;
			if (a1->man[FLT128_WORDS-3]==0) {
				a1->man[FLT128_WORDS-2]++;
				if (a1->man[FLT128_WORDS-2]==0) {
					a1->man[FLT128_WORDS-1]++;
					if (a1->man[FLT128_WORDS-1] & 0x80000000) {
						a1->ShiftManRight();
						a1->exp++;
						if (a1->exp & 0x8000) {
							a1->exp = 0x7fff;
							a1->Zeroman();
						}
					}
				}
			}
		}
	}
	t = (a1->man[FLT128_WORDS-1] << 1) | (a1->man[FLT128_WORDS-2] << 1) | (a1->man[FLT128_WORDS-3] >> 31);
	*i = a1->sign ? ~t + 1 : t;
	delete (a1);
}

void Float128::Float128ToDouble(double *d, Float128 *a)
{
	bool sgn;
	unsigned __int16 exp;
	__int64 *di = (__int64 *)d;

	// Do we have a zero ?
	if (a->IsZero()) {
		*di = a->sign ? 0x8000000000000000LL : 0x0000000000000000LL;
		return;
	}
	// Or an infinite number ?
	if (a->IsInfinite()) {
		*di = a->sign ? 0xFFF0000000000000LL : 0x7FF0000000000000LL;
		return;
	}
	// Too large a number -> infinity
	if (a->exp > a->bias + 0x400) {
		*di = a->sign ? 0xFFF0000000000000LL : 0x7FF0000000000000LL;
		return;
	}
	// Too small a number -> zero
	if (a->exp < a->bias - 0x3ff) {
		*di = a->sign ? 0x8000000000000000LL : 0x0000000000000000LL;
	}
	sgn = a->sign;
	exp = a->exp - (bias - 0x3ff);
	*di = (__int64)sgn << 63;
	*di |= (__int64)exp << 52;
	*di |= (__int64)(a->man[FLT128_WORDS-1] & 0x3FFFFFFFL) << 22;
	*di |= (__int64)a->man[FLT128_WORDS-2] >> 10;
}

void Float128::Pack(int prec)
{
	Float128 a;
	if (man[FLT128_WORDS-5] & 0x40000000) {
		man[FLT128_WORDS-5] += 0x80000000;
		if ((man[FLT128_WORDS-5] & 0x80000000)==0) {
			man[FLT128_WORDS-4]++;
			if (man[FLT128_WORDS-4]==0) {
				man[FLT128_WORDS-3]++;
				if (man[FLT128_WORDS-3]==0) {
					man[FLT128_WORDS-2]++;
					if (man[FLT128_WORDS-2]==0) {
						man[FLT128_WORDS-1]++;
						if (man[FLT128_WORDS-1] & 0x80000000) {
							exp++;
							ShiftManRight();
							if (exp & 0x8000) {
								exp = 0x7FFF;
								man[FLT128_WORDS-1] = 0;
							}
						}
					}
				}
			}
		}
	}	
	Float128::Assign(&a,this);
	a.ShiftManLeft();
	a.ShiftManLeft();
	if (prec==64) {
		double d;
		__int32 *p = (__int32 *)&d;
		Float128ToDouble(&d,this);
		pack[3] = p[1];
		pack[2] = p[0];
	}
	else if (prec==80) {
		pack[3] = (((unsigned __int32)sign << 31) | (unsigned __int32)exp << 16) | (a.man[FLT128_WORDS-1] >> 16);
		pack[2] = ((a.man[FLT128_WORDS-1] & 0xFFFF) << 16) | (a.man[FLT128_WORDS-2] >> 16);
		pack[1] = ((a.man[FLT128_WORDS-2] & 0xFFFF) << 16) | (a.man[FLT128_WORDS-3] >> 16);
	}
	else {
		pack[3] = (((unsigned __int32)sign << 31) | (unsigned __int32)exp << 16) | (a.man[FLT128_WORDS-1] >> 16);
		pack[2] = ((a.man[FLT128_WORDS-1] & 0xFFFF) << 16) | (a.man[FLT128_WORDS-2] >> 16);
		pack[1] = ((a.man[FLT128_WORDS-2] & 0xFFFF) << 16) | (a.man[FLT128_WORDS-3] >> 16);
		pack[0] = ((a.man[FLT128_WORDS-3] & 0xFFFF) << 16) | (a.man[FLT128_WORDS-4] >> 16);
	}
}

char *Float128::ToString()
{
	static char buf[50];

	Pack(FLT_PREC);
	switch(FLT_PREC) {
	case 64:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X", pack[2],pack[3]);
		break;
	case 80:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X,0x%08X", pack[1],pack[2],pack[3]);
		break;
	case 128:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X,0x%08X,0x%08X", pack[0],pack[1],pack[2],pack[3]);
		break;
	}
	return (buf);
}

char *Float128::ToString(int prec)
{
	static char buf[50];

	Pack(prec);
	switch(prec) {
	case 64:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X", pack[2],pack[3]);
		break;
	case 80:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X,0x%08X", pack[1],pack[2],pack[3]);
		break;
	case 128:
		sprintf_s(buf,sizeof(buf),"0x%08X,0x%08X,0x%08X,0x%08X", pack[0],pack[1],pack[2],pack[3]);
		break;
	}
	return (buf);
}

char *Float128::ToHexString()
{
	static char buf[50];

	Pack(128);
	sprintf_s(buf, sizeof(buf), "%08x%08x%08x%08x", pack[3], pack[2], pack[1], pack[0]);
	return (buf);
}

bool Float128::IsManZero() const
{
	int nn;

	for (nn = 0; nn < FLT128_WORDS; nn++) {
		if (man[nn] != 0)
			return (false);
	}
	return (true);
}


// Zero could be either + or -.
bool Float128::IsZero() const
{
	if (exp != 0)
		return (false);
	return (IsManZero());
}

bool Float128::IsEqual(Float128 *a, Float128 *b)
{
	if (a->IsZero() && b->IsZero())
		return (true);
	if (a->sign != b->sign)
		return (false);
	if (a->exp != b->exp)
		return (false);
	if (!ManEQ(a,b))
		return (false);
	return (true);
}

// IsEqual test without zero checking.

bool Float128::IsEqualNZ(Float128 *a, Float128 *b)
{
	if (a->sign != b->sign)
		return (false);
	if (a->exp != b->exp)
		return (false);
	if (!ManEQ(a,b))
		return (false);
	return (true);
}

bool Float128::IsNaN(Float128 *a)
{
	if (a->exp==infxp && !a->IsManZero())
		return (true);
	return (false);
}

bool Float128::IsInfinite() const
{
	return (exp==infxp && IsManZero());
}

bool Float128::IsLessThan(Float128 *a, Float128 *b)
{
	if (a->IsZero() && b->IsZero())
		return (false);
	if (a->sign && !b->sign)
		return (true);
	if (!a->sign & b->sign)
		return (false);
	if (a->exp < b->exp)
		return (true);
	if (a->exp > b->exp)
		return (false);
	return (ManGT(b, a));
}
