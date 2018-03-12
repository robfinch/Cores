#pragma once

class AsmButterfly
{
public:
	static void prefix(int);
	static void prefixw(int);
	static void prefixu(int);
	static int addi(Opa *);
	static int addi2(Opa *);
	static int cmpi(Opa *);
	static int subi(Opa *);
	static int subi2(Opa *);
	static int rr(Opa *);
	static int ri(Opa *);
	static int riu(Opa *);
	static int shift(Opa *);
	static int br(Opa *);
	static int ldi(Opa *);
	static int ldr(Opa *);
	static int lsRind(Opa *);
	static int lscAbs(Opa *);
	static int lscDrind(Opa *);
	static int lswAbs(Opa *);
	static int lswDrind(Opa *);
	static int jmpAbs(Opa *);
	static int jmpRind(Opa *);
	static int jmpDrind(Opa *);
	static int trap(Opa *);
	static int tsr(Opa *);
	static int trs(Opa *);
};
