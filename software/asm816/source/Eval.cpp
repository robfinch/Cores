#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "fwstr.h"
#include "sym.h"
#include "Assembler.h"
#include "asmbuf.h"
#include <inttypes.h>


/* ===============================================================
	(C) 2014 Robert Finch
	(C) 2000 Bird Computer
	All rights reserved
=============================================================== */

/* -------------------------------------------------------------------
	Description :
		Expression parser. Evaluates simple expressions that result
	in long constant values. All function return long value.
------------------------------------------------------------------- */

#define isoctal(d)   (((d) >= '0') && ((d) < '8'))
uint64_t stouxl(const char *instr, const char **outstr)
{
	uint64_t num = 0;
   char *str = (char *)instr;

   while(isspace(*str))
      ++*str;

   if (*str == '$')
   {
        for(++str; isxdigit(*str) || *str=='_'; ++str)
			if (*str != '_')
				num = (num * 16) + (isdigit(*str) ? *str - '0' : toupper(*str) - 'A' + 10);
   }
   else if (*str == '@' || *str=='%')
   {
        for(++str; *str=='0' || *str=='1' || *str=='_'; ++str)
			if (*str != '_')
				num = (num * 2) + *str - '0';
   }
   else if (*str != '0')
   {
      while(isdigit(*str))
         num = (num * 10) + (*str++ - '0');
   }
   else
   {
      ++str;
      switch(*str)
      {
         case 'x':
         case 'X':
            for(++str; isxdigit(*str) || *str=='_'; ++str)
               if (*str != '_') num = (num * 16) + (isdigit(*str) ? *str - '0' : toupper(*str) - 'A' + 10);
            break;

         case 'o':
         case 'O':
            for(++str; (*str >= '0' && *str <= '7') || *str == '_'; ++str)
               if (*str != '_') num = (num * 8) + *str - '0';
            break;

         case 'b':
         case 'B':
            for(++str; *str == '0' || *str == '1' || *str == '_'; ++str)
               if (*str != '_') num = (num + num) + *str - '0';
            break;

         default:
         {
            while('0' <= *str && *str <= '7')
            {
               num *= 8;
               num += *str++ -'0';
            }
         }
      }
   }
   if (outstr)
      *outstr = str;
   return (num);
}


extern "C" {
   jmp_buf jbEvalErr;
}

union aval {
	float f;
	long l;
	double d;
	__int64 i;
};


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
/*
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
*/
	return outval;
}


namespace RTFClasses
{
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
         $<digits>   hexidecimal constant
         0x<digits>  hexidecimal constant
         0o<digits>  octal constant
         0<digits>   octal constant
         0b<digits>  binary constant
         0d<digits>  decimal constant
         '<character constant>'  as in 'a', 'b', ...
         '\<char code>'          as in '\n', '\r'


