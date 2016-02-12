#include "stdafx.h"
#include "insn.h"
#include "clsSystem.h"
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
	else if (rg < 48) {
		switch(rg) {
		case 32:	sprintf(buf, "zs"); break;
		case 33:	sprintf(buf, "ds"); break;
		case 34:	sprintf(buf, "es"); break;
		case 35:	sprintf(buf, "fs"); break;
		case 36:	sprintf(buf, "gs"); break;
		case 37:	sprintf(buf, "hs"); break;
		case 38:	sprintf(buf, "ss"); break;
		case 39:	sprintf(buf, "cs"); break;
		case 40:	sprintf(buf, "zs.lmt"); break;
		case 41:	sprintf(buf, "ds.lmt"); break;
		case 42:	sprintf(buf, "es.lmt"); break;
		case 43:	sprintf(buf, "fs.lmt"); break;
		case 44:	sprintf(buf, "gs.lmt"); break;
		case 45:	sprintf(buf, "hs.lmt"); break;
		case 46:	sprintf(buf, "ss.lmt"); break;
		case 47:	sprintf(buf, "cs.lmt"); break;
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
	sprintf(buf, "$%I64X[r%d]", *disp, *Ra);
	return std::string(buf);
}

std::string clsDisassem::Disassem(int ad, int *nb)
{
	int byt;
	int opcode, func;
	int n;
	__int64 val, disp;
	int rv;
	int b1, b2, b3, b4;
	int Ra,Rb,Rc,Rt,Sprn,Sg;
	int Cr,Ct;
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
		disp = (b1 << 4) | (opcode & 0xF);
		if (disp & 0x800)
			disp |= 0xFFFFFFFFFFFFF000LL;
		sprintf(&buf[strlen(buf)], " BR $%LLX", disp + cpu1.pc);
		if (nb) *nb = 3;
		imm_prefix = false;
		return std::string(buf);
	}

	switch(opcode) {

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
		sprintf(&buf[strlen(buf)], " ADDUI r%d,r%d,#$%08LLX", Rt, Ra, val);
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
		sprintf(&buf[strlen(buf)], " ADDUI r%d,r%d,#$%08LLX", Rt, Ra, val);
		if (nb) *nb = 4;
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
		sprintf(&buf[strlen(buf)], " JSR c%d,$%LLX[c%d]", Ct, disp, Cr);
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
			sprintf(&buf[strlen(buf)], "[c%d]  ($%LLX)", Cr, cpu1.pc + disp);
		else
			sprintf(&buf[strlen(buf)], "[c%d]", Cr);
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

	case LH:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		b3 = ReadByte(ad);
		ad++;
		Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
		str = dRn(b1,b2,b3,&Ra,&Sg,&disp);
		sprintf(&buf[strlen(buf)]," LH r%d,%s", Rt, str.c_str());
		if (nb) *nb = 5;
		imm_prefix = false;
		return std::string(buf);

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
		case OR:
			sprintf(&buf[strlen(buf)], " OR r%d,r%d,r%d", Rt, Ra, Rb);
			break;
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

	case MOV:
		b1 = ReadByte(ad);
		ad++;
		b2 = ReadByte(ad);
		ad++;
		Ra = b1 & 0x3f;
		Rt = ((b2 & 0xF) << 2) | (b1 >> 6);
		sprintf(&buf[strlen(buf)]," MOV r%d,r%d", Rt, Ra);
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
		}
		if (nb) *nb = 5;
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
		case SHLI:
			sprintf(&buf[strlen(buf)], " SHLI r%d,r%d,#$%X", Rt, Ra, Rb);
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

	}
	*nb = 1;
	return std::string("");
}
