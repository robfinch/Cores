#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fwstr.h>
#include "err.h"
#include "SOut.h"
#include "fasm68.h"

/* ----------------------------------------------------------------------------
   int emitb(byte)
   unsigned int byte;

   Description :
      One the first pass just increments the appropriate counter. On the
   second pass sends a byte to output file and updates the appropriate
   counter.
---------------------------------------------------------------------------- */

void emitb(unsigned int byte)
{
   static int toggle;
   static int LastArea;
   int type;
   static int bcnt = 0;
   static unsigned __int8 byts[4];
	static int bcnt2 = 0;

   if(pass >= lastpass)
   {
      if (ObjOut)
      {
         // If no object code has been output yet then output manufacturer
         // record and object name.
         if (FirstObj)
         {
            ObjFile.uWrite(T_MFCTR, verstr2, strlen(verstr2));
            ObjFile.uWrite(T_NAME, File[0].name, strlen(File[0].name));
            FirstObj = 0;
         }

         // Flush output buffer if output area changed since last time.
         if (LastArea != CurrentSection())
            ObjFile.flush();

         // If the output buffer had to be flushed then we want to set up a
         // new object record.
         if (ObjFile.bWrite(T_VDATA, (char *)&byte, 1))
            ObjFile.ClearBuf();

         // If no data has been output to record yet then output the start
         // of a verbatium data record.
         if (ObjFile.GetLength() == 0)
         {
            switch(CurrentSection())
            {
               case DATA_AREA:
                  type = A_DATA;
                  ObjFile.bWrite(T_VDATA, (char *)&type, 1);
                  //ObjFile.bWrite(T_VDATA, (char *)&DataCounter, 4);
                  break;
               case BSS_AREA:  // No output for uninitialized data
                  break;
               case CODE_AREA:
               default:
                  type = A_CODE;
                  ObjFile.bWrite(T_VDATA, (char *)&type, 1);
                  //ObjFile.bWrite(T_VDATA, (char *)&ProgramCounter, 4);
				  ObjFile.bWrite(T_VDATA, (char *)&SectionTbl.activeSection->counter,4);
                  break;
            }
            ObjFile.bWrite(T_VDATA, (char *)&byte, 1);
         }
         
         LastArea = CurrentSection();
      }

      // Here we're just outputting binary data
      else
      {
		  // Default start address to first location of code
		  // output, if not otherwise defined
		  if (CurrentSection() == CODE_AREA)
		  {
			if (fFirstCode && !fStartDefined)
				StartAddress = SectionTbl.activeSection->Counter();
//				ProgramCounter;
			fFirstCode = FALSE;
		  }
			
		  // There is no output to the BSS area
		  if (!SectionTbl.IsCurrentSection(BSS_AREA))
		  {
			if (fVerilogOut) {
				byts[bcnt] = byte;
				bcnt++;
				if (bcnt==2) {
					fprintf(fpVerilog, "rommem[%d] <= 16'h%02X%02X%;\r\n",
						(unsigned int)(SectionTbl.activeSection->Counter() / 2) % 8192,
						byts[0],byts[1]);
					fprintf(fpMem, "%02X%02X ", byts[0],byts[1]);
					fprintf(fpMem, "\n");
					bcnt = 0;
				}
			}
			if (fBinOut)
			{
				fputc(byte, fpBin);
				if(ferror(fpBin))
					Err(E_WRITEOUT);
			}
			if (fSOut)
			  gSOut.putb(byte);
		  }
      }

      // If a listing is being generated then output data byte
      if(fListing)
      {
emitb1:
         if(col == 1)
         {
            fprintf(fpList, "%7d ", OutputLine);
		  fprintf(fpList, "%08.08lX ", SectionTbl.activeSection->Counter());
            col = 18;
            if (!SectionTbl.IsCurrentSection(BSS_AREA)) {
               fprintf(fpList, "%02.2X", byte);
			   if (giProcessor & PL_FT) {
				   fputc(' ', fpList);
			   }
               if (DoingDef) {
                  switch(gSzChar) {
                     case 'B':
//                        putchar (' ');
						 fputc(' ', fpList);
                        col = 21;
                        break;
					 case 'S':
                     case 'L':
                        col = 20;
                        toggle = 1;
                        break;
                     case 'W':
                     default:
                        col = 20;
                        toggle = 1;
                        break;
                  }
               }
               else {
                  col = 21;
                  toggle = 1;
               }
			   if (giProcessor & PL_FT)
				   col++;
            }
         }
         else
         {
            if (!SectionTbl.IsCurrentSection(BSS_AREA)) {
               if (DoingDef) {
                  switch(gSzChar)
                  {
                     case 'B':
                        fprintf(fpList, "%02.2X ",byte);
                        col += 3;
                        break;
					 case 'S':
                     case 'L':
                        // At first byte of long, check to see if it will fit
                        // on the line.
                        if (toggle == 0) {
                           if (col > 35) {
                              for (; col < 43; col++)
//                                 putchar(' ');
								fputc(' ', fpList);
                              outListLine();
                              *sol = '\0';   // to prevent duplicates
                              goto emitb1;
                           }
                        }
                        fprintf(fpList, "%02.2X",byte);
                        toggle++;
                        col += 2;
                        if (toggle == 4 || (giProcessor & PL_FT)) {
//                           putchar(' ');
							fputc(' ', fpList);
                           col++;
                           toggle = 0;
                        }
                        break;
                     case 'W':
                     default:
                        // At first byte of word, check to see if it will fit
                        // on the line.
                        if (toggle == 0) {
                           if (col > 37) {
                              for (; col < 43; col++)
//                                 putchar(' ');
									fputc(' ', fpList);
                              outListLine();
                              *sol = '\0';   // to prevent duplicates
                              goto emitb1;
                           }
                        }
                        fprintf(fpList, "%02.2X",byte);
                        col += 2;
                        toggle ^= 1;
                        if (toggle == 0 || (giProcessor & PL_FT)) {
//                           putchar(' ');
							fputc(' ', fpList);
                           col++;
                        }
                        break;
                  }
               }
               else {
                  toggle ^= 1;   // (toggle == 0) ? 1 : 0;
                  fprintf(fpList, "%02.2X",byte);
                  if (toggle == 0 || (giProcessor & PL_FT)) {
                     //putchar(' ');
						fputc(' ', fpList);
                  }
				  if (giProcessor & PL_FT)
					  col += 3;
				  else
					  col += 2 + toggle;
               }
            }
         }
         if (col > 41) {
            for (; col < 43; col++)
               //tchar(' ');
			   fputc(' ', fpList);
            outListLine();
            *sol = '\0';   // to prevent duplicates
         }
      }
   }

   // Increment counter for appropriate area
   SectionTbl.activeSection->counter++;
}


