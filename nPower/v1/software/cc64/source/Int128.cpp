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
	Assign(o, &k);
	return (true);
}

// Shift right one bit.
bool Int128::Shr(Int128 *o, Int128 *a) {
	bool c = (a->high & 1LL) != 0LL;
	Int128 r;
	r.low = (uint64_t)a->low >> 1LL;
	r.high = a->high >> 1LL;
	if (c)
		r.low |= 0x8000000000000000LL;
	c = (a->low & 1LL) != 0LL;
	o->low = r.low;
	o->high = r.high;
	return (c);
}

bool Int128::Lsr(Int128* o, Int128* a) {
	bool c = (a->high & 1LL) != 0LL;
	Int128 r;
	r.low = (uint64_t)a->low >> 1LL;
	r.high = (uint64_t)a->high >> 1LL;
	if (c)
		r.low |= 0x8000000000000000LL;
	c = (a->low & 1LL) != 0LL;
	o->low = r.low;
	o->high = r.high;
	o->high &= 0x7fffffffffffffffLL;
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

int64_t Int128::Lsr(Int128* o, Int128* a, int b) {
	Int128 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Lsr(&k, &k);
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
		Shl(&p1, &p1);
		if (Shl(&p0, &p0))
			p1.low |= 1;
		if (Shl(&oa, &oa)) {
			if (Add(&p0,&p0,&ob))
				p1.low|=1LL;
		}
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
		if (IsLE(&oa,&rm)) {
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

bool Int128::IsNBit(int bitno)
{
	__int64 bit;

	if (bitno > 64LL) {
		bitno -= 64LL;
		bit = (high >> (bitno - 1LL)) & 1LL;
		for (++bitno; bitno <= 64LL; bitno++) {
			if (((high >> (bitno - 1LL)) & 1LL) != bit)
				return false;
		}
	}
	else {
		if ((low >> 63LL) != 0) {
			if (high != -1LL)
				return false;
		}
		else {
			if (high != 0LL)
				return false;
		}
		bit = (low >> (bitno - 1LL)) & 1LL;
		for (++bitno; bitno <= 64LL; bitno++) {
			if (((low >> (bitno - 1LL)) & 1LL) != bit)
				return false;
		}
	}
	return true;
}

int64_t Int128::StickyCalc(int amt)
{
	int64_t st;
	Int128 b;

	Assign(&b, this);
	if (amt >= 64) {
		st = b.low != 0;
		b.low = b.high;
		b.high = 0;
		amt -= 64;
	}
	else
		st = 0;
	for (; amt > 0; amt--)
		st = st | Shr(&b, &b);
	return (st & 1LL);
}

void Int128::insert(int64_t i, int64_t offset, int64_t width)
{
	Int128 aa, bb;
	Int128 mask;
	int nn;

	Assign(&aa, this);
	Assign(&mask, Zero());
	for (nn = 0; nn < width; nn++) {
		Shl(&mask, &mask, 1LL);
		mask.low |= 1LL;
	}
	Shl(&mask, &mask, offset);
	// clear out bitfield
	aa.low &= ~mask.low;
	aa.high &= ~mask.high;
	bb.low = i;
	Shl(&bb, &bb, offset);
	bb.low &= mask.low;
	bb.high &= mask.high;
	aa.low |= bb.low;
	aa.high |= bb.high;
	low = aa.low;
	high = aa.high;
}

int64_t Int128::extract(int64_t offset, int64_t width)
{
	Int128 k;

	Lsr(&k, this, offset);
	k.low &= ((1LL << width) - 1LL);
	return (k.low);
}

