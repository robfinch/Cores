#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "fwstr.h"
#include "fasm68.h"
#include "asmbuf.h"

/* -------------------------------------------------------------------
	Description :
		Expression parser. Evaluates simple expressions that result
	in long constant values. All function return long value.
------------------------------------------------------------------- */

#define isoctal(d)   (((d) >= '0') && ((d) < '8'))

union aval {
	float f;
	long l;
	double d;
	__int64 i;
};

static char GetSizeCh(char, char);

/* ---------------------------------------------------------------
	Description:
		This routine converts from the IEEE format to Fast-
	Floating-Point format. The compiler automatically uses
	IEEE format. There's alot of bit fiddling so it's in
	assembler.
--------------------------------------------------------------- */
unsigned __int32 cvtIEEEtoFFP(unsigned __int32 inval)
{
	unsigned __int32 outval;

	_asm {
		mov eax,inval
		rol eax,9		// move exponent to low order byte

		mov dl,80h
		xor al,dl		// convert from excess 127 to two's compl
		add al,al
		jo  ffpovf
		add al,5		// adjust excess 127 to 64 and set
						// mantissa high bit
		jo  exphi
		xor al,dl		// back to excess 64
		ror eax,1
		jmp done2
ffpovf:
		jnc ffpovlw
		cmp al,7ch
		je  ffpovfls
		cmp al,7eh
		jne ffptovf
ffpovfls:
		add al,85h	// excess 64 adjustment and mantissa high bit
		ror eax,1
		or	al,al
		jne done2
		jmp explo
ffptovf:
		and ax,0feffh
		or  eax,eax
		je  done2
		or  al,al
		je  denor
		// exponent too small for FFP format
explo:
		sub eax,eax
		jmp done2
		// denormalized number
denor:	
		sub eax,eax
		jmp done2
ffpovlw:
		cmp al,0feh
		jne exphi
		shr eax,8
		shr eax,1
		jne nan

inf:
		jc  inf1
		mov eax,0ffffff7fh
		jmp done2
inf1:
		mov eax,-1
		jmp done2
		// exponent too large for ffp
exphi:
		shl ax,8
		jc  exphi1
		mov eax,0ffffff7fh
		jmp done2
exphi1:
		mov	eax,-1
		jmp done2

nan:
		sub eax,eax
done2:
		mov outval,eax
	};
	return outval;
}


/* -------------------------------------------------------------------

	Description :
		This file contains routines for supporting #if directive.
	Note that macros are expanded before the if test is evaluated.
	This means we can count on there being only integer constants
	to evaluate.

		Order of precedence. All operators listed on the same line
	have the same precedence.

      numeric or character constant
      - (unary), !, ~, (),       // unary
      *, /, %, <<, >>            // multiplicative
      +, -, &, |, ^              // bitwise, additive
      &&,
      ||                         // boolean
      =, <, >, >=, <=, <>, !=    // relational

------------------------------------------------------------------- */

/* -------------------------------------------------------------------
   constant - we assume a constant, so let's see what kind it is.
      constants can be
         0x<digits>  hexidecimal constant
         0o<digits>  octal constant
         0<digits>   octal constant
         0b<digits>  binary constant
         0d<digits>  decimal constant
         '<character constant>'  as in 'a', 'b', ...
         '\<char code>'          as in '\n', '\r'


   Returns (long) - value
------------------------------------------------------------------- */

