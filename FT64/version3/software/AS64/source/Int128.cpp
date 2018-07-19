#include "stdafx.h"

bool Int128::Add(Int128 *sum, Int128 *a, Int128 *b) {
	Int128 s1;
	bool c;
	s1.frac = a->frac + b->frac;
	s1.low = a->low + b->low + (AddCarry4(s1.frac, a->frac, b->frac) ? 1LL : 0LL);
	s1.frac &= 0x0f;
	s1.high = a->high + b->high;
	if (AddCarry(s1.low, a->low, b->low)) { 
		s1.high++;
	}
	c = AddCarry(sum->high,a->high,b->high);
	Assign(sum,&s1);
	return (c);
}

// Subtract two 128 bit numbers.
bool Int128::Sub(Int128 *sum, Int128 *a, Int128 *b) {
	Int128 s1;
	bool c;
	s1.frac = a->frac - b->frac;
	s1.low = a->low - b->low - SubBorrow4(s1.frac, a->frac, b->frac);
	s1.frac &= 0x0f;
	s1.high = a->high - b->high;
	if (SubBorrow(s1.low, a->low, b->low)) { 
		s1.high--;
	}
	c = SubBorrow(s1.high,a->high,b->high);
	Assign(sum,&s1);
	return (c);
}

// Shift left one bit.
bool Int128::Shl(Int128 *o, Int128 *a) {
	bool c8 = (a->frac & 0x08) != 0;
	bool c = (a->low & 0x8000000000000000LL) != 0LL;
	Int128 r;
	r.frac = a->frac << 1;
	r.frac &= 0x0f;
	r.low = a->low << 1;
	r.high = a->high << 1;
	if (c8)
		r.low |= 1;
	if (c)
		r.high |= 1;
	c = (a->high & 0x8000000000000000LL) != 0LL;
	o->frac = r.frac;
	o->low = r.low;
	o->high = r.high;
	return (c);
}

// Shift right one bit.
bool Int128::Shr(Int128 *o, Int128 *a) {
	bool c8 = (a->low & 1LL) != 0LL;
	bool c = (a->high & 1LL) != 0LL;
	Int128 r;
	r.frac = (a->frac >> 1) & 0x07;
	r.low = (a->low >> 1) & 0x7FFFFFFFFFFFFFFFLL;
	r.high = (a->high >> 1) & 0x7FFFFFFFFFFFFFFFLL;
	if (c8)
		r.frac |= 0x8;
	if (c)
		r.low |= 0x8000000000000000LL;
	c = (a->frac & 1) != 0;
	o->frac = r.frac;
	o->low = r.low;
	o->high = r.high;
	return (c);
}

void Int128::Mul(Int128 *p, Int128 *a, Int128 *b)
{
	Int128 p0,p1;
	Int128 oa,ob;
	int nn;
	bool sign;

	p0.low = 0;
	p0.high = 0;
	p0.frac = 0;
	p1.low = 0;
	p1.high = 0;
	p1.frac = 0;
	Assign(&oa,a);
	Assign(&ob,b);
	// Compute output sign
	sign = ((oa.high ^ ob.high) >> 63);
	// Make a positive
	if (oa.high < 0LL)
		Sub(&oa,Zero(),&oa);
	// Make b positive
	if (ob.high < 0LL)
		Sub(&ob,Zero(),&ob);
	for (nn = 0; nn < 132; nn++) {
		if (Shl(&p0,&p0)) {
			Shl(&p1,&p1);
			p1.frac |= 1;
		}
		else
			Shl(&p1,&p1);
		if (oa.high & 0x8000000000000000LL) {
			if (Add(&p0,&p0,&ob))
				p1.frac|=1;
		}
		Shl(&oa,&oa);
	}
	// Multiplying created a product with 8 decimal places
	// instead of 4. Need to shift right by 4 to get back to 4
	// decimals.
	for (nn = 0; nn < 4; nn++)
		Shr(&p0,&p0);
	Assign (p,&p0);
	if (sign) {
		Sub(p,Zero(),p);
	}
}

void Int128::Div(Int128 *q, Int128 *r, Int128 *a, Int128 *b)
{
	Int128 qu,rm,oa,ob;
	int nn;
	bool sign = ((a->high ^ b->high) >> 63) != 0LL;

	// Make operands positive
	if ((b->high >> 63) & 1)
		Sub(&ob,Zero(),b);
	else
		Assign(&ob,b);
	if ((a->high >> 63) & 1)
		Sub(&oa,Zero(),a);
	else
		Assign(&oa,a);

	qu.high = oa.high;
	qu.low = oa.low;
	qu.frac = oa.frac;
	rm.frac = 0;
	rm.high = 0;
	rm.low = 0;
	for (nn = 0; nn < 132; nn++) {
		Shl(&rm,&rm);
		if (Shl(&qu,&qu))
			rm.frac |= 1;
		if (IsLessThan(&ob,&rm)) {
			Sub(&rm,&rm,&ob);
			qu.frac |= 1;
		}
	}
//	for (nn = 0; nn < 4; nn++)
//		Shr(&qu,&qu);
	if (sign)
		Sub(r,Zero(),&rm);
	else
		Assign(r,&rm);
	if (sign)
		Sub(q,Zero(),&qu);
	else
		Assign(q,&qu);
}

bool Int128::IsEqual(Int128 *a, Int128 *b)
{
	if (a->frac != b->frac)
		return (false);
	if (a->low != b->low)
		return (false);
	if (a->high != b->high)
		return (false);
	return (true);
}

bool Int128::IsLessThan(Int128 *a, Int128 *b)
{
	Int128 d;

	Sub(&d, a, b);
	if ((d.high >> 63) & 1)
		return (true);
	return (false);
}
