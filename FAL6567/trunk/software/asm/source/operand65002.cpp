#include <stdio.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "Assembler.h"
#include "operand65002.h"

namespace RTFClasses
{
	/* ---------------------------------------------------------------
		Operand type recognizer.

			The value of the program counter to be used in
		calculating	displacements must be passed into the optype
		processing routines	because OpType doesn't know exactly how
		many words will be output before the extension words it is
		calculating. The program counter value depends on whether or
		not an instruction opword or immediate value op words have
		already been output.
	---------------------------------------------------------------- */

	/* ---------------------------------------------------------------
			Determines if the passed string represents an index
		register. If it does represent an index then the string
		is parsed apart into it's components.

	Returns :
	--------------------------------------------------------------- */

	bool Operand65002::isNdxReg(char *str, int *reg)
	{
		return (isReg(str, reg));
	}


	bool Operand65002::isAReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==1)
				return true;
		return false;
	}

	bool Operand65002::isXReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==2)
				return true;
		return false;
	}

	bool Operand65002::isYReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==3)
				return true;
		return false;
	}

	bool Operand65002::isSPReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==15)
				return true;
		return false;
	}

	bool Operand65002::isDPReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==16)
				return true;
		return false;
	}

	/* ---------------------------------------------------------------
	Description :
		Determines if string is a register.

	Returns :
		true if string is a register, otherwise false.
	--------------------------------------------------------------- */

	bool Operand65002::isReg(char *str, int *reg)
	{
		char c1, c2, c3, c4;
		*reg = 0;

		while (isspace(*str)) str++;
		c1 = toupper(*str);
		str++;
		switch(c1) {
		case 'A':
			c2 = toupper(*str);
			str++;
			if (!IsIdentChar(c2)) {
				*reg = 1;
				return true;
			}
			return false;
		case 'X':
			c2 = toupper(*str);
			str++;
			if (!IsIdentChar(c2)) {
				*reg = 2;
				return true;
			}
			return false;
		case 'Y':
			c2 = toupper(*str);
			str++;
			if (!IsIdentChar(c2)) {
				*reg = 3;
				return true;
			}
			return false;
		case 'S':	// SP
			c2 = toupper(*str);
			str++;
			if(c2 == 'P') {
				c3 = toupper(*str);
				str++;
				if (!IsIdentChar(c3)) {
					*reg = 31;
					return true;
				}
			}
			return false;

		case 'D':	// DP
			c2 = toupper(*str);
			str++;
			if(c2 == 'P') {
				c3 = toupper(*str);
				str++;
				if (!IsIdentChar(c3)) {
					*reg = 16;
					return true;
				}
			}
			return false;

		case 'R':
			c2 = toupper(*str);
			str++;
			if (isdigit(c2))
			{
				c3 = toupper(*str);
				str++;
				if (isdigit(c3))
				{
					c4 = toupper(*str);
					str++;
					if (!IsIdentChar(c4))
					{
						*reg = ('0' - c2) * 10 + ('0' - c3);
						if (*reg < 16)
							return true;
					}
				}
				else
				{
					if (!IsIdentChar(c3))
					{
						*reg = '0' - c2;
						return true;
					}
				}
			}
			return false;

		default:
			return false;
	}
	return (false);
	}

	/* ---------------------------------------------------------------
	Description :
		Determines if string is a special purpose register.

	Returns :
		true if string is a register, otherwise false.
	--------------------------------------------------------------- */

	bool Operand65002::isSprReg(char *str, int *reg)
	{
		char c1, c2, c3, c4, c5;
		*reg = 0;

		while (isspace(*str)) str++;
		c1 = toupper(*str);
		str++;
		switch(c1) {
		case 'C':	// CC
			c2 = toupper(*str);
			str++;
			if(c2 == 'C') {
				c3 = toupper(*str);
				str++;
				if (!IsIdentChar(c3)) {
					*reg = 0;
					return true;
				}
			}
			return false;
		case 'S':	// SP
			c2 = toupper(*str);
			str++;
			if(c2 == 'P') {
				c3 = toupper(*str);
				str++;
				if (c3=='8') {
					c4 = toupper(*str);
					str++;
					if (!IsIdentChar(c4)) {
						*reg = 14;
						return true;
					}
				}
				else if (!IsIdentChar(c3)) {
					*reg = 15;
					return true;
				}
			}
			return false;

		case 'D':	// DP/DP8
			c2 = toupper(*str);
			str++;
			if(c2 == 'P') {
				c3 = toupper(*str);
				str++;
				if (c3=='8') {
					c4 = toupper(*str);
					str++;
					if (!IsIdentChar(c4)) {
						*reg = 6;
						return true;
					}
				}
				else if (!IsIdentChar(c3)) {
					*reg = 1;
					return true;
				}
			}
			return false;

		case 'P':	// PH/PL
			c2 = toupper(*str);
			str++;
			if(c2 == 'H') {
				c3 = toupper(*str);
				str++;
				if (!IsIdentChar(c3)) {
					*reg = 3;
					return true;
				}
			}
			else if(c2 == 'L') {
				c3 = toupper(*str);
				str++;
				if (!IsIdentChar(c3)) {
					*reg = 2;
					return true;
				}
			}
			return false;

		case 'T':	// TICK
			c2 = toupper(*str);
			str++;
			if(c2 == 'I') {
				c3 = toupper(*str);
				str++;
				if (c3=='C') {
					c4 = toupper(*str);
					str++;
					if (c4=='K') {
						c5 = toupper(*str);
						str++;
						if (!IsIdentChar(c5)) {
							*reg = 4;
							return true;
						}
					}
				}
			}
			return false;

		case 'L':	// LFSR
			c2 = toupper(*str);
			str++;
			if(c2 == 'F') {
				c3 = toupper(*str);
				str++;
				if (c3=='S') {
					c4 = toupper(*str);
					str++;
					if (c4=='R') {
						c5 = toupper(*str);
						str++;
						if (!IsIdentChar(c5)) {
							*reg = 5;
							return true;
						}
					}
				}
			}
			return false;

		case 'A':	// ABS8
			c2 = toupper(*str);
			str++;
			if(c2 == 'B') {
				c3 = toupper(*str);
				str++;
				if (c3=='S') {
					c4 = toupper(*str);
					str++;
					if (c4=='8') {
						c5 = toupper(*str);
						str++;
						if (!IsIdentChar(c5)) {
							*reg = 7;
							return true;
						}
					}
				}
			}
			return false;

		case 'V':	// VBR
			c2 = toupper(*str);
			str++;
			if(c2 == 'B') {
				c3 = toupper(*str);
				str++;
				if (c3=='R') {
					c4 = toupper(*str);
					str++;
					if (!IsIdentChar(c4)) {
						*reg = 8;
						return true;
					}
				}
			}
			return false;

		case 'H':	// HIST
			c2 = toupper(*str);
			str++;
			if(c2 == 'I') {
				c3 = toupper(*str);
				str++;
				if (c3=='S') {
					c4 = toupper(*str);
					str++;
					if (c4=='T') {
						c5 = toupper(*str);
						str++;
						if (!IsIdentChar(c5)) {
							*reg = 10;
							return true;
						}
					}
				}
			}
			return false;

		default:
			return false;
	}
	return (false);
	}