void CAsmBuf::Constant(SValue *val)
{
   const char *backcodes = { "abfnrtv0'\"\\" };
   const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   char *p;
   __int64 value = 0;
   char buf[5], *eptr,*ep2, *ep1;
   union aval fval;

   val->fForwardRef = FALSE;
   /* -----------------------------
      Check if numeric constant.
   ----------------------------- */
   if (isdigit(PeekCh()) || PeekCh()=='%')
   {
j1:
	   val->fLabel = FALSE;
       value = stouxl(Ptr(), &ep1);
	   fval.d = strtod(Ptr(), &ep2);
	   // whichever one got the most characters wins
	   if (ep2 > ep1) {
		   if (fpFormat == FP_FFP) {
			fval.f = (float)fval.d;	// convert to shorter format
			value = (__int64)cvtIEEEtoFFP(fval.l);
		   }
		else
			value = fval.i;
		eptr = ep2;
	   }
	   else
		   eptr = ep1;
      if (value >= -128 && value <= 127)
         val->size = 'B';
      else if (value >= -32768 && value <= 32767)
         val->size = 'W';
      else if (value >= (__int64)-2147483647-(__int64)1 && value <= (__int64)2147483648)
         val->size = 'L';
	  else
		  val->size = 'D';
      setptr(eptr);
      val->value = value;
      return;
   }

	/* --------------------------
		counter value ?
	-------------------------- */
	else if (PeekCh() == '$')
	{
		NextCh();
		if (IsIdentChar(PeekCh())) {
			unNextCh();
			goto j1;
		}
		value = Counter();
		val->size = 'L';
		val->value = value;
		val->fLabel = TRUE;
		return;
	}

   /* ----------------------------------
      Check for a character constant.
   ---------------------------------- */
   else if (PeekCh() == '\'')
   {
      NextCh();
      if (PeekCh() == '\\')
      {
         NextCh();
         p = (char *)strchr(backcodes, PeekCh());
         if (p)
            value = textequ[p - backcodes];
         else
         {
            // if an 'x' is seen then assume the following two
			 // characters are a hexidecimal constant specifying
			 // the character
            if (PeekCh() == 'x')
            {
               NextCh();
               strncpy(buf, Ptr(), 2);
               buf[2] = '\0';
               value = strtol(buf, &eptr, 16);
               setptr(Ptr() + strlen(buf));
            }
            // otherwise, if an octal digit is seen then assume the
            // following two characters are part of a three digit
            // octal number.
            else if(isoctal(PeekCh()))
            {
               strncpy(buf, Ptr(), 3);
               buf[3] = '\0';
               setptr(Ptr() + strlen(buf));
               value = strtol(buf, &eptr, 8);
            }
            else
               value = PeekCh();  // use character as-is
         }
      }
      else
         value = PeekCh();  // pick up regular character
      NextCh();
      if(PeekCh() != '\'')
      {
//         unNextCh();
         Err( E_QUOTE);
      }
	  else
		  NextCh();
      val->size = 'B';
      val->value = value;
	  val->fLabel = FALSE;
		return;
   }
   /* --------------------------------------------------------
      Not a number, prog loc, or escaped char, then what ?. 
   -------------------------------------------------------- */
   throw ExprErr(E_EXPR);
}


/* ----------------------------------------------------------------------------
   Description :
   Returns :
      1 if the string is a function, otherwise 0
---------------------------------------------------------------------------- */
static int isfunc(char *str)
{
   static char *flist = "defined~size~not~";
   char buf[100];

   strncpy(buf, str, sizeof(buf)-1);
   strcat(buf, "~");
   strlwr(buf);	// make case insensitive
   return (strstr(flist, buf) ? 1 : 0);
}


/* -------------------------------------------------------------------
   functions
      defined(x)  - returns 1 if 'x' is a symbol
      size(x)     - returns the size of the symbol
      not(x)      - returns ones complement of x
------------------------------------------------------------------- */

void CAsmBuf::Func(SValue *val, int ch)
{
   int LookForBracket = 0;
   int id;
   char *sptr, *eptr;
   char ch2;
   CSymbol ts, *pts = NULL;

	val->fLabel = FALSE;

   while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
   if (PeekCh() == '(')
      LookForBracket = 1;

   switch(ch)
   {
      case 'n':   // not
         Relational(val);
		 val->value = !val->value;
		 val->size = 'B';
         break;

      case 's':
         id = GetIdentifier(&sptr, &eptr, FALSE);
         if (!id)
            Err(E_SIZEOP);
         else
         {
            ch2 = *eptr;
            *eptr = '\0';
            ts.SetName(sptr);
            if (LocalSymTbl)
               pts = LocalSymTbl->find(&ts);
            if (pts == NULL)
               pts = SymbolTbl->find(&ts);
            if (pts == NULL) {
               Err(E_NOTDEFINED, sptr);
               val->value = 0;
            }
            else {
               switch(pts->Size())
               {
                  case 'B': val->value = 1; break;
                  case 'W': val->value = 2; break;
                  case 'L': val->value = 4; break;
                  default: val->value = 4; break;
               }
            }
            if (pts)
               if (pts->Defined() == 0 && pass > 1)
                  Err(E_NOTDEFINED, sptr);
            val->size = 'B';
            *eptr = ch2;
         }
         break;

      case 'd':
         id = GetIdentifier(&sptr, &eptr, FALSE);
         if (!id)
            Err(E_DEFINE);
         else
         {
            pts = NULL;
            ch2 = *eptr;
            *eptr = '\0';
            ts.SetName(sptr);
            if (LocalSymTbl)
               pts = LocalSymTbl->find(&ts);
            if (pts == NULL)
               pts = SymbolTbl->find(&ts);
            if (pts)
               val->value = 1;
            else
               val->value = 0;
            val->size = 'B';
            *eptr = ch2;
         }
         break;
   }

   while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
   if (LookForBracket)
      if (NextCh() != ')')
      {
         unNextCh();
         Err(E_PAREN);
      }
   return;
}


