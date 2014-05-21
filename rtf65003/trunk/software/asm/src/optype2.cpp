#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fwlib.h"
#include "fwstr.h"   // strmat
#include "err.h"
#include "asmbuf.h"
#include "asm24.h"

/* ===============================================================
	(C) 2001 Bird Computer
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

static int OpWord;
static long PrjPC;	// projected program counter

// a zero value is needed in a couple of places


/* ---------------------------------------------------------------
   Description :
		Determines if the passed string represents an index
	register. If it does represent an index then the string
	is parsed apart into it's components.

   Returns :
--------------------------------------------------------------- */

static int IsNdxReg(char *str, int *reg)
{
	return (IsReg(str, reg));
}


static int isAReg(char *str)
{
    int reg;

    if (IsReg(str, &reg))
        if (reg==1)
            return TRUE;
    return FALSE;
}

static int isXReg(char *str)
{
    int reg;

    if (IsReg(str, &reg))
        if (reg==2)
            return TRUE;
    return FALSE;
}

static int isYReg(char *str)
{
    int reg;

    if (IsReg(str, &reg))
        if (reg==3)
            return TRUE;
    return FALSE;
}

static int isSPReg(char *str)
{
    int reg;

    if (IsReg(str, &reg))
        if (reg==15)
            return TRUE;
    return FALSE;
}

/* ---------------------------------------------------------------
   Description :
      Determines if string is a register.

   Returns :
      TRUE if string is a register, otherwise FALSE.
--------------------------------------------------------------- */

int IsReg(char *str, int *reg)
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
			return TRUE;
		}
		return FALSE;
    case 'X':
		c2 = toupper(*str);
		str++;
		if (!IsIdentChar(c2)) {
			*reg = 2;
			return TRUE;
		}
		return FALSE;
    case 'Y':
		c2 = toupper(*str);
		str++;
		if (!IsIdentChar(c2)) {
			*reg = 3;
			return TRUE;
		}
		return FALSE;
	case 'S':	// SP
		c2 = toupper(*str);
		str++;
		if(c2 == 'P') {
			c3 = toupper(*str);
			str++;
			if (!IsIdentChar(c3)) {
				*reg = 15;
				return TRUE;
			}
		}
		return FALSE;
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
                        return TRUE;
                }
            }
            else
            {
                if (!IsIdentChar(c3))
                {
                    *reg = '0' - c2;
                    return TRUE;
                }
            }
        }
        return FALSE;

	default:
		return FALSE;
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
      Determines if string is a special purpose register.
	  Special purpose regs
	  VER	0x00
	  SR	0x1b
	  PTI	0x1c
	  PTE	0x1d
	  CR	0x1f

   Returns :
      TRUE if string is a register, otherwise FALSE.
