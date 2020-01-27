#pragma once

class Int128
{
public:
	__int64 low;
	__int64 high;
public:
	Int128() {};
	Int128(int64_t val) {
		low = val;
		if (val < 0)
			high = 0xffffffffffffffffLL;
		else
			high = 0;
	};
	static Int128 *MakeInt128(int64_t val) {
		static Int128 p;

		p.low = val;
		if (val < 0)
			p.high = 0xffffffffffffffffLL;
		else
			p.high = 0;
		return (&p);
	};
	static Int128 *Zero() {
		static Int128 zr;
		zr.low = 0LL;
		zr.high = 0LL;
		return (&zr);
	};
	static Int128 *One() {
		static Int128 zr;
		zr.low = 1LL;
		zr.high = 0LL;
		return (&zr);
	};
	static void Assign(Int128 *a, Int128 *b) {
		a->low = b->low;
		a->high = b->high;
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
	// Add two 128 bit numbers.
	static bool Add(Int128 *sum, Int128 *a, Int128 *b);
	// Subtract two 128 bit numbers.
	static bool Sub(Int128 *sum, Int128 *a, Int128 *b);
	// Shift left one bit.
	static bool Shl(Int128 *o, Int128 *a);
	static bool Shr(Int128 *o, Int128 *a);
	static bool Shl(Int128 *o, Int128 *a, int);
	static int64_t Shr(Int128 *o, Int128 *a, int);
	static void Mul(Int128 *p, Int128 *a, Int128 *b);
	static void Div(Int128 *q, Int128 *r, Int128 *a, Int128 *b);
	static bool IsEqual(Int128 *a, Int128 *b);
	static bool IsLessThan(Int128 *a, Int128 *b);
	static bool IsLE(Int128 *a, Int128 *b) { return (IsEqual(a, b) ||  IsLessThan(a, b)); };
	static bool IsGE(Int128 *a, Int128 *b) { return (IsEqual(a, b) || !IsLessThan(a, b)); };
	Int128 operator =(Int128&s) {
		this->high = s.high;
		this->low = s.low;
		return s;
	}
	static Int128 Convert(__int64 v) {
		Int128 p;

		p.low = v;
		if (v < 0)
			p.high = 0xffffffffffffffffLL;
		else
			p.high = 0;
		return (p);
	}
	static Int128 Convert(long v) {
		Int128 p;

		p.low = v;
		if (v < 0)
			p.high = 0xffffffffffffffffLL;
		else
			p.high = 0;
		return (p);
	}
	bool IsNBit(int bitno);
};
