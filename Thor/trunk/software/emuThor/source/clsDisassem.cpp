#include "stdafx.h"
#include "insn.h"
#include "clsDisassem.h"

extern clsSystem system1;

std::string clsDisassem::SprName(int rg)
{
	char buf[100];

	buf[0] = '\0';
	if (rg < 16)
		sprintf(buf, "p%d", rg);
	else if (rg < 32)
		sprintf(buf, "c%d", rg-16);
	else if (rg < 64) {
		switch(rg) {
		case 32:	sprintf(buf, "zs"); break;
		case 33:	sprintf(buf, "ds"); break;
		case 34:	sprintf(buf, "es"); break;
		case 35:	sprintf(buf, "fs"); break;
		case 36:	sprintf(buf, "gs"); break;
		case 37:	sprintf(buf, "hs"); break;
		case 38:	sprintf(buf, "ss"); break;
		case 39:	sprintf(buf, "cs"); break;
		case 40:	sprintf(buf, "LDT"); break;
		case 41:	sprintf(buf, "GDT"); break;
		case 43:	sprintf(buf, "segsw"); break;
		case 44:	sprintf(buf, "segbase"); break;
		case 45:	sprintf(buf, "seglmt"); break;
		case 47:	sprintf(buf, "segacr"); break;
/*
		case 40:	sprintf(buf, "zs.lmt"); break;
		case 41:	sprintf(buf, "ds.lmt"); break;
		case 42:	sprintf(buf, "es.lmt"); break;
		case 43:	sprintf(buf, "fs.lmt"); break;
		case 44:	sprintf(buf, "gs.lmt"); break;
		case 45:	sprintf(buf, "hs.lmt"); break;
		case 46:	sprintf(buf, "ss.lmt"); break;
		case 47:	sprintf(buf, "cs.lmt"); break;
*/
		case 48:	sprintf(buf, "pregs"); break;
		case 50:	sprintf(buf, "tick"); break;
		case 51:	sprintf(buf, "lc"); break;
		case 60:	sprintf(buf, "bir"); break;
		default:	sprintf(buf, "???"); break;
		}
	}
	return std::string(buf);
}

std::string clsDisassem::PredCond(int cnd)
{
	switch(cnd) {
	case PF: return "PF  ";
	case PT: return "PT  ";
	case PEQ: return "PEQ ";
	case PNE: return "PNE ";
	case PLE: return "PLE ";
	case PGT: return "PGT ";
	case PGE: return "PGE ";
	case PLT: return "PLT ";
	case PLEU: return "PLEU";
	case PGTU: return "PGTU";
	case PGEU: return "PGEU";
	case PLTU: return "PLTU";
	default: return "????";
	}
}

int clsDisassem::DefaultSeg(int rg)
{
	switch(rg) {
	case 27:
	case 28:
	case 29:
	case 30:
	case 31:	return 6;
	default:	return 1;
	}
}

std::string clsDisassem::SegName(int sg)
{
	switch(sg) {
	case 0:	return "zs";
	case 1: return "ds";
	case 2: return "es";
	case 3: return "fs";
	case 4: return "gs";
	case 5: return "hs";
	case 6: return "ss";
	case 7: return "cs";
	default: return "<err>";
	}
}

std::string clsDisassem::TLBRegName(int rg)
{
	switch(rg) {
	case 0:	return "Wired";
	case 1: return "Index";
	case 2: return "Random";
	case 3: return "PageSize";
	case 4: return "VirtPage";
	case 5: return "PhysPage";
	case 6: return "ASID";
	case 7: return "DMA";
	case 8: return "IMA";
	case 9: return "PTA";
	case 10: return "PTC";
	default: return "???";
	}
}

// Compute d[Rn] address info
std::string clsDisassem::dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp)
{
	char buf[100];

	if (!Ra || !disp || !Sg)
		return "<error>";
	*Ra = b1 & 0x3f;
	*Sg = (b3 >> 5) & 7;
	*disp = ((b2 >> 4) & 0xF) | ((b3 & 0x1f) << 4);
	if (*disp & 0x100)
		*disp |= 0xFFFFFFFFFFFFFE00LL;
	if (imm_prefix) {
		*disp &= 0xFF;
		*disp |= imm;
	}
	if (*Sg != DefaultSeg(*Ra))
		sprintf(buf, "%s:$%I64X[r%d]", SegName(*Sg).c_str(), *disp, *Ra);
	else 
		sprintf(buf, "$%I64X[r%d]", *disp, *Ra);
	return std::string(buf);
}