/* -------------------------------------------------------------------
   factor - a factor may be
	  factor.<size spec>
      not factor
      -factor
      !factor
      ~factor
      (relation)
      a number
      a symbol
      defined(<macro>)
------------------------------------------------------------------- */

void CAsmBuf::Factor(SValue *val)
{
   __int64 value = 0;
	 int valu;
   int LookForBracket = 0;
   int id;
   char ch, ch2;
   char *sptr, *eptr, sz;
   char buf[500];
   CSymbol ts, *pts;
	char localLabel = FALSE;

   val->fLabel = FALSE;
   val->fForcedSize = FALSE;
   val->fForwardRef = FALSE;
   skipSpacesLF();
   id = GetIdentifier(&sptr, &eptr, TRUE);
   setptr(eptr);
   if (id)
   {
      ch = *eptr;
      *eptr = '\0';
			printf(sptr);
			printf(" ");
			if (!stricmp(sptr, "REG") || !stricmp(sptr, "REGS")) {
				sz = 'L';
				*eptr = ch;
				value = IsRegList(sptr, &valu);
				goto exitpt3;
			}
      else if (isfunc(sptr))
      {
         *eptr = ch;
         Func(val, *sptr);
         goto exitpt2;
      }
      else
      {
         if (sptr[0]=='.')  // local label
            sprintf(buf, "%s%s", current_label, sptr);
         else
             strcpy(buf, sptr);
         pts = NULL;
         ts.SetName(buf);
         if (LocalSymTbl)
            pts = LocalSymTbl->find(&ts);
         if (pts == NULL)
            pts = SymbolTbl->find(&ts);
         if (pass > 1) {
            if (pts == NULL)
               Err(E_NOTDEFINED, sptr);
			else if (pts->Defined() == 0) {
				if (!pts->IsExtern())
					Err(E_NOTDEFINED, sptr);
			}
         }
		 lastsym = pts;
         value = (pts) ? pts->Value() : 0;
         sz = (pts) ? (char)pts->Size() : 'L';
		 val->fLabel = (pts) ? pts->IsLabel() : FALSE;
		 if (pts == NULL || pts->Defined() == 0)
			val->fForwardRef = TRUE;
         *eptr = ch;
      }
      goto exitpt;
   }

   switch (NextCh())
   {
      case '!':
         Factor(val);
         value = !val->value;
         sz = val->size;
		 val->fLabel = FALSE;
         break;
      case '-':
         Factor(val);
         value = -val->value;
         sz = val->size;
		 val->fLabel = FALSE;
         break;
      case '~':
         Factor(val);
         value = ~val->value;
         sz = val->size;
		 val->fLabel = FALSE;
         break;
      case '(':
         Relational(val);
         value = val->value;
         sz = val->size;
         if (NextCh() != ')')
         {
            unNextCh();
            Err(E_PAREN);
            errtype = FALSE;
         }
         break;

      default:    // If nothing else try for a constant.
         unNextCh();
         Constant(val);
         value = val->value;
         sz = val->size;
   }
exitpt:
   // Look for sizing indicator and chop value to specified
   // size. No warnings.
   if (NextCh() == '.') {
	   ch = NextCh();
	   ch2 = NextCh();
	   unNextCh();
	   if (IsIdentChar(ch2)) {
		   unNextCh();
		   unNextCh();
	   }
	   else {
		   switch(toupper(ch)) {
		   case 'B':
			   sz = 'B';
			   value = (__int8) value;
			   val->fForcedSize = TRUE;
			   break;
		   case 'W':
			   sz = 'W';
			   value = (__int16) value;
			   val->fForcedSize = TRUE;
			   break;
		   case 'L':
			   sz = 'L';
			   value = (__int32) value;
			   val->fForcedSize = TRUE;
			   break;
		   default:
			   unNextCh();
			   unNextCh();
		   }
	   }
   }
	else
		unNextCh();
exitpt3:
   val->value = value;
   val->size = sz;
exitpt2:
   return;
}


/* -------------------------------------------------------------------
   term()  A term is a factor *, /, %, <<, >> a term 
------------------------------------------------------------------- */

