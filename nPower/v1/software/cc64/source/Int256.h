#pragma once

class Int256
{
public:
	uint64_t low;
	uint64_t midLow;
	uint64_t midHigh;
	int64_t high;
public:
	Int256() {};
	Int256(int64_t val) {
		low = val;
		if (val < 0) {
			high = 0xffffffffffffffffLL;
			midLow = 0xffffffffffffffffLL;
			midHigh = 0xffffffffffffffffLL;
		}
		else {
			high = 0LL;
			midLow = 0LL;
			midHigh = 0LL;
		}
	};
	static Int256 *MakeInt256(int64_t val) {
		static Int256 p;

		p.low = val;
		if (val < 0) {
			p.high = 0xffffffffffffffffLL;
			p.midLow = 0xffffffffffffffffLL;
			p.midHigh = 0xffffffffffffffffLL;
		}
		else {
			p.high = 0LL;
			p.midLow = 0LL;
			p.midHigh = 0LL;
		}
		return (&p);
	};
	static Int256 *Zero() {
		static Int256 zr;
		zr.low = 0LL;
		zr.midLow = 0LL;
		zr.midHigh = 0LL;
		zr.high = 0LL;
		return (&zr);
	};
	static Int256 *One() {
		static Int256 zr;
		zr.low = 1LL;
		zr.midLow = 0LL;
		zr.midHigh = 0LL;
		zr.high = 0LL;
		return (&zr);
	};
	static void Assign(Int256 *a, Int256 *b) {
		a->low = b->low;
		a->midLow = b->midLow;
		a->midHigh = b->midHigh;
		a->high = b->high;
	};
	static Int256 MakeMask(int64_t width) {
		Int256 a;
		Int256 one;

		a = *Int256::One();
		one = *Int256::One();
		a.Shl(&a, &a, width);
		a.Sub(&a, &a, &one);
		return (a);
	};
	static Int256 MakeMask(int64_t offset, int64_t width) {
		Int256 a;

		a = MakeMask(width);
		a.Shl(&a, &a, offset);
		return (a);
	};
	//fnASCarry = op? (~a&b)|(s&~a)|(s&b) : (a&b)|(a&~s)|(b&~s);
	// Compute carry bit from 64 bit addition.
	static bool AddCarry(__int64 s, __int64 a, __int64 b) {
		return (((a&b)|(a&~s)|(b&~s)) >> 63LL);
	};
	// Compute carry bit from 64 bit subtraction.
	static bool SubBorrow(__int64 s, __int64 a, __int64 b) {
		return (((~a&b)|(s&~a)|(s&b)) >> 63LL);
	};
	// Add two 256 bit numbers.
	static bool Add(Int256 *sum, Int256 *a, Int256 *b);
	// Subtract two 256 bit numbers.
	static bool Sub(Int256 *sum, Int256 *a, Int256 *b);
	static void BitAnd(Int256* dst, Int256* a, Int256* b) {
		dst->low = a->low & b->low;
		dst->midLow = a->midLow & b->midLow;
		dst->midHigh = a->midHigh & b->midHigh;
		dst->high = a->high & b->high;
	};
	// Shift left one bit.
	static bool Shl(Int256 *o, Int256 *a);
	static bool Shr(Int256 *o, Int256 *a);
	static bool Lsr(Int256* o, Int256* a);
	static bool Shl(Int256 *o, Int256 *a, int);
	static int64_t Shr(Int256 *o, Int256 *a, int);
	static int64_t Lsr(Int256* o, Int256* a, int);
	static int64_t StickyCalc(Int256* a, int);
	static void Mul(Int256 *p, Int256 *a, Int256 *b);
	static void Div(Int256 *q, Int256 *r, Int256 *a, Int256 *b);
	static bool IsEqual(Int256 *a, Int256 *b);
	static bool IsLessThan(Int256 *a, Int256 *b);
	static bool IsLE(Int256 *a, Int256 *b) { return (IsEqual(a, b) ||  IsLessThan(a, b)); };
	static bool IsGE(Int256 *a, Int256 *b) { return (IsEqual(a, b) || !IsLessThan(a, b)); };
	Int256 operator =(Int256&s) {
		this->high = s.high;
		this->midLow = s.midLow;
		this->midHigh = s.midHigh;
		this->low = s.low;
		return s;
	}
	static Int256 Convert(int64_t v) {
		Int256 p;

		p.low = v;
		if (v < 0) {
			p.high = 0xffffffffffffffffLL;
			p.midLow = 0xffffffffffffffffLL;
			p.midHigh = 0xffffffffffffffffLL;
		}
		else {
			p.high = 0LL;
			p.midLow = 0LL;
			p.midHigh = 0LL;
		}
		return (p);
	}
	static Int256 Convert(uint64_t v) {
		Int256 p;

		p.low = v;
		p.midLow = 0LL;
		p.midHigh = 0LL;
		p.high = 0LL;
		return (p);
	}
	bool IsNBit(int bitno);
	void insert(int64_t i, int64_t offset, int64_t width);
	void insert(Int256 i, int64_t offset, int64_t width);
	int64_t extract(int64_t offset, int64_t width);
};
