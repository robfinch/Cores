#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "asm24.h"
#include "am.h"
#include "operandButterfly.h"

/* ===============================================================
	(C) 2003 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/* ---------------------------------------------------------------
   Description :
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
   Description :
		Determines if the passed string represents an index
	register. If it does represent an index then the string
	is parsed apart into it's components.

   Returns :
--------------------------------------------------------------- */

bool OperandButterfly::isNdxReg(char *str, int *reg)
{
	return (isReg(str, reg));
}


bool OperandButterfly::isSPReg(char *str)
{
    int reg;

    if (isReg(str, &reg))
        if (reg==15)
            return true;
    return false;
}

/* ---------------------------------------------------------------
   Description :
      Determines if string is a register.

   Returns :
      true if string is a register, otherwise false.
--------------------------------------------------------------- */

bool OperandButterfly::isReg(char *str, int *reg)
{
	char c1, c2, c3, c4;
	*reg = 0;

	while (isspace(*str)) str++;
	c1 = toupper(*str);
	str++;
	switch(c1) {
	case 'L':	// LR
		c2 = toupper(*str);
		str++;
		if(c2 == 'R') {
			c3 = toupper(*str);
			str++;
			if (!IsIdentChar(c3)) {
				*reg = 15;
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
			if (!IsIdentChar(c3)) {
				*reg = 14;
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
                    *reg = (c2 - '0') * 10 + (c3 - '0');
                    if (*reg < 16)
                        return true;
                }
            }
            else
            {
                if (!IsIdentChar(c3))
                {
                    *reg = c2 - '0';
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

bool OperandButterfly::isSPRReg(char *str, int *reg)
{
	char c1, c2, c3, c4;
	*reg = 0;

	while (isspace(*str)) str++;
	c1 = toupper(*str);
	str++;
	switch(c1) {
	case 'S':	// SR
		c2 = toupper(*str);
		str++;
		if(c2 == 'R') {
			c3 = toupper(*str);
			str++;
			if (!IsIdentChar(c3)) {
				*reg = 0;
				return true;
			}
		}
		return false;

	case 'I':	// ILR
		c2 = toupper(*str);
		str++;
		if(c2 == 'L') {
			c3 = toupper(*str);
			str++;
			if (c3=='R') {
				str++;
				if (!IsIdentChar(c4)) {
					*reg = 1;
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

int OperandButterfly::parse(char *op)
{
	char ch;
	AsmBuf eb(100);
	AsmBuf ob(op+1,strlen(op+1)+1);
	int regno = 0;
	char bf[100];

	errtype = true;

	type = 0;
	val.value = 0;

	// Immediate
	if(op[0] == '#') {
		val = ob.expeval(NULL);
		return type = AM_IMM;
	}

	if (isReg(op, &r1))
		return type = AM_REG;

	if (isSPRReg(op, &r1))
		return type = AM_SPR;

    if (strmat(op, " [ %s] ", bf))
    	if (isReg(bf, &r1))
    		return AM_RIND;

    if (strmat(op, " %s[ %s] ", eb.gBuf(), bf)) {
		val = eb.expeval(NULL);
    	if (isReg(bf, &r1))
    		return AM_DRIND;
    }

	// Assume
	// Absolute
	// This must be the last mode tested for since anything will
	// match
    strmat(op, " %s ", eb.gBuf());
	val = eb.expeval(NULL);
	return type = AM_ABS;
}