void CAsmBuf::Term(SValue *val)
{
   __int64 valuet;
   char sz2;
   SValue v2;

   Factor(&v2);
   while(1)
   {
      while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
      switch (NextCh())
      {
         case '*':
            Factor(val);
            v2.value = v2.value * val->value;
            v2.size = GetSizeCh(v2.size, val->size);
			v2.fLabel = FALSE;
			if (val->fForwardRef)
				v2.fForwardRef = TRUE;
            break;
         case '/':
            Factor(val);
            valuet = val->value;
            sz2 = val->size;
            if(valuet == 0)
            { // Check for divide by zero
               err(NULL, E_DIV);
               v2.value = -1;
               v2.size = 'L';
               errtype = FALSE;
            }
            else {
               v2.value = v2.value / valuet;
               v2.size = GetSizeCh(v2.size, sz2);
            }
			 v2.fLabel = FALSE;
			if (val->fForwardRef)
				v2.fForwardRef = TRUE;
            break;

         case '%':
            Factor(val);
            valuet = val->value;
            sz2 = val->size;
            if(valuet == 0)
            { // Check for divide by zero
               Err(E_MOD);
               v2.value = -1;
               v2.size = 'L';
               errtype = FALSE;
            }
            else {
               v2.value = v2.value % valuet;
               v2.size = GetSizeCh(v2.size, sz2);
            }
			 v2.fLabel = FALSE;
			if (val->fForwardRef)
				v2.fForwardRef = TRUE;
            break;

         case '>':
            if (PeekCh() == '>')
            {
               NextCh();
               Factor(val);
               v2.value >>= val->value;
               v2.size = GetSizeCh(v2.size, val->size);
				 v2.fLabel = FALSE;
				if (val->fForwardRef)
					v2.fForwardRef = TRUE;
               break;
            }
            unNextCh();
            goto xitLoop;

         case '<':
            if (PeekCh() == '<')
            {
               NextCh();
               Factor(val);
               v2.value <<= val->value;
               v2.size = GetSizeCh(v2.size, val->size);
				 v2.fLabel = FALSE;
				if (val->fForwardRef)
					v2.fForwardRef = TRUE;
               break;
            }
            unNextCh();
            goto xitLoop;

         default:
            unNextCh();
            goto xitLoop;
      }
   }
xitLoop:
   *val = v2;
   return;
}


/* -------------------------------------------------------------------
   Expr - evaluate expression and return a long (long) number 
      a + b
      a - b
      a & b
      a ^ b
      a | b
------------------------------------------------------------------- */

void CAsmBuf::Expr(SValue *val)
{
   SValue v2;
   int lcnt = 0;

   Term(&v2);
   if (v2.fLabel) lcnt = 1;
   while(1)
   {
      while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
      switch(NextCh())
      {
         case '+':
            Term(val);
            v2.value += val->value;
			if (val->fLabel) lcnt++;
            v2.size = GetSizeCh(v2.size, val->size);
            break;
         case '-':
            Term(val);
            v2.value -= val->value;
			if (val->fLabel) lcnt++;
            v2.size = GetSizeCh(v2.size, val->size);
            break;
         case '&':
            if (PeekCh() == '&')
            {
               unNextCh();
               goto xitLoop;
            }
            Term(val);
            v2.value &= val->value;
			lcnt=2;
            v2.size = GetSizeCh(v2.size, val->size);
            break;

         case '^':
            Term(val);
            v2.value ^= val->value;
            v2.size = GetSizeCh(v2.size, val->size);
			lcnt = 2;
            break;
         case '|':
            if (PeekCh() == '|')
            {
               unNextCh();
               goto xitLoop;
            }
            Term(val);
            v2.value |= val->value;
            v2.size = GetSizeCh(v2.size, val->size);
			lcnt = 2;
            break;

         default:
            unNextCh();
            goto xitLoop;
      }
   }
xitLoop:
   *val = v2;
   val->fLabel = (lcnt == 1) ? TRUE : FALSE;
   return;
}


/* -------------------------------------------------------------------
   Description :
      Evaluate logical 'and' expressions.
------------------------------------------------------------------- */

void CAsmBuf::AndExpr(SValue *val)
{
   SValue v2;
   char fLabel;

   Expr(&v2);
   fLabel = v2.fLabel;
   while(1)
   {
      while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
      if (Ptr()[0] == '&' && Ptr()[1] == '&')
      {
         setptr(Ptr() + 2);
         Expr(val);
         v2.value = v2.value && val->value;
         v2.size = GetSizeCh(v2.size, val->size);
		 fLabel = FALSE;
      }
      else
         break;
   }
   *val = v2;
   val->fLabel = fLabel;
   return;
}