// Compute d[Rn] address info
std::string clsDisassem::ndx(int b1, int b2, int b3, int *Ra, int *Rb, int *Rt, int *Sg, int *Sc)
{
	char buf[100];

	if (!Ra || !Rb || !Rt || !Sg)
		return "<error>";
	*Ra = b1 & 0x3f;
	*Rb = (b1 >> 6) | ((b2 & 0x0f) << 2);
	*Rt = ((b2 & 0xF0) >> 4) | ((b3 & 3) << 4);
	*Sg = (b3 >> 5) & 7;
	*Sc = (b3 >> 2) & 3;
	if (*Sg != DefaultSeg(*Ra))
		sprintf(buf, "%s:[r%d+r%d", SegName(*Sg).c_str(), *Ra, *Rb);
	else 
		sprintf(buf, "[r%d+r%d", *Ra, *Rb);
	if (*Sc != 1)
		sprintf(&buf[strlen(buf)], "*%d]", (1 << *Sc));
	else
		sprintf(&buf[strlen(buf)], "]");
	return std::string(buf);
}

std::string clsDisassem::mem(std::string mne, int ad, int *nb)
{
	int b1, b2, b3;
	int Ra,Rt,Sg;
	__int64 disp;
	std::string str;
	char buf[100];

	buf[0] = '\0';
	b1 = ReadByte(ad);
	ad++;
	b2 = ReadByte(ad);
	ad++;
	b3 = ReadByte(ad);
	ad++;
	Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
	str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
	sprintf(&buf[strlen(buf)]," %s r%d,%s", mne.c_str(), Rt, str.c_str());
	if (nb) *nb = 5;
	imm_prefix = false;
	return std::string(buf);
}

std::string clsDisassem::memndx(std::string mne, int ad, int *nb)
{
	int b1, b2, b3;
	int Ra,Rb,Rt,Sg,Sc;
	__int64 disp;
	std::string str;
	char buf[100];

	buf[0] = '\0';
	b1 = ReadByte(ad);
	ad++;
	b2 = ReadByte(ad);
	ad++;
	b3 = ReadByte(ad);
	ad++;
	str = ndx(b1,b2,b3,&Ra,&Rb,&Rt,&Sg,&Sc);
	sprintf(&buf[strlen(buf)]," %s r%d,%s", mne.c_str(), Rt, str.c_str());
	if (nb) *nb = 5;
	imm_prefix = false;
	return std::string(buf);
}

