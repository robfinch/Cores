#pragma once

class RawPosit
{
public:
	RawPosit(int8_t exWidth, int8_t psWidth) {
		sigWidth = psWidth - exWidth - 2 + 1;
		expWidth = exWidth;
	};
	void Size(int8_t exWidth, int8_t psWidth) {
		sigWidth = psWidth - exWidth - 2 + 1;
		expWidth = exWidth;
	}
	bool isNaR;
	bool isInf;
	bool isZero;
	bool sign;
	bool regsign;
	int64_t regime;
	int8_t exp;
	int64_t regexp;
	int8_t expWidth;
	int8_t sigWidth;
	Int128 sig;
};

class Posit64
{
	static int8_t posWidth;
	static int8_t expWidth;
	int64_t val;
public:
	Posit64() { val = 0; };
	Posit64(int64_t i);
	Posit64 Addsub(int8_t op, Posit64 a, Posit64 b);
	Posit64 Add(Posit64 a, Posit64 b);
	Posit64 Sub(Posit64 a, Posit64 b);
	Posit64 Multiply(Posit64 a, Posit64 b);
	Posit64 Divide(Posit64 a, Posit64 b);
	Posit64 IntToPosit(int64_t i);
	int64_t PositToInt(Posit64 p);
	void Decompose(Posit64 a, RawPosit* b);
};

