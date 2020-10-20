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
	static int Posit64::DividerLUT[65536];
public:
	static int64_t posWidth;
	static int64_t expWidth;
	int64_t val;
public:
	Posit64() { val = 0; };
	Posit64(int64_t i);
	void Zero() { val = 0; };
	void One() { val = 0x4000000000000000LL; };
	void Ten() { val = 0x4d00000000000000LL; };
	void OneTenth() {	val = 0x3266666666666666LL; };
	Posit64 Addsub(int8_t op, Posit64 a, Posit64 b);
	Posit64 Add(Posit64 a, Posit64 b);
	Posit64 Sub(Posit64 a, Posit64 b);
	Posit64 Multiply(Posit64 a, Posit64 b);
	Posit64 Divide(Posit64 a, Posit64 b);
	Posit64 IntToPosit(int64_t i);
	int64_t PositToInt(Posit64 p);
	void Decompose(Posit64 a, RawPosit* b);
	char *ToString();
};

class Posit64Multiplier : public Posit64
{
public:
	Posit64 Multiply(Posit64 a, Posit64 b);
	Int256 BuildResult(Int128 prod1, int64_t exp, int64_t rs);
	Posit64 Round(Int256 tmp1, int rgml, uint64_t so, bool zero, bool inf);
};