std::string clsDisassem::Disassem(int ad, int *nb)
{
	int byt;
	int opcode, func;
	int n;
	__int64 val, disp, amt;
	int rv;
	int b1, b2, b3, b4;
	int Ra,Rb,Rc,Rt,Sprn,Sg,Sc,Sz;
	int Cr,Ct,Tn;
	int Pn;
	char buf[100];
	std::string str;

	buf[0] = '\0';
	byt = system1.ReadByte(ad);
	ad++;
	if (byt==0x00) {
		if (nb) *nb = 1;
		return std::string("        BRK");
	}
	if (byt==0x10) {
		if (nb) *nb = 1;
		return std::string("        NOP");
	}
	if (byt==0x20) {
		val = system1.ReadByte(ad);
		ad++;
		if (val & 0x80LL)
			val |= 0xFFFFFFFFFFFFFF00LL;
		sprintf(buf, "        IMM %02LLX",val);
		if (nb) *nb = 2;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x30) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		if (val & 0x8000LL)
			val |= 0xFFFFFFFFFFFF0000LL;
		sprintf(buf, "        IMM %04LLX",val);
		if (nb) *nb = 3;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x40) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		val += (system1.ReadByte(ad) << 16);
		ad++;
		if (val & 0x800000LL)
			val |= 0xFFFFFFFFFF000000LL;
		sprintf(buf, "        IMM %06LLX",val);
		imm = val << 8;
		if (nb) *nb = 4;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x50) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		val += (system1.ReadByte(ad) << 16);
		ad++;
		val += (system1.ReadByte(ad) << 24);
		ad++;
		if (val & 0x80000000LL)
			val |= 0xFFFFFFFF00000000LL;
		sprintf(buf, "        IMM %08LLX",val);
		if (nb) *nb = 5;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x60) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		val += (system1.ReadByte(ad) << 16);
		ad++;
		val += (system1.ReadByte(ad) << 24);
		ad++;
		val += (system1.ReadByte(ad) << 32);
		ad++;
		if (val & 0x8000000000LL)
			val |= 0xFFFFFF0000000000LL;
		sprintf(buf, "        IMM %010LLX",val);
		if (nb) *nb = 6;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x70) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		val += (system1.ReadByte(ad) << 16);
		ad++;
		val += (system1.ReadByte(ad) << 24);
		ad++;
		val += (system1.ReadByte(ad) << 32);
		ad++;
		val += (system1.ReadByte(ad) << 40);
		ad++;
		if (val & 0x800000000000LL)
			val |= 0xFFFF000000000000LL;
		sprintf(buf, "        IMM %012LLX",val);
		if (nb) *nb = 7;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt==0x80) {
		val = system1.ReadByte(ad);
		ad++;
		val += (system1.ReadByte(ad) << 8);
		ad++;
		val += (system1.ReadByte(ad) << 16);
		ad++;
		val += (system1.ReadByte(ad) << 24);
		ad++;
		val += (system1.ReadByte(ad) << 32);
		ad++;
		val += (system1.ReadByte(ad) << 40);
		ad++;
		val += (system1.ReadByte(ad) << 48);
		ad++;
		if (val & 0x80000000000000LL)
			val |= 0xFF00000000000000LL;
		sprintf(buf, "        IMM %014LLX",val);
		if (nb) *nb = 8;
		imm = val << 8;
		imm_prefix = true;
		return std::string(buf);
	}
	if (byt != 0x01)
		sprintf(buf, "p%d.%s ", (byt & 0xF0) >> 4, PredCond(byt & 0xF).c_str());
	opcode = system1.ReadByte(ad);
	ad++;
	if ((opcode & 0xF0)==0x00) {
		b1 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Pn = opcode & 0x0f;
		sprintf(&buf[strlen(buf)], "TST p%d,r%d", Pn, Ra);
		if (nb) *nb = 3;
		imm_prefix = false;
		return std::string(buf);
	}
	if ((opcode & 0xF0)==0x10) {
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rb = ((b2 << 2) | (b1 >> 6)) & 0x3f;
		Pn = opcode & 0x0f;
		switch(b2 >> 4) {
		case 0:	sprintf(&buf[strlen(buf)], " CMP p%d,r%d,r%d", Pn, Ra, Rb); break;
		case 1:	sprintf(&buf[strlen(buf)], " FCMP.S p%d,r%d,r%d", Pn, Ra, Rb); break;
		case 2:	sprintf(&buf[strlen(buf)], " FCMP.D p%d,r%d,r%d", Pn, Ra, Rb); break;
		}
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);
	}
	if ((opcode & 0xF0)==0x20) {
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Pn = opcode & 0x0f;
		val = (b2 << 2) | (b1 >> 6);
		if (imm_prefix)
			val = imm | (val & 0xFF);
		else {
			if (val & 0x200)
				val |= 0xFFFFFFFFFFFFFE00LL;
		}
		sprintf(&buf[strlen(buf)], " CMPI p%d,r%d,#$%LLX", Pn, Ra, val);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);
	}
	if ((opcode & 0xF0)==0x30) {
		b1 = system1.ReadByte(ad);
		ad++;
		disp = b1 | ((opcode & 0xF) << 8);
		if (disp & 0x800)
			disp |= 0xFFFFFFFFFFFFF000LL;
		sprintf(&buf[strlen(buf)], " BR $%LLX", disp + ad);
		if (nb) *nb = 3;
		imm_prefix = false;
		return std::string(buf);
	}

	switch(opcode) {

	case _2ADDUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " _2ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case _4ADDUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " _4ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case _8ADDUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " _8ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case _16ADDUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " _16ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case ADDUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case ADDUIS:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = Ra;
		val = (b2 << 2) | (b1 >> 6);
		sprintf(&buf[strlen(buf)], " ADDUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case ANDI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " ANDI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case BITI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Pn = ((b2 & 0x3) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " BITI p%d,r%d,#$%I64X", Pn, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case CLI:
		sprintf(&buf[strlen(buf)], " CLI");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case DIVI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " DIVI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case DIVUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " DIVUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case EORI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " EORI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case INC:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		b4 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Sz = (b1 >> 6) | ((b2 & 1) << 2);
		disp = (b2 >> 4) | ((b3 & 31) << 4);
		if (disp & 0x100)
			disp |= 0xFFFFFFFFFFFFFF00LL;
		Sg = b3 >> 5;
		amt = b4;
		if (amt & 0x80)
			amt |= 0xFFFFFFFFFFFFFF00LL;
		sprintf(&buf[strlen(buf)], " INC.%c %s:$%I64X[r%d],#%I64d",
			Sz==0 ? 'B' : Sz==1 ? 'C' : Sz==2 ? 'H' : 'W',
			SegName(Sg), disp, Ra, amt);
		if (nb) *nb = 6;
		imm_prefix = false;
		return std::string(buf);

	case JSR:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		b4 = system1.ReadByte(ad);
		ad++;
		Cr = b1 >> 4;
		Ct = b1 & 0xF;
		if (imm_prefix)
			disp = imm | b2;
		else {
			disp = (b4 << 16) | (b3 << 8) | b2;
			if (disp & 0x800000LL)
				disp |= 0xFFFFFFFFFF000000LL;
		}
		if (nb) *nb = 6;
		imm_prefix = false;
		sprintf(&buf[strlen(buf)], " JSR c%d,$%I64X[c%d]", Ct, disp, Cr);
		if (Cr==15)
			sprintf(&buf[strlen(buf)], "  ($%I64X)", ad-6 + disp);
		return std::string(buf);

	case JSRI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Ct = (b1 >> 6) | (b2 << 2) & 0xc0;
		Sz = (b2 >> 2) & 3;
		Sg = b3 >> 5;
		disp = ((b3 & 0x1f) << 4) | (b2 >> 4);
		if (disp & 0x800LL)
			disp |= 0xFFFFFFFFFFFFFE00LL;
		if (imm_prefix) {
			disp &= 0xFFLL;
			disp = imm | disp;
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		switch(Sz) {
		case 1:	sprintf(&buf[strlen(buf)], " JCI c%d,%s:$%I64X[r%d]", Ct, SegName(Sg).c_str(), disp, Ra); break;
		case 2:	sprintf(&buf[strlen(buf)], " JHI c%d,%s:$%I64X[r%d]", Ct, SegName(Sg).c_str(), disp, Ra); break;
		case 3:	sprintf(&buf[strlen(buf)], " JWI c%d,%s:$%I64X[r%d]", Ct, SegName(Sg).c_str(), disp, Ra); break;
		}
		return std::string(buf);

	case JSRS:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Cr = b1 >> 4;
		Ct = b1 & 0xF;
		if (imm_prefix)
			disp = imm | b2;
		else {
			disp = (b3 << 8) | b2;
			if (disp & 0x8000LL)
				disp |= 0xFFFFFFFFFFFF0000LL;
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		sprintf(&buf[strlen(buf)], " JSR c%d,$%LLX", Ct, disp);
		if (Cr==15)
			sprintf(&buf[strlen(buf)], "[c%d]  ($%LLX)", Cr, ad-5 + disp);
		else
			sprintf(&buf[strlen(buf)], "[c%d]", Cr);
		return std::string(buf);

	case JSRR:
		b1 = system1.ReadByte(ad);
		ad++;
		Cr = b1 >> 4;
		Ct = b1 & 0xF;
		if (nb) *nb = 3;
		imm_prefix = false;
		sprintf(&buf[strlen(buf)], " JSR c%d,[c%d]", Ct, Cr);
		return std::string(buf);

	case LDI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Rt = b1 & 0x3f;
		val = (b2 << 2) | (b1 >> 6);
		if (imm_prefix)
			val = imm | (val & 0xFF);
		else {
			if (val & 0x200)
				val |= 0xFFFFFFFFFFFFFE00LL;
		}
		sprintf(&buf[strlen(buf)], " LDI r%d,#$%08LLX", Rt, val);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case LDIS:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Sprn = b1 & 0x3f;
		val = (b2 << 2) | (b1 >> 6);
		if (imm_prefix)
			val = imm | (val & 0xFF);
		else {
			if (val & 0x200)
				val |= 0xFFFFFFFFFFFFFE00LL;
		}
		sprintf(&buf[strlen(buf)], " LDIS %s,#$%08LLX", SprName(Sprn).c_str(), val);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case LB:	return mem("LB", ad, nb);
	case LBX:	return memndx("LBX", ad, nb);
	case LBUX:	return memndx("LBUX", ad, nb);
	case LVB:	return mem("LVB", ad, nb);
	case LBU:	return mem("LBU", ad, nb);
	case LC:	return mem("LC", ad, nb);
	case LCX:	return memndx("LCX", ad, nb);
	case LCUX:	return memndx("LCUX", ad, nb);
	case LVC:	return mem("LVC", ad, nb);
	case LCU:	return mem("LCU", ad, nb);
	case LH:	return mem("LH", ad, nb);
	case LHX:	return memndx("LHX", ad, nb);
	case LHUX:	return memndx("LHUX", ad, nb);
	case LVH:	return mem("LVH", ad, nb);
	case LHU:	return mem("LHU", ad, nb);
	case LW:	return mem("LW", ad, nb);
	case LWX:	return memndx("LWX", ad, nb);
	case LVW:	return mem("LVW", ad, nb);
	case LVWAR:	return mem("LVWAR", ad, nb);

	case LLA:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," LLA r%d,%s", Rt, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case LOGIC:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rb = ((b2 & 0x0f) << 2) | (b1 >> 6);
		Rt = ((b3 & 3) << 4) | (b2 >> 4);
		func = b3 >> 2;
		switch(func) {
		case AND:	sprintf(&buf[strlen(buf)], " AND r%d,r%d,r%d", Rt, Ra, Rb); break;
		case OR:	sprintf(&buf[strlen(buf)], " OR r%d,r%d,r%d", Rt, Ra, Rb); break;
		case EOR:	sprintf(&buf[strlen(buf)], " EOR r%d,r%d,r%d", Rt, Ra, Rb); break;
		case NAND:	sprintf(&buf[strlen(buf)], " NAND r%d,r%d,r%d", Rt, Ra, Rb); break;
		case NOR:	sprintf(&buf[strlen(buf)], " NOR r%d,r%d,r%d", Rt, Ra, Rb); break;
		case ENOR:	sprintf(&buf[strlen(buf)], " ENOR r%d,r%d,r%d", Rt, Ra, Rb); break;
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case LOOP:
		disp = system1.ReadByte(ad);
		ad++;
		if (disp & 0x80LL)
			disp |= 0xFFFFFFFFFFFFFF00LL;
		sprintf(&buf[strlen(buf)], " LOOP $%LLX", disp + ad);
		if (nb) *nb = 3;
		imm_prefix = false;
		return std::string(buf);

	case LWS:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," LWS %s,%s", SprName(Rb).c_str(), str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case MEMSB:
		sprintf(&buf[strlen(buf)], " MEMSB");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case MEMDB:
		sprintf(&buf[strlen(buf)], " MEMDB");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case MFSPR:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Sprn = b1 & 0x3f;
		Rt = ((b2 & 0x0f) << 2) | (b1 >> 6);
		sprintf(&buf[strlen(buf)], " MFSPR r%d,%s", Rt, SprName(Sprn).c_str());
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case MODI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " MODI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case MODUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " MODUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case GRPA7:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xF) << 2) | (b1 >> 6);
		switch(b2>>4) {
		case MOV:	sprintf(&buf[strlen(buf)]," MOV r%d,r%d", Rt, Ra); break;
		case NEG:	sprintf(&buf[strlen(buf)]," NEG r%d,r%d", Rt, Ra); break;
		case SXB:	sprintf(&buf[strlen(buf)]," SXB r%d,r%d", Rt, Ra); break;
		case SXC:	sprintf(&buf[strlen(buf)]," SXC r%d,r%d", Rt, Ra); break;
		case SXH:	sprintf(&buf[strlen(buf)]," SXH r%d,r%d", Rt, Ra); break;
		case ZXB:	sprintf(&buf[strlen(buf)]," ZXB r%d,r%d", Rt, Ra); break;
		case ZXC:	sprintf(&buf[strlen(buf)]," ZXC r%d,r%d", Rt, Ra); break;
		case ZXH:	sprintf(&buf[strlen(buf)]," ZXH r%d,r%d", Rt, Ra); break;
		}
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case MTSPR:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Sprn = ((b2 & 0x0f) << 2) | (b1 >> 6);
		sprintf(&buf[strlen(buf)], " MTSPR %s,r%d", SprName(Sprn).c_str(), Ra);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case MULI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " MULI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case MULUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " MULUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case ORI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " ORI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case RR:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rb = ((b2 & 0x0f) << 2) | (b1 >> 6);
		Rt = ((b3 & 3) << 4) | (b2 >> 4);
		func = b3 >> 2;
		switch(func) {
		case ADD:
			sprintf(&buf[strlen(buf)], " ADD r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case ADDU:
			sprintf(&buf[strlen(buf)], " ADDU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case DIV:
			sprintf(&buf[strlen(buf)], " DIV r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case DIVU:
			sprintf(&buf[strlen(buf)], " DIVU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case MUL:
			sprintf(&buf[strlen(buf)], " MUL r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case MULU:
			sprintf(&buf[strlen(buf)], " MULU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case _2ADDU:
			sprintf(&buf[strlen(buf)], " _2ADDU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case _4ADDU:
			sprintf(&buf[strlen(buf)], " _4ADDU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case _8ADDU:
			sprintf(&buf[strlen(buf)], " _8ADDU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case _16ADDU:
			sprintf(&buf[strlen(buf)], " _16ADDU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case MOD:
			sprintf(&buf[strlen(buf)], " MOD r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case MODU:
			sprintf(&buf[strlen(buf)], " MODU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SUB:
			sprintf(&buf[strlen(buf)], " SUB r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SUBU:
			sprintf(&buf[strlen(buf)], " SUBU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case RTD:
		sprintf(&buf[strlen(buf)], " RTD");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case RTE:
		sprintf(&buf[strlen(buf)], " RTE");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case RTI:
		sprintf(&buf[strlen(buf)], " RTI");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case RTS:
		b1 = system1.ReadByte(ad);
		ad++;
		Cr = b1 >> 4;
		sprintf(&buf[strlen(buf)], " RTS $%X[c%d]", b1 & 0xF, Cr);
		if (nb) *nb = 3;
		imm_prefix = false;
		return std::string(buf);

	case RTSQ:
		sprintf(&buf[strlen(buf)], " RTS");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case SB:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SB r%d,%s", Rb, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SBX:	return memndx("SBX", ad, nb);
	case SCX:	return memndx("SCX", ad, nb);
	case SHX:	return memndx("SHX", ad, nb);
	case SWX:	return memndx("SWX", ad, nb);

	case SC:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SC r%d,%s", Rb, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SH:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SH r%d,%s", Rb, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SHIFT:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rb = ((b2 & 0x0f) << 2) | (b1 >> 6);
		Rt = ((b3 & 3) << 4) | (b2 >> 4);
		func = b3 >> 2;
		switch(func) {
		case SHL:
			sprintf(&buf[strlen(buf)], " SHL r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SHR:
			sprintf(&buf[strlen(buf)], " SHR r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SHLU:
			sprintf(&buf[strlen(buf)], " SHLU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SHRU:
			sprintf(&buf[strlen(buf)], " SHRU r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case SHLI:
			sprintf(&buf[strlen(buf)], " SHLI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		case SHRI:
			sprintf(&buf[strlen(buf)], " SHRI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		case SHLUI:
			sprintf(&buf[strlen(buf)], " SHLUI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		case SHRUI:
			sprintf(&buf[strlen(buf)], " SHRUI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		case ROL:
			sprintf(&buf[strlen(buf)], " ROL r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case ROR:
			sprintf(&buf[strlen(buf)], " ROR r%d,r%d,r%d", Rt, Ra, Rb);
			break;
		case ROLI:
			sprintf(&buf[strlen(buf)], " ROLI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		case RORI:
			sprintf(&buf[strlen(buf)], " RORI r%d,r%d,#$%X", Rt, Ra, Rb);
			break;
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case STP:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		sprintf(&buf[strlen(buf)]," STP #$%04X", (int)((b2<<8)|b1));
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case STSET:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		Sg = b3 >> 5;
		switch((b3 >> 2) & 7) {
		case 0: sprintf(&buf[strlen(buf)]," STSET.BI r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 1: sprintf(&buf[strlen(buf)]," STSET.CI r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 2: sprintf(&buf[strlen(buf)]," STSET.HI r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 3: sprintf(&buf[strlen(buf)]," STSET.WI r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 4: sprintf(&buf[strlen(buf)]," STSET.BD r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 5: sprintf(&buf[strlen(buf)]," STSET.CD r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 6: sprintf(&buf[strlen(buf)]," STSET.HD r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		case 7: sprintf(&buf[strlen(buf)]," STSET.WD r%d,%s:[r%d]", Rb, SegName(Sg).c_str(), Ra);
		}
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SUBUI:
		b1 = system1.ReadByte(ad);
		ad++;
		b2 = system1.ReadByte(ad);
		ad++;
		b3 = system1.ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xf) << 2) | (b1 >> 6);
		val = (b3 << 4) | (b2 >> 4);
		sprintf(&buf[strlen(buf)], " SUBUI r%d,r%d,#$%I64X", Rt, Ra, val);
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SW:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SW r%d,%s", Rb, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SWCR:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SWCR r%d,%s", Rb, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SWS:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," SWS %s,%s", SprName(Rb).c_str(), str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

	case SYNC:
		sprintf(&buf[strlen(buf)], " SYNC");
		if (nb) *nb = 2;
		imm_prefix = false;
		return std::string(buf);

	case SYS:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		Cr = b1 >> 4;
		Ct = b1 & 0xF;
		sprintf(&buf[strlen(buf)], " SYS c%d,c%d,#%X", Ct, Cr, b2);
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	case TLB:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		Tn = b1 >> 4;
		Rt = b2 & 0x3f;
		Ra = Rt;
		str = "TLB";
		switch(b1 & 0xF) {
		case 0:
			str += "NOP";
			sprintf(&buf[strlen(buf)]," %s", str.c_str());
			break;
		case 1:
			str += "PB";
			sprintf(&buf[strlen(buf)]," %s r%d", str.c_str(), Ra);
			break;
		case 2:
			str += "RD";
			sprintf(&buf[strlen(buf)]," %s r%d,%s", str.c_str(), Rt, TLBRegName(Tn));
			break;
		case 3:
			str += "WR";
			sprintf(&buf[strlen(buf)]," %s %s,r%d", str.c_str(), TLBRegName(Tn), Rt);
			break;
		case 4:
			str += "WI";
			sprintf(&buf[strlen(buf)]," %s %s,r%d", str.c_str(), TLBRegName(Tn), Rt);
			break;
		case 5:
			str += "EN";
			sprintf(&buf[strlen(buf)]," %s", str.c_str());
			break;
		case 6:
			str += "DIS";
			sprintf(&buf[strlen(buf)]," %s", str.c_str());
			break;
		default:
			str += "???";
			sprintf(&buf[strlen(buf)]," %s", str.c_str());
			break;
		}
		if (nb) *nb = 4;
		imm_prefix = false;
		return std::string(buf);

	}
	*nb = 1;
	return std::string("");
}