/* ---------------------------------------------------------------
	int ParseOperand(op, SOperand *);
	char *op;	// operand string
   
		Parse an operand string into something that can be used
	by the assembler.
   
		Find out what kind of an operand it is and return its
	type. If it's illegal, return a 0 and complain thru err().
	The operand type is returned in an integer within which each
	bit position represents a different operand addressing mode.
	Although the operand can qualify for only a single addressing
	mode, a separate bit within the integer is used to represent
	the mode. This allows the detected operand type to be AND
	masked against another integer representing a set of valid
	operand modes.

	valid types are:

	Rn             register direct
	(Rn)           reg indirect
	(disp, Rn)     reg indirect with displacement
	(Rn, Rn)       indexed reg indirect
	(abs).b        absolute short
	(abs).w        absolute long
	#x             immediate

	(%s, %s) could be

	(disp, Rn)
	(Rn, Rn)

		This is a prime example of spaghetti code. It could be
	reworked to use subroutines, however the code would be
	larger and slower.
		*** You can't simply OR the matching statements
	together to detect different formats of the same address
	mode because the detection order is important.
--------------------------------------------------------------- */

int Operand65002::parse(char *op)
{
	char ch;
	char ch1;
	int reg;
	AsmBuf eb(100);
	AsmBuf ob(op+1,strlen(op+1)+1);

	theAssembler.errtype = true;

	type = 0;
	val.value = 0;
	r1 = 0;
	r2 = 0;

	if (isAReg(op))
		return type = AM_ACC;

	if (isSprReg(op, &r1))
		return type = AM_SPR;

	// Immediate
	if(op[0] == '#') {
		val = ob.expeval(NULL);
		if (val.value >= -8 && val.value < 8)
			type = AM_IMM4;
		else if (val.value >= -128 && val.value < 128)
			type = AM_IMM8;
		else if (val.value >= -32768 && val.value < 32768)
			type = AM_IMM16;
		else
			type = AM_IMM32;
		return type;
	}

	if (strmat(op, " r%d ", &reg)) {
		if (reg > 15) goto j1;
		r1 = reg;
		return type = AM_RN;
	}
	if (strmat(op, " R%d ", &reg)) {
		if (reg > 15) { printf("R%d\r\n",reg); goto j1; }
		r1 = reg;
		return type = AM_RN;
	}
j1:
	// (d,s),y
    if (strmat(op, " ( %s, %c ) , %c ", eb.buf(), &ch1, &ch))
    {
		if (tolower(ch1) == 's') {
			val = eb.expeval(NULL);
			if (tolower(ch)!='y')
				Err(E_INVOPERAND, op);
			return type = AM_SRIY;
		}
    }

	// (zp),y
    if (strmat(op, " ( %s) , %c ", eb.buf(), &ch))
    {
		val = eb.expeval(NULL);
		if (tolower(ch)!='y')
			Err(E_INVOPERAND, op);
		r1 = 3;
		return type = AM_IY;
    }

	// [zp],y
    if (strmat(op, " [ %s] , %c ", eb.buf(), &ch))
    {
		val = eb.expeval(NULL);
		if (tolower(ch)!='y')
			Err(E_INVOPERAND, op);
		return type = AM_IYL;
    }

	// (zp,x)
	if(strmat(op, " ( %s, %c) ", eb.buf(), &ch))
	{
		val = eb.expeval(NULL);
		r1 = 2;
		if (tolower(ch)!='x')
			Err(E_INVOPERAND, op);
		return type = AM_IX;
	}

	if (strmat(op, " ( r%d ) ", &reg)) {
		r1 = reg;
		return type = AM_RIND;
	}

	if (strmat(op, " ( R%d ) ", &reg)) {
		r1 = reg;
		return type = AM_RIND;
	}

	if (strmat(op, " ( x ) ")) {
		r1 = 2;
		return type = AM_RIND;
	}

	if (strmat(op, " ( y ) ")) {
		r1 = 3;
		return type = AM_RIND;
	}

	// (abs)  { jmp }
	if(strmat(op, " ( %s) ", eb.buf()))
	{
		r1 = 0;
		val = eb.expeval(NULL);
        if (val.value < 4096 && val.value >= 0)
			return type = AM_ZI;
		return type = AM_I;
	}

	// [abs]  { jmp }
	if(strmat(op, " [ %s] ", eb.buf()))
	{
		r1 = 0;
		val = eb.expeval(NULL);
        if (val.value < 4096 && val.value >= 0)
			return type = AM_ZIL;
		return type = AM_IL;
	}

    // Could be indexed
    if (strmat(op, " %s, r%d ", eb.buf(), &reg))
	{
		val = eb.expeval(NULL);
        if (val.value < 2048 && val.value >= -2048)
		{
			if (reg >= 0 && reg < 16) {
				r1 = reg;
				return type = AM_ZX;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_ZX;
		}
		else
		{
			if (reg >= 0 && reg < 16) {
				r1 = reg;
				return type = AM_AX;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_AX;
		}
	}

   // Could be indexed
    if (strmat(op, " %s, R%d ", eb.buf(), &reg))
	{
		val = eb.expeval(NULL);
        if (val.value < 2048 && val.value >= -2048)
		{
			if (reg >= 0 && reg < 16) {
				r1 = reg;
				return type = AM_ZX;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_ZX;
		}
		else
		{
			if (reg >= 0 && reg < 16) {
				r1 = reg;
				return type = AM_AX;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_AX;
		}
	}
	// d,sp
    if (strimat(op, " %s, sp ", eb.buf()))
    {
		val = eb.expeval(NULL);
		return type = AM_SR;
    }

    // Could be indexed
    if (strmat(op, " %s, %c ", eb.buf(), &ch))
	{
		val = eb.expeval(NULL);
        if (val.value < 2048 && val.value >= -2048)
		{
			if (tolower(ch)=='x') {
				r1 = 2;
				return type = AM_ZX;
			}
			else if (tolower(ch)=='y') {
				r1 = 3;
				return type = AM_ZY;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_Z;
		}
        else {
			if (tolower(ch)=='x') {
				r1 = 2;
				return type = AM_AX;
			}
			else if (tolower(ch)=='y') {
				r1 = 3;
				return type = AM_AY;
			}
			else 
				Err(E_INVOPERAND, op);
			return AM_A;
		}
	}


	// Assume
	// Absolute / Zero page
	// This must be the last mode tested for since anything will
	// match
	strmat(op, " %s", eb.buf());
	val = eb.expeval(NULL);
	if (val.value < 2048 && val.value >= -2048) {
		r2 = 0;
		return type = AM_ZX;
	}
	return type = AM_A;
}


}
