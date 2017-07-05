#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <fwlib.h>
#include <fwstr.h>   // strmat
#include "err.h"
#include "asmbuf.h"
#include "fasm68.h"

/* ---------------------------------------------------------------
   (C) 1999 Bird Computer

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


/* -----------------------------------------------------------------------------
   ScaleSize(value);
   long value;

      Returns a two bit code for the size of the scale.

   Returns :

   Code  Scale
    0       1
    1       2
    2       4
    3       8
    0    other (warning)
----------------------------------------------------------------------------- */

static int ScaleSize(long value)
{
   switch(value)
   {
      case 1: return (0);
      case 2: return (1);
      case 4: return (2);
      case 8: return (3);
      default:
         Err(E_SCALESZ, (int)value);
   }
   return (0);
}



/* -----------------------------------------------------------------------------
   BdSize(value);
   long value;

   Description :
      Figures out a two bit code for the base (or outer) displacement size.

   Returns :
      1  if value = 0
      2  value will fit in word
      3  value will fit in long word
----------------------------------------------------------------------------- */

static int BdSize(SValue *val)
{
	if (val == NULL)
		return (1);
	if (!val->fForcedSize) {
		if (val->value == 0)
			return (1);
		else if (val->value >= -32768 && val->value <= 32767)
		{
			wordop[opsize++] = (int)(val->value & 0xffff);
			return (2);
		}
		wordop[opsize++] = (int)(val->value >> 16);
		wordop[opsize++] = (int)(val->value & 0xffff);
		return (3);
	}
	if (val->size == 'B' || val->size == 'W') {
		wordop[opsize++] = (int)(val->value & 0xffff);
		return 2;
	}
	wordop[opsize++] = (int)(val->value >> 16);
	wordop[opsize++] = (int)(val->value & 0xffff);
	return 3;
}


/* ---------------------------------------------------------------
	Build indexing word, uses full extension word format if
	required. This is for base / dsiplacement modes only.
--------------------------------------------------------------- */

static void BldIWord(
	char *exp,	// base displacement expression
	char bs,	// base register suppress indicator
	char is,	// index register suppress indicator
	char ad,	// address / data index register
	char reg,	// index register
	char size,	// index register size
	int scale	// index scaling value
	)	
{
	SValue val;

	val.fLabel = FALSE;

	/* ------------------------------------
         Set common bits in index word.
	------------------------------------ */
	wordop[1] |= IADBit((tolower(ad) == 'a') ? 1 : 0);     // Set index register type
	wordop[1] |= IWLBit((tolower(size) == 'l') ? 1 : 0);   // Set index register size
	wordop[1] |= IRegBits(reg);

	if (gProcessor & PL_01)
	{
		if (bs || is)
			Err(E_REGSUP);
		if (scale != 1)
			Err(E_SCALNOSUP);
		scale = 1;
	}

    wordop[1] |= IScaleBits(ScaleSize(scale));
	/* -----------------------------------------------------------
         Check the value of the displacement. If it is outside
      the range of a single byte then a full format extension
      word must be used to represent the addressing. The full
      format mode is only supported in 68020 and later
      processors.
	----------------------------------------------------------- */
	opsize = 2;
	if (exp)
		val = expeval(exp, NULL);
	else {
		val.value = 0;
		val.fForcedSize = FALSE;
		val.size = 'B';
	}
	/* -----------------------------------------------------------
         If the base register is the program counter then
		 subtract off the address of the program counter. This
		 works like a branch
	------------------------------------------------------------ */
	if (((OpWord & 070) == 070) && !bs)
		if (val.fLabel)
			val.value -= PrjPC;

	if (gProcessor & PL_01)
	{
		if (val.value < -128 || val.value > 127 || (val.fForcedSize && val.size != 'B'))
			err(NULL, E_DISPLACEMENT, val.value);
		wordop[1] |= IFIBit(0);     // Set brief format extension word
		wordop[1] |= (int)IDispBits(val.value);
		return;
	}

	// We're not processing memory indirect modes here
	wordop[1] |= IIISBits(0);     // IIISBits(iis) ??? indirect/indexing
	/* -----------------------------------------------------------
			If base or index suppression is requested then we
		must use full extension word format. Otherwise the
		format used depends on the displacement value.
	----------------------------------------------------------- */
	if (!(is || bs))
	{
		// can we use 8 bit displacement ?
		if (val.value >= -128 && val.value <= 127 || (val.fForcedSize && val.size == 'B'))
		{
			val.value &= 0xff;
			wordop[1] |= IFIBit(0);     // Set brief format extension word
			wordop[1] |= (int)IDispBits(val.value);
			return;
		}
	}
	// must use full format
	wordop[1] |= IFIBit(1);       // Set full format extension word bit
	wordop[1] |= IISBit(is);
	wordop[1] |= IBSBit(bs);
	wordop[1] |= IBDBits(BdSize(&val));
}


/* ---------------------------------------------------------------
   Description :
		Determines if the passed string represents an index
	register. If it does represent an index then the string
	is parsed apart into it's components.

   Returns :
--------------------------------------------------------------- */

static int IsNdxReg(
	char *str,
	char *ad,
	char *reg,
	char *sz,
	long *scale)
{
	char ScaleStr[80];

	if (strmat(str, " %c%c.%c * %s", ad, reg, sz, ScaleStr))
		*scale = expeval(ScaleStr, NULL).value;
	else if (strmat(str, " %c%c * %s", ad, reg, ScaleStr)) {
		*sz = 'L';
		*scale = expeval(ScaleStr, NULL).value;
	}
	else if (strmat(str, " %c%c.%c ", ad, reg, sz))
		*scale = 1;
	else if (strmat(str, " %c%c ", ad, reg)) {
		*scale = 1;
		*sz = 'L';
	}
	else
		return (FALSE);
   *ad = (char)toupper(*ad);
   *sz = (char)toupper(*sz);
   if (*ad == 'S' && toupper(*reg) == 'P') {
      *ad = 'A';
      *reg = '7';
   }
   if (*reg >= '0' && *reg <= '7' && (*ad == 'A' || *ad == 'D'))
      return (TRUE);
   return (FALSE);
}


