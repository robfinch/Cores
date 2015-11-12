#pragma once

namespace RTFClasses
{
	class AsmFT832
	{
		static int ndx;
		static int mem;
	public:
		static void amem(Opa *);
		static void andx(Opa *);
		static void zp(Opa *);
		static void mv(Opa *);
		static void sr(Opa *);
		static void pea(Opa *);
		static void per(Opa *);
		static void imm(Opa *);
		static void immm(Opa *);
		static void immx(Opa *);
		static void abs(Opa *);
		static void labs(Opa *);
		static void xlabs(Opa *);
		static void jsegoffs(Opa *);
		static void br(Opa *);
		static void lbr(Opa *);
		static void brl(Opa *);
		static bool isX16() { return ndx==16; };
		static bool isM16() { return mem==16; };
		static bool isX32() { return ndx==32; };
		static bool isM32() { return mem==32; };
		static void doSegPrefix(void);
		static void doSizePrefix(void);
	};
}
