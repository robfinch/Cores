#pragma once

class Int128
{
public:
	__int8 frac;
	__int64 low;
	__int64 high;
public:
	static Int128 *Zero() {
		static Int128 zr;
		zr.frac = 0;
		zr.low = 0;
		zr.high = 0;
		return (&zr);
	};
	static Int128 *One() {
		static Int128 zr;
		zr.frac = 0;
		zr.low = 1;
		zr.high = 0;
		return (&zr);
	};
	static Int128 *Eight() {
		static Int128 zr;
		zr.frac = 0;
		zr.low = 8;
		zr.high = 0;
		return (&zr);
	};
	static Int128 *Eighteen() {
		static Int128 zr;
		zr.frac = 0;
		zr.low = 18;
		zr.high = 0;
		return (&zr);
	};
	static void Assign(Int128 *a, Int128 *b) {
		a->frac = b->frac;
		a->low = b->low;
		a->high = b->high;
	};
	//fnASCarry = op? (~a&b)|(s&~a)|(s&b) : (a&b)|(a&~s)|(b&~s);
	// Compute carry bit from 8 bit addition.
	static bool AddCarry4(__int8 s, __int8 a, __int8 b) {
		return (((a&b)|(a&~s)|(b&~s)) >> 3) & 1;
	};
	// Compute carry bit from 64 bit addition.
	static bool AddCarry(__int64 s, __int64 a, __int64 b) {
		return (((a&b)|(a&~s)|(b&~s)) >> 63);
	};
	static bool SubBorrow4(__int8 s, __int8 a, __int8 b) {
		return (((~a&b)|(s&~a)|(s&b)) >> 3) & 1;
	};
	// Compute carry bit from 64 bit subtraction.
	static bool SubBorrow(__int64 s, __int64 a, __int64 b) {
		return (((~a&b)|(s&~a)|(s&b)) >> 63);
	};
	// Add two 128 bit numbers.
	static bool Add(Int128 *sum, Int128 *a, Int128 *b);
	// Subtract two 128 bit numbers.
	static bool Sub(Int128 *sum, Int128 *a, Int128 *b);
	// Shift left one bit.
	static bool Shl(Int128 *o, Int128 *a);
	static bool Shr(Int128 *o, Int128 *a);
	static void Mul(Int128 *p, Int128 *a, Int128 *b);
	static void Div(Int128 *q, Int128 *r, Int128 *a, Int128 *b);
	static bool IsEqual(Int128 *a, Int128 *b);
	static bool IsLessThan(Int128 *a, Int128 *b);
};

class Int128b : public Int128
{
public:
};
