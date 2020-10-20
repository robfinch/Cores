#include "stdafx.h"

bool Int256::Add(Int256 *sum, Int256 *a, Int256 *b) {
	Int256 s1;
	bool c;
	s1.low = a->low + b->low;
	s1.midLow = a->midLow + b->midLow;
	s1.midHigh = a->midHigh + b->midHigh;
	s1.high = a->high + b->high;
	if (AddCarry(s1.low, a->low, b->low))
		s1.midLow++;
	if (AddCarry(s1.midLow, a->midLow, b->midLow))
		s1.midHigh++;
	if (AddCarry(s1.midHigh, a->midHigh, b->midHigh))
		s1.high++;
	c = AddCarry(sum->high,a->high,b->high);
	Assign(sum,&s1);
	return (c);
}

// Subtract two 256 bit numbers.
bool Int256::Sub(Int256 *sum, Int256 *a, Int256 *b) {
	Int256 s1;
	bool c;
	s1.low = a->low - b->low;
	s1.midLow = a->midLow - b->midLow;
	s1.midHigh = a->midHigh - b->midHigh;
	s1.high = a->high - b->high;
	if (SubBorrow(s1.low, a->low, b->low))
		s1.midLow--;
	if (SubBorrow(s1.midLow, a->midLow, b->midLow))
		s1.midHigh--;
	if (SubBorrow(s1.midHigh, a->midHigh, b->midHigh))
		s1.high--;
	c = SubBorrow(s1.high,a->high,b->high);
	Assign(sum,&s1);
	return (c);
}

// Shift left one bit.
bool Int256::Shl(Int256 *o, Int256 *a) {
	bool c;
	bool clo = (a->low & 0x8000000000000000LL) != 0LL;
	bool cmidlo = (a->midLow & 0x8000000000000000LL) != 0LL;
	bool cmidhi = (a->midHigh & 0x8000000000000000LL) != 0LL;
	Int256 r;
	r.low = a->low << 1LL;
	r.midLow = a->midLow << 1LL;
	r.midHigh = a->midHigh << 1LL;
	r.high = a->high << 1LL;
	if (clo) r.midLow |= 1LL;
	if (cmidlo) r.midHigh |= 1LL;
	if (cmidhi) r.high |= 1LL;
	c = (a->high & 0x8000000000000000LL) != 0LL;
	o->low = r.low;
	o->midLow = r.midLow;
	o->midHigh = r.midHigh;
	o->high = r.high;
	return (c);
}

bool Int256::Shl(Int256 *o, Int256 *a, int b) {
	Int256 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Shl(&k, &k);
	}
	Assign(o, &k);
	return (true);
}

// Shift right one bit.
bool Int256::Shr(Int256 *o, Int256 *a) {
	bool c;
	bool chi = (a->high & 1LL) != 0LL;
	bool cmidhi = (a->midHigh & 1LL) != 0LL;
	bool cmidlo = (a->midLow & 1LL) != 0LL;
	Int256 r;
	r.low = a->low >> 1LL;
	r.midLow = a->midLow >> 1LL;
	r.midHigh = a->midHigh >> 1LL;
	r.high = a->high >> 1LL;
	if (cmidlo) r.low |= 0x8000000000000000LL;
	if (cmidhi) r.midLow |= 0x8000000000000000LL;
	if (chi) r.midHigh |= 0x8000000000000000LL;
	c = (a->low & 1LL) != 0LL;
	o->low = r.low;
	o->midLow = r.midLow;
	o->midHigh = r.midHigh;
	o->high = r.high;
	return (c);
}

bool Int256::Lsr(Int256* o, Int256* a) {
	bool c;
	bool chi = (a->high & 1LL) != 0LL;
	bool cmidhi = (a->midHigh & 1LL) != 0LL;
	bool cmidlo = (a->midLow & 1LL) != 0LL;
	Int256 r;
	r.low = a->low >> 1LL;
	r.midLow = a->midLow >> 1LL;
	r.midHigh = a->midHigh >> 1LL;
	r.high = a->high >> 1LL;
	if (cmidlo) r.low |= 0x8000000000000000LL;
	if (cmidhi) r.midLow |= 0x8000000000000000LL;
	if (chi) r.midHigh |= 0x8000000000000000LL;
	c = (a->low & 1LL) != 0LL;
	o->low = r.low;
	o->midLow = r.midLow;
	o->midHigh = r.midHigh;
	o->high = r.high;
	o->high &= 0x7fffffffffffffffLL;
	return (c);
}

int64_t Int256::Shr(Int256 *o, Int256 *a, int b) {
	Int256 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Shr(&k, &k);
	}
	if (o)
		Assign(o, &k);
	return (k.low);
}

int64_t Int256::Lsr(Int256* o, Int256* a, int b) {
	Int256 k;

	Assign(&k, a);
	for (; b > 0; b--) {
		Lsr(&k, &k);
	}
	if (o)
		Assign(o, &k);
	return (k.low);
}

void Int256::Mul(Int256 *p, Int256 *a, Int256 *b)
{
	Int256 p0,p1;
	Int256 oa,ob;
	int nn;
	bool sign;

	p0 = *Zero();
	p1 = *Zero();
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
	for (nn = 0; nn < 256; nn++) {
		Shl(&p1, &p1);
		if (Shl(&p0, &p0))
			p1.low |= 1LL;
		if (Shl(&oa, &oa)) {
			if (Add(&p0, &p0, &ob))
				p1.low|=1LL;
		}
	}
	Assign (p,&p0);
	if (sign) {
		Sub(p,Zero(),p);
	}
}