/* ----------------------------------------------------------------------------
   emitnull
      Causes address to be displayed in listing   
---------------------------------------------------------------------------- */
void emitnull()
{
   static int toggle;
   static int LastArea;

   if(pass >= lastpass)
   {
      // If a listing is being generated then output data byte
      if(fListing)
      {
         if(col == 1)
         {
            fprintf(fpList, "%7d ", OutputLine);
			fprintf(fpList, "%08.08lX ", SectionTbl.activeSection->Counter());
            col = 18;
         }
      }
   }
}


/* ----------------------------------------------------------------------------
   emitw
   
      Send a word to output file (two bytes). If attempting to output a word
   at a odd address then give warning and pad output to prevent more errors.
---------------------------------------------------------------------------- */

int emitw(unsigned int word)
{
	if (SectionTbl.IsCurrentSection(CODE_AREA) && Counter() & 1)
	{
		Err(E_WORDODD);
		emitb(0);
	}
	if (giProcessor & PL_FT) {
		emitb(word & 0xff);
		emitb((word >> 8) & 0xff); // low order byte then high order byte
	}
	else {
		emitb((word >> 8) & 0xff); // high order byte then low order byte
		emitb(word & 0xff);
	}
	return (TRUE);
}


/* ---------------------------------------------------------------------------
   emits
      Performs same function as emit but outputs only a single character
   for a byte value. Does not check for word alignment. Used for data
   pseudo-op.
--------------------------------------------------------------------------- */

