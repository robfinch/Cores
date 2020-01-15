#pragma once
// ============================================================================
//        __
//   \\__/ o\    (C) 2016-2019  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// 128 bit floating point class
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// Floats here are actually represented with a 128 bit mantissa for simpliity
// rather than 112 bits.
// ============================================================================
//
#define FLT128_WORDS	4
#define FLT_PREC		128

class Float128
{
public:
	static const __int16 bias = 0x3FFF;
	static const __int16 infxp = 0x7FFF;
public:
	unsigned __int32 pack[4];
	unsigned __int32 man[FLT128_WORDS];
	unsigned __int16 exp;
	unsigned __int8 sign;
	unsigned __int16 prec;
	// The following is for compiler use
	//-----------------------------------
	Float128 *next;	// next in a list
	int label;
	char *nmspace;
	//-----------------------------------
	void ShiftManLeft();
private:
	void ShiftManRight();
	static bool ManEQ(Float128 *a, Float128 *b);
	static bool ManGT(Float128 *a, Float128 *b);
	static bool ManGE(Float128 *a, Float128 *b) {
		if (ManGT(a,b))
			return (true);
		if (ManEQ(a,b))
			return (true);
		return (false);
	};
	static bool AddMan(Float128 *s, Float128 *a, Float128 *b);
	static bool SubMan(Float128 *d, Float128 *a, Float128 *b);
	void Denormalize(unsigned __int16 xp);
	void Denorm1();
public:
	Float128() {
		Zeroman();
		exp = 0;
		sign = false;
	};
	Float128(Float128 *a);
	void Zeroman() {
		int nn;
		for (nn = 0; nn < FLT128_WORDS; nn++)
			man[nn] = 0;
	};
	static Float128 *Zero() {
		static Float128 p;
		static bool first = true;

		if (first) {
			p.Zeroman();
			p.exp = 0x0000;
		}
		return (&p);
	};
	static Float128 *One() {
		static Float128 p;
		p.Zeroman();
		p.man[FLT128_WORDS-1] = 0x40000000;
		p.exp = 0x3FFF;
		return (&p);
	};
	static Float128 *Ten() {
		static Float128 p;
		p.Zeroman();
		p.man[FLT128_WORDS-1] = 0x50000000;
		p.exp = 0x4002;
		return (&p);
	};
	static Float128 *OneTenth() {
		int nn;
		static Float128 p;
		for (nn = 0; nn < FLT128_WORDS; nn++)
			p.man[nn] = 0x66666666;
		p.exp = 0x3FFB;
		return (&p);
	};
	static Float128 *FloatMax() {
		int nn;
		static Float128 p;
		static bool first = true;

		if (first) {
			for (nn = 0; nn < FLT128_WORDS; nn++)
				p.man[nn] = 0xFFFFFFFF;
			for (nn = 0; nn < FLT128_WORDS / 2; nn++)
				p.man[nn] = 0;
			for (; nn < FLT128_WORDS - 1; nn++)
				p.man[nn] = 0xFFFFFFFF;
			p.man[FLT128_WORDS / 2 - 1] = 0x80000000;
			p.man[FLT128_WORDS - 1] = 0x7FFFFFFF;
			p.exp = 0x7FFE;
		}
		return (&p);
	};
	static Float128 *Neg(Float128 *p) {
		Float128 *q = new Float128;
		q->sign = !p->sign;
		return q;
	};
	static void Add(Float128 *s, Float128 *a, Float128 *b);
	static void Sub(Float128 *d, Float128 *a, Float128 *b) {
		Float128 *b1 = Neg(b);
		Add(d, a, b1);
		delete b1;
	};
	static void Mul(Float128 *p, Float128 *a, Float128 *b);
	static void Div(Float128 *q, Float128 *a, Float128 *b);
	static void Assign(Float128 *d, Float128 *s) {
		int nn;
		for (nn = 0; nn < FLT128_WORDS; nn++)
			d->man[nn] = s->man[nn];
		d->exp = s->exp;
		d->sign = s->sign;
	};
	static void Normalize(Float128 *a);
	static void IntToFloat(Float128 *d, __int64 v);
	static void FloatToInt(__int64 *i, Float128 *a);
	static void Float128ToDouble(double *d, Float128 *a);
	void Pack(int);
	char *ToString();
	char *ToString(int);
	char *ToHexString();
	bool IsManZero() const;
	bool IsZero() const;
	bool IsInfinite() const;
	static bool IsEqual(Float128 *a, Float128 *b);
	static bool IsEqualNZ(Float128 *a, Float128 *b);
	static bool IsNaN(Float128 *a);
	static bool IsLessThan(Float128 *, Float128 *);
	bool IsNaN() { return (IsNaN(this)); };
};