--------------------------------------------------------------- */
int IsSPRReg(char *str, int *reg)
{
	char c1, c2, c3, c4;
	*reg = 0;

	while (isspace(*str)) str++;
	c1 = toupper(*str);
	str++;
	switch(c1) {
	case 'S':
		c2 = toupper(*str);
		str++;
		if(c2 == 'R') {
			c3 = toupper(*str);
			str++;
            if (c3=='8') {
                *reg = 3;
                return TRUE;
            }
			if (!IsIdentChar(c3)) {
				*reg = 0x00;
				return TRUE;
			}
		}
		return FALSE;
	case 'R':
		c2 = toupper(*str);
		str++;
		if(c2 == 'A') {
			c3 = toupper(*str);
			str++;
			if(c3 == 'N') {
				c4 = toupper(*str);
				str++;
				if (!IsIdentChar(c4)) {
					*reg = 1;
					return TRUE;
				}
			}
		}
		return FALSE;
	case 'V':
		c2 = toupper(*str);
		str++;
		if(c2 == 'E') {
			c3 = toupper(*str);
			str++;
			if(c3 == 'R') {
				c4 = toupper(*str);
				str++;
				if (!IsIdentChar(c4)) {
					*reg = 0;
					return TRUE;
				}
			}
		}
		return FALSE;
	case 'C':
		c2 = toupper(*str);
		str++;
		if(c2 == 'R') {
			c3 = toupper(*str);
			str++;
			if (!IsIdentChar(c3)) {
				*reg = 0x1f;
				return TRUE;
			}
		}
		return FALSE;
	case 'P':
		c2 = toupper(*str);
		str++;
		if(c2 == 'T') {
			c3 = toupper(*str);
			str++;
			if(c3 == 'I') {
				c4 = toupper(*str);
				str++;
				if (!IsIdentChar(c4)) {
					*reg = 0x1c;
					return TRUE;
				}
			}
			else if(c3 == 'E') {
				c4 = toupper(*str);
				str++;
				if (!IsIdentChar(c4)) {
					*reg = 0x1d;
					return TRUE;
				}
			}
		}
		return FALSE;
	default:
		return FALSE;
	}
	return FALSE;
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

int COperand::parse(char *op)
{
	char
		exp[81], ch,
        exp1[80];
	CAsmBuf eb, ob, eb2;

	eb.set(exp, sizeof(exp));
	eb2.set(exp1, sizeof(exp1));
	ob.set(op+1, strlen(op+1));
	errtype = TRUE;

	type = 0;
	r1 = 0;
	r2 = 0;
	val.value = 0;

	if (isAReg(op))
		return type = AM_ACC;

	// register direct
	if (IsReg(op, &r1))
		return type = AM_RN;
		
	if (IsSPRReg(op, &r1))
		return type = AM_SPR_RN;

	// Immediate
	if(op[0] == '#') {
		val = ob.expeval(NULL);
		return type = AM_IMM;
	}

    if (strmat(op, " ( %s) , %s ", exp, exp1))
    {
		val = eb.expeval(NULL);
        IsReg(exp1, &r1);
        return type = AM_IY;
    }

	// Absolute short/long
	if (strmat(op," ( %s).%c ", exp, &ch))
	{
abs_am:
		ch = (char)toupper(ch);
		val = eb.expeval(NULL);
		if (ch == 'L')
			return type = AM_A;
		else if (ch == 'S')
			return type = AM_Z;
		err(NULL, E_ONLYBW);
		return type = AM_A;
	}

	// The following match must be before %s[%s+%s]
	if(strmat(op, " [ %s+ %s] ", exp, exp1))
		goto reg_indirect_disp;

	/* -----------------------------------------
		Could be (z,x)
	----------------------------------------- */
	if(strmat(op, " ( %s, %s) ", exp, exp1))
	{
reg_indirect_disp:
		// indexed register indirect
		// exp must be displacement
		val = eb.expeval(NULL);
		if (IsReg(exp1, &r1))
        {
            if (r1==2)
			    return type = AM_IX;
        }
		// Shouldn't get here
		// two displacments ?? - probably an error
		err(NULL, E_INVOPERAND, op);
		return type = AM_IX;
	}

    // Could be indexed
    if (strmat(op, " %s, %s ", exp, exp1))
        goto rid;

	// simple register indirect ?
	if (strmat(op, " [ %s] ", exp))
	{
ri:
		strcpy(exp1,"0");
		val = eb.expeval(NULL);
		if (IsReg(exp, &r1)) {
            if (r1==2)
                return type = AM_ZX;
            else if (r1==3)
                return type = AM_ZY;
            else if (r1==15)
                return type = AM_DS;
		}
		return type = AM_I;
	}

	// Register indirect - displacement alternate format
	if (strmat(op, "%s[ %s]", exp, exp1)) {
rid:
		// Rn[xx] - invalid
		if (IsReg(exp, &r1)) {
			err(NULL, E_INVOPERAND, op);
			return type = AM_RN;
		}
		if (IsSPRReg(exp, &r1)) {
			err(NULL, E_INVOPERAND, op);
			return type = AM_SPR_RN;
		}
		// exp must be displacement
		val = eb.expeval(NULL);
		if (IsReg(exp1, &r1))
        {
            if (r1==2)
            {
                if ((val.value < 256 && val.value >= 0))
                    return type = AM_ZX;
				else if ((val.value < 65536 && val.value >= 0))
                    return type = AM_AX;
                else
                    return type = AM_AXL;
            }
            else if (r1==3)
            {
                if ((val.value < 256 && val.value >= 0))
                    return type = AM_ZY;
                else
                    return type = AM_AY;
            }
            else if (r1==15)
            {
                if ((val.value >= -128 && val.value < 128))
                    return type = AM_DS;
                else
                {
            		err(NULL, E_INVOPERAND, op);
                    return type = AM_DS;
                }
            }
			return type = AM_A;
        }
		// exp1 must be reg
		err(NULL, E_INVOPERAND, op);
		return type = AM_A;
	}

	// Register indirect - displacement - second form
	if (strmat(op, "[ %s].%s", exp1, exp))
		goto rid;

	// register indirect
	if (strmat(op, " ( %s) ", exp))
		goto ri;

   // Register indirect - displacement third form
   if (strmat(op, "%s( %s)", exp, exp1))
      goto rid;
   
	// Absolute short/long 2
	if (strmat(op," %s.%c ", exp, &ch))
		goto abs_am;

	// Assume absolute 
	// This must be the last mode tested for since anything will
	// match
	val = eb.expeval(NULL);
    if (val.value < 256 && val.value >= 0)
        return type = AM_Z;
//	return type = (val.size == 'B') ? AM_ABS_SHORT : AM_ABS_LONG;
	return type = AM_A;

	// Unknown addressing mode
	err(NULL, E_INVOPERAND, op);
	return FALSE;
}


/* -------------------------------------------------------------------
   GetOperands();

      Gets operands from the input buffer. Operands are separated
	by commas. Since there are also commas in different addressing
	modes this routine keeps track of the number of round brackets
	encountered. Only when a comma follows a matching set of
	brackets is it considered to be separating the operands.
	Operands are stored in global operand buffers which must be
	freed when no longer needed.

    z
    z(x)     = z,x
    z(y)     = z,y
    a(x)     = a,x
    a(y)     = a,y
    (z,x)    = (z,x)
    (z)y     = (z),y

------------------------------------------------------------------- */

int GetOperands()
{
   int bcount = 0, ii, xx;
   char *sptr, *eptr, tt, ch;
   COperand tmpOp;
   char strTmp[200];
   int reg;

//   printf("GetOperands\n");
   gOpsig = 0;
   ii = 0;
   ibuf.SkipSpacesLF();
   sptr = ibuf.Ptr();
   while(ibuf.PeekCh())
   {
      ch = ibuf.NextCh();
      switch(ch)
      {
         case '(':
            bcount++;
            break;
         case ')':
            bcount--;
            if (bcount < 0)
               err(NULL, E_CPAREN);
            break;
		// Note string scanning must check for an escaped quote
		// character, so it's not confused with the actual end
		// of the string.
         // If we detect a quote then scan until end quote
         case '"':
            while(1) {
               ch = ibuf.NextCh();
			   if (ch == '\\') {
				   if (ibuf.PeekCh() == '"') {
					   ibuf.NextCh();		// get "
					   ch = ibuf.NextCh();	// move to next char
				   }
			   }
               if (ch < 1 || ch == '\n')
                  goto ExitLoop;
               if (ch == '"')
                  break;
            }
            break;
         // If we detect a quote then scan until end quote.
         case '\'':
            while(1) {
               ch = ibuf.NextCh();
			   if (ch == '\\') {
				   if (ibuf.PeekCh() == '\'') {
					   ibuf.NextCh();
					   ch = ibuf.NextCh();
				   }
			   }
               if (ch < 1 || ch == '\n')
                  goto ExitLoop;
               if (ch == '\'')
                  break;
            }
            break;
         // semicolon marks the start of comment following operands. If
         // semicolon detected then break loop
         case ';':
            ibuf.unNextCh();  // backup ptr
            goto ExitLoop;
         // If at outermost level of brackets then split at comma.
         case ',':
            if (bcount == 0)
            {
               // Check that we haven't got too many operands
               if (ii >= MAX_OPERANDS)
               {
                  err(NULL, E_OPERANDS);
                  return (ii);
               }
               eptr = ibuf.Ptr() - 2;
               while (eptr > sptr && isspace(*eptr)) --eptr;
               eptr++;
               tt = *eptr;
               *eptr = '\0';
               gOperand[ii] = strdup(sptr);
               if (gOperand[ii] == NULL)
                  err(NULL, E_MEMORY);
//               printf("gOperand[ii] = %s| sptr=%s|tt=%c,ii=%d\n", gOperand[ii], sptr, tt, ii);
               sptr = ibuf.Ptr();
               *eptr = tt;
               ii++;
            }
            break;
         // Newline marks end of operand
         case '\n':
            ibuf.unNextCh();
            goto ExitLoop;
      }
   }
ExitLoop:
   // If pointer advanced beyond last sptr
   if (ibuf.Ptr() > sptr)
   {
      eptr = ibuf.Ptr() - 1;
      while (eptr > sptr && isspace(*eptr)) --eptr;
      eptr++;
      tt = *eptr;
      *eptr = '\0';
      gOperand[ii] = strdup(sptr);
      if (gOperand[ii] == NULL)
         err(NULL, E_MEMORY);
      *eptr = tt;
      ii++;
   }
   // Trim leading and trailing spaces from operand
   for (xx = 0; xx < ii; xx++)
      if (gOperand[xx])
         trim(gOperand[xx]);
//   for (xx = 0; xx < ii; xx++)
//      printf("gOperand[%d]=%s|,", xx, gOperand[xx]);
//   printf("\n");

    // Merge the last two operands if they end in ,x ,y or ,sp as
    // this represents an indexed addressing mode
    if (ii > 1)
    {
        if (IsReg(gOperand[ii-1], &reg))
        {
            sprintf(strTmp, "%.*s,%s", sizeof(strTmp)-5, gOperand[ii-2], gOperand[ii-1]);
            free(gOperand[ii-1]);
            gOperand[ii-1] = NULL;
            free(gOperand[ii-2]);
            gOperand[ii-2] = strdup(strTmp);
            --ii;
        }
    }

    // Figure operand signature
    for (xx = 0; xx < ii; xx++)
        if (gOperand[xx] && gOperand[xx][0] !='"') {
            gOpsig <<= 5;
            gOpsig |= tmpOp.parse(gOperand[xx]);
        }

   return (ii);
}