int emits(int size, unsigned __int64 d)
{
	if (giProcessor & PL_FT) {
	   switch(toupper(size))
	   {
		  case 'D':
			 emitb((int)(d & 0xff));
			 emitb((int)((d >> 8) & 0xff));
			 emitb((int)((d >> 16) & 0xff));
			 emitb((int)((d >> 24) & 0xff));  // Note can't use emitw() - no word alignment
			 emitb((int)((d >> 32) & 0xff));
			 emitb((int)((d >> 40) & 0xff));  // Note can't use emitw() - no word alignment
			 emitb((int)((d >> 48) & 0xff));
			 emitb((int)((d >> 56) & 0xff));  // Note can't use emitw() - no word alignment
			 break;
		  case 'S':
		  case 'L':
			 emitb((int)(d & 0xff));
			 emitb((int)((d >> 8) & 0xff));
			 emitb((int)((d >> 16) & 0xff));
			 emitb((int)((d >> 24) & 0xff));  // Note can't use emitw() - no word alignment
			 break;
		  case 'W':
		  default:
			 emitb((int)(d & 0xff));
			 emitb((int)((d >> 8) & 0xff));
			 break;
		  case 'B':
			 emitb((int)(d & 0xff));
			 break;
	   }
	}
	else {
   switch(toupper(size))
   {
	  case 'D':
         emitb((int)((d >> 56) & 0xff));  // Note can't use emitw() - no word alignment
         emitb((int)((d >> 48) & 0xff));
         emitb((int)((d >> 40) & 0xff));  // Note can't use emitw() - no word alignment
         emitb((int)((d >> 32) & 0xff));
         emitb((int)((d >> 24) & 0xff));  // Note can't use emitw() - no word alignment
         emitb((int)((d >> 16) & 0xff));
         emitb((int)((d >> 8) & 0xff));
         emitb((int)(d & 0xff));
		 break;
	  case 'S':
      case 'L':
         emitb((int)((d >> 24) & 0xff));  // Note can't use emitw() - no word alignment
         emitb((int)((d >> 16) & 0xff));
         emitb((int)((d >> 8) & 0xff));
         emitb((int)(d & 0xff));
		 break;
      case 'W':
      default:
         emitb((int)((d >> 8) & 0xff));
         emitb((int)(d & 0xff));
		 break;
      case 'B':
         emitb((int)(d & 0xff));
         break;
   }
	}
   return (TRUE);
}


/* ----------------------------------------------------------------------------
   emit - emit the proper size operand variable 
---------------------------------------------------------------------------- */

int emit(int size, unsigned __int64 data)
{
	if (giProcessor & PL_FT) {
	  switch(toupper(size))
	  {
		case 'B':
		   data &= 0xff;
		   emitw((int) data);
		   break;
		case 'D':
		   emitw((unsigned int) (data & 0xffff));
		   emitw((unsigned int) ((data >> 16) & 0xffff));
		   emitw((unsigned int) ((data >> 32) & 0xffff));
		   emitw((unsigned int) ((data >> 48) & 0xffff));
		   break;
		case 0:
		case 'L': 
		   emitw((unsigned int) (data & 0xffff));
		   emitw((unsigned int) ((data >> 16) & 0xffff));
		   break;
		case 'W':
		   emitw((unsigned int) (data & 0xffff));
		   break;

		default: break;
	  }
	}
	else {
  switch(toupper(size))
  {
    case 'B':
       data &= 0xff;
       emitw((int) data);
       break;
	case 'D':
       emitw((unsigned int) ((data >> 48) & 0xffff));
       emitw((unsigned int) ((data >> 32) & 0xffff));
	case 0:
    case 'L': 
       emitw((unsigned int) ((data >> 16) & 0xffff));
    case 'W':
       emitw((unsigned int) (data & 0xffff));
       break;

    default: break;
  }
	}
  return (TRUE);
}