/* -------------------------------------------------------------------
   Description:

   Note: we cannot do
      value = value || AndExpr()
   because MSC will optimize the expression and not call AndExpr if
   value is true. Since we always want to call AndExpr() we force it
   to be called by storing the return value in another variable.
------------------------------------------------------------------- */

void CAsmBuf::OrExpr(SValue *val)
{
   SValue v3, v2;
   char fLabel;

   AndExpr(&v3);
   fLabel = v3.fLabel;
   while(1) {
      while(isspace(PeekCh()) && PeekCh() != '\n') NextCh();
      if (Ptr()[0] == '|' && Ptr()[1] == '|') {
         setptr(Ptr() + 2);
         AndExpr(val);
         v2 = *val;
         v3.value = v3.value || v2.value;
         v3.size = GetSizeCh(v3.size, v2.size);
		 fLabel = FALSE;
      }
      else
         break;
   }
   *val = v3;
   val->fLabel = fLabel;
   return;
}


/* -------------------------------------------------------------------
   Returns the largest size
------------------------------------------------------------------- */
static char GetSizeCh(char s1, char s2)
{
   switch(s1)
   {
      case 'B':
		 return (s2 != 'B') ? s2 : 'B';
      case 'W':
         if (s2 == 'L') return 'L';
         if (s2 == 'S') return 'S';
         if (s2 == 'D') return 'D';
         return 'W';
      case 'L':
         if (s2 == 'D') return 'D';
         return 'L';
   }
   return 'L';
}


/* -------------------------------------------------------------------
   Relational expressions
      <,>,<=,>=,<>,!=
------------------------------------------------------------------- */

void CAsmBuf::Relational(SValue *val)
{
   SValue v2;
   char fLabel;

   OrExpr(&v2);
   fLabel = v2.fLabel;
   while(1) {
      while (isspace(PeekCh()) && PeekCh() != '\n') NextCh();
      switch(NextCh()) {
         case '<':
            if (PeekCh() == '>') {
               NextCh();
               OrExpr(val);
               v2.value = v2.value != val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else if (PeekCh() == '=') {
               NextCh();
               OrExpr(val);
               v2.value = v2.value <= val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else if (PeekCh() != '<') {
               OrExpr(val);
               v2.value = v2.value < val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '>':
            if (PeekCh() == '=') {
               NextCh();
               OrExpr(val);
               v2.value = v2.value >= val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else if (PeekCh() != '>') {
               OrExpr(val);
               v2.value = v2.value > val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else
            {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '=':
            OrExpr(val);
            v2.value = v2.value == val->value;
            v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            break;

         case '!':
            if (PeekCh() == '=') {
               NextCh();
               OrExpr(val);
               v2.value = v2.value != val->value;
               v2.size = GetSizeCh(v2.size, val->size);
			   fLabel = FALSE;
            }
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         default:
            unNextCh();
            goto xitLoop;
      }
   }
xitLoop:
   *val = v2;
   val->fLabel = fLabel;
   return;
}


/* -------------------------------------------------------------------
   expeval(s, es)
   char *s;    - expression to evaluate.
   char **es;  - point where evaluation stopped.

   Description :
      Evaluate a string expression and return a numeric result.

------------------------------------------------------------------- */

SValue CAsmBuf::expeval(char **pout)
{
	SValue value;

//   printf("Eval:%s|\n", Ptr());
	try {
		errtype = TRUE;
		Relational(&value);
	}
	catch(ExprErr e)
	{
		value.value = 0;
		value.size = 'L';
		value.fLabel = FALSE;
		value.fForwardRef = FALSE;
		value.fForcedSize = FALSE;
		errtype = FALSE;
	}

	if (pout)
		*pout = Ptr();
	return value;  /* evaluate string */
}

/* -------------------------------------------------------------------
   expeval(s, es)
   char *s;    - expression to evaluate.
   char **es;  - point where evaluation stopped.

   Description :
      Evaluate a string expression and return a numeric result.

------------------------------------------------------------------- */
SValue expeval(char *bf, char **ep)
{
   CAsmBuf eb;
   SValue val;

   lastsym = NULL;
   eb.set(bf, strlen(bf));
   val = eb.expeval(ep);
   return val;
}

