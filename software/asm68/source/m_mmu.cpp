#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <fwstr.h>
#include "asmbuf.h"
#include "fasm68.h"

/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
static int GetFCEncoding()
{
	int Dn;
	int bits;

	if (!stricmp(gOperand[0], "SFC"))
		return 0;
	if (!stricmp(gOperand[0], "DFC"))
		return 1;
	if (IsDReg(gOperand[0], &Dn))
		return (8 | RegFld(Dn));
	if (gOperand[0][0] == '#')
	{
		bits = expeval(&gOperand[0][1], NULL).value;
		if (bits < 0 || bits > 7)
			Err(E_FCSEL, bits);
		bits &= 7;
		return (16 | bits);
	}
	return 0;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pbcc(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int val;

	if (gSzChar == 0) gSzChar = 'W';
	if (gSzChar != 'W' && gSzChar != 'L')
		Err(E_ONLYWL);
	if (gSzChar == 'L')
		op |= 0x40;
	emitw(op);
	val = expeval(gOperand[0], NULL).value;
	val -= Counter();
	if (gSzChar == 'L')
		emitw(val >> 16);
	emitw(val);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pdbcc(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int val, reg = 0;

	if (gSzChar != 0)
		if (gSzChar != 'W')
			Err(E_WORDONLY);
	if (!IsDReg(gOperand[0], &reg))
		Err(E_DATAREG, gOperand[0]);
	emitw(op | RegFld(reg));
	emitw(op2);
	val = expeval(gOperand[1], NULL).value;
	val -= Counter();
	emitw(val);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
	pflush / pflushs
--------------------------------------------------------------- */
int m_pflush(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int ot, pat = 0;
	int An = 0;
	int fc = 0;

	if (gProcessor & (PL_3 | PL_M))
	{
		int mask = 0;

		if (g_nops < 2) {
			Err(E_2FEWOPS);
			goto jmp1;
		}
		if (gOperand[1][0] == '#')
			mask = expeval(&gOperand[1][1], NULL).value;
		else
			mask = expeval(&gOperand[1][0], NULL).value;
		if (mask < 0 || mask > 7)
			Err(E_MASK2, mask);
		mask &= 7;

		fc = GetFCEncoding();
		if (g_nops == 3)
		{
			ot = OpType(gOperand[2], &pat, Counter()+4);
			if (!(ot & AM_CTLALT))
				Err(E_ILLADMD, gOperand[2]);
jmp1:
			op |= pat;
			emitw(op);
			emitw(op2 | (6 << 10) | (mask << 5) | fc);
			emitrest();
			return TRUE;
		}
		emitw(op);
		emitw(op2 | (4 << 10) | (mask << 5) | fc);
		return TRUE;
	}
	if (gProcessor & (PL_4 | PL_LC40 | PL_EC40))
	{
		if (gProcessor & PL_EC40)
			Err(W_EC40);
		ot = OpType(gOperand[0], &pat, Counter()+2);
		if (!(ot & AM_AR_IND))
			Err(E_ILLADMD, gOperand[0]);
		An = pat & 7;
		emitw(0xf500 | (1 << 3) | RegFld(An));
		return TRUE;
	}
	return FALSE;
}



/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pflusha(SOp *o)
{
	if (gProcessor & (PL_3 | PL_M))
	{
		emitw(0xf000 | mmu_cpid);
		emitw(0x2400);
		return TRUE;
	}
	if (gProcessor & PL_4)
	{
		emitw(0xf518);
		return TRUE;
	}
	return FALSE;
}



/* ---------------------------------------------------------------
   Description :
	68040 only
--------------------------------------------------------------- */

int m_pflushn(SOp *o)
{
	int ot, An = 0;
	int pat;

	ot = OpType(gOperand[0], &pat, Counter()+2);
	if (!(ot & AM_AR_IND))
		Err(E_ILLADMD, gOperand[0]);
	An = pat & 7;
	emitw(o->ocode | RegFld(An));
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
	pflushr
	68851 only
--------------------------------------------------------------- */

int m_pflushr(SOp *o)
{
	int ot, An = 0;
	int pat;

	ot = OpType(gOperand[0], &pat, Counter()+4);
	if (!(ot & AM_MEMORY))
		Err(E_ILLADMD, gOperand[0]);
	emitw(o->ocode | pat | mmu_cpid);
	emitw(o->ocode2);
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pload(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int ot, pat;
	int An = 0;
	int fc = GetFCEncoding();

	ot = OpType(gOperand[1], &pat, Counter()+4);
	if (!(ot & AM_CTLALT))
		Err(E_ILLADMD, gOperand[1]);

	op |= pat;
	emitw(op);
	emitw(op2 | fc);
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int m_pmove(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int rg;
	int ot, pat = 0;
	int rw = 0;
	int fMMUReg = 0;

	// Is MMU register source ?
	if (gProcessor & PL_3)
	{
		fMMUReg = GetMMUReg(gOperand[0], &rg);
		if (fMMUReg)
		{
			rw = 1;
			ot = OpType(gOperand[1], &pat, Counter()+4);
			if (!(ot & AM_CTLALT))
				goto j68851;	// could be pmmu inst.
			if (rg == MMU_SRP || rg == MMU_CRP || rg == MMU_TC ||
				rg == MMU_TT0 || rg == MMU_TT1)
			{
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			if (rg == MMU_PSR)
			{
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			goto j68851;	// could be pmmu reg
		}
		// Is MMU register destination ?
		fMMUReg = GetMMUReg(gOperand[1], &rg);
		if (fMMUReg)
		{
			rw = 0;
			ot = OpType(gOperand[0], &pat, Counter()+4);
			if (!(ot & AM_CTLALT))
				goto j68851;	// could be pmmu inst.
			if (rg == MMU_SRP || rg == MMU_CRP || rg == MMU_TC ||
				rg == MMU_TT0 || rg == MMU_TT1)
			{
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			if (rg == MMU_PSR)
			{
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			goto j68851;	// could be pmmu reg
		}
		// The mmu coprocessor could be enabled
		// so don't return false yet
	}
	// 68EC030
	else if (gProcessor & PL_EC30)
	{
		fMMUReg = GetMMUReg(gOperand[0], &rg);
		if (fMMUReg)
		{
			rw = 1;
			ot = OpType(gOperand[1], &pat, Counter()+4);
			if (!(ot & AM_CTLALT))
				goto j68851;	// could be pmmu inst.
			if (rg == MMU_AC0 || rg == MMU_AC1)
			{
				if (gSzChar && gSzChar != 'L')
					Err(E_ONLYLONG);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			if (rg == MMU_ACUSR)
			{
				if (gSzChar && gSzChar != 'W')
					Err(E_WORDONLY);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			goto j68851;	// could be pmmu reg
		}
		// Is MMU register destination ?
		fMMUReg = GetMMUReg(gOperand[1], &rg);
		if (fMMUReg)
		{
			rw = 0;
			ot = OpType(gOperand[0], &pat, Counter()+4);
			if (!(ot & AM_CTLALT))
				goto j68851;	// could be pmmu inst.
			if (rg == MMU_AC0 || rg == MMU_AC1)
			{
				if (gSzChar && gSzChar != 'L')
					Err(E_ONLYLONG);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			if (rg == MMU_ACUSR)
			{
				if (gSzChar && gSzChar != 'W')
					Err(E_WORDONLY);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			goto j68851;	// could be pmmu reg
		}
		// The mmu coprocessor could be enabled
		// so don't return false yet
	}
j68851:
	// 68851
	if (gProcessor & PL_M)
	{
		fMMUReg = GetMMUReg(gOperand[0], &rg);
		if (fMMUReg)
		{
			rw = 1;
			ot = OpType(gOperand[1], &pat, Counter()+4);
			if (!(ot & AM_ALT))
				Err(E_ILLADMD, gOperand[1]);
			if (rg == MMU_SRP || rg == MMU_CRP || rg == MMU_TC ||
				rg == MMU_DRP || rg == MMU_CAL || rg == MMU_VAL ||
				rg == MMU_SCC || rg == MMU_AC ||
				rg == MMU_BAD0 || rg == MMU_BAD1 ||
				rg == MMU_BAD2 || rg == MMU_BAD3 ||
				rg == MMU_BAD4 || rg == MMU_BAD5 ||
				rg == MMU_BAD6 || rg == MMU_BAD7 ||
				rg == MMU_BAC0 || rg == MMU_BAC1 ||
				rg == MMU_BAC2 || rg == MMU_BAC3 ||
				rg == MMU_BAC4 || rg == MMU_BAC5 ||
				rg == MMU_BAC6 || rg == MMU_BAC7 ||
				rg == MMU_PSR || rg == MMU_PCSR)

			{
				if (ot & AM_RN)
					if (rg == MMU_CRP || rg == MMU_SRP || rg == MMU_DRP)
						err(NULL, E_ILLADMD, gOperand[0]);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			emitw(op | pat);
			emitw(op2 | (rw << 9));
			emitrest();
			return TRUE;
		}
		// Is MMU register destination ?
		fMMUReg = GetMMUReg(gOperand[1], &rg);
		if (fMMUReg)
		{
			rw = 0;
			ot = OpType(gOperand[0], &pat, Counter()+4);
			if (!(ot & AM_ANY))
				Err(E_ILLADMD, gOperand[0]);
			if (rg == MMU_SRP || rg == MMU_CRP || rg == MMU_TC ||
				rg == MMU_DRP || rg == MMU_CAL || rg == MMU_VAL ||
				rg == MMU_SCC || rg == MMU_AC ||
				rg == MMU_BAD0 || rg == MMU_BAD1 ||
				rg == MMU_BAD2 || rg == MMU_BAD3 ||
				rg == MMU_BAD4 || rg == MMU_BAD5 ||
				rg == MMU_BAD6 || rg == MMU_BAD7 ||
				rg == MMU_BAC0 || rg == MMU_BAC1 ||
				rg == MMU_BAC2 || rg == MMU_BAC3 ||
				rg == MMU_BAC4 || rg == MMU_BAC5 ||
				rg == MMU_BAC6 || rg == MMU_BAC7 ||
				rg == MMU_PSR || rg == MMU_PCSR)
			{
				if (ot & AM_RN)
					if (rg == MMU_CRP || rg == MMU_SRP || rg == MMU_DRP)
						Err(E_ILLADMD, gOperand[0]);
				emitw(op | pat);
				emitw(op2 | rg | (rw << 9));
				if (ot & AM_IMMEDIATE) {
					switch(rg) {
					case MMU_SRP:
					case MMU_DRP:
					case MMU_CRP:
						emitw(wordop[1]);
						emitw(wordop[2]);
					case MMU_TC:
						emitw(wordop[3]);
					case MMU_AC:
					case MMU_PSR:
					case MMU_PCSR:
					case MMU_BAD0:
					case MMU_BAD1:
					case MMU_BAD2:
					case MMU_BAD3:
					case MMU_BAD4:
					case MMU_BAD5:
					case MMU_BAD6:
					case MMU_BAD7:
					case MMU_BAC0:
					case MMU_BAC1:
					case MMU_BAC2:
					case MMU_BAC3:
					case MMU_BAC4:
					case MMU_BAC5:
					case MMU_BAC6:
					case MMU_BAC7:
						emitw(wordop[4]);
						break;
					case MMU_CAL:
					case MMU_VAL:
					case MMU_SCC:
						emitw(wordop[4] & 0xff);
						break;
					}
				}		
				else
					emitrest();
				return TRUE;
			}
			// any other register should be trapped in GetMMUReg
			emitw(op | pat);
			emitw(op2 | (rw << 9));
			emitrest();
			return TRUE;
		}
	}
	return FALSE;
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int m_prestore(SOp *o)
{
   return (stdemit1(AM_CTLPOST, o->ocode | mmu_cpid));
}


/* ---------------------------------------------------------------
--------------------------------------------------------------- */
int m_psave(SOp *o)
{
   return (stdemit1(AM_CALTPRE, o->ocode | mmu_cpid));
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pscc(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int ot, pat = 0;

	if (gSzChar && gSzChar != 'B')
		Err(E_ONLYBYTE);
	ot = OpType(gOperand[0], &pat, Counter()+4);
	if (!(ot & AM_DATALT))
		Err(E_ILLADMD, gOperand[0]);

	emitw(op | pat);
	emitw(op2);
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_ptest(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int ot, pat;
	int An = 0;
	int fc = 0;
	int level = 0;

	if (gProcessor & (PL_3 | PL_M | PL_EC30))
	{
		fc = GetFCEncoding();
		ot = OpType(gOperand[1], &pat, Counter()+4);
		if (!(ot & AM_CTLALT))
			Err(E_ILLADMD, gOperand[1]);
		op |= pat;
		emitw(op);

		if (!(gProcessor & PL_EC30))
		{
			if (gOperand[2][0] != '#')
				level = expeval(&gOperand[2][0], NULL).value;
			else
				level = expeval(&gOperand[2][1], NULL).value;
			if (level < 0 || level > 7)
				Err(E_MMULEVEL, level);
			level &= 7;

			if (g_nops == 4)
			{
				op2 |= (1 << 8);
				if (gProcessor & PL_M)
				{
					ot = OpType(gOperand[3], &pat, Counter()+2);
					An = pat & 7;
					if (!(ot & AM_AR_IND))
						Err(E_ILLADMD, gOperand[3]);
				}
				else
				{
					if (!IsAReg(gOperand[3], &An))
						Err(E_XADREG, gOperand[3]);
				}
				op2 |= RegFld5(An);
			}
		}
		else
		{
			if (g_nops != 2)
				Err(E_NOPERAND, 2);
			level = 0;
		}

		op2 |= (level << 10) | fc;
		emitw(op2);
		emitrest();
		return TRUE;
	}

	else if (gProcessor & PL_EC30)
	{
		if (g_nops != 2)
			Err(E_NOPERAND, 2);
		fc = GetFCEncoding();
		ot = OpType(gOperand[1], &pat, Counter()+4);
		if (!(ot & AM_CTLALT))
			Err(E_ILLADMD, gOperand[1]);
		op |= pat;
		emitw(op);
		level = 0;
		op2 |= (level << 10) | fc;
		emitw(op2);
		emitrest();
		return TRUE;
	}

	else if (gProcessor & (PL_4 | PL_EC40))
	{
		if (gProcessor & PL_EC40)
			Err(W_EC40);
		if (g_nops != 1)
			Err(E_NOPERAND, 1);
		ot = OpType(gOperand[0], &pat, Counter()+2);
		if (!(ot & AM_AR_IND))
			Err(E_ILLADMD, gOperand[0]);
		An = pat & 7;
		emitw(0xf548 | RegFld(An) | ((op & 0x200) ? (1 << 5) : 0));
		return TRUE;
	}
	return FALSE;
}


/* ---------------------------------------------------------------
   Description :
	see also m_trapcc
--------------------------------------------------------------- */
int m_ptrapcc(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;

	if ((gOperand[0] && gOperand[0][0] != '#') ||
		(gOperand[1] != NULL))
		return FALSE;

	if (gOperand[0])
	{
		SValue val;

		if (gSzChar == 0) gSzChar = 'L';
		if (gSzChar != 'W' && gSzChar != 'L')
		{
			Err(E_ONLYWL);
			if (gSzChar == 'B')
				gSzChar = 'W';
			else
				gSzChar = 'L';
		}
		val = expeval(&gOperand[0][1], NULL);
		emitw(op | ((gSzChar == 'W') ? 2 : 3));
		emitw(op2);
		emit(gSzChar, val.value);
		return TRUE;
	}
	emitw(op | 4);
	emitw(op2);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_pvalid(SOp *o)
{
	int op = o->ocode | mmu_cpid;
	int op2 = o->ocode2;
	int ot, pat = 0;
	int An = 0;
	
	ot = OpType(gOperand[1], &pat, Counter()+4);
	if (!(ot & AM_CTLALT))
		Err(E_ILLADMD, gOperand[1]);
	op |= pat;
	emitw(op);
	if (IsAReg(gOperand[0], &An))
		op2 |= 0x0800 | RegFld(An);
	else
	{
		if (!strimat(gOperand[0], " VAL"))
			Err(E_INVREG, gOperand[0]);
	}
	emitw(op2);
	emitrest();
	return TRUE;
}
