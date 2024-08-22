#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <ht.h>
#include <inttypes.h>
#include "fpp.h"

static int64_t ConditionalExpr(int);
static int64_t OrExpr(int);
static int64_t Relational(int);
static int64_t Factor(int);

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

static int64_t Constant(int needed)
{
	char *backcodes = { "abfnrtv0'\"\\" };
	const char *textequ = { "\a\b\f\n\r\t\v\0'\"\\" };

   char *s,*p;
   int64_t value = 0;
   int ch;

   ch = NextNonSpace(0);
   if (isdigit(ch)) {
      if (ch == '0') {
         ch = NextCh();
         switch(ch) {
            case 'b': value = strtoull(inptr, &s, 2); break;
            case 'o': value = strtoull(inptr, &s, 8); break;
            case 'd': value = strtoull(inptr, &s, 10); break;
            case 'x': value = strtoull(inptr, &s, 16); break;
            default:
               inptr -= 2;
//               unNextCh();
               value = strtoull(inptr, &s, 0);
         }
      }
      else {
         unNextCh();
         value = strtoull(inptr, &s, 0);
      }
      // Allow a number to be followed directly by an 'L' or 'U'.
      if (s[0] == 'L' || s[0]=='U')
        s++;
      if (s[0] == 'L')
        s++;
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
               value = strtoull(inptr, &s, 0);
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
   return (value);
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

static int64_t Factor(int needed)
{
   int64_t value = 0;
   int ch;
   char *ptr;
   def_t dp;

   ch = NextNonSpace(0);
	switch (ch)
	{
      case '!': value = !Factor(needed); break;
      case '-': value = -Factor(needed); break;
      case '~': value = ~Factor(needed); break;
      case '(': value = ConditionalExpr(needed);
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
            value = Constant(needed);
            break;
         }
         inptr += 6;
         ch = NextNonSpace(0);
         if (ch != '(') {
            inptr = ptr;
            unNextCh();
            value = Constant(needed);
            break;
         }
         ptr = inptr;
         dp.name = GetIdentifier();
         if (needed) {
           if (dp.name == NULL) {
             err(21);
           }
           else
             value = (htFind(&HashInfo, &dp) ? 1 : 0);
         }
         else
           value = 1;
         ch = NextNonSpace(0);
         if (ch != ')') {
            unNextCh();
            err(3);
         }
         break;

      default:    // If nothing else try for a constant.
         unNextCh();
         value = Constant(needed);
   }
   return (value);
}


/* ----------------------------------------------------------------------------
 	term()  A term is a factor *, /, %, <<, >> a term 
---------------------------------------------------------------------------- */

static int64_t Term(int needed)
{
   int64_t value, valuet;
   int ch;

   value = Factor(needed);
   while(1) {
      ch = NextNonSpace(0);
      switch (ch) {
         case '*': value = value * Factor(needed); break;
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
            valuet = Factor(needed);
            if(valuet == 0)
            { // Check for divide by zero
              if (needed) {
                err(4);
                value = -1;
              }
              else
                value = 1;
            }
            else
               value = value / valuet;
            break;

         case '%':
            valuet = Factor(needed);
            if(valuet == 0)
            { // Check for divide by zero
              if (needed) {
                err(4);
                value = -1;
              }
              else
                value = 1;
            }
            else
               value = value % valuet;
            break;

         case '>':
            if (PeekCh() == '>') {
               NextCh();
               value >>= Factor(needed);
               break;
            }
            unNextCh();
            goto xitLoop;

         case '<':
            if (PeekCh() == '<') {
               NextCh();
               value <<= Factor(needed);
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
   return (value);
}


/* ----------------------------------------------------------------------------
	Expr - evaluate expression and return a long (long) number 
---------------------------------------------------------------------------- */

static int64_t Expr(int needed)
{
   int64_t value;
   int ch;

   value = Term(needed);
   while(1) {
      ch = NextNonSpace(0);
      switch(ch)
      {
         case '+': value += Term(needed); break;
         case '-': value -= Term(needed); break;
         case '&':
            if (PeekCh() == '&') {
               unNextCh();
               goto xitLoop;
            }
            value &= Term(needed);
            break;

         case '^': value ^= Term(needed); break;
         case '|':
            if (PeekCh() == '|') {
               unNextCh();
               goto xitLoop;
            }
            value |= Term(needed);
            break;

         default:
            unNextCh();
            goto xitLoop;
      }
   }
xitLoop:
   return (value);
}


/* ---------------------------------------------------------------------------
   Relational expressions
      <,>,<=,>=,<>,!=
--------------------------------------------------------------------------- */

static int64_t Relational(int needed)
{
   int64_t value;
   int ch;

   value = Expr(needed);
   while(1) {
      ch = NextNonSpace(0);
      switch(ch) {
         case '<':
            if (PeekCh() == '>') {
               NextCh();
               value = value != Expr(needed);
            }
            else if (PeekCh() == '=') {
               NextCh();
               value = value <= Expr(needed);
            }
            else if (PeekCh() != '<')
               value = value < Expr(needed);
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '>':
            if (PeekCh() == '=') {
               NextCh();
               value = value >= Expr(needed);
            }
            else if (PeekCh() != '>')
               value = value > Expr(needed);
            else {
               unNextCh();
               goto xitLoop;
            }
            break;

         case '=':
			 if (PeekCh()=='=')
				 NextCh();
            value = value == Expr(needed);
            break;

         case '!':
            if (PeekCh() == '=') {
               NextCh();
               value = value != Expr(needed);
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
   return (value);
}


/* ---------------------------------------------------------------------------
   Note: we cannot do
      value = value && AndExpr()
   because MSC will optimize the expression and not call Relational if
   value is false. Since we always want to call Relational() we force it
   to be called by storing the return value in another variable.
--------------------------------------------------------------------------- */

static int64_t AndExpr(int needed)
{
   int64_t value, value2;
   int ch;

   value = Relational(needed);
   while(1) {
      ch = NextNonSpace(0);
      if (ch == '&' && PeekCh() == '&') {
		  NextCh();
		    value2 = Relational(value!=0);
        value = value && value2;
      }
      else {
         unNextCh();
         break;
      }
   }
   return (value);
}


/* ---------------------------------------------------------------------------
   Description:

   Note: we cannot do
      value = value || AndExpr()
   because MSC will optimize the expression and not call AndExpr if
   value is true. Since we always want to call AndExpr() we force it
   to be called by storing the return value in another variable.
--------------------------------------------------------------------------- */

static int64_t OrExpr(int needed)
{
   int64_t value, value2;
   int ch;

   value = AndExpr(needed);
   while(1) {
      ch = NextNonSpace(0);
      if (ch == '|' && PeekCh() == '|') {
         NextCh();
         value2 = AndExpr(value==0);
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
--------------------------------------------------------------------------- */

static int64_t ConditionalExpr(int needed)
{
  int64_t value1, value2, value3;
  int ch;

  value2 = 0;
  value1 = OrExpr(needed);
  ch = NextNonSpace(0);
  if (ch != '?') {
    unNextCh();
    return (value1);
  }
  value2 = ConditionalExpr(value1!=0);
  ch = NextNonSpace(0);
  if (ch != ':') {
    err(26);
    unNextCh();
    return (value2);
  }
  value3 = ConditionalExpr(value1==0);
  return ((value1 == 0) ? value3 : value2);
}

/* ---------------------------------------------------------------------------
	expeval - evaluate the expression s and return a number.
--------------------------------------------------------------------------- */

int64_t expeval()
{
   return (ConditionalExpr(1));
}
