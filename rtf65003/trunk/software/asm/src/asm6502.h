#pragma once

#include "Assembler.h"

namespace RTFClasses
{
	class Asm6502
	{
		static void emit16(int n) { theAssembler.emit16(n); };
		static void emit8(int n) { theAssembler.emit8(n); };
	public:
		static void out8(Opa *o) { theAssembler.out8(o); };
		static void out16(Opa *o) { theAssembler.out16(o); };

		static void zp(Opa *);
		static void imm(Opa *);
		static void abs(Opa *);
		static void jml_abs(Opa *);
		static void br(Opa *);
	};
}
