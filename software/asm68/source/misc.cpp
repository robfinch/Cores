#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "fasm68.h"

extern "C" unsigned __int64 stouxl(char *instr, char **outstr);
extern "C" unsigned long stoul(char *instr, char **outstr);

/*
*/
int min(int a, int b)
{
   return (a < b) ? a : b;
}

// ignore REGS designator
bool IsRegKeyword(char *ptr, char **eptr)
{
	*eptr = ptr;
	if (!strnicmp(ptr, "REG", 3))
	{
		if (ptr[3] == 'S' || ptr[3] == 's')
			ptr++;
		ptr += 3;
		*eptr = ptr;
		if (IsIdentChar(*ptr))
			return 0;
		return 1;
	}
	return 0;
}

/* ---------------------------------------------------------------
   Description :
      Gets bits pattern for specified registers. Registers may
	be specified individually, in a block or as a range. The '/'
	may be used as a separator for aesthetic reasons.

      d0-7        range of registers
      d0d1d2      individually specified
      d012        block specified

   Returns :
--------------------------------------------------------------- */

int IsRegList(char *s,int *rev)
{
   int regpat, flag = 'd';
   int LastDigit, NewDigit;
   char *ptr;
   char *ep;
	 int id;
	 char *sptr, *eptr;
	 char buf[500];
	 CSymbol ts, *pts = nullptr;
	 CAsmBuf eb;

	 eb.set(s, strlen(s));

   *rev = 1;
   ptr = s;
   regpat = 0;
	while(isspace(*ptr)) ptr++;
	if (*ptr=='#') {
		*rev = 0;
		ptr++;
		if (*ptr=='0' && (ptr[1]=='x' || ptr[1]=='X')) {
			regpat = stouxl(ptr, &ep);
			ptr = ep;
			return regpat;
		}
		regpat = stoul(ptr, &ep);
		ptr = ep;
		return regpat;
	}
again:
	while(isspace(*ptr)) ptr++;
   while(*ptr)
   {
	   // skip any spaces encountered
	   while(isspace(*ptr)) ptr++;
      switch(*ptr)
      {
		  // Allow use of '/' to separate address/data/registers
		case '/':
			break;
         /* ----------------------------------------
               Set bits for a range of registers.
         ---------------------------------------- */
         case '-':
            ptr++;
            for (; *ptr && !isdigit(*ptr); ptr++);
            if (*ptr)
            {
               NewDigit = *ptr - '0';
			   if (NewDigit >= LastDigit)
			   {
	               for(LastDigit++; NewDigit >= LastDigit; LastDigit++)
		           {
			          if (flag == 'd')
				         regpat |= (1 << LastDigit);
					  else
						 regpat |= (0x100 << LastDigit);
					}
				   LastDigit--;
			   }
			   else {
	               for(LastDigit--; NewDigit <= LastDigit; LastDigit--)
		           {
			          if (flag == 'd')
				         regpat |= (1 << LastDigit);
					  else
						 regpat |= (0x100 << LastDigit);
					}
				   LastDigit++;
			   }
            }
            else
               err(NULL, E_INVREG, ptr);
            --ptr;   // allow for ptr++ at end of loop.
            break;

         /* ----------------------------------
               Set address / data register.
         ---------------------------------- */
         case 'a':
         case 'd':
		 case 'A':
		 case 'D':
            flag = tolower(*ptr);
            break;

         default:
            if (isdigit(*ptr))
            {
               LastDigit = *ptr - '0';
               if (flag == 'd')
                  regpat |= (1 << LastDigit);
               else
                  regpat |= (0x100 << LastDigit);
            }
			else
				goto grp1;	// abort processing
      }
      ptr++;
   }
 grp1:
	 if (regpat == 0) {
		 eb.set(s, strlen(s));
		 // ignore REGS designator
		 id = eb.GetIdentifier(&sptr, &eptr, 0);
		 if (id) {
			 strncpy_s(buf, sizeof(buf), sptr, id);
			 if (id == 3) {
				 if (!strnicmp(buf, "REG", 3)) {
					 ptr = s + 3;
					 goto again;
				 }
			 }
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
				 if (pts) {
					 if (pts->reglist)
						 return pts->value;
				 }
			 }
			 else {
				 if (pts)
					 if (pts->reglist)
						 return 0xFFFF;
			 }
		 }
	 }
   return (regpat);
}


/* ---------------------------------------------------------------
   Description :
      Gets bits pattern for specified registers. Registers may
	be specified individually, in a block or as a range. The '/'
	may be used as a separator for aesthetic reasons.

      fp0-7        range of registers
      fp0fp1fp2    individually specified
	  fp0/fp1/fp2
      fp012        block specified

	Note register pattern is reverse order compared to
	integer set.

   Returns :
--------------------------------------------------------------- */

