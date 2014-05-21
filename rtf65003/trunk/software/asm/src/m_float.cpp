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
int m_fabs(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int ot, pat = 0;
	int rm = 0;
	int dr = 0;
	int sr = 0;

	op |= fp_cpid;
	if (g_nops == 1)
	{
		emitw(op);
		if (!IsFPReg(gOperand[0], &dr))
			err(NULL, E_EXPECTREG);
		emitw(op2 | (dr << 10) | RegFld7(dr));
		return TRUE;
	}

	if (g_nops != 2)
		err(NULL, E_OPERANDS);

	if (!IsFPReg(gOperand[1], &dr))
		err(NULL, E_EXPECTREG);
	ot = OpType(gOperand[0], &pat, Counter().val+4);
	if (ot & AM_FPR)	// is first operand FPn ?
	{
		emitw(op);
		sr = (pat & 7);
		emitw(op2 | (sr << 10) | RegFld7(dr));
		return TRUE;
	}

	if (!(ot & AM_DATA))
		err(NULL, E_INVOPERAND, gOperand[0]);
	if (ot & AM_DR)
	{
		if (!strchr("BWLS", gSzChar))
			err(NULL, E_BWLS);
	}
	emitw(op | pat);
	emitw(op2 | 0x4000 | (fmt2bit(gSzChar) << 10) | RegFld7(dr));
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fbcc(SOp *o)
{
	int op = o->ocode;
	int val;

	op |= fp_cpid;
	if (gSzChar == 0) gSzChar = 'W';
	if (gSzChar != 'W' && gSzChar != 'L')
		err(NULL, E_ONLYWL);
	if (gSzChar == 'L')
		op |= 40;
	emitw(op);
	val = expeval(gOperand[0], NULL).value;
	val -= Counter().val;
	if (gSzChar == 'L')
		emitw(val >> 16);
	emitw(val);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fdbcc(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int val, reg = 0;

	op |= fp_cpid;
	if (gSzChar != 0)
		if (gSzChar != 'W')
			err(NULL, E_WORDONLY);
	if (!IsDReg(gOperand[0], &reg))
		err(NULL, E_DATAREG, gOperand[0]);
	emitw(op | RegFld(reg));
	emitw(op2);
	val = expeval(gOperand[1], NULL).value;
	val -= Counter.val();
	emitw(val);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fmove(SOp *o)
{
	int op = o->ocode | fp_cpid;
	int op2 = o->ocode2;
	int ot, pat;
	int dr = 0, sr = 0;
	int cr;

	// fmove.l FPCR,<ea>
	cr = IsFPCR(gOperand[0]);
	if (cr)
	{
		if (gSzChar != 'L' && gSzChar != 0)
			err(NULL, E_ONLYLONG);
		ot = OpType(gOperand[1], &pat, Counter().val+4);
		if (!(ot & AM_ALT) || (cr != 1 && (ot & AM_AR)))
			err(NULL, E_ILLADMD, gOperand[1]);
		op |= pat; 
		op2 |= 0x2000; // set dr bit
		op2 |= 0x8000 | (cr << 10);
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}
	// fmove.l <ea>,FPCR
	cr = IsFPCR(gOperand[1]);
	if (cr)
	{
		if (gSzChar != 'L' && gSzChar != 0)
			err(NULL, E_ONLYLONG);
		ot = OpType(gOperand[0], &pat, Counter().val+4);
		if (!(ot & AM_ANY) || (cr != 1 && (ot & AM_AR)))
			err(NULL, E_ILLADMD, gOperand[0]);
		op |= pat; 
		op2 |= 0x8000 | (cr << 10);
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}
	if (gSzChar == 0) gSzChar = 'S';
	ot = OpType(gOperand[0], &pat, Counter().val+4);
	if (!(ot & 0x13ffd))
		err(NULL, E_INVOPERAND, gOperand[0]);
	if ((ot & AM_DR) == AM_DR)
	{
		if (!strchr("BWLS", gSzChar))
		{
			err(NULL, E_OPSIZE);
			gSzChar = 'S';
		}
	}
	// memory / data reg to FPn
	if ((ot & AM_FPR) != AM_FPR)
	{
		if (!IsFPReg(gOperand[1], &dr))
			err(NULL, E_FPREG, gOperand[1]);
		emitw(op | pat);
		emitw(op2 | 0x4000 | (fmt2bit(gSzChar) << 10) | (dr << 7));
		emitrest();
		return TRUE;
	}
	sr = pat & 7;
	// FPn to memory
	if (!IsFPReg(gOperand[1], &dr))
	{
		op2 |= 0x6000;
		// need k factor ?
		gOpType.k_factor = FALSE;
		if (gSzChar == 'P')
		{
			gOpType.k_factor = TRUE;	// search for k_factor
			ot = OpType(gOperand[1], &pat, Counter().val+4);
			if (!(ot & AM_DATA))
				err(NULL, E_INVOPERAND, gOperand[0]);
			if (ot & AM_DR)
			{
				if (!strchr("BWLS", gSzChar))
					err(NULL, E_BWLS);
			}
			if (!gOpType.k_factor)
				err(NULL, E_KFACT);
			op2 |= (sr << 7);
			if (gOpType.k_IsReg)
				op2 |= ((7 << 10) | (gOpType.k_reg << 4));
			else
				op2 |= (3 << 10) | (gOpType.k_imm & 127);
			emitw(op | pat);
			emitw(op2);
			emitrest();
			return TRUE;
		}
		ot = OpType(gOperand[1], &pat, Counter().val+4);
		if (!(ot & AM_DATA))
			err(NULL, E_INVOPERAND, gOperand[0]);
		if (ot & AM_DR)
		{
			if (!strchr("BWLS", gSzChar))
				err(NULL, E_BWLS);
		}
		op2 |= (fmt2bit(gSzChar) << 10) | (sr << 7);
		emitw(op | pat);
		emitw(op2);
		emitrest();
		return TRUE;
	}	
	// FPn to FPm
	emitw(op);
	sr = (pat & 7);
	emitw(op2 | (sr << 10) | (dr << 7));
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fmovecr(SOp *o)
{
	int op = o->ocode | fp_cpid;
	int op2 = o->ocode2;
	int val, dr = 0;
	int xx;
	static int legalcr[] = { 0, 0xb, 0xc, 0xd, 0xe, 0xf, 0x30,
		0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
		0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f };

	if (gSzChar && gSzChar != 'X')
		err(NULL, E_ONLYX);
	if (gOperand[0][0] != '#')
		err(NULL, E_SOURCEIMM, gOperand[0]);
	if (!IsFPReg(gOperand[1], &dr))
		err(NULL, E_FPREG, gOperand[1]);
	val = expeval(&gOperand[0][1], NULL).value;
	for (xx = sizeof(legalcr) / sizeof(int) - 1; xx >=0; xx--)
		if (val == legalcr[xx]) break;
	if (xx >= 0)
		err(NULL, E_ROMCONSTANT, val);
	val &= 0x7f;
	op2 |= val;
	op2 |= RegFld7(dr);
	emitw(op);
	emitw(op2);
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fmovem(SOp *o)
{
	int op = o->ocode | fp_cpid;
	int op2 = o->ocode2;
	int ot, pat = 0;
	int nn = 0;
	int fToMem = 1;
	int crpat = 0;
	int rlpat = 0;
	int Dn = 0;
	__int8 fDns = 0;
	__int8 fDnd = 0;

	fDns = IsDReg(gOperand[0], &Dn);
	// if the source dynamic
	if (fDns)
	{
		// Size must be 'X' or unspecified
		if (gSzChar != 'X' && gSzChar != 0)
			err(NULL, E_ONLYX);
		ot = OpType(gOperand[1], &pat, Counter().val+4);
		if (ot & AM_AR_PRE)	// predecrement mode
		{
			op2 |= (1 << 14) | (1 << 11) | (1 << 13) | RegFld4(Dn);
			op |= pat;
			emitw(op);
			emitw(op2);
			emitrest();
			return TRUE;
		}
		if (ot & 0x11f4)
			;
		else
			err(NULL, E_ILLADMD, gOperand[1]);
		op2 |= (1 << 14) | (3 << 11) | (1 << 13) | RegFld4(Dn);
		op |= pat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}
	fDnd = IsDReg(gOperand[1], &Dn);
	// if the destination is dynamic
	if (fDnd)
	{
		// Size must be 'X' or unspecified
		if (gSzChar != 'X' && gSzChar != 0)
			err(NULL, E_ONLYX);
		ot = OpType(gOperand[0], &pat, Counter().val+4);
		if (ot & 0x37ec)
			;
		else
			err(NULL, E_ILLADMD, gOperand[0]);
		op2 |= (1 << 14) | (3 << 11) | (0 << 13) | RegFld4(Dn);
		op |= pat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}

	// static encodings
	crpat = IsFPCRList(gOperand[0]);
	// source cr list ?
	if (crpat)
	{
		// Size must be 'L' or unspecified
		if (gSzChar != 'L' && gSzChar != 0)
			err(NULL, E_ONLYLONG);
		ot = OpType(gOperand[1], &pat, Counter().val+4);
		if (!(ot & AM_ALT))
			err(NULL, E_ILLADMD, gOperand[1]);
		// must be single register for Dn
		if (ot & AM_DR)
		{
			if (crpat != 0x40 && crpat != 0x80 && crpat != 0x100)
				err(NULL, E_ILLADMD, gOperand[1]);
		}
		if (ot & AM_AR)
			if (crpat != 0x40)
				err(NULL, E_ILLADMD, gOperand[1]);
		op |= pat;
		op2 |= (1 << 13) | crpat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}
	// destination cr list ?
	crpat = IsFPCRList(gOperand[1]);
	// source cr list ?
	if (crpat)
	{
		// Size must be 'L' or unspecified
		if (gSzChar != 'L' && gSzChar != 0)
			err(NULL, E_ONLYLONG);
		ot = OpType(gOperand[0], &pat, Counter().val+4);
		if (!(ot & 0x3fff))
			err(NULL, E_ILLADMD, gOperand[0]);
		// must be single register for Dn
		if (ot & AM_DR)
		{
			if (crpat != 0x40 && crpat != 0x80 && crpat != 0x100)
				err(NULL, E_ILLADMD, gOperand[0]);
		}
		if (ot & AM_AR)
			if (crpat != 0x40)
				err(NULL, E_ILLADMD, gOperand[0]);
		op |= pat;
		op2 |= (0 << 13) | crpat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}


	// source register list ?
	rlpat = IsFPRegList(gOperand[0]);
	if (rlpat)
	{
		// Size must be 'X' or unspecified
		if (gSzChar != 'X' && gSzChar != 0)
			err(NULL, E_ONLYX);
		ot = OpType(gOperand[1], &pat, Counter().val+4);
		if (!(ot & 0x11f4))
			err(NULL, E_ILLADMD, gOperand[1]);
		// reverse order of reglist for -(An)
		if (ot & AM_AR_PRE)
		{
			rlpat = ReverseBitsByte(rlpat);

			op2 |= (1 << 14) | (0 << 11) | (1 << 13) | (rlpat & 0xff);
			op |= pat;
			emitw(op);
			emitw(op2);
			emitrest();
			return TRUE;
		}
		op2 |= (1 << 14) | (2 << 11) | (1 << 13) | (rlpat & 0xff);
		op |= pat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}

	// destination register list ?
	rlpat = IsFPRegList(gOperand[1]);
	if (rlpat)
	{
		// Size must be 'X' or unspecified
		if (gSzChar != 'X' && gSzChar != 0)
			err(NULL, E_ONLYX);
		ot = OpType(gOperand[0], &pat, Counter().val+4);
		if (!(ot & 0x37ec))
			err(NULL, E_ILLADMD, gOperand[0]);

		op2 |= (1 << 14) | (2 << 11) | (0 << 13) | (rlpat & 0xff);
		op |= pat;
		emitw(op);
		emitw(op2);
		emitrest();
		return TRUE;
	}

	// something else
	return FALSE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fnop(SOp *o)
{
	int op = o->ocode | fp_cpid;
	int op2 = o->ocode2;

	emitw(op);
	emitw(op2);
	return TRUE;
}



/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_frestore(SOp *o)
{
	return (stdemit1(AM_CTLPOST, o->ocode | fp_cpid));
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fsave(SOp *o)
{
    return (stdemit1(AM_CALTPRE, o->ocode | fp_cpid));
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fscc(SOp *o)
{
	int op = o->ocode | fp_cpid;
	int op2 = o->ocode2;
	int ot, pat = 0;

	if (gSzChar && gSzChar != 'B')
		err(NULL, E_ONLYBYTE);
	ot = OpType(gOperand[0], &pat, Counter().val+4);
	if (!(ot & AM_DATALT))
		err(NULL, E_ILLADMD, gOperand[0]);

	emitw(op | pat);
	emitw(op2);
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
--------------------------------------------------------------- */
int m_fsincos(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int rm = 0;
	int ds = 0, dc = 0;
	int sr = 0;
	int ot, pat = 0;

	op |= fp_cpid;

	if (!IsFPRegPair(gOperand[1], &ds, &dc))
		err(NULL, E_REGPAIR, gOperand[1]);
	ot = OpType(gOperand[0], &pat, Counter().val+4);
	if (ot & AM_FPR)	// is first operand FPn ?
	{
		emitw(op);
		sr = (pat & 7);
		emitw(op2 | (sr << 10) | RegFld7(ds) | RegFld(dc));
		return TRUE;
	}

	if (!(ot & AM_DATA))
		err(NULL, E_INVOPERAND, gOperand[0]);
	if (ot & AM_DR)
	{
		if (!strchr("BWLS", gSzChar))
			err(NULL, E_BWLS);
	}
	emitw(op | pat);
	emitw(op2 | 0x4000 | (fmt2bit(gSzChar) << 10) | RegFld7(ds) | RegFld(dc));
	emitrest();
	return TRUE;
}


/* ---------------------------------------------------------------
   Description :
	see also m_trapcc
--------------------------------------------------------------- */
int m_ftrapcc(SOp *o)
{
	int op = o->ocode | fp_cpid;
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
			err(NULL, E_ONLYWL);
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
int m_ftst(SOp *o)
{
	int op = o->ocode;
	int op2 = o->ocode2;
	int ot, pat = 0;
	int rm = 0;
	int dr = 0;
	int sr = 0;

	op |= fp_cpid;
	ot = OpType(gOperand[0], &pat, Counter().val+4);
	if (ot & AM_FPR)	// is operand FPn ?
	{
		if (gSzChar && gSzChar != 'X')
			err(NULL, E_ONLYX);
		emitw(op);
		sr = (pat & 7);
		emitw(op2 | RegFld10(sr) | RegFld7(0));
		return TRUE;
	}

	if (!(ot & AM_DATA))
		err(NULL, E_INVOPERAND, gOperand[0]);
	if (ot & AM_DR)
	{
		if (!strchr("BWLS", gSzChar))
			err(NULL, E_BWLS);
	}
	emitw(op | pat);
	emitw(op2 | 0x4000 | (fmt2bit(gSzChar) << 10) | RegFld7(0));
	emitrest();
	return TRUE;
}