/* ----------------------------------------------------------------------------
   emitrest
   
      Send out rest of words in operand      
---------------------------------------------------------------------------- */

int emitrest()
{
  int i;

  for(i = 1; i < opsize; i++)
     emitw(wordop[i]);
  return (TRUE);
}


/* ----------------------------------------------------------------------------
	Emit immediate value according to size specifier character.
---------------------------------------------------------------------------- */

void emitimm(char sz)
{
	if (giProcessor & PL_FT) {
		switch(sz) {
		case 'D':
			emitw(wordop[4]);
			emitw(wordop[3]);
			emitw(wordop[2]);
			emitw(wordop[1]);
			break;
		case 'S':
		case 'L':
		case 0:
			emitw(wordop[4]);
			emitw(wordop[3]);
			break;
		case 'B':
		case 'W':
			emitw(wordop[4]);
		}
	}
	else {
		switch(sz) {
		case 'D':
			emitw(wordop[1]);
			emitw(wordop[2]);
		case 'S':
		case 'L':
		case 0:
			emitw(wordop[3]);
		case 'B':
		case 'W':
			emitw(wordop[4]);
		}
	}
}


/* -----------------------------------------------------------------------------
   
   stdemit()
   char *exp;	// string containing address mode
   int amd;		// allowable address modes

   Description:
      Common routine for spitting out opcodes.

	AM_DR        1        // a Dn
	AM_AR        2        // b An
	AM_AR_IND    4        // c (An)
	AM_AR_POST   8        // d (An)+

	AM_AR_PRE    16       // e -(An)
	AM_AR_DISP   32       // f d16(An)
	AM_AR_NDX    64       // g d8(An, Xn.s)
	AM_ABS_SHORT 128      // h (abs).w

	AM_ABS_LONG  256      // i (abs).l
	AM_PC_REL    512      // j d16(PC)
	AM_PC_NDX    1024     // k d8(PC, Xn.s)
	AM_IMMEDIATE 2048     // l #

	AM_MEM       4096     // ([
	AM_MEM_PC	 8192

	AM_BITFLD	32768
	AM_FPR		1<<16
0x11f4
----------------------------------------------------------------------------- */

int stdemit(char *exp, int amd, int reg, int s, int op)
{
   int oppat = 0, ea;

   ea = OpType(exp, &oppat, Counter() + 2);
   if ((ea & amd) == 0)
	   Err(E_ILLADMD, exp);
   emitw(op | ((s == 'x') ? 0 : bwl2bit(s)) | oppat | RegFld2(reg));
   if (lastsym)
	lastsym->AddReference(Counter());
   /*
		Immediate mode patch. OpType just returns a 32-bit
		immediate value because it doesn't know the operation
		size. If we really only wanted a byte or word we have to
		take care of this specially.
   */
   if(ea == AM_IMMEDIATE)
	emitimm(s);
   else
      emitrest();
   return (TRUE);
}


/* -----------------------------------------------------------------------------
   
   stdemit1()
   int md;	// allowable address mode pattern
   int op;	// base opcode

----------------------------------------------------------------------------- */

int stdemit1(int md, int op)
{
   int ocpat = 0;

   if(!(OpType(gOperand[0], &ocpat, Counter() + 2) & md))
	   Err(E_ILLADMD, gOperand[0]);
   emitw(op | ocpat);
   if (lastsym)
	lastsym->AddReference(Counter());
   emitrest();
   return (TRUE);
}