void Int256::Div(Int256 *q, Int256 *r, Int256 *a, Int256 *b)
{
	Int256 qu,rm,oa,ob;
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
	qu.midLow = ob.midLow;
	qu.midHigh = ob.midHigh;
	qu.low = ob.low;
	rm.high = 0LL;
	rm.midLow = 0LL;
	rm.midHigh = 0LL;
	rm.low = 0LL;
	for (nn = 0; nn < 256; nn++) {
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

bool Int256::IsEqual(Int256 *a, Int256 *b)
{
	if (a->low != b->low)
		return (false);
	if (a->midLow != b->midLow)
		return (false);
	if (a->midHigh != b->midHigh)
		return (false);
	if (a->high != b->high)
		return (false);
	return (true);
}

bool Int256::IsLessThan(Int256 *a, Int256 *b)
{
	Int256 d;

	Sub(&d, a, b);
	return ((d.high >> 63)!=0);
}

bool Int256::IsNBit(int bitno)
{
	__int64 bit;

	if (bitno > 192LL) {
		bitno -= 192;
		bit = (high >> (bitno - 1LL)) & 1LL;
		for (++bitno; bitno <= 64LL; bitno++) {
			if (((high >> (bitno - 1LL)) & 1LL) != bit)
				return (false);
		}
	}
	else if (bitno > 128LL) {
		if ((midHigh >> 63LL) != 0) {
			if (high != -1LL)
				return false;
		}
		else {
			if (high != 0LL)
				return false;
		}
		bitno -= 128;
		bit = (midHigh >> (bitno - 1LL)) & 1LL;
		for (++bitno; bitno <= 64LL; bitno++) {
			if (((midHigh >> (bitno - 1LL)) & 1LL) != bit)
				return (false);
		}
	}
	else if (bitno > 64LL) {
		if ((midLow >> 63LL) != 0) {
			if (high != -1LL && midHigh != -1LL)
				return false;
		}
		else {
			if (high != 0LL || midHigh != 0LL)
				return false;
		}
		bitno -= 64LL;
		bit = (midLow >> (bitno - 1LL)) & 1LL;
		for (++bitno; bitno <= 64LL; bitno++) {
			if (((midLow >> (bitno - 1LL)) & 1LL) != bit)
				return false;
		}
	}
	else {
		if ((low >> 63LL) != 0) {
			if (high != -1LL && midHigh != -1LL && midLow != -1LL)
				return false;
		}
		else {
			if (high != 0LL || midLow != 0LL || midHigh != 0LL)
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

int64_t Int256::StickyCalc(Int256* a, int amt)
{
	int64_t st;
	Int256 b;

	Assign(&b, a);
	st = 0;
	if (amt >= 192) {
		st = (b.low | b.midLow | b.midHigh) != 0;
		b.low = b.high;
		b.midLow = 0LL;
		b.midHigh = 0LL;
		b.high = 0LL;
		amt -= 192;
	}
	else if (amt >= 128) {
		st = (b.low | b.midLow) != 0;
		b.low = b.midHigh;
		b.midLow = b.high;
		b.midHigh = 0LL;
		b.high = 0LL;
		amt -= 128;
	}
	else if (amt >= 64) {
		st = b.low != 0;
		b.low = b.midLow;
		b.midLow = b.midHigh;
		b.midHigh = b.high;
		b.high = 0LL;
		amt -= 64;
	}
	for (; amt > 0; amt--)
		st = st | Shr(&b, &b);
	return (st & 1LL);
}

void Int256::insert(int64_t i, int64_t offset, int64_t width)
{
	Int256 aa, bb;
	Int256 mask;
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
	aa.midLow &= ~mask.midLow;
	aa.midHigh &= ~mask.midHigh;
	aa.high &= ~mask.high;
	bb.low = i;
	Shl(&bb, &bb, offset);
	bb.low &= mask.low;
	bb.midLow &= mask.midLow;
	bb.midHigh &= mask.midHigh;
	bb.high &= mask.high;
	aa.low |= bb.low;
	aa.midLow |= bb.midLow;
	aa.midHigh |= bb.midHigh;
	aa.high |= bb.high;
	low = aa.low;
	midLow = aa.midLow;
	midHigh = aa.midHigh;
	high = aa.high;
}

void Int256::insert(Int256 i, int64_t offset, int64_t width)
{
	Int256 aa, bb;
	Int256 mask;
	int nn;

	Assign(&aa, &i);
	Assign(&mask, One());
	for (nn = 0; nn < width; nn++) {
		Shl(&mask, &mask, 1LL);
		mask.low |= 1LL;
	}
	aa.BitAnd(&aa, &aa, &mask);
	aa.Shl(&aa, &aa, offset);
	Shl(&mask, &mask, offset);
	// clear out bitfield
	Assign(&bb, this);
	bb.low &= ~mask.low;
	bb.midLow &= ~mask.midLow;
	bb.midHigh &= ~mask.midHigh;
	bb.high &= ~mask.high;
	aa.low |= bb.low;
	aa.midLow |= bb.midLow;
	aa.midHigh |= bb.midHigh;
	aa.high |= bb.high;
	low = aa.low;
	midLow = aa.midLow;
	midHigh = aa.midHigh;
	high = aa.high;
}

int64_t Int256::extract(int64_t offset, int64_t width)
{
	Int256 k;

	Lsr(&k, this, offset);
	k.low &= ((1LL << width) - 1LL);
	return k.low;
}

