#include <stdio.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "Assembler.h"
#include "operand6502.h"

extern "C" {
    char *trim(char*);
};

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

	bool Operand6502::isNdxReg(char *str, int *reg)
	{
		return (isReg(str, reg));
	}


	bool Operand6502::isAReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==1)
				return true;
		return false;
	}

	bool Operand6502::isXReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==2)
				return true;
		return false;
	}

	bool Operand6502::isYReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==3)
				return true;
		return false;
	}

	bool Operand6502::isSPReg(char *str)
	{
		int reg;

		if (isReg(str, &reg))
			if (reg==15)
				return true;
		return false;
	}

	bool Operand6502::isDPReg(char *str)
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

	bool Operand6502::isReg(char *str, int *reg)
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
			if (!IsIdentChar(c2)) {
			  *reg = 4;
			  return true;
			}
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

int Operand6502::parse(char *op)
{
	char ch;
	char ch1;
	int reg;
	AsmBuf eb(100),ec(100),ed(100);
	AsmBuf ob(op+1,strlen(op+1)+1);
	hasSegPrefix = 0;
	hasFarPrefix = 0;
	hasJmpPrefix = 0;

	theAssembler.errtype = true;

	type = 0;
	val.value = 0;
	seg.value = 0;
	r1 = 0;
	r2 = 0;

	if (isAReg(op))
		return type = AM_ACC;

	// Immediate
	if(op[0] == '#') {
		val = ob.expeval(NULL);
		type = AM_IMM;
		return type;
	}

	// (d,s),y
    if (strmat(op, " %s( %s, %c ) , %c ", ec.buf(), eb.buf(), (char *)&ch1, (char *)&ch))
    {
        if (stricmp(::trim(ec.buf()), "FAR")==0) {
            hasFarPrefix = 1;                                           
    		if (tolower(ch1) == 's') {
    			val = eb.expeval(NULL);
    			if (tolower(ch)!='y')
    				Err(E_INVOPERAND, op);
    			return type = AM_SRIY;
    		}
        }
    }
    if (strmat(op, " ( %s, %c ) , %c ", eb.buf(), (char *)&ch1, (char *)&ch))
    {
		if (tolower(ch1) == 's') {
			val = eb.expeval(NULL);
			if (tolower(ch)!='y')
				Err(E_INVOPERAND, op);
			return type = AM_SRIY;
		}
    }

	// {d,s},y
    if (strmat(op, " %s{ %s, %c } , %c ", ec.buf(), eb.buf(), (char *)&ch1, (char *)&ch))
    {
        if (stricmp(::trim(ec.buf()),"FAR")==0)            
            hasFarPrefix = 1;                                        
    		if (tolower(ch1) == 's') {
    			val = eb.expeval(NULL);
    			if (tolower(ch)!='y') {
    				Err(E_INVOPERAND, op);
   			  }
    			return type = AM_XSRIY;
        }
    }
    if (strmat(op, " { %s, %c } , %c ", eb.buf(), (char *)&ch1, (char *)&ch))
    {
		if (tolower(ch1) == 's') {
			val = eb.expeval(NULL);
			if (tolower(ch)!='y')
				Err(E_INVOPERAND, op);
			return type = AM_XSRIY;
		}
    }

	// (zp),y
    if (strmat(op, " %s( %s) , %c ", ec.buf(), eb.buf(), (char *)&ch))
    {
        if (stricmp(::trim(ec.buf()),"FAR")==0) 
            hasFarPrefix = 1;                                      
    		val = eb.expeval(NULL);
    		if (tolower(ch)!='y')
    			Err(E_INVOPERAND, op);
    		r1 = 3;
    		return type = AM_IY;
    }
    if (strmat(op, " ( %s) , %c ", eb.buf(), (char *)&ch))
    {
		val = eb.expeval(NULL);
		if (tolower(ch)!='y')
			Err(E_INVOPERAND, op);
		r1 = 3;
		return type = AM_IY;
    }

	// [zp],y
    if (strmat(op, " %s[ %s] , %c ", ec.buf(), eb.buf(), (char *)&ch))
    {
        if (stricmp(::trim(ec.buf()),"FAR")==0) {
            hasFarPrefix = 1;                            
    		val = eb.expeval(NULL);
    		if (tolower(ch)!='y')
    			Err(E_INVOPERAND, op);
    		return type = AM_IYL;
        }
    }
    if (strmat(op, " [ %s] , %c ", eb.buf(), (char *)&ch))
    {
		val = eb.expeval(NULL);
		if (tolower(ch)!='y')
			Err(E_INVOPERAND, op);
		return type = AM_IYL;
    }

	// {zp},y
    if (strmat(op, " %s{ %s} , %c ", ec.buf(), eb.buf(), (char *)&ch))
    {
        if (stricmp(::trim(ec.buf()),"FAR")==0) {                   
            hasFarPrefix = 1;
    		val = eb.expeval(NULL);
    		if (tolower(ch)!='y')
    			Err(E_INVOPERAND, op);
    		return type = AM_XIYL;
        }
    }
    if (strmat(op, " { %s} , %c ", eb.buf(), (char *)&ch))
    {
		val = eb.expeval(NULL);
		if (tolower(ch)!='y')
			Err(E_INVOPERAND, op);
		return type = AM_XIYL;
    }

	// (zp,x)
	if(strmat(op, " %s( %s, %c) ", ec.buf(), eb.buf(), (char *)&ch))
	{
        if (stricmp(::trim(ec.buf()), "FAR")==0) {
            hasFarPrefix = 1;
    		val = eb.expeval(NULL);
    		r1 = 2;
    		if (tolower(ch)!='x')
    			Err(E_INVOPERAND, op);
    		return type = AM_IX;
        }
	}
	if(strmat(op, " ( %s, %c) ", eb.buf(), (char *)&ch))
	{
		val = eb.expeval(NULL);
		r1 = 2;
		if (tolower(ch)!='x')
			Err(E_INVOPERAND, op);
		return type = AM_IX;
	}

	// (abs)  { jmp }
	if(strmat(op, " %s( %s) ", ec.buf(), eb.buf()))
	{
        if (stricmp(::trim(ec.buf()),"FAR")==0) {          
            hasFarPrefix = 1;                                        
    		val = eb.expeval(NULL);
            if (val.value < 256 && val.value >= 0)
    			return type = AM_ZI;
    		return type = AM_I;
        } 
	}
	if(strmat(op, " ( %s) ", eb.buf()))
	{
		val = eb.expeval(NULL);
        if (val.value < 256 && val.value >= 0)
			return type = AM_ZI;
		return type = AM_I;
	}

	// [abs]  { jmp }
	if(strmat(op, " %s[ %s] ", ec.buf(), eb.buf()))
	{
        if (stricmp(::trim(ec.buf()), "FAR")==0) {                  
            hasFarPrefix = 1;                
    		val = eb.expeval(NULL);
            if (val.value < 256 && val.value >= 0)
    			return type = AM_ZIL;
    		return type = AM_IL;
        }
	}
	if(strmat(op, " [ %s] ", eb.buf()))
	{
		val = eb.expeval(NULL);
        if (val.value < 256 && val.value >= 0)
			return type = AM_ZIL;
		return type = AM_IL;
	}

	// {zp} 
	if(strmat(op, " %s{ %s} ", ec.buf(), eb.buf()))
	{
        if (stricmp(::trim(ec.buf()), "FAR")==0) {
            hasFarPrefix = 1;
    		val = eb.expeval(NULL);
            if (val.value < 256 && val.value >= 0)
    			return type = AM_XIL;
    		Err(E_INVOPERAND, op);
    		return type = AM_XIL;
        }
	}
	if(strmat(op, " { %s} ", eb.buf()))
	{
		val = eb.expeval(NULL);
        if (val.value < 256 && val.value >= 0)
			return type = AM_XIL;
		Err(E_INVOPERAND, op);
		return type = AM_XIL;
	}

    if (strmat(op, " %s:%s ", ec.buf(), eb.buf())) {
        if (stricmp(ec.buf(), "CS")==0) {
           type = parse(eb.buf());
           hasSegPrefix = 1;
           return type;
        }
        else if (stricmp(ec.buf(), "ZS")==0) {
           type = parse(eb.buf());
           hasSegPrefix = 2;
           return type;
        }
        else if (stricmp(ec.buf(), "SEG0")==0) {
           type = parse(eb.buf());
           hasSegPrefix = 2;
           return type;
        }
        else if (stricmp(ec.buf(), "IOS")==0) {
           type = parse(eb.buf());
           hasSegPrefix = 3;
           return type;
        }
        else if (strnicmp(ec.buf(), "SEG",3)==0) {
           strmat(ec.buf(), " SEG %s ", ed.buf());
           type = parse(eb.buf());
           seg = ed.expeval(NULL);
           hasSegPrefix = 4;
           return type;
        }
        else if (strnicmp(ec.buf(), "FAR",3)==0) {
           strmat(ec.buf(), " FAR %s ", ed.buf());
           type = parse(eb.buf());
           seg = ed.expeval(NULL);
           hasSegPrefix = 4;
           return type;
        }
        else if (stricmp(ec.buf(), "JMP")==0) {
           type = parse(eb.buf());
           hasJmpPrefix = 1;
           return type;
        }
        type = parse(eb.buf());
        seg = ec.expeval(NULL);
        hasSegPrefix = 5;
        return type;
    }

	// d,sp
    if (strmat(op, " %s, %c ", eb.buf(), &ch))
    {
		if (tolower(ch)=='s') {
			val = eb.expeval(NULL);
			return type = AM_SR;
		}
    }

    // Could be indexed
    if (strmat(op, " %s, %c ", eb.buf(), &ch))
	{
		val = eb.expeval(NULL);
        if (val.value < 256 && val.value >= 0)
		{
			if (tolower(ch)=='x')
				return type = AM_ZX;
			else if (tolower(ch)=='y')
				return type = AM_ZY;
			else 
				Err(E_INVOPERAND, op);
			return AM_Z;
		}
        else if (val.value < 65536 && val.value >= 0)
		{
			if (tolower(ch)=='x')
				return type = AM_AX;
			else if (tolower(ch)=='y')
				return type = AM_AY;
			else 
				Err(E_INVOPERAND, op);
			return AM_Z;
		}
        else if (val.value < 16777216 && val.value >=0) {
			if (tolower(ch)=='x')
				return type = AM_AXL;
			else if (tolower(ch)=='y')
				return type = AM_XAYL;
			else 
				Err(E_INVOPERAND, op);
			return AM_AL;
		}
        else {
			if (tolower(ch)=='x')
				return type = AM_XAXL;
			else if (tolower(ch)=='y')
				return type = AM_XAYL;
			else 
				Err(E_INVOPERAND, op);
			return AM_XAL;
		}
	}

	// Assume
	// Absolute / Zero page
	// This must be the last mode tested for since anything will
	// match
	strmat(op, " %s ", eb.buf());
	val = eb.expeval(NULL);
	if (val.value < 256 && val.value >= 0) {
		r2 = 0;
		return type = AM_Z;
	}
	if (val.value < 65536 && val.value >= 0) {
    	return type = AM_A;
    }
	else if (val.value < 16777216 && val.value >= 0) {
    	return type = AM_AL;
    }
    return type = AM_XAL;
}


}
