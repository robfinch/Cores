#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <ht.h>
#include "fpp.h"

static long OrExpr(void);
static long Relational(void);
static long Factor(void);

/* -----------------------------------------------------------------------------

   Description :
      This file contains routines for supporting #if directive. Note that
   macros are expanded before the if test is evaluated. This means we can
   count on there being only integer constants to evaluate.

      Order of precedence. All operators listed on the same line have the
   same precedence.

      numeric or character constant
      - (unary), !, ~, (),       // unary
      *, /, %, <<, >>            // multiplicative
      +, -, &, |, ^              // bitwise, additive
      &&,
      ||                         // boolean
      =, <, >, >=, <=, <>, !=    // relational

----------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
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
--------------------------------------------------------------------------- */

static long Constant()
{
	char *backcodes = { "abfnrtv0'\"\\" };
	const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   char *s,*p;
   long value = 0;
   int ch;

   ch = NextNonSpace(0);
   if (isdigit(ch)) {
      if (ch == '0') {
         ch = NextCh();
         switch(ch) {
            case 'b': value = strtoul(inptr, &s, 2); break;
            case 'o': value = strtoul(inptr, &s, 8); break;
            case 'd': value = strtoul(inptr, &s, 10); break;
            case 'x': value = strtoul(inptr, &s, 16); break;
            default:
               inptr -= 2;
//               unNextCh();
               value = strtoul(inptr, &s, 0);
         }
      }
      else {
         unNextCh();
         value = strtoul(inptr, &s, 0);
      }
      inptr = s;
   }
   else if (ch == '\'') {
      ch = NextCh();
		if (ch == '\\') {
         ch = NextCh();
			p = strchr(backcodes, ch);
			if (p)
            value = textequ[p - backcodes];
			else {
            if(isdigit(ch)) {
               unNextCh();
               value = strtoul(inptr, &s, 0);
               inptr = s;
            }
            else
               value = ch;   // use character as-is
			}
		}
      else
         value = ch;   // pick up regular character
      ch = NextCh();
      if(ch != '\'') {
         unNextCh();
         err(0);
      }
   }
   else {
	   GetIdentifier();
	   value = 0;
      //err(1);
   }
   return value;
}


/* ----------------------------------------------------------------------------
	factor - a factor may be
      not factor
		-factor
		!factor
      ~factor
		(relation)
		a number
      defined(<macro>)
---------------------------------------------------------------------------- */

static long Factor()
{
   long value = 0;
   int ch;
   char *ptr;
   SDef dp;

   ch = NextNonSpace(0);
	switch (ch)
	{
      case '!': value = !Factor(); break;
      case '-': value = -Factor(); break;
      case '~': value = ~Factor(); break;
      case '(': value = OrExpr();
         ch = NextNonSpace(0);
         if (ch != ')') {
            unNextCh();
            err(3);
         }
         break;

      case 'd':
         ptr = inptr;   // record pointer
         if (strcmp(inptr, "efined")) {
            unNextCh();
            value = Constant();
            break;
         }
         inptr += 6;
         ch = NextNonSpace(0);
         if (ch != '(') {
            inptr = ptr;
            unNextCh();
            value = Constant();
            break;
         }
         ptr = inptr;
         dp.name = GetIdentifier();
         if (dp.name == NULL) {
            err(21);
         }
         else
            value = (htFind(&HashInfo, &dp) ? 1 : 0);
         ch = NextNonSpace(0);
         if (ch != ')') {
            unNextCh();
            err(3);
         }
         break;

      default:    // If nothing else try for a constant.
         unNextCh();
         value = Constant();
   }
   return value;
}


/* ----------------------------------------------------------------------------
 	term()  A term is a factor *, /, %, <<, >> a term 
---------------------------------------------------------------------------- */