/* ---------------------------------------------------------------
   Description :
		Determines if the passed string represents a suppressed
	index register. If it does represent an index then the
	string is parsed apart into it's components. Just in case
	someone wants to specify specific index register and
	scaling, perhaps for self modifying code.

   Returns :
--------------------------------------------------------------- */

static int IsZNdxReg(
	char *str,
	char *ad,
	char *reg,
	char *sz,
	long *scale)
{
	char ScaleStr[80];

	if (strimat(str, " Z%c%c.%c * %s", ad, reg, sz, ScaleStr))
		*scale = expeval(ScaleStr, NULL).value;
	else if (strimat(str, " Z%c%c * %s", ad, reg, ScaleStr)) {
		*sz = 'L';
		*scale = expeval(ScaleStr, NULL).value;
	}
	else if (strimat(str, " Z%c%c.%c ", ad, reg, sz))
		*scale = 1;
	else if (strimat(str, " Z%c%c ", ad, reg)) {
		*scale = 1;
		*sz = 'L';	// default size
	}
	else
		return (FALSE);
   *ad = (char)toupper(*ad);
   *sz = (char)toupper(*sz);
   if (*ad == 'S' && toupper(*reg) == 'P') {
      *ad = 'A';
      *reg = '7';
   }
   if (*reg >= '0' && *reg <= '7' && (*ad == 'A' || *ad == 'D'))
      return (TRUE);
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
----------------------------------------------------------------------------- */

static int PCRel(char *exp)
{
	SValue val;

	OpWord = 072;
	val = expeval(exp,NULL);
	if (val.fLabel)
		val.value -= PrjPC;			// Like a branch
	if (val.value < -32768 || val.value > 32767)
	{
		if (gProcessor & PL_01)
			Err(E_DISPLACEMENT, val.value);
		else
		{
			OpWord = 073;
			BldIWord(exp, FALSE, TRUE, 'A', 0, 'L', 1);
			return AM_PC_NDX;
		}
	}
	wordop[1] = (int)(val.value & 0xffff);
	opsize = 2;
	return AM_PC_REL;
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is the program counter.

   Returns :
      TRUE if string is the program counter, otherwise FALSE.
----------------------------------------------------------------------------- */

static int IsPCReg(char *str)
{
	while (isspace(*str)) str++;
	if (toupper(*str) != 'P')
		return (FALSE);
	str++;
	if (toupper(*str) != 'C')
		return (FALSE);
	str++;
	if (!IsIdentChar(*str))
        return (TRUE);
	return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is a suppressed program counter.

   Returns :
      TRUE if string is suppressed program counter, otherwise FALSE.
----------------------------------------------------------------------------- */

static int IsZPCReg(char *str)
{
	while (isspace(*str)) str++;
	if (toupper(*str) != 'Z')
		return (FALSE);
	str++;
	if (toupper(*str) != 'P')
		return (FALSE);
	str++;
	if (toupper(*str) != 'C')
		return (FALSE);
	str++;
	if (!IsIdentChar(*str))
        return (TRUE);
	return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is an address register.

   Returns :
      TRUE if string is address register, otherwise FALSE.
----------------------------------------------------------------------------- */

int IsAReg(char *str, int *reg)
{
   char c1, c2;
   *reg = 0;
   while (isspace(*str)) str++;
   c1 = toupper(*str);
   if (c1 != 'A' && c1 != 'S')
      return (FALSE);
   str++;
   c2 = toupper(*str);
   
   if ((c1 == 'A' && c2 >= '0' && c2 <= '7') || (c1 == 'S' && c2 == 'P'))
   {
	   // To ensure it's not actually an index register, make sure there's
	   // nothing else in the string.
      str++;
		while (isspace(*str)) str++;
		if (*str != '\0')
			return FALSE;
         if (c2 == 'P')
            *reg = 7;
         else
            *reg = (*(str-1)) & 7;
         return (TRUE);
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is a suppressed address register (used for
	indexed modes).

   Returns :
      TRUE if string is address register, otherwise FALSE.
----------------------------------------------------------------------------- */

int IsZAReg(char *str, int *reg)
{
   char c1, c2, c3;
   *reg = 0;
   while (isspace(*str)) str++;
   c1 = toupper(*str);
   if (c1 != 'Z')
      return (FALSE);
   str++;
   c2 = toupper(*str);
   if (c2 != 'A' && c2 != 'S')
	   return FALSE;
   str++;
   c3 = toupper(*str);
   
   if ((c2 == 'A' && c3 >= '0' && c3 <= '7') || (c2 == 'S' && c3 == 'P'))
   {
	   // To ensure it's not actually an index register, make sure there's
	   // nothing else in the string.
      str++;
		while (isspace(*str)) str++;
		if (*str != '\0')
			return FALSE;
        if (c3 == 'P')
            *reg = 7;
         else
            *reg = (*(str-1)) & 7;
         return (TRUE);
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is a data register.

   Returns :
      TRUE if string is data register, otherwise FALSE.
----------------------------------------------------------------------------- */

int IsDReg(char *str, int *reg)
{
   *reg = 0;
   while (isspace(*str)) str++;
   if (toupper(*str) != 'D')
      return (FALSE);
   str++;
   if (*str >= '0' && *str <= '7')
   {
      str++;
      if (!IsIdentChar(*str))
      {
         *reg = (*(str-1)) & 7;
         return (TRUE);
      }
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is a suppressed data register.

   Returns :
      TRUE if string is data register, otherwise FALSE.
----------------------------------------------------------------------------- */

int IsZDReg(char *str, int *reg)
{
   *reg = 0;
   while (isspace(*str)) str++;
   if (toupper(*str) != 'Z')
      return (FALSE);
   str++;
   if (toupper(*str) != 'D')
      return (FALSE);
   str++;
   if (*str >= '0' && *str <= '7')
   {
      str++;
      if (!IsIdentChar(*str))
      {
         *reg = (*(str-1)) & 7;
         return (TRUE);
      }
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Determines if string is a floating point register.

   Returns :
      TRUE if string is floating point register, otherwise FALSE.
----------------------------------------------------------------------------- */

int IsFPReg(char *str, int *reg)
{
   *reg = 0;
   while (isspace(*str)) str++;
   if (toupper(*str) != 'F')
      return (FALSE);
   str++;
	if (toupper(*str) != 'P')
		return FALSE;
   str++;
   if (*str >= '0' && *str <= '7')
   {
      str++;
      if (!IsIdentChar(*str))
      {
         *reg = (*(str-1)) & 7;
         return (TRUE);
      }
   }
   return (FALSE);
}


/* ---------------------------------------------------------------
   IsFPRegPair(str, reg1, reg2);
   char *str;
   int *reg1, *reg2;

	Figures out if the string represents a register pair.
--------------------------------------------------------------- */
int IsFPRegPair(char *str, int *reg1, int *reg2)
{
	char str1[80], str2[80];
	int r1, r2;
	__int8 f1 = FALSE, f2 = FALSE;

	*reg1 = *reg2 = 0;
	if (strmat(str, " %s: %s", str1, str2))
	{
		f1 = IsFPReg(str1, &r1);
		f2 = IsFPReg(str2, &r2);
		*reg1 = r1;
		*reg2 = r2;
		return (f1 && f2) ? TRUE : FALSE;
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   IsRegPair(str, reg1, reg2);
   char *str;
   int *reg1, *reg2;

	Figures out if the string represents a register pair.
	Register values return 0 - 7 for data registers,
	8 to 15 for address registers.
--------------------------------------------------------------- */
int IsRegPair(char *str, int *reg1, int *reg2)
{
	char str1[80], str2[80];
	int r1, r2;
	__int8 f1 = FALSE, f2 = FALSE;

	*reg1 = *reg2 = 0;
	if (strmat(str, " %s: %s", str1, str2))
	{
		f1 = IsAReg(str1, &r1);
		if (f1)
			r1 |= 8;
		else
			f1 = IsDReg(str1, &r1);

		f2 = IsAReg(str2, &r2);
		if (f2)
			r2 |= 8;
		else
			f2 = IsDReg(str2, &r2);

		*reg1 = r1;
		*reg2 = r2;
		return (f1 && f2) ? TRUE : FALSE;
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   IsDRegPair(str, reg1, reg2);
   char *str;
   int *reg1, *reg2;

	Figures out if the string represents a data register pair.
--------------------------------------------------------------- */
int IsDRegPair(char *str, int *r1, int *r2)
{
	if (IsRegPair(str, r1, r2))
	{
		if (*r1 < 8 && *r2 < 8)
			return TRUE;
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   IsRegIndPair(str, reg1, reg2);
   char *str;
   int *reg1, *reg2;

	Figures out if the string represents a register indirect
	pair.
	Register values return 0 - 7 for data registers,
	8 to 15 for address registers.
--------------------------------------------------------------- */
int IsRegIndPair(char *str, int *reg1, int *reg2)
{
	char str1[80], str2[80];
	int r1, r2;
	__int8 f1 = FALSE, f2 = FALSE;

	*reg1 = *reg2 = 0;
	if (strmat(str, " ( %s) : ( %s) ", str1, str2))
	{
		f1 = IsAReg(str1, &r1);
		if (f1)
			r1 |= 8;
		else
			f1 = IsDReg(str1, &r1);

		f2 = IsAReg(str2, &r2);
		if (f2)
			r2 |= 8;
		else
			f2 = IsDReg(str2, &r2);

		*reg1 = r1;
		*reg2 = r2;
		return (f1 && f2) ? TRUE : FALSE;
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   Description :
		Checks for various components of memory indirect
	operands. Sets bits in opwords according to what it finds,
	but doesn't turn off bits if something is not found.

   Returns :
--------------------------------------------------------------- */

static int Chk(char *str, int mask) {
	SValue val;
	int reg;
	char ad, regch, sz;
	long scale;

	/* ------------------------------
         Check for base register.
	------------------------------ */
	if (mask & M_BR) {
		if (IsAReg(str, &reg)) {
			OpWord = 060 | reg;
			mask = M_BR;
			wordop[1] &= ~IBSBit(TRUE);
			goto chk_exit;
		}
		else if (IsPCReg(str)) {
			OpWord = 073;
			mask = M_BR;
			wordop[1] &= ~IBSBit(TRUE);
			goto chk_exit;
		}
		// Check for specific suppressed base register, this is
		// needed in case there is a desire to indicate a specific
		// base register. The only reason I can think of for doing
		// this is self modifying code, yuck!
		else if (IsZAReg(str, &reg)) {
			OpWord = 060 | reg;
			mask = M_BR;
			goto chk_exit;
		}
		else if (IsZPCReg(str)) {
			OpWord = 073;
			mask = M_BR;
			goto chk_exit;
		}
		else
			mask &= ~M_BR;
	}
	/* -------------------------------
         Check for index register.
	------------------------------- */
	if (mask & M_XN) {
		if (IsNdxReg(str, &ad, &regch, &sz, &scale)) {
			wordop[1] &= ~IADBit(1);
			wordop[1] &= ~IWLBit(1);
			wordop[1] &= ~IRegBits(7);
		    wordop[1] &= ~IScaleBits(3);
			wordop[1] |= IADBit((tolower(ad) == 'a') ? 1 : 0);	// Set index register type
			wordop[1] |= IWLBit((tolower(sz) == 'l') ? 1 : 0);	// Set index register size
			wordop[1] |= IRegBits(regch);
		    wordop[1] |= IScaleBits(ScaleSize(scale));
			mask = M_XN;
			wordop[1] &= ~IISBit(TRUE);
			goto chk_exit;
		}
		else if (IsZNdxReg(str, &ad, &regch, &sz, &scale)) {
			wordop[1] &= ~IADBit(1);
			wordop[1] &= ~IWLBit(1);
			wordop[1] &= ~IRegBits(7);
		    wordop[1] &= ~IScaleBits(3);
			wordop[1] |= IADBit((tolower(ad) == 'a') ? 1 : 0);	// Set index register type
			wordop[1] |= IWLBit((tolower(sz) == 'l') ? 1 : 0);	// Set index register size
			wordop[1] |= IRegBits(regch);
		    wordop[1] |= IScaleBits(ScaleSize(scale));
			mask = M_XN;
			goto chk_exit;
		}
		else
			mask &= ~M_XN;
	}
	/* -----------------------------------------------------------
			Check for displacement. Note no need to clear other
		bits of mask as they will be cleared above.
	----------------------------------------------------------- */
	if (mask & (M_BD | M_OD)) {
		val = expeval(str,NULL);
		if (mask & M_BD)
		{
			if (val.fLabel && OpWord == 073)
				val.value -= PrjPC;			// Like a branch
			wordop[1] &= ~IBDBits(3);
			wordop[1] |= IBDBits(BdSize(&val));
		}
		else
		{
			wordop[1] &= ~IIISBits(7);
			wordop[1] |= IIISBits(BdSize(&val));
		}
	}
chk_exit:
	mask &= 0xf;
	if (!mask)
		err(NULL, E_INVMIOP, str);
	return (mask);
}


/* ---------------------------------------------------------------
   MemIndir(op);
   char *op;
		
		Computes operand code for memory indirect modes. There
	are eight basic patterns derived from 20 possible address
	mode combinations.

      Mode              Pattern

      ([bd,An,Xn],od)   ( [ %s, %s, %s] , %s)
      ([bd,An],Xn,od)   ( [ %s, %s] , %s, %s)
      ([bd,An,Xn])      ( [ %s, %s, %s] )
      ([bd,An],Xn)      ( [ %s, %s] , %s)
      ([bd,An],od)
      ([bd,Xn],od)
      ([An,Xn],od)
      ([bd],Xn,od)      ( [ %s], %s, %s)
      ([An],Xn,od)
      ([bd,An])         ( [ %s, %s] )
      ([bd,Xn])
      ([An,Xn])
      ([bd],Xn)         ( [ %s], %s)
      ([bd],od)
      ([An],Xn)
      ([An],od)
      ([Xn],od)
      ([bd])            ( [ %s] )
      ([An])
      ([Xn])

   Changes
           Author      : R. Finch
           Date        : 92/09/28
           Version     :
           Description : new module

--------------------------------------------------------------- */

static void MemIndir(char *op)
{
   char Str[4][80];
   int mask;

	/* -----------------------------------------------------------
         Set bits for memory indirect mode. Start out with all
		components turned off.
	----------------------------------------------------------- */
	OpWord = 060;
	wordop[1] = IFIBit(TRUE);
	wordop[1] |= IBSBit(TRUE);
	wordop[1] |= IISBit(TRUE);
	wordop[1] |= IBDBits(BdSize(NULL)); // no base displacement
	wordop[1] |= IIISBits(BdSize(NULL));// no outer displacement
	wordop[1] |= IADBit(0);				// default index register type to data
	wordop[1] |= IWLBit(1);				// default index register size to long
	wordop[1] |= IRegBits(0);			// d0
	wordop[1] |= IScaleBits(ScaleSize(1));
	opsize = 2;

	// preindexed everything

	if (strmat(op, " ( [ %s, %s, %s] , %s)", Str[0], Str[1], Str[2], Str[3])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		Chk(Str[3], M_OD);
		return;
	}
	if (strmat(op, " [ [ %s, %s, %s] , %s]", Str[0], Str[1], Str[2], Str[3])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		Chk(Str[3], M_OD);
		return;
	}

	// post indexed everthing

	if (strmat(op, " ( [ %s, %s] , %s, %s)", Str[0], Str[1], Str[2], Str[3])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		Chk(Str[3], M_OD);
		// if index is suppressed, then don't set post index bit
		if (!(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit
		return;
	}
	if (strmat(op, " [ [ %s, %s] , %s, %s]", Str[0], Str[1], Str[2], Str[3])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		Chk(Str[3], M_OD);
		// if index is suppressed, then don't set post index bit
		if (!(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit
		return;
	}

	// preindexed null outer displacement

	if (strmat(op, " ( [ %s, %s, %s] )", Str[0], Str[1], Str[2])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		return;
	}
	if (strmat(op, " [ [ %s, %s, %s] ]", Str[0], Str[1], Str[2])) {
		Chk(Str[0], M_BD);
		Chk(Str[1], M_BR);
		Chk(Str[2], M_XN);
		return;
	}

	if (strmat(op, " ( [ %s, %s], %s)", Str[0], Str[1], Str[2])) {
		mask = Chk(Str[0], M_BD | M_BR) & M_BR;            // If M_BR then don't check in next step
		mask = Chk(Str[1], (M_BR & ~mask) | M_XN) & M_XN;  // If M_XN then don't check in next step
		mask = Chk(Str[2], (M_XN & ~mask) | M_OD);
		if ((mask & M_XN) && !(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit
		return;
	}

	if (strmat(op, " [ [ %s, %s], %s]", Str[0], Str[1], Str[2])) {
		mask = Chk(Str[0], M_BD | M_BR) & M_BR;            // If M_BR then don't check in next step
		mask = Chk(Str[1], (M_BR & ~mask) | M_XN) & M_XN;  // If M_XN then don't check in next step
		mask = Chk(Str[2], (M_XN & ~mask) | M_OD);
		if ((mask & M_XN) && !(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit
		return;
	}

	if (strmat(op, " ( [ %s, %s] )", Str[0], Str[1])) {
		mask = Chk(Str[0], M_BD | M_BR) & M_BR;   // bd or An
		mask = Chk(Str[1], (M_BR & ~mask) | M_XN); // An or Xn
		return;
	}
	if (strmat(op, " [ [ %s, %s] ]", Str[0], Str[1])) {
		mask = Chk(Str[0], M_BD | M_BR) & M_BR;   // bd or An
		mask = Chk(Str[1], (M_BR & ~mask) | M_XN); // An or Xn
		return;
	}

	if (strmat(op, " ( [ %s] , %s, %s)", Str[0], Str[1], Str[2])) {
		mask = Chk(Str[0], M_BD | M_BR); // bd, An
		Chk(Str[1], M_XN);                  // Xn - note no confusion here
		Chk(Str[2], M_OD);                  // od
		if (!(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);       // set post index mode bit
		return;
	}
	if (strmat(op, " [ [ %s] , %s, %s]", Str[0], Str[1], Str[2])) {
		mask = Chk(Str[0], M_BD | M_BR); // bd, An
		Chk(Str[1], M_XN);                  // Xn - note no confusion here
		Chk(Str[2], M_OD);                  // od
		if (!(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);       // set post index mode bit
		return;
	}

	if (strmat(op, " ( [ %s] , %s)", Str[0], Str[1])) {
		mask = Chk(Str[0], M_XN | M_BR | M_BD);  // bd, An, or Xn
		mask = Chk(Str[1], M_OD | (M_XN & ~mask));	// Xn, od
		if ((mask & M_XN) && !(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit - no outer displacement
		return;
	}
	if (strmat(op, " [ [ %s] , %s]", Str[0], Str[1])) {
		mask = Chk(Str[0], M_XN | M_BR | M_BD);  // bd, An, or Xn
		mask = Chk(Str[1], M_OD | (M_XN & ~mask));	// Xn, od
		if ((mask & M_XN) && !(wordop[1] & 0x40))
			wordop[1] |= IIISBits(4);  // set post index mode bit - no outer displacement
		return;
	}

	if (strmat(op, " ( [ %s] )", Str[0])) {
		mask = Chk(Str[0], M_XN | M_BR | M_BD);   // bd, An, or Xn
		return;
	}
	if (strmat(op, " [ [ %s] ]", Str[0])) {
		mask = Chk(Str[0], M_XN | M_BR | M_BD);   // bd, An, or Xn
		return;
	}
}


/* ---------------------------------------------------------------
   optype(op);
   char *op

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

   Dn             data register
   An             address reg
   (An)           addr reg indirect: [an]
   (An)+          addr reg indirect postincrement
   -(An)          addr reg indirect predecrement
   (d16, An)      addr reg indirect displacement
   (d8, An, Xn.s) addr reg indirect with displacement and index
   (abs).w        absolute short
   (abs).l        absolute long
   (d16, PC)      pc relative
   (d8, PC, Xn.s) pc relative indexed
   #x             immediate


   (%s, %s) could be

   (d16, An)
   (An, Xn.s)
   (d16, PC)
   (PC, Xn.s)

		Addressing modes involving the program counter are
	identical to the modes involving an address register except
	that the mode field and register fields are set
	differently.

		This is a prime example of spaghetti code. It could be
	reworked to use subroutines, however the code would be
	larger and slower.
--------------------------------------------------------------- */

int OpType(char *op, int *pat, long ppc)
{
	SValue val;
	int i, reg, am = 0, reg2, reg1;
	int xx;
	char
		ad,	// address / data flag
		regch,
		exp[81], ch, sz,
        exp1[80],
        RegStr1[40];
	CAsmBuf eb, ob;
	long scale;
	char *strbf;
	__int8 fIS, fBS;

	PrjPC = ppc;
	eb.set(exp, sizeof(exp));
	ob.set(op+1, strlen(op+1));
	errtype = TRUE;
	opsize = 1;
	OpWord = 0;
	for (i = 0; i < 20; i++)
		wordop[i] = 0;

	// Look for k-factor ?
	if (gOpType.k_factor)
	{
		gOpType.k_IsReg = FALSE;
		for (xx = 0; op[xx]; xx++)
		{
			if (op[xx] == '{')
			{
				xx++;
				while(isspace(op[xx])) xx++;
				if (IsDReg(&op[xx], &reg))
				{
					gOpType.k_IsReg = TRUE;
					gOpType.k_reg = reg;
					break;
				}
				if (op[xx] == '#')
					xx++;
				gOpType.k_imm = expeval(&op[xx],NULL).value;
				break;
			}
		}
		// If we didn't find a k-factor
		if (!op[xx])
			gOpType.k_factor = FALSE;
	}

	else
	{
		// First we check for bit field specifications
		for (xx = 0; op[xx]; xx++)
		{
			if (op[xx] == '{')
			{
				// Parse the bitfield
				strbf = &op[xx];
				if (strmat(strbf, "{ %s: %s} ", exp, exp1))
				{
					int bfval;
					if (IsDReg(exp, &reg))
						wordop[1] = 0x800 | (reg << 6);
					else
					{
						bfval = expeval((exp[0] == '#') ? &exp[1] : exp, NULL).value;
						if (bfval < 0 || bfval > 31)
							err(NULL, E_IMMTRUNC, bfval);
						wordop[1] = ((bfval & 31) << 6);
					}
					if (IsDReg(exp1, &reg))
						wordop[1] |= 0x20 | reg;
					else
					{
						bfval = expeval((exp1[0] == '#') ? &exp1[1] : exp1, NULL).value;
						if (bfval < 0 || bfval > 31)
							err(NULL, E_IMMTRUNC, bfval);
						wordop[1] |= bfval & 31;
					}
					opsize = 2;
					am = AM_BITFLD;
				}
				else
					break;	// extra junk in ea
			}
		}
	}


	*pat = 0;

	// Data register direct
	if (IsDReg(op, &reg))
	{
		*pat = reg;
		return(am |= AM_DR);
	}

	// Address register direct
	if (IsAReg(op, &reg))
	{
		*pat = 010 | reg;    // 010 octal
		return (am | AM_AR);
	}

	// Floating point register direct
	if (IsFPReg(op, &reg))
	{
		*pat = reg;
		return (am | AM_FPR);
	}

	// Memory indirect
	else if (strmat(op, " ( ["))
	{
	   if (gProcessor & (PL_01 | PL_CPU32))
		   Err(E_INVOPMODE, op);
		MemIndir(op);
		*pat |= OpWord;
		if (OpWord == 073)
			return (am | AM_MEM_PC);
		return (am | AM_MEM);
	}

	// Memory indirect
	else if (strmat(op, " [ ["))
	{
	   if (gProcessor & (PL_01 | PL_CPU32))
		   Err(E_INVOPMODE, op);
		MemIndir(op);
		*pat |= OpWord;
		if (OpWord == 073)
			return (am | AM_MEM_PC);
		return (am | AM_MEM);
	}

	// Address register indirect - post incrementing
	if(strmat(op, " ( %s) + ", exp))
	{
ar_indirect_post:
		if (IsAReg(exp, &reg))
		{
			*pat = 030 | reg;   // note octal 030
			return (am | AM_AR_POST);
		}
		Err(E_INVOPERAND, op);
		return (am | AM_AR_POST);
	}

	// Address register indirect - post incrementing
	if(strmat(op, " [ %s++ ] ", exp))
		goto ar_indirect_post;

	// Address register indirect - post incrementing
	if(strmat(op, " [ %s] ++ ", exp))
		goto ar_indirect_post;

	// Address register indirect  - pre decrementing
	if(strmat(op, " - ( %s) ", exp))
	{
ar_indirect_pre:
		if (IsAReg(exp, &reg))
		{
			*pat |= 040 | reg;   // note octal 040
			return (am | AM_AR_PRE);
		}
		Err(E_INVOPERAND, op);
		return (am | AM_AR_PRE);
	}

	// Address register indirect  - pre decrementing
	if(strmat(op, " [ --%s] ", exp))
		goto ar_indirect_pre;

	// Address register indirect  - pre decrementing
	if(strmat(op, " -- [ %s] ", exp))
		goto ar_indirect_pre;

	// Immediate
	if(op[0] == '#')
	{
		*pat |= 074;
		val = ob.expeval(NULL);
		wordop[1] = (int) ((val.value >> 48) & 0xffff);
		wordop[2] = (int) ((val.value >> 32) & 0xffff);
		wordop[3] = (int) ((val.value >> 16) & 0xffff);
		wordop[4] = (int) (val.value & 0xffff);
		opsize = 5;
		return (am | AM_IMMEDIATE);
	}

	// Absolute short/long
	if (strmat(op," ( %s).%c ", exp, &ch))
	{
abs_am:
		ch = (char)toupper(ch);
		val = eb.expeval(NULL);
		if (ch == 'L')
		{
abs_long:
			*pat |= 071;
			if (giProcessor & PL_FT) {
				wordop[1] = (int) val.value;
				wordop[2] = (int) (val.value >> 16);
			}
			else {
				wordop[1] = (int) (val.value >> 16);
				wordop[2] = (int) val.value;
			}
			opsize = 3;
			return (am | AM_ABS_LONG);
		}
		else if (ch == 'W')
		{
abs_short:
			*pat |= 070;
			wordop[1] = (int) val.value;
			opsize = 2;
			return (am | AM_ABS_SHORT);
		}
		Err(E_ONLYWL);
		return (am | AM_ABS_LONG);
	}

	/* -----------------------------------------------------------
			This matches generic base displacement mode.
			No flexibility here must be in order
			(base displacement, An | PC, Xn)
	----------------------------------------------------------- */
	if (strmat(op, " ( %s, %s, %s) ", exp, RegStr1, exp1))
	{
jmp1:
		fIS = fBS = FALSE;
		// Address register indirect indexed with displacement
		// or base displacment mode depending on extension
		// word required
		OpWord = 060 | reg;	// default for errors
		if (IsAReg(RegStr1, &reg))
		{
			OpWord = 060 | reg;
			*pat |= 060 | reg;
			am |= AM_AR_NDX;
		}
		else if (IsZAReg(RegStr1, &reg))
		{
			OpWord = 060 | reg;
			*pat |= 060 | reg;
			am |= AM_AR_NDX;
			fBS = TRUE;
		}
		// Program counter relative with displacement and index
		else if (IsPCReg(RegStr1))
		{
			OpWord = 073;
			*pat |= 073;
			am |= AM_PC_NDX;
		}
		else if (IsZPCReg(RegStr1))
		{
			OpWord = 073;
			*pat |= 073;
			am |= AM_PC_NDX;
			fBS = TRUE;
		}
		else
		{
			Err(E_INVREG, RegStr1);
			am |= AM_AR_NDX;
		}
		if (IsNdxReg(exp1, &ad, &regch, &sz, &scale))
			BldIWord(exp, fBS, 0, ad, regch, sz, scale);
		else if (IsZNdxReg(exp1, &ad, &regch, &sz, &scale))
			BldIWord(exp, fBS, 1, ad, regch, sz, scale);
		else {
			err(NULL, E_INVREG, exp1);
			am |= AM_AR_NDX;
		}
		return (am);
	}

	// The following match must be before %s[%s+%s]
	if(strmat(op, " [ %s+ %s] ", exp, exp1))
		goto reg_indirect_disp;

	if (strmat(op, " %s[ %s+ %s] ", exp, RegStr1, exp1))
		goto jmp1;

	if (strmat(op, " [ %s+ %s].%s", RegStr1, exp1, exp))
		goto jmp1;

	/* -----------------------------------------------------------
			There are numerous possibilities for this scan
		pattern. Note modes have to be checked in a specific
		order !!!

		Could be 
			two registers
			1 (An, Xn)	assume second register is an index
			2 (PC, Xn)
			3 (disp, An)
			4 (disp, PC)
			5 (disp, Xn)	suppress base register
	----------------------------------------------------------- */
	if(strmat(op, " ( %s, %s) ", exp, exp1))
	{
reg_indirect_disp:
		fBS = FALSE;
		if (IsZAReg(exp, &reg1))
			fBS = TRUE;
		// Address register indirect indexed with zero displacement
		if (fBS || IsAReg(exp, &reg2))
		{
			reg = (fBS ? reg1 : reg2);
			OpWord = 060 | RegFld(reg);
			*pat = 060 | RegFld(reg);
			am |= AM_AR_NDX;
rid1:
			// 8 (An, Xn)
			if (IsNdxReg(exp1, &ad, &regch, &sz, &scale))
				BldIWord(NULL, fBS, FALSE, ad, regch, sz, scale);
			else if (IsZNdxReg(exp1, &ad, &regch, &sz, &scale))
				BldIWord(NULL, fBS, TRUE, ad, regch, sz, scale);
			else
			{
				BldIWord(NULL, fBS, FALSE, 'A', 0, 'L', 1);
				Err(E_INVOPERAND, op);
			}
			return (am | AM_AR_NDX);
		}

		// Program counter relative with zero displacement and index
		if (IsZPCReg(exp))
			fBS = TRUE;
		if (fBS || IsPCReg(exp))
		{
			OpWord = 073;
			*pat = 073;
			am |= AM_PC_NDX;
			goto rid1;
		}

		// Register indirect - displacement
		// (disp, An)
		if (IsZAReg(exp1, &reg1))
			fBS = TRUE;
		if (fBS || IsAReg(exp1, &reg))
		{
			reg = (fBS ? reg1 : reg);
			// (disp, An)
			val = eb.expeval(NULL);
			*pat |= reg;
			// do we have simple (An)
			if (val.value == 0)
	            goto ar_indirect1;

			if (val.value >= -32768 && val.value < 32768 && !fBS)
			{
				*pat |= 050;
				wordop[1] = (int) (val.value & 0xffff);
				opsize = 2;
				return (am | AM_AR_DISP);
			}
			else
			{
				if ((val.value < -32768 || val.value > 32767) && (gProcessor & PL_01))
				{
					*pat |= 050;
					wordop[1] = (int) (val.value & 0xffff);
					opsize = 2;
					Err(E_DISPLACEMENT, val.value);
					return (am | AM_AR_DISP);
				}
				else
				{
					OpWord = 060;
					*pat |= 060;
					BldIWord(exp, fBS, TRUE, 'A', '0', 'L', 1);
					return (am | AM_AR_NDX);
				}
			}
			// Shouldn't get here
			Err(E_INVOPERAND, op);
			*pat |= 050;
			opsize = 2;
			return (am | AM_AR_DISP);
		}

		// Program counter relative with displacement
		if (IsZPCReg(exp1))
			fBS = TRUE;

		if (fBS || IsPCReg(exp1))
		{
			val = eb.expeval(NULL);
			if (val.fLabel)
				val.value -= PrjPC;			// Like a branch
			if (val.value >= -32768 && val.value <= 32767 && !fBS)
			{
				*pat = 072;
				wordop[1] = (int)(val.value & 0xffff);
				opsize = 2;
				return (am | AM_PC_REL);
			}
			else
			{
				if ((val.value < -32768 || val.value > 32767) && (gProcessor & PL_01))
				{
					*pat = 072;
					wordop[1] = (int) (val.value & 0xffff);
					opsize = 2;
					Err(E_DISPLACEMENT, val.value);
					return (am | AM_PC_REL);
				}
				else
				{
					OpWord = 073;
					*pat = 073;
					BldIWord(exp, fBS, TRUE, 'A', '0', 'L', 1);
					return (am | AM_PC_NDX);
				}
			}
			// Shouldn't get here
			Err(E_INVOPERAND, op);
			*pat = 072;
			opsize = 2;
			return (am | AM_PC_REL);
		}

		// Supressing base and index ? Then the only thing left
		// is the displacement which means we have absolute short
		// or long address mode
		if (IsZNdxReg(exp1, &ad, &regch, &sz, &scale)) {
			val = eb.expeval(NULL);
			if (val.value < -32768 || val.value > 32767)
				goto abs_long;
			else
				goto abs_short;
		}

		// index register indirect with displacement
		// (base suppressed)
		// (disp, Xn)

		if (IsNdxReg(exp1, &ad, &regch, &sz, &scale))
		{
			val = eb.expeval(NULL);
			if (gProcessor & PL_01)
			{
				Err(E_INVOPMODE, op);
				OpWord = 050 | RegFld(regch);
				*pat = 050 | RegFld(regch);
				wordop[1] = (int) (val.value & 0xffff);
				opsize = 2;
				return am | AM_AR_DISP;
			}
			OpWord = 060;
			*pat = OpWord;
			BldIWord(exp, TRUE, FALSE, ad, regch, sz, scale);
			return (am | AM_AR_NDX);
		}
		// Undetermineable mode
		// We know there were two components
		// Guess disp(An)
		else
		{
			*pat = 050;
			wordop[1] = 0xffff;
			opsize = 2;
			Err(E_INVOPERAND, op);
			return (am | AM_AR_DISP);
		}
	}

	// Register indirect - displacement third form
	if (strmat(op, "%s( %s, %s) ", exp, RegStr1, exp1))
		goto jmp1;

	// Address / PC / data register indirect
	if (strmat(op, " [ %s] ", exp))
	{
ar_indirect:
		if (IsAReg(exp, &reg))
		{
ar_indirect1:
			*pat |= 020 | reg;
			return (am | AM_AR_IND);
		}
		if (IsZAReg(exp, &reg))
		{
			OpWord = 060 | reg;
			*pat = OpWord;
			BldIWord(NULL, TRUE, TRUE, 'A', '0', 'L', 1);
			return (am | AM_AR_NDX);
		}
		// Program counter relative with zero displacement
		if (IsPCReg(exp))
		{
			am |= PCRel("0");
			*pat |= OpWord;
			return am;
		}
		if (IsZPCReg(exp))
		{
			OpWord = 073;
			*pat = 073;
			BldIWord(NULL, TRUE, TRUE, 'A', '0', 'L', 1);
			return (am | AM_PC_NDX);
		}
		// could be data register indirect
		if ((gProcessor & PL_01) == 0)
		{
			if (IsNdxReg(exp, &ad, &regch, &sz, &scale))
			{
				OpWord = 060;
				*pat |= OpWord;
				BldIWord(NULL, TRUE, FALSE, ad, regch, sz, scale);
			}
			else if (IsZNdxReg(exp, &ad, &regch, &sz, &scale))
			{
				OpWord = 060;
				*pat |= OpWord;
				BldIWord(NULL, TRUE, TRUE, ad, regch, sz, scale);
			}
			// assume base displacement
			else {
				// ****	ToDo: add *pat|=Opword for 
				*pat |= 060;
				BldIWord(exp, TRUE, TRUE, 'A', 0, 'L', 1);
			}
			return (am | AM_AR_NDX);
		}
		Err(E_INVOPERAND, op);
		return (am | AM_AR_IND);
	}

	// Register indirect - displacement
	if (strmat(op, "%s[ %s]", exp, exp1))
		goto reg_indirect_disp;

	// Register indirect - displacement - second form
	if (strmat(op, "[ %s].%s", exp1, exp))
		goto reg_indirect_disp;

	// Address / PC / data register indirect
	if (strmat(op, " ( %s) ", exp))
		goto ar_indirect;

   // Register indirect - displacement third form
   if (strmat(op, "%s( %s)", exp, exp1))
      goto reg_indirect_disp;
   
	// Absolute short/long 2
	if (strmat(op," %s.%c ", exp, &ch))
		goto abs_am;

	// Assume absolute 
	// This must be the last mode tested for since anything will
	// match
	val = eb.expeval(NULL);
	if (val.size == 'B' || val.size == 'W')
	{
		*pat |= 070;
		wordop[1] = (int) val.value;
		opsize = 2;
		return (am | AM_ABS_SHORT);
	}
	else
	{
		if (val.size != 'L') {
			if (val.size=='D' && ((val.value & 0xFFFFFFFF00000000LL) != 0))
				err(NULL, E_ONLYWL);
		}
		*pat |= 071;
		if (giProcessor & PL_FT) {
			wordop[1] = (int) val.value;
			wordop[2] = (int) (val.value >> 16);
		}
		else {
			wordop[1] = (int) (val.value >> 16);
			wordop[2] = (int) val.value;
		}
		opsize = 3;
		return (am | AM_ABS_LONG);
	}

ErrXit:
	// Unknown addressing mode
	Err(E_INVOPERAND, op);
	return (am | FALSE);
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
------------------------------------------------------------------- */

int GetOperands()
{
   int bcount = 0, ii, xx;
   char *sptr, *eptr, tt, ch;

//   printf("GetOperands\n");
   ii = 0;
   ibuf.skipSpacesLF();
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
                  Err(E_OPERANDS);
                  return (ii);
               }
               eptr = ibuf.Ptr() - 2;
               while (eptr > sptr && isspace(*eptr)) --eptr;
               eptr++;
               tt = *eptr;
               *eptr = '\0';
               gOperand[ii] = strdup(sptr);
               if (gOperand[ii] == NULL)
                  Err(E_MEMORY);
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
         Err(E_MEMORY);
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
   return (ii);
}

