#include "stdafx.h"

bool Int128::Add(Int128 *sum, Int128 *a, Int128 *b) {
	Int128 s1;
	bool c;
	s1.low = a->low + b->low;
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
	s1.low = a->low - b->low;
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
	bool c = (a->low & 0x8000000000000000LL) != 0LL;
	Int128 r;
	r.low = a->low << 1LL;
	r.high = a->high << 1LL;
	if (c)
		r.high |= 1LL;
	c = (a->high & 0x8000000000000000LL) != 0LL;
	o->low = r.low;
	o->high = r.high;
	return (c);
}

bool Int128::Shl(Int128 *o, Int128 *a, int b) {
	Int128 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Shl(&k, &k);
	}
	Assign(0, &k);
	return (true);
}

// Shift right one bit.
bool Int128::Shr(Int128 *o, Int128 *a) {
	bool c = (a->high & 1LL) != 0LL;
	Int128 r;
	r.low = a->low >> 1LL;
	r.high = a->high >> 1LL;
	if (c)
		r.low |= 0x8000000000000000LL;
	c = (a->low & 1LL) != 0LL;
	o->low = r.low;
	o->high = r.high;
	return (c);
}

int64_t Int128::Shr(Int128 *o, Int128 *a, int b) {
	Int128 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Shr(&k, &k);
	}
	if (o)
		Assign(o, &k);
	return (k.low);
}

void Int128::Mul(Int128 *p, Int128 *a, Int128 *b)
{
	Int128 p0,p1;
	Int128 oa,ob;
	int nn;
	bool sign;

	p0.low = 0LL;
	p0.high = 0LL;
	p1.low = 0LL;
	p1.high = 0LL;
	Assign(&oa,a);
	Assign(&ob,b);
	// Compute output sign
	sign = ((oa.high ^ ob.high) >> 63LL);
	// Make a positive
	if (oa.high < 0)
		Sub(&oa,Zero(),&oa);
	// Make b positive
	if (ob.high < 0)
		Sub(&ob,Zero(),&ob);
	for (nn = 0; nn < 128; nn++) {
		if (Shl(&p0,&p0)) {
			Shl(&p1,&p1);
			p1.low |= 1LL;
		}
		else
			Shl(&p1,&p1);
		if (oa.high & 0x8000000000000000LL) {
			if (Add(&p0,&p0,&ob))
				p1.low|=1LL;
		}
		Shl(&oa,&oa);
	}
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
	if ((b->high >> 63LL) & 1LL)
		Sub(&ob,Zero(),b);
	else
		Assign(&ob,b);
	if ((a->high >> 63LL) & 1LL)
		Sub(&oa,Zero(),a);
	else
		Assign(&oa,a);

	qu.high = ob.high;
	qu.low = ob.low;
	rm.high = 0LL;
	rm.low = 0LL;
	for (nn = 0; nn < 128; nn++) {
		Shl(&rm,&rm);
		if (Shl(&qu,&qu))
			rm.low |= 1LL;
		if (IsLessThan(&oa,&rm)) {
			Sub(&rm,&rm,&oa);
			qu.low |= 1LL;
		}
	}
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
	return ((d.high >> 63)!=0);
}
