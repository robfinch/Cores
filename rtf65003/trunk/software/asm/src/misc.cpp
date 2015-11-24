#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "Assembler.h"

/* ===============================================================
	(C) 2000 Bird Computer
	All rights reserved

		Please read the Sparrow Licensing Agreement
	(license.html file). Use of this file is subject to the
	license agreement.
=============================================================== */

/*
*/
int min(int a, int b)
{
   return (a < b) ? a : b;
}

namespace RTFClasses
{
/* -------------------------------------------------------------------
   Description :
      Gets the size character. If size code is present then save it
	and increment pointer to operand.
------------------------------------------------------------------- */

int Assembler::getSzChar()
{
   int xx = 0;
   char *eptr;
   Value val;

   xx = 'W';	// default to word size
   if (ibuf->peekCh() == '.')
   {
      ibuf->nextCh();
      if (ibuf->peekCh() == '(')
      {
         ibuf->nextCh();
         val = ibuf->expeval(&eptr);
         xx = val.value;
         if (ibuf->peekCh() == ')')
            ibuf->nextCh();
         else
            Err(E_PAREN);
		 switch(xx)
		 {
		 case 8:
            return ('B');
		 case 16:
            return ('C');
		 case 32:
            return ('W');
		 case 64:
			 return ('D');
		 default:
            return (xx);
		 }
      }
      else {
		  xx = toupper(ibuf->nextCh());
		  if (xx=='U')
			  xx = (xx << 8) | (toupper(ibuf->nextCh()) & 0xff);
		  if (toupper(ibuf->peekCh()) == 'P') {
			xx = xx | 256;
			ibuf->nextCh();
		  }
         return(xx);
	  }
   }
   return (0);
//   return (gProcessor==102?'W':'B');
}


int Assembler::GetSzCode(int xx)
{
	int rr;

	if (xx & 256)	// parallel
		rr = 4;
	else
		rr = 0;
	if ((xx & 0xff) == 'C' || (xx & 0xff)=='H' )	// half word
		rr |= 1;
	else if ((xx & 0xff) == 'W' || xx == 0)	// word
		rr |= 2;
	// byte = 0
	return rr << 9;
}


	// Returns the value of the current counter.

	Counter &Assembler::getCounter()
	{
		switch(CurrentArea)
		{
		case BSS_AREA: return BSSCounter;
		case DATA_AREA: return DataCounter;
		}
		return ProgramCounter;
	}


/* ---------------------------------------------------------------
	Returns format field setting for floating point.
--------------------------------------------------------------- */
int Assembler::fmt2bit(int s)
{
	switch(toupper(s))
	{
	case 'B': return 6;
	case 'W': return 4;
	case 'L': return 0;
	case 'X': return 2;
	case 'P': return 3;
	case 'D': return 5;
	case 0:
	case 'S':
		return 1;
	default:
		Err(E_LENGTH);
		return 1;
	}
}

/* -----------------------------------------------------------------------------
   Description :
      Saves a copy of the opcodes in a save buffer.
----------------------------------------------------------------------------- */

void Assembler::SaveOps()
{
	int ii;

	SaveOpSize = opsize;
	for (ii = 0; ii < opsize; ii++)
		SaveOpCode[ii] = wordop[ii];
}


void Assembler::RestoreOps()
{
	int ii;

	opsize = SaveOpSize;
	for (ii = 0; ii < opsize; ii++)
		wordop[ii] = SaveOpCode[ii];
}


/* -----------------------------------------------------------------------------
   Description :
      Reverses the order of bits in the input pattern.
----------------------------------------------------------------------------- */

int Assembler::ReverseBits(int inpat)
{
	int ii, outpat = 0;

	for (ii = 0; ii < 16; ii++)
	{
		outpat <<= 1;
		outpat |= (inpat & 1);
		inpat >>= 1;
	}
	return (outpat);
}


/* -----------------------------------------------------------------------------
   Description :
      Reverses the order of bits in the input pattern.
----------------------------------------------------------------------------- */

int Assembler::ReverseBitsByte(int inpat)
{
	int ii, outpat = 0;

	for (ii = 0; ii < 8; ii++)
	{
		outpat <<= 1;
		outpat |= (inpat & 1);
		inpat >>= 1;
	}
	return (outpat);
}


/* -----------------------------------------------------------------------------
   Function :  Copy the opposite of the condition code to the string.
                        "cc" is the inverse of "cs", "eq", "ne", etc. 
----------------------------------------------------------------------------- */

int Assembler::invcc(char *s)
{
	static const char *cc = "ls~hi~cs~cc~eq~ne~vs~vc~mi~pl~lt~ge~le~gt~";
	char buf[3], *p;
	int i;

	buf[2] = '\0';
	strncpy(buf, s, 2);
	p = (char *)strstr(cc, buf);
	i = p - cc;
	if (i > 0)
	{
		i /= 3;
		strncpy(s, &cc[i + ((i % 6) ? 3: -3)], 2);
	}
	return (TRUE);
}
}