int IsFPRegList(char *s)
{
   int regpat;
   int LastDigit, NewDigit;
   char *ptr;

   ptr = s;
   regpat = 0;
	while(isspace(*ptr)) ptr++;
	// ignore REGS designator
	if (!strnicmp(ptr, "REGS", 4)) {
		ptr += 4;
		if (IsIdentChar(*ptr))
			return 0;
	}
	while(isspace(*ptr)) ptr++;
   while(*ptr)
   {
	   // skip any spaces encountered
	   while(isspace(*ptr)) ptr++;
      switch(*ptr)
      {
		  // Allow use of '/' to separate address/data/registers
		case '/':
			break;
         /* ----------------------------------------
               Set bits for a range of registers.
         ---------------------------------------- */
         case '-':
            ptr++;
            for (; *ptr && !isdigit(*ptr); ptr++);
            if (*ptr)
            {
               NewDigit = *ptr - '0';
			   if (NewDigit >= LastDigit) {
				for(LastDigit++; NewDigit >= LastDigit; LastDigit++)
                     regpat |= (1 << LastDigit);
				LastDigit--;
			   }
			   else {
				for(LastDigit--; NewDigit <= LastDigit; LastDigit--)
                     regpat |= (1 << LastDigit);
				LastDigit++;
			   }
            }
            else
               err(NULL, E_INVREG, ptr);
            --ptr;   // allow for ptr++ at end of loop.
            break;

         /* ----------------------------------
			ignore fp designation
         ---------------------------------- */
         case 'f':
         case 'F':
		 case 'p':
		 case 'P':
            break;

         default:
            if (isdigit(*ptr))
            {
               LastDigit = *ptr - '0';
               regpat |= (1 << LastDigit);
            }
			// if other 'junk' return
			else
				return 0;
      }
      ptr++;
   }
   regpat = ReverseBitsByte(regpat);
   return (regpat);
}


/* -------------------------------------------------------------------
   Description :
------------------------------------------------------------------- */
int IsFPCRList(char *s)
{
	char *ptr = s;
	unsigned __int8 fFPCR = 0;
	unsigned __int8 fFPSR = 0;
	unsigned __int8 fFPIAR = 0;

	while(isspace(*ptr)) ptr++;
	// ignore REGS designator
	if (!strnicmp(ptr, "REGS", 4)) {
		ptr += 4;
		if (IsIdentChar(*ptr))
			return 0;
	}
	while(isspace(*ptr)) ptr++;
	while(*ptr)
	{
		// skip any spaces encountered
		while(isspace(*ptr)) ptr++;
		if (toupper(*ptr) == 'F')
		{
			ptr++;
			if (toupper(*ptr) == 'P')
			{
				ptr++;
				if (toupper(*ptr) == 'C')
				{
					ptr++;
					if (toupper(*ptr) == 'R')
					{
						ptr++;
						fFPCR = 1;
						continue;
					}
					ptr--;
				}
				else if (toupper(*ptr) == 'S')
				{
					ptr++;
					if (toupper(*ptr) == 'R')
					{
						ptr++;
						fFPSR = 1;
						continue;
					}
					ptr--;
				}
				else if (toupper(*ptr) == 'I')
				{
					ptr++;
					if (toupper(*ptr) == 'A')
					{
						ptr++;
						if (toupper(*ptr) == 'R')
						{
							ptr++;
							fFPIAR = 1;
							continue;
						}
					}
					ptr--;
				}
				ptr--;
			}
			ptr--;
		}
		else if (*ptr == '/')
			;
		ptr++;
	}
	return (fFPCR << 12) | (fFPSR << 11) | (fFPIAR << 10);
}


/* -------------------------------------------------------------------
   Description :
      Gets the size character. If size code is present then save it
	and increment pointer to operand.
------------------------------------------------------------------- */

int GetSzChar()
{
   int xx;
   char *eptr;
   SValue val;

   if (ibuf.PeekCh() == '.')
   {
      ibuf.NextCh();
      if (ibuf.PeekCh() == '(')
      {
         ibuf.NextCh();
         val = ibuf.expeval(&eptr);
         xx = val.value;
         if (ibuf.PeekCh() == ')')
            ibuf.NextCh();
         else
            Err(E_PAREN);
		 switch(xx)
		 {
		 case 8:
            return ('B');
		 case 16:
            return ('W');
		 case 32:
            return('L');
		 default:
            return (xx);
		 }
      }
      else
         return(toupper(ibuf.NextCh()));
   }
   return (0);
}


/* -------------------------------------------------------------------
   Description :
		Returns the value of the current counter.
------------------------------------------------------------------- */

long Counter()
{
	//switch(CurrentSection)
	//{
	//case BSS_AREA: return BSSCounter;
	//case DATA_AREA: return DataCounter;
	//}
	//return ProgramCounter;
	return SectionTbl.activeSection->Counter();
}


short int CurrentSection()
{
	return SectionTbl.activeSection->number;
}

