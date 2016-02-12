#include "stdafx.h"
#include "clsThor.h"
#include "insn.h"

extern clsSystem system1;

void clsThor::Reset()
{
	pc = 0xFFFFFFFFFFFC0000LL;
	tick = 0;
	gp[0] = 0;
	ca[0] = 0;
}

// Compute d[Rn] address info
void clsThor::dRn(int b1, int b2, int b3, int *Ra, int *Sg, __int64 *disp)
{
	if (Ra) *Ra = b1 & 0x3f;
	if (Sg) *Sg = (b3 >> 5) & 7;
	if (disp) *disp = ((b2 >> 4) & 0xF) | ((b3 & 0x1f) << 4);
	if (*disp & 0x100)
		*disp |= 0xFFFFFFFFFFFFFE00LL;
	if (imm_prefix) {
		*disp &= 0xFF;
		*disp |= imm;
	}
}

void clsThor::Step()
{
	bool ex = true;	// execute instruction
	unsigned int opcode, func;
	__int64 disp;
	int Ra,Rb,Rc,Rt,Pn,Cr,Ct;
	int Sprn,Sg;
	int b1, b2, b3, b4;
	int nn;
	__int64 dat;

	gp[0] = 0;
	ca[0] = 0;
	if (imcd > 0) {
		imcd--;
		if (imcd==1)
			im = 0;
	}
	tick = tick + 1;
	pred = ReadByte(pc);
	pc++;
	for (nn = 39; nn >= 0; nn--)
		pcs[nn] = pcs[nn-1];
	pcs[0] = pc;
	switch (pred) {
	case 0x00:	// BRK instruction
		return;
	case 0x10:	// NOP
		return;
	case 0x20:
		imm = ReadByte(pc) << 8;
		pc++;
		if (imm & 0x8000LL)
			imm |= 0xFFFFFFFFFFFF0000LL;
		imm_prefix = true;
		return;
	case 0x30:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		if (imm & 0x800000LL)
			imm |= 0xFFFFFFFFFF000000LL;
		imm_prefix = true;
		return;
	case 0x40:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		imm |= ReadByte(pc) << 24;
		pc++;
		if (imm & 0x80000000LL)
			imm |= 0xFFFFFFFF00000000LL;
		imm_prefix = true;
		return;
	case 0x50:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		imm |= ReadByte(pc) << 24;
		pc++;
		imm |= ReadByte(pc) << 32;
		pc++;
		if (imm & 0x8000000000LL)
			imm |= 0xFFFFFF0000000000LL;
		imm_prefix = true;
		return;
	case 0x60:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		imm |= ReadByte(pc) << 24;
		pc++;
		imm |= ReadByte(pc) << 32;
		pc++;
		imm |= ReadByte(pc) << 40;
		pc++;
		if (imm & 0x800000000000LL)
			imm |= 0xFFFF000000000000LL;
		imm_prefix = true;
		return;
	case 0x70:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		imm |= ReadByte(pc) << 24;
		pc++;
		imm |= ReadByte(pc) << 32;
		pc++;
		imm |= ReadByte(pc) << 40;
		pc++;
		imm |= ReadByte(pc) << 48;
		pc++;
		if (imm & 0x80000000000000LL)
			imm |= 0xFF00000000000000LL;
		imm_prefix = true;
		return;
	case 0x80:
		imm = ReadByte(pc) << 8;
		pc++;
		imm |= ReadByte(pc) << 16;
		pc++;
		imm |= ReadByte(pc) << 24;
		pc++;
		imm |= ReadByte(pc) << 32;
		pc++;
		imm |= ReadByte(pc) << 40;
		pc++;
		imm |= ReadByte(pc) << 48;
		pc++;
		imm |= ReadByte(pc) << 56;
		pc++;
		imm_prefix = true;
		return;
	default: {
		int rv;

		rv = pr[pred>>4];
		switch(pred & 15) {
		case PF: ex = false; break;
		case PT: ex = true; break;
		case PEQ: ex = rv & 1; break;
		case PNE: ex = !(rv & 1); break;
		case PLE: ex = (rv & 1)||(rv & 2); break;
		case PGT: ex = !((rv & 1)||(rv & 2)); break;
		case PGE: ex = (rv & 2)==0; break;
		case PLT: ex = (rv & 2)!=0; break;
		case PLEU: ex = (rv & 1)||(rv & 4); break;
		case PGTU: ex = !((rv & 1)||(rv & 4)); break;
		case PGEU: ex = (rv & 4)==0; break;
		case PLTU: ex = (rv & 4)!=0; break;
		default:	ex = false;
		}
		}
	}
	opcode = ReadByte(pc);
	pc++;
	if ((opcode & 0xF0)==0x00) {	// TST
		b1 = ReadByte(pc);
		pc++;
		if (ex) {
			Ra = b1 & 0x3f;
			Pn = opcode & 0x0f;
			pr[Pn] = 0;
			if (gp[Ra]==0)
				pr[Pn] |= 1;
			if ((signed)gp[Ra] < (signed)0)
				pr[Pn] |= 2;
		}
		imm_prefix = false;
		return;
	}
	else if ((opcode & 0xF0)==0x10) {	// CMP
		b1 = ReadByte(pc);
		pc++;
		b2 = ReadByte(pc);
		pc++;
		if (ex) {
			Ra = b1 & 0x3f;
			Rb = ((b1 & 0xC0) >> 6) | ((b2 & 0x0f)<<2);
			Pn = opcode & 0x0f;
			pr[Pn] = 0;
			if (gp[Ra]==gp[Rb])
				pr[Pn] |= 1;
			if ((signed)gp[Ra] < (signed)gp[Rb])
				pr[Pn] |= 2;
			if (gp[Ra] < gp[Rb])
				pr[Pn] |= 4;
		}
		imm_prefix = false;
		return;
	}
	else if ((opcode & 0xF0)==0x20) {	// CMPI
		b1 = ReadByte(pc);
		pc++;
		b2 = ReadByte(pc);
		pc++;
		if (ex) {
			Ra = b1 & 0x3f;
			if (imm_prefix) {
				imm |= ((b2 << 2) & 0xFF) | ((b1 >> 6) & 3);
			}
			else {
				imm = ((b2 << 2) & 0x3FF) | ((b1 >> 6) & 3);
				if (imm & 0x200)
					imm |= 0xFFFFFFFFFFFFFE00LL;
			}
			Pn = opcode & 0x0f;
			pr[Pn] = 0;
			if (gp[Ra]==imm)
				pr[Pn] |= 1;
			if ((signed)gp[Ra] < (signed)imm)
				pr[Pn] |= 2;
			if (gp[Ra] < imm)
				pr[Pn] |= 4;
		}
		imm_prefix = false;
		return;
	}
	else if ((opcode & 0xF0)==0x30) {	// BR
		disp = ReadByte(pc);
		pc++;
		if (ex) {
			disp = disp | ((opcode & 0x0F) << 8);
			if (disp & 0x800)
				disp |= 0xFFFFFFFFFFFFF000LL;
			pc = pc + disp;
		}
		imm_prefix = false;
		return;
	}
	else {
		switch(opcode) {
		case ADDUI:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				if (imm_prefix) {
					imm |= ((b3 << 4)&0xF0) | ((b2 >> 4) & 0xF);
				}
				else {
					imm = (b3 << 4) | ((b2 >> 4) & 0xF);
					if (imm & 0x800)
						imm |= 0xFFFFFFFFFFFFF000LL;
				}
				gp[Rt] = gp[Ra] + imm;
				gp[0] = 0;
			}
			imm_prefix = false;
			return;

		case ADDUIS:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rt = Ra;
				if (imm_prefix) {
					imm |= ((b2 << 2)&0xFC) | ((b1 >> 6) & 0x3);
				}
				else {
					imm = ((b2 << 2)&0x3FC) | ((b1 >> 6) & 0x3);
					if (imm & 0x200)
						imm |= 0xFFFFFFFFFFFFFE00LL;
				}
				gp[Rt] = gp[Ra] + imm;
				gp[0] = 0;
			}
			imm_prefix = false;
			return;

		case JSR:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			b4 = ReadByte(pc);
			pc++;
			if (ex) {
				Ct = b1 & 0x0F;
				Cr = (b1 & 0xF0) >> 4;
				if (Ct != 0)
					ca[Ct] = pc;
				disp = (b3 << 16) | (b2 << 8) | b1;
				if (disp & 0x800000)
					disp |= 0xFFFFFFFFFF000000LL;
				if (imm_prefix) {
					disp &= 0xFF;
					disp |= imm;
				}
				ca[15] = pc;
				pc = disp + ca[Cr];
			}
			imm_prefix = false;
			return;

		case JSRS:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Ct = b1 & 0x0F;
				Cr = (b1 & 0xF0) >> 4;
				ca[Ct] = pc;
				ca[0] = 0;
				disp = (b3 << 8) | b2;
				if (disp & 0x8000)
					disp |= 0xFFFFFFFFFFFF0000LL;
				if (imm_prefix) {
					disp &= 0xFFLL;
					disp |= imm;
				}
				ca[15] = pc;
				pc = disp + ca[Cr] - 5;
			}
			imm_prefix = false;
			return;

		case JSRR:
			b1 = ReadByte(pc);
			pc++;
			if (ex) {
				Ct = b1 & 0x0F;
				Cr = (b1 & 0xF0) >> 4;
				if (Ct != 0)
					ca[Ct] = pc;
				disp = 0;
				if (imm_prefix) {
					disp &= 0xFF;
					disp |= imm;
				}
				ca[15] = pc;
				pc = disp + ca[Cr];
			}
			imm_prefix = false;
			return;

		case LDIS:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Sprn = b1 & 0x3f;
				if (imm_prefix) {
					imm |= ((b2 << 2) & 0xFF) | ((b1 >> 6) & 3);
				}
				else {
					imm = ((b2 << 2) & 0x3FF) | ((b1 >> 6) & 3);
					if (imm & 0x200)
						imm |= 0xFFFFFFFFFFFFFE00LL;
				}
				if (Sprn < 16) {
					pr[Sprn] = imm & 0xF;
				}
				else if (Sprn < 32) {
					ca[Sprn-16] = imm;
					ca[0] = 0;
					ca[15] = pc;
				}
				else if (Sprn < 40) {
					seg_base[Sprn-32] = imm & 0xFFFFFFFFFFFFF000LL;
				}
				else if (Sprn < 48) {
					seg_limit[Sprn-40] = imm & 0xFFFFFFFFFFFFF000LL;
				}
				else {
					switch(Sprn) {
					case 51:	lc = imm; break;
					case 52:
						for (nn = 0; nn < 16; nn++) {
							pr[nn] = (imm >> (nn * 4)) & 0xF;
						}
						break;
					case 60:	bir = imm & 0xFFLL; break;
					case 61:
						switch(bir) {
						case 0: dbad0 = imm; break;
						case 1: dbad1 = imm; break;
						case 2: dbad2 = imm; break;
						case 3: dbad3 = imm; break;
						case 4: dbctrl = imm; break;
						case 5: dbstat = imm; break;
						}
					}
				}
			}
			imm_prefix = false;
			return;

		case LDI:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Rt = b1 & 0x3f;
				if (imm_prefix) {
					imm |= ((b2 << 2) & 0xFF) | ((b1 >> 6) & 3);
				}
				else {
					imm = ((b2 << 2) & 0x3FF) | ((b1 >> 6) & 3);
					if (imm & 0x200)
						imm |= 0xFFFFFFFFFFFFFE00LL;
				}
				gp[Rt] = imm;
			}
			imm_prefix = false;
			return;

		case LH:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				dat = system1->Read(ea);
				if (ea & 4)
					dat = (dat >> 32);
				if (ea & 2)
					dat = (dat >> 16);
				dat &= 0xFFFF;
				if (dat & 0x8000LL)
					dat |= 0xFFFFFFFFFFFF0000LL;
				gp[Rt] = dat;
				gp[0] = 0;
			}
			imm_prefix = false;
			return;

		case LLA:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				gp[Rt] = ea;
				gp[0] = 0;
			}
			imm_prefix = false;
			return;

		case LOGIC:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rb = ((b2 << 2) & 0x3c) | (b1 >> 6);
				Rt = (b2 >> 4) | ((b3 & 0x3) << 4);
				func = b3 >> 2;
				switch(func) {
				case OR:
					gp[Rt] = gp[Ra] | gp[Rb];
					gp[0] = 0;
					break;
				}
			}
			imm_prefix = 0;
			return;

		case LOOP:
			disp = ReadByte(pc);
			pc++;
			if (ex) {
				if (disp & 0x80LL)
					disp |= 0xFFFFFFFFFFFFFF00LL;
				if (lc > 0) {
					lc--;
					pc = pc + disp;
				}
			}
			imm_prefix = false;
			return;

		case MFSPR:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Sprn = b1 & 0x3f;
				Rt = ((b2 & 0xF) << 2) | ((b1 >> 6) & 3);
				if (Sprn < 16) {
					gp[Rt] = pr[Sprn];
					gp[0] = 0;
				}
				else if (Sprn < 32) {
					Sprn -= 16;
					gp[Rt] = ca[Sprn];
					gp[0] = 0;
				}
				else if (Sprn < 40) {
					gp[Rt] = seg_base[Sprn-32];
					gp[0] = 0;
				}
				else if (Sprn < 48) {
					gp[Rt] = seg_limit[Sprn-32];
					gp[0] = 0;
				}
				else {
					switch(Sprn) {
					case 50:	gp[Rt] = tick; gp[0] = 0; break;
					case 51:	gp[Rt] = lc; gp[0] = 0; break;
					case 52:
						gp[Rt] = 0;
						for (nn = 0; nn < 16; nn++) {
							gp[Rt] |= pr[nn] << (nn * 4);
						}
						gp[0] = 0;
						break;
					case 60:	gp[Rt] = bir; gp[0] = 0; break;
					case 61:
						switch(bir) {
						case 0: gp[Rt] = dbad0; gp[0] = 0; break;
						case 1: gp[Rt] = dbad1;  gp[0] = 0; break;
						case 2: gp[Rt] = dbad2;  gp[0] = 0; break;
						case 3: gp[Rt] = dbad3;  gp[0] = 0; break;
						case 4: gp[Rt] = dbctrl;  gp[0] = 0; break;
						case 5: gp[Rt] = dbstat;  gp[0] = 0; break;
						}
					}
				}
			}
			imm_prefix = false;
			return;

		case MOV:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rt = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				gp[Rt] = gp[Ra];
				gp[0] = 0;
			}
			imm_prefix = false;
			return;

		case MTSPR:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Sprn = ((b2 & 0xF) << 2) | ((b1 >> 6) & 3);
				if (Sprn < 16)
					pr[Sprn] = gp[Ra];
				else if (Sprn < 32) {
					Sprn -= 16;
					ca[Sprn] = gp[Ra];
					ca[0] = 0;
					ca[15] = pc;
				}
				else if (Sprn < 40) {
					seg_base[Sprn-32] = gp[Ra] & 0xFFFFFFFFFFFFF000LL;
				}
				else if (Sprn < 48) {
					seg_limit[Sprn-32] = gp[Ra] & 0xFFFFFFFFFFFFF000LL;
				}
				else {
					switch(Sprn) {
					case 51:	lc = gp[Ra]; break;
					case 52:
						for (nn = 0; nn < 16; nn++) {
							pr[nn] = (gp[Ra] >> (nn * 4)) & 0xF;
						}
						break;
					case 60:	bir = gp[Ra] & 0xFFLL; break;
					case 61:
						switch(bir) {
						case 0: dbad0 = gp[Ra]; break;
						case 1: dbad1 = gp[Ra]; break;
						case 2: dbad2 = gp[Ra]; break;
						case 3: dbad3 = gp[Ra]; break;
						case 4: dbctrl = gp[Ra]; break;
						case 5: dbstat = gp[Ra]; break;
						}
					}
				}
			}
			imm_prefix = false;
			return;

		case RR:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rb = ((b2 << 2) & 0x3c) | (b1 >> 6);
				Rt = (b2 >> 4) | ((b3 & 0x3) << 4);
				func = b3 >> 2;
				switch(func) {
				case _2ADDU:
					gp[Rt] = (gp[Ra] << 1) + gp[Rb];
					gp[0] = 0;
					break;
				case _4ADDU:
					gp[Rt] = (gp[Ra] << 2) + gp[Rb];
					gp[0] = 0;
					break;
				case _8ADDU:
					gp[Rt] = (gp[Ra] << 3) + gp[Rb];
					gp[0] = 0;
					break;
				case _16ADDU:
					gp[Rt] = (gp[Ra] << 4) + gp[Rb];
					gp[0] = 0;
					break;
				}
			}
			imm_prefix = 0;
			return;

		case RTS:
			b1 = ReadByte(pc);
			pc++;
			if (ex) {
				Cr = (b1 & 0xF0) >> 4;
				pc = ca[Cr] + (b1 & 0x0F);
			}
			imm_prefix = 0;
			return;

		case RTSQ:
			if (ex) {
				pc = ca[1];
			}
			imm_prefix = 0;
			return;

		case SB:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				system1->Write(ea,gp[Rb],(0x1 << (ea & 7)) & 0xFF);
			}
			imm_prefix = false;
			return;

		case SC:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				system1->Write(ea,gp[Rb],(0x3 << (ea & 7)) & 0xFF);
			}
			imm_prefix = false;
			return;

		case SH:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				system1->Write(ea,gp[Rb],(0xF << (ea & 7)) & 0xFF);
			}
			imm_prefix = false;
			return;

		case SHIFT:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Ra = b1 & 0x3f;
				Rb = ((b2 << 2) & 0x3c) | (b1 >> 6);
				Rt = (b2 >> 4) | ((b3 & 0x3) << 4);
				func = b3 >> 2;
				switch(func) {
				case SHL:
					gp[Rt] = (gp[Ra] << (gp[Rb] & 0x3f));
					gp[0] = 0;
					break;
				case SHLI:
					gp[Rt] = (gp[Ra] << Rb);
					gp[0] = 0;
					break;
				}
			}
			imm_prefix = false;
			return;

		case STP:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			imm_prefix = false;
			return;

		case SW:
			b1 = ReadByte(pc);
			pc++;
			b2 = ReadByte(pc);
			pc++;
			b3 = ReadByte(pc);
			pc++;
			if (ex) {
				Rb = ((b2 & 0xF) << 2) | (( b1 >> 6) & 3);
				dRn(b1,b2,b3,&Ra,&Sg,&disp);
				ea = (unsigned __int64) disp + seg_base[Sg] + gp[Ra];
				system1->Write(ea,gp[Rb],(0xFF << (ea & 7)) & 0xFF);
			}
			imm_prefix = false;
			return;

		}
	}
}