static long Term()
{
   long value, valuet;
   int ch;

   value = Factor();
   while(1) {
      ch = NextNonSpace(0);
      switch (ch) {
         case '*': value = value * Factor(); break;
         case '/':
			 // Absorb a comment
			 if (PeekCh()=='*') {
				 NextCh();
				 do {
					 ch = NextCh();
				 }
				 while (ch && !(ch == '*' && PeekCh()=='/'));
				 ch = NextCh();
				 continue;
			 }
			 if (PeekCh()=='/') {
				 do {
					 ch = NextCh();
				 }
				 while (ch && ch!='\n');
				 unNextCh();
				 continue;
			 }
            valuet = Factor();
            if(valuet == 0)
            { // Check for divide by zero
               err(4);
               value = -1;
            }
            else
               value = value / valuet;
            break;

         case '%':
            valuet = Factor();
            if(valuet == 0)
            { // Check for divide by zero
               err(4);
               value = -1;
            }
            else
               value = value % valuet;
            break;

         case '>':
            if (PeekCh() == '>') {
               NextCh();
               value >>= Factor();
               break;
            }
            unNextCh();
            goto xitLoop;

         case '<':
            if (PeekCh() == '<') {
               NextCh();
               value <<= Factor();
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
   return value;
}


/* ----------------------------------------------------------------------------
	Expr - evaluate expression and return a long (long) number 
---------------------------------------------------------------------------- */

static long Expr()
{
   long value;
   int ch;

   value = Term();
   while(1) {
      ch = NextNonSpace(0);
      switch(ch)
      {
         case '+': value += Term(); break;
         case '-': value -= Term(); break;
         case '&':
            if (PeekCh() == '&') {
               unNextCh();
               goto xitLoop;
            }
            value &= Term();
            break;

         case '^': value ^= Term(); break;
         case '|':
            if (PeekCh() == '|') {
               unNextCh();
               goto xitLoop;
            }
            value |= Term();
            break;

         default:
            unNextCh();
            goto xitLoop;
      }
   }
xitLoop:
   return value;
}


/* ---------------------------------------------------------------------------
   Relational expressions
      <,>,<=,>=,<>,!=
--------------------------------------------------------------------------- */

static long Relational()
{
   long value;
   int ch;

   value = Expr();
   while(1) {
      ch = NextNonSpace(0);
      switch(ch) {
         case '<':
            if (PeekCh() == '>') {
               NextCh();
               value = value != Expr();
            }
            else if (PeekCh() == '=') {
               NextCh();
               value = value <= Expr();
            }
            else if (PeekCh() != '<')
               value = value < Expr();
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '>':
            if (PeekCh() == '=') {
               NextCh();
               value = value >= Expr();
            }
            else if (PeekCh() != '>')
               value = value > Expr();
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '=':
			 if (PeekCh()=='=')
				 NextCh();
            value = value == Expr();
            break;

         case '!':
            if (PeekCh() == '=') {
               NextCh();
               value = value != Expr();
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
   return value;
}


/* ---------------------------------------------------------------------------
   Note: we cannot do
      value = value && AndExpr()
   because MSC will optimize the expression and not call Relational if
   value is false. Since we always want to call Relational() we force it
   to be called by storing the return value in another variable.
--------------------------------------------------------------------------- */

static long AndExpr()
{
   long value, value2;
   int ch;

   value = Relational();
   while(1) {
      ch = NextNonSpace(0);
      if (ch == '&' && PeekCh() == '&') {
		  NextCh();
		 value2 = Relational();
         value = value && value2;
      }
      else {
         unNextCh();
         break;
      }
   }
   return value;
}


/* ---------------------------------------------------------------------------
   Description:

   Note: we cannot do
      value = value || AndExpr()
   because MSC will optimize the expression and not call AndExpr if
   value is true. Since we always want to call AndExpr() we force it
   to be called by storing the return value in another variable.
--------------------------------------------------------------------------- */

static long OrExpr()
{
   long value, value2;
   int ch;

   value = AndExpr();
   while(1) {
      ch = NextNonSpace(0);
      if (ch == '|' && PeekCh() == '|') {
         NextCh();
         value2 = AndExpr();
         value = value || value2;
      }
      else {
         unNextCh();
         break;
      }
   }
   return value;
}


/* ---------------------------------------------------------------------------
	expeval - evaluate the expression s and return a number.
--------------------------------------------------------------------------- */

long expeval()
{
   return OrExpr();
}