/* ---------------------------------------------------------------
   Description :
		Calculates how many words ahead in the instruction
	stream a extension word is located. Assuming the opcode
	has not been output yet, nor has an immediate value of
	size sc been output.

   Returns :

--------------------------------------------------------------- */

long sz46(char sc)
{
	long xx;

	switch(sc)
	{
	case 'B':
	case 'W': xx = 4; break;
	case 'L':
	default: xx = 6;
	}
	return Counter() + xx;
}


/* ---------------------------------------------------------------
  
   int bwl2bit(int s);
   int s;

   Description :
      Converts character code to bit pattern for opcode.

   Returns :
      Bit pattern for size of operator to or with opcode or 64
	  if invalid.

--------------------------------------------------------------- */

int bwl2bit(int s)
{
   switch(toupper(s))
   {
      case 'B': return 0;
      case 'W': return 64;
	  case 0:
      case 'L': return 128;
      default:
         Err(E_LENGTH);
         return (128);
   }
}


/* ---------------------------------------------------------------
   Description :

   Returns :
	Returns format field setting for floating point.
--------------------------------------------------------------- */
int fmt2bit(int s)
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

   Returns :

----------------------------------------------------------------------------- */

void SaveOps()
{
   int ii;

   SaveOpSize = opsize;
   for (ii = 0; ii < opsize; ii++)
      SaveOpCode[ii] = wordop[ii];
}


/* -----------------------------------------------------------------------------
   Description :

   Returns :
----------------------------------------------------------------------------- */

void RestoreOps()
{
   int ii;

   opsize = SaveOpSize;
   for (ii = 0; ii < opsize; ii++)
      wordop[ii] = SaveOpCode[ii];
}


/* -----------------------------------------------------------------------------
   Description :
      Gets control register name.
----------------------------------------------------------------------------- */

int GetCReg(char *buf, int *num)
{
   int ii;
   char *sptr;
   int idlen;
   CBuf bbuf;

   bbuf.set(buf, strlen(buf));
   idlen = bbuf.GetIdentifier(&sptr, NULL, FALSE);
   if (idlen == 0)
      return (FALSE);
                
   for (ii = 0; ii < N_CREG; ii++)
   {
      if (!stricmp(sptr, creg[ii].name))
      {
		  if ((creg[ii].PrcLevel & gProcessor) == 0)
			  Err(E_INVCREG, sptr);
         *num = creg[ii].num;
         return (TRUE);
      }
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Gets control register name.
----------------------------------------------------------------------------- */

int GetMMUReg(char *buf, int *num)
{
   int ii;
   char *sptr;
   int idlen;
   CBuf bbuf;

   bbuf.set(buf, strlen(buf));
   idlen = bbuf.GetIdentifier(&sptr, NULL, FALSE);
   if (idlen == 0)
      return (FALSE);
                
   for (ii = 0; ii < N_MMUREG; ii++)
   {
      if (!stricmp(sptr, mmureg[ii].name))
      {
		  if ((mmureg[ii].PrcLevel & gProcessor) == 0)
			  Err(E_INVMMUREG, sptr);
         *num = mmureg[ii].num;
         return (TRUE);
      }
   }
   return (FALSE);
}


/* -----------------------------------------------------------------------------
   Description :
      Reverses the order of bits in the input pattern.
----------------------------------------------------------------------------- */

int ReverseBits(int inpat)
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

int ReverseBitsByte(int inpat)
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
   Module : invcc.c

   Function :  Copy the opposite of the condition code to the string.
                        "cc" is the inverse of "cs", "eq", "ne", etc. 

   Parameters :

   Returns :
----------------------------------------------------------------------------- */

int invcc(char *s)
{
   static char *cc = "ls~hi~cs~cc~eq~ne~vs~vc~mi~pl~lt~ge~le~gt~";
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





/* -----------------------------------------------------------------------------
   Description :
		Detects FPCR/FPSR/FPIAR

   Returns :
----------------------------------------------------------------------------- */

int IsFPCR(char *str)
{
	while (isspace(*str)) str++;
	if (toupper(*str) != 'F')
		return (0);
	str++;
	if (toupper(*str) != 'P')
		return (0);
	str++;
	if (toupper(*str) == 'C')
	{
		str++;
		if (toupper(*str) != 'R')
			return (0);
		str++;
		if (!IsIdentChar(*str))
			return (4);
	}
	else if (toupper(*str) == 'S')
	{
		str++;
		if (toupper(*str) != 'R')
			return (0);
		str++;
		if (!IsIdentChar(*str))
			return (2);
	}
	else if (toupper(*str) == 'I')
	{
		str++;
		if (toupper(*str) != 'A')
			return (0);
		str++;
		if (toupper(*str) != 'R')
			return (0);
		str++;
		if (!IsIdentChar(*str))
			return (1);
	}
	return (0);
}