   Returns (long) - value
------------------------------------------------------------------- */

void AsmBuf::constant(Value *val)
{
   const char *backcodes = { "abfnrtv0'\"\\" };
   const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   char *p;
   uint64_t value = 0;
   char buf[5], *eptr;
   union aval fval;
   const char *ep1;
   char *ep2;

   val->fForwardRef = false;
   /* -----------------------------
      Check if numeric constant.
   ----------------------------- */
   while(peekCh()==' ') nextCh();
   if (isdigit(peekCh())||peekCh()=='$'||peekCh()=='@'||peekCh()=='%')
   {
	   val->fLabel = false;
       value = stouxl(getPtr(), &ep1);
	   fval.d = strtod(getPtr(), &ep2);
	   // whichever one got the most characters wins
	   if (ep2 > ep1) {
		   if (theAssembler.getFpFormat() == FP_FFP) {
			fval.f = (float)fval.d;	// convert to shorter format
			value = (__int64)cvtIEEEtoFFP(fval.l);
		   }
		else
			value = fval.i;
		eptr = ep2;
	   }
	   else
		   eptr = (char *)ep1;
      if (value >= -128 && value <= 127)
         val->size = 'B';
      else if (value >= -8388608 && value <= 8388607)
         val->size = 'W';
	  else
		  val->size = 'D';
      setptr(eptr);
      val->value = value;
	  val->bDefined = true;	// constants are defined
      return;
   }

   /* ----------------------------------
      Check for a character constant.
   ---------------------------------- */
   else if (peekCh() == '\'')
   {
      nextCh();
      if (peekCh() == '\\')
      {
         nextCh();
         p = strchr(backcodes, peekCh());
         if (p)
            value = textequ[p - backcodes];
         else
         {
            // if an 'x' is seen then assume the following two
			 // characters are a hexidecimal constant specifying
			 // the character
            if (peekCh() == 'x')
            {
               nextCh();
               strncpy(buf, getPtr(), 2);
               buf[2] = '\0';
               value = strtol(buf, &eptr, 16);
               move(strlen(buf));
            }
            // otherwise, if an octal digit is seen then assume the
            // following two characters are part of a three digit
            // octal number.
            else if(isoctal(peekCh()))
            {
               strncpy(buf, getPtr(), 3);
               buf[3] = '\0';
               move(strlen(buf));
               value = strtol(buf, &eptr, 8);
            }
            else
               value = peekCh();  // use character as-is
         }
      }
      else
         value = peekCh();  // pick up regular character
      nextCh();
      if(peekCh() != '\'')
      {
//         unNextCh();
         Err(E_QUOTE);
      }
	  else
		  nextCh();
      val->size = 'B';
      val->value = value;
	  val->fLabel = false;
	  val->bDefined = true;
		return;
   }
   else if (peekCh() == '"')
   {
      nextCh();
      if (peekCh() == '"')
      {
         nextCh();
         p = strchr(backcodes, peekCh());
         if (p)
            value = textequ[p - backcodes];
         else
         {
            // if an 'x' is seen then assume the following two
			 // characters are a hexidecimal constant specifying
			 // the character
            if (peekCh() == 'x')
            {
               nextCh();
               strncpy(buf, getPtr(), 2);
               buf[2] = '\0';
               value = strtol(buf, &eptr, 16);
               move(strlen(buf));
            }
            // otherwise, if an octal digit is seen then assume the
            // following two characters are part of a three digit
            // octal number.
            else if(isoctal(peekCh()))
            {
               strncpy(buf, getPtr(), 3);
               buf[3] = '\0';
               move(strlen(buf));
               value = strtol(buf, &eptr, 8);
            }
            else
               value = peekCh();  // use character as-is
         }
      }
      else
         value = peekCh();  // pick up regular character
      nextCh();
      if(peekCh() != '"')
      {
//         unNextCh();
         Err(E_QUOTE);
      }
	  else
		  nextCh();
      val->size = 'B';
      val->value = value;
	  val->fLabel = false;
	  val->bDefined = true;
		return;
   }
	// Program counter value ?
	else if (peekCh()=='*')
	{
		//NextNonSpaceLF();
		//unNextCh();
		nextCh();
		val->fLabel = FALSE;
		value = theAssembler.getCounter().val;
		val->size = 'W';
		val->value = value;
		val->fLabel = false;
		val->bDefined = true;
		return;
	}
	/* --------------------------------------------------------
		Not a number, prog loc, or escaped char, then what ?. 
	-------------------------------------------------------- */
	Err e1(E_EXPR);
	throw e1;
	return;
}


/* ----------------------------------------------------------------------------
   Description :
   Returns :
      1 if the string is a function, otherwise 0
---------------------------------------------------------------------------- */
bool AsmBuf::isFunc(char *str) const
{
	static const char *flist = "*~defined~size~not~pc~";
	char buf[100];

	strncpy(buf, str, sizeof(buf)-1);
	strcat(buf, "~");
	strlwr(buf);	// make case insensitive
	return (strstr(flist, buf) ? true : false);
}


/* -------------------------------------------------------------------
   functions
      defined(x)  - returns 1 if 'x' is a symbol
      size(x)     - returns the size of the symbol
      not(x)      - returns ones complement of x
------------------------------------------------------------------- */

void AsmBuf::func(Value *val, int ch)
{
	int LookForBracket = 0;
	int id;
	char *sptr, *eptr;
	char ch2;
	Symbol ts, *pts = NULL;

	val->fLabel = false;

	while(isspace(peekCh()) && peekCh() != '\n') nextCh();
	if (peekCh() == '(')
		LookForBracket = 1;

   switch(ch)
   {
      case 'n':   // not
         relational(val);
		 val->value = !val->value;
		 val->size = 'B';
		 val->bDefined = true;
         break;

      case 's':
         id = getIdentifier(&sptr, &eptr);
         if (!id)
            Err(E_SIZEOP);
         else
         {
            ch2 = *eptr;
            *eptr = '\0';
            ts.setName(sptr);
            if (theAssembler.getLocalSymTbl())
               pts = theAssembler.getLocalSymTbl()->find(&ts);
            if (pts == NULL)
               pts = theAssembler.getGlobalSymTbl()->find(&ts);
            if (pts == NULL) {
               Err(E_NOTDEFINED, sptr);
               val->value = 0;
            }
            else {
               switch(pts->getSize())
               {
                  case 'B': val->value = 1; break;
                  case 'W': val->value = 4; break;
                  default: val->value = 4; break;
               }
            }
            if (pts)
               if (!pts->isDefined() && theAssembler.getPass() > 1)
                  Err(E_NOTDEFINED, sptr);
            val->size = 'B';
            *eptr = ch2;
			val->bDefined = true;
         }
         break;

      case 'd':
         id = getIdentifier(&sptr, &eptr);
         if (!id)
            Err(E_DEFINE);
         else
         {
            pts = NULL;
            ch2 = *eptr;
            *eptr = '\0';
            ts.setName(sptr);
            if (theAssembler.getLocalSymTbl())
               pts = theAssembler.getLocalSymTbl()->find(&ts);
            if (pts == NULL)
               pts = theAssembler.getGlobalSymTbl()->find(&ts);
            if (pts)
               val->value = 1;
            else
               val->value = 0;
            val->size = 'B';
            *eptr = ch2;
			val->bDefined = true;
         }
         break;

        // program counter
	  case 'p':
		case '*':
            val->size = 'W';
            val->value = theAssembler.getCounter().val;
            val->fLabel = true;
            val->bDefined = true;
            break;
   }

	nextNonSpaceLF();
	unNextCh();
	if (LookForBracket)
		if (nextCh() != ')')
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
      >factor
      <factor
      (relation)
      a number
      a symbol
      defined(<macro>)
------------------------------------------------------------------- */

void AsmBuf::factor(Value *val)
{
   __int64 value = 0;
   int LookForBracket = 0;
   int id;
   char ch, ch2;
   char *sptr, *eptr, sz;
   Symbol ts, *pts;
   String nm;

   val->fLabel = false;
   val->fForcedSize = false;
   val->fForwardRef = false;
   id = getIdentifier(&sptr, &eptr);
   setptr(eptr);
   if (id)
   {
      ch = *eptr;
      *eptr = '\0';
      if (isFunc(sptr))
      {
         *eptr = ch;
         func(val, *sptr);
         goto exitpt2;
      }
      else
      {
		  val->bDefined = true;	// default to TRUE
         pts = NULL;
		 if (sptr[0]=='.') {
			 nm = theAssembler.lastLabel;
             nm.add(sptr);
         }
		 else
			 nm = sptr;
         ts.setName(nm.buf());
         if (theAssembler.getLocalSymTbl())
            pts = theAssembler.getLocalSymTbl()->find(&ts);
         if (pts == NULL)
            pts = theAssembler.getGlobalSymTbl()->find(&ts);
         if (theAssembler.getPass() > 1) {
			 if (pts == NULL) {
               Err(E_NOTDEFINED, nm.buf());
			 }
			else if (pts->isDefined() == false) {
               Err(E_NOTDEFINED, nm.buf());
			}
         }
		 // The symbol is unknown, so define it locally.
		 else {
			 if (pts==NULL) {
				Symbol *ns = new Symbol;
				ns->setName(ts.getName().buf());
				ns->setDefined(false);
				ns->setLine(theAssembler.getLineno());
				ns->setFile(theAssembler.getCurFilenum());
				// We have to set the value to something, so guess and use the PC.
				ns->setValue(theAssembler.getCounter().val);
				if (theAssembler.getLocalSymTbl() && theAssembler.getFileLevel() > 0) {
					theAssembler.getLocalSymTbl()->insert(ns);
				}
				else {
					theAssembler.getGlobalSymTbl()->insert(ns);
				}
			 }
		 }
         value = (pts) ? pts->getValue() : 0;
//		 if (value ==0)
//			 printf("name:%s\r\n", sptr);
         sz = (pts) ? (char)pts->getSize() : 'W';
		 val->fLabel = (pts) ? pts->isLabel() : false;
		 if (pts == NULL || pts->isDefined() == false) {
			val->fForwardRef = true;
			val->bDefined = true;
		 }
         *eptr = ch;
      }
      goto exitpt;
   }

//    while(isspace(peekCh()) && peekCh() != '\n') nextCh();
	while ((ch=nextCh())==' ');
	switch (ch)
   {
      case '!':
         factor(val);
         value = !val->value;
         sz = val->size;
		 val->fLabel = false;
         break;
      case '-':
         factor(val);
         value = -val->value;
         sz = val->size;
		 val->fLabel = false;
         break;
      case '~':
         factor(val);
         value = ~val->value;
         sz = val->size;
		 val->fLabel = false;
         break;
      case '<':
         factor(val);
         value = val->value & 0xff;
         sz = 'B';
		 val->fLabel = false;
         break;
      case '>':
         factor(val);
         value = (val->value >> 8) & 0xff;
         sz = 'B';
		 val->fLabel = false;
         break;
	  case '[':
      case '(':
         relational(val);
         value = val->value;
         sz = val->size;
		 ch = nextCh();
         if (ch != ')' && ch!=']')
         {
            unNextCh();
            Err(E_PAREN);
            theAssembler.errtype = false;
         }
         break;
	  //case '*':
   //      func(val, '*');
		 //break;

      default:    // If nothing else try for a constant.
         unNextCh();
         constant(val);
 		 value = val->value;
         sz = val->size;
   }
exitpt:
   // Look for sizing indicator and chop value to specified
   // size. No warnings.
   switch(nextCh()) {
   case '.':
 	   ch = nextCh();
	   ch2 = nextCh();
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
			   val->fForcedSize = true;
			   break;
		   case 'W':
			   sz = 'W';
			   value = (__int32) value;
			   val->fForcedSize = true;
			   break;
		   default:
			   unNextCh();
			   unNextCh();
		   }
	   }
   case '\0':
		break;
   default:
	   unNextCh();
   }


