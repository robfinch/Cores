#pragma once

namespace RTFClasses
{
	class AsmW65C816S
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
		static void br(Opa *);
		static void lbr(Opa *);
		static void brl(Opa *);
		static bool isX16() { return ndx==16; };
		static bool isM16() { return mem==16; };
	};
}
