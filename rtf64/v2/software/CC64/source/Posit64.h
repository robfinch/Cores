#pragma once

class Posit16;
class Posit32;

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

class Posit
{
public:
	static int DividerLUT[65536];
};

class Posit64 : public Posit
{
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
	static bool IsEqual(Posit64 a, Posit64 b) {
		return (a.val == b.val);
	};
	Posit32 ConvertTo32();
	Posit16 ConvertTo16();
};

class Posit64Multiplier : public Posit64
{
public:
	Posit64 Multiply(Posit64 a, Posit64 b);
	Int256 BuildResult(Int128 prod1, int64_t exp, int64_t rs);
	Posit64 Round(Int256 tmp1, int rgml, uint64_t so, bool zero, bool inf);
};

class Posit32 : public Posit
{
public:
	static int64_t posWidth;
	static int64_t expWidth;
	int val;
public:
	Posit32() { val = 0; };
	Posit32(int i);
	void Zero() { val = 0; };
	void One() { val = 0x40000000LL; };
	void Ten() { val = 0x4d000000LL; };
	void OneTenth() { val = 0x32666666LL; };
	Posit32 Addsub(int8_t op, Posit32 a, Posit32 b);
	Posit32 Add(Posit32 a, Posit32 b);
	Posit32 Sub(Posit32 a, Posit32 b);
	Posit32 Multiply(Posit32 a, Posit32 b);
	Posit32 Divide(Posit32 a, Posit32 b);
	Posit32 IntToPosit(int64_t i);
	int64_t PositToInt(Posit32 p);
	void Decompose(Posit32 a, RawPosit* b);
	char* ToString();
	static bool IsEqual(Posit32 a, Posit32 b) {
		return (a.val == b.val);
	};
	Posit64 ConvertTo64();
};

class Posit32Multiplier : public Posit32
{
public:
	Posit32 Multiply(Posit32 a, Posit32 b);
	Int256 BuildResult(Int128 prod1, int64_t exp, int64_t rs);
	Posit32 Round(Int256 tmp1, int rgml, uint64_t so, bool zero, bool inf);
};

class Posit16 : public Posit
{
public:
	static int64_t posWidth;
	static int64_t expWidth;
	int val;
public:
	Posit16() { val = 0; };
	Posit16(int i);
	void Zero() { val = 0; };
	void One() { val = 0x4000LL; };
	void Ten() { val = 0x4d00LL; };
	void OneTenth() { val = 0x3266LL; };
	Posit16 Addsub(int8_t op, Posit16 a, Posit16 b);
	Posit16 Add(Posit16 a, Posit16 b);
	Posit16 Sub(Posit16 a, Posit16 b);
	Posit16 Multiply(Posit16 a, Posit16 b);
	Posit16 Divide(Posit16 a, Posit16 b);
	Posit16 IntToPosit(int64_t i);
	int64_t PositToInt(Posit16 p);
	void Decompose(Posit16 a, RawPosit* b);
	char* ToString();
	static bool IsEqual(Posit16 a, Posit16 b) {
		return (a.val == b.val);
	};
	Posit64 ConvertTo64();
};

class Posit16Multiplier : public Posit16
{
public:
	Posit16 Multiply(Posit16 a, Posit16 b);
	Int256 BuildResult(Int128 prod1, int64_t exp, int64_t rs);
	Posit16 Round(Int256 tmp1, int rgml, uint64_t so, bool zero, bool inf);
};