   val->value = value;
   val->size = sz;
exitpt2:
   return;
}


/* -------------------------------------------------------------------
   term()  A term is a factor *, /, %, <<, >> a term 
------------------------------------------------------------------- */

void AsmBuf::term(Value *val)
{
   __int64 valuet;
   char sz2;
   Value v2;

   factor(&v2);
   while(1)
   {
      while(isspace(peekCh()) && peekCh() != '\n') nextCh();
      switch (nextCh())
      {
         case '*':
           factor(val);
            v2.value = v2.value * val->value;
            v2.size = getSizeCh(v2.size, val->size);
			v2.fLabel = FALSE;
			if (val->fForwardRef)
				v2.fForwardRef = true;
            break;
         case '/':
            factor(val);
            valuet = val->value;
            sz2 = val->size;
            if(valuet == 0)
            { // Check for divide by zero
               Err(E_DIV);
               v2.value = -1;
               v2.size = 'L';
               theAssembler.errtype = false;
            }
            else {
               v2.value = v2.value / valuet;
               v2.size = getSizeCh(v2.size, sz2);
            }
			 v2.fLabel = false;
			if (val->fForwardRef)
				v2.fForwardRef = true;
            break;

         case '%':
            factor(val);
            valuet = val->value;
            sz2 = val->size;
            if(valuet == 0)
            { // Check for divide by zero
               Err(E_MOD);
               v2.value = -1;
               v2.size = 'L';
               theAssembler.errtype = false;
            }
            else {
               v2.value = v2.value % valuet;
               v2.size = getSizeCh(v2.size, sz2);
            }
			 v2.fLabel = false;
			if (val->fForwardRef)
				v2.fForwardRef = true;
            break;

         case '>':
            if (peekCh() == '>')
            {
               nextCh();
               factor(val);
               v2.value >>= val->value;
               v2.size = getSizeCh(v2.size, val->size);
				 v2.fLabel = FALSE;
				if (val->fForwardRef)
					v2.fForwardRef = true;
               break;
            }
            unNextCh();
            goto xitLoop;

         case '<':
            if (peekCh() == '<')
            {
               nextCh();
               factor(val);
               v2.value <<= val->value;
               v2.size = getSizeCh(v2.size, val->size);
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

	void AsmBuf::expr(Value *val)
	{
		Value v2;
		int lcnt = 0;
		term(&v2);
		if (v2.fLabel) lcnt = 1;
		while(1)
		{
			while(isspace(peekCh()) && peekCh() != '\n') nextCh();
			switch(nextCh())
			{
				case '+':
					term(val);
					v2.size = getSizeCh(v2.size, val->size);
					v2.value += val->value;
					if (val->fLabel) lcnt++;
					break;

				case '-':
					term(val);
					v2.value -= val->value;
					if (val->fLabel) lcnt++;
						v2.size = getSizeCh(v2.size, val->size);
					break;

				case '&':
					if (peekCh() == '&')
					{
						unNextCh();
						goto xitLoop;
					}
					term(val);
					v2.value &= val->value;
					lcnt=2;
					v2.size = getSizeCh(v2.size, val->size);
					break;

				case '^':
					term(val);
					v2.value ^= val->value;
					v2.size = getSizeCh(v2.size, val->size);
					lcnt = 2;
					break;

				case '|':
					if (peekCh() == '|')
					{
						unNextCh();
						goto xitLoop;
					}
					term(val);
					v2.value |= val->value;
					v2.size = getSizeCh(v2.size, val->size);
					lcnt = 2;
					break;

				default:
					unNextCh();
					goto xitLoop;
			}
		}
	xitLoop:
		*val = v2;
		val->fLabel = (lcnt == 1);
		return;
	}


	/* -------------------------------------------------------------------
		expeval(s, es)
		char *s;    - expression to evaluate.
		char **es;  - point where evaluation stopped.

		Evaluate a string expression and return a numeric result.
	------------------------------------------------------------------- */

	Value AsmBuf::expeval(char **pout)
	{
		Value value;

		try {
	//	printf("Eval:%s|\n", getPtr());
		if (setjmp(jbEvalErr))  // error exit point
		{
			value.value = 0;
			value.size = 'L';
			value.fLabel = false;
			value.fForwardRef = false;
			value.fForcedSize = false;
			theAssembler.errtype = false;
			goto exitpt;
		}

		theAssembler.errtype = true;
		relational(&value);
	exitpt:
		if (pout)
			*pout = getPtr();
		}
		catch (...) {
		}
		return value;  /* evaluate string */
	}

	/* -------------------------------------------------------------------
		expeval(s, es)
		char *s;    - expression to evaluate.
		char **es;  - point where evaluation stopped.

		Evaluate a string expression and return a numeric result.
	------------------------------------------------------------------- */
	Value expeval(char *bf, char **ep)
	{
		AsmBuf eb(bf, strlen(bf)+1);
		Value val;
		
		try {
			val = eb.expeval(ep);
		}
		catch(...) {
		}
		return val;
	}
}
