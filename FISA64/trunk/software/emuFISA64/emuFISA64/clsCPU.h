#include "Instructions.h"
#include "clsSystem.h"

#pragma once

extern class clsSystem system1;

// Currently unaligned memory access is not supported.
// Made more complicated by the fact it's a 64 bit machine.

class clsCPU
{
public:
	char isRunning;
	char brk;
	unsigned int ir, xir, wir;
	int sir;
	unsigned __int64 regs[32];
	unsigned int pc;
	unsigned int pcs[40];
	unsigned int dpc;
	unsigned int epc;
	unsigned int ipc;
	unsigned __int64 dsp;
	unsigned __int64 esp;
	unsigned __int64 isp;
	unsigned int vbr;
	unsigned dbad0;
	unsigned dbad1;
	unsigned dbad2;
	unsigned dbad3;
	unsigned __int64 dbctrl;
	unsigned __int64 dbstat;
	unsigned __int64 tick;
	unsigned __int64 ubound[64];
	unsigned __int64 lbound[64];
	unsigned __int64 mmask[64];
	char km;
	char irq;
	char nmi;
	char im;
	short int vecno;
	unsigned __int64 cr0;
	int Ra,Rb,Rc;
	int Rt;
	int mb,me;
	int spr;
	int Bn;
	unsigned int imm1;
	unsigned int imm2;
	char hasPrefix;
	int immcnt;
	unsigned int opcode;
	int i1;
	__int64 a, b, res, imm, sp_res;
	unsigned __int64 ua, ub;
	int nn;
	int bmask;

	void Reset()
	{
		km = true;
		brk = 0;
		im = true;
		irq = false;
		nmi = false;
		isRunning = false;
		regs[0] = 0;
		pc = 0x10000;
		vbr = 0;
		tick = 0;
	};
	void BuildConstant() {
		if (immcnt==2) {
			imm1 = (((xir >> 7) << 15) | (ir >> 17));
			imm2 = ((xir >> 7) >> 17);
			imm2 = imm2 | ((wir >> 7) << 8);
		}
		else if (immcnt==1) {
			imm1 = (((xir >> 7) << 15) | (ir >> 17));
			imm2 = ((xir >> 7) >> 17);
			imm2 = imm2 | (xir&0x80000000 ? 0xFFFFFF00 : 0x00000000);
		}
		else {
			sir = ir;
			imm1 = (sir >> 17);
			imm2 = sir&0x80000000 ? 0xFFFFFFFF : 0x00000000;
		}
		imm = ((__int64)imm2 << 32) | imm1;
	};
	//c = op? (~a&b)|(s&~a)|(s&b) : (a&b)|(a&~s)|(b&~s);
	int HalfCarry(int as, int a, int b, int r) {
		int hc;
		if (as)
			hc = (~a&b)|(r&~a)|(r&b);
		else
			hc = (a & b) | (a & ~r) | (b & ~r);
		hc >>= 31;
		return hc;
	}
	void Step()
	{
		unsigned int ad;
		int nn;
		int sc;
		tick = tick + 1;
		//---------------------------------------------------------------------------
		// Instruction Fetch stage
		//---------------------------------------------------------------------------
		wir = xir;
		xir = ir;
		if (nmi)
			sir = ir = 0x38 + (0x1E << 7) + (510 << 17) + 0x80000000L;
		else if (irq & ~im)
			sir = ir = 0x38 + (0x1E << 7) + (vecno << 17) + 0x80000000L;
		else
			sir = ir = system1.Read(pc);
		for (nn = 39; nn >= 0; nn--)
			pcs[nn] = pcs[nn-1];
		pcs[0] = pc;
		//---------------------------------------------------------------------------
		// Decode stage
		//---------------------------------------------------------------------------
		Ra = (ir >> 7) & 0x1f;
		Rb = (ir >> 17) & 0x1F;
		Rt = (ir >> 12) & 0x1f;
		Rc = (ir >> 12) & 0x1f;
		Bn = (ir >> 17) & 0x3f;
		spr = (ir >> 17) & 0xff;
		sc = (ir >> 22) & 3;
		mb = (ir >> 17) & 0x3f;
		me = (ir >> 23) & 0x3f;

		a = regs[Ra];
		b = regs[Rb];
		ua = a;
		ub = b;
		res = 0;
		opcode = ir & 0x7f;
		//---------------------------------------------------------------------------
		// Execute stage
		//---------------------------------------------------------------------------
		switch(opcode) {
		case RR:
			switch(ir >> 25) {
			case CPUID:	// for now cpuid return 0
				res = 0;
				pc = pc + 4;
				break;
			case PCTRL:
				Rt = 0;
				switch((ir >> 17) & 0x1f) {
				case SEI:  im = true; pc = pc + 4; break;
				case CLI:  im = false; pc = pc + 4; break;
				case WAI:	if (irq || nmi) pc = pc + 4; break;
				case RTI:
					pc = ipc;
					regs[30] = isp;
					break;
				case RTD:
					pc = dpc;
					regs[30] = dsp;
					break;
				case RTE:
					pc = epc;
					regs[30] = esp;
					break;
				default: pc = pc + 4;
				}
				break;
			case MTSPR:
				Rt = 0;
				switch(spr) {
				case 0: cr0 = a; break;
				case 7: dpc = a; break;
				case 8: ipc = a; break;
				case 9: epc = a; break;
				case 10: vbr = a; break;
				case 15: isp = a; break;
				case 16: dsp = a; break;
				case 17: esp = a; break;
				case 50: dbad0 = a; break;
				case 51: dbad1 = a; break;
				case 52: dbad2 = a; break;
				case 53: dbad3 = a; break;
				case 54: dbctrl = a; break;
				case 55: dbstat = a; break;
				default:
					if (spr >= 64 && spr < 128)
						lbound[spr-64] = a;
					else if (spr >= 128 && spr < 192)
						ubound[spr-128] = a;
					else if (spr >= 192 && spr < 256)
						mmask[spr-192] = a;
				}
				pc = pc + 4;
				break;
			case MFSPR:
				switch(spr) {
				case 0: res = cr0; break;
				case 4: res = tick; break;
				case 7: res = dpc; break;
				case 8: res = ipc; break;
				case 9: res = epc; break;
				case 10: res = vbr; break;
				case 15: res = isp; break;
				case 16: res = dsp; break;
				case 17: res = esp; break;
				case 50: res = dbad0; break;
				case 51: res = dbad1; break;
				case 52: res = dbad2; break;
				case 53: res = dbad3; break;
				case 54: res = dbctrl; break;
				case 55: res = dbstat; break;
				default:
					if (spr >= 64 && spr < 128)
						res = lbound[spr-64];
					else if (spr >= 128 && spr < 192)
						res = ubound[spr-128];
					else if (spr >= 192 && spr < 256)
						res = mmask[spr-192];
				}
				pc = pc + 4;
				break;
			case SXB:
				res = (a & 0xff) | ((a & 0x80) ? 0xFFFFFFFFFFFFFF00LL : 0x0);
				pc = pc + 4;
				break;
			case SXC:
				res = (a & 0xFFFF) | ((a & 0x8000) ? 0xFFFFFFFFFFFF0000LL : 0x0);
				pc = pc + 4;
				break;
			case SXH:
				res = (a & 0xFFFFFFFF) | ((a & 0x80000000) ? 0xFFFFFFFF00000000LL : 0x0);
				pc = pc + 4;
				break;
			case ADD:
			case ADDU:
				res = a + b;
				pc = pc+4;
				break;
			case SUB:
			case SUBU:
				res = a - b;
				pc = pc+4;
				break;
			case CMP:
				if (a < b)
					res = -1LL;
				else if (a == b)
					res=0LL;
				else
					res=1LL;
				pc = pc + 4;
				break;
			case CMPU:
				if (ua < ub)
					res = -1LL;
				else if (ua == ub)
					res=0LL;
				else
					res=1LL;
				pc = pc + 4;
				break;
			case MUL:
				res = a * b;
				pc = pc + 4;
				break;
			case MULU:
				res = ua * ub;
				pc = pc + 4;
				break;
			case AND:
				res = a & b;
				pc = pc + 4;
				break;
			case OR:
				res = a | b;
				pc = pc + 4;
				break;
			case EOR:
				res = a ^ b;
				pc = pc + 4;
				break;
			case CHK:
				res = (a >= lbound[Bn] && a < ubound[Bn] && (a & mmask[Bn]==0));
				pc = pc + 4;
				break;
			case ASL:
				res = a << (b & 0x3f);
				pc = pc + 4;
				break;
			case LSR:
				res = ua >> (b & 0x3f);
				pc = pc + 4;
				break;
			case ROL:
				res = (a << (b & 0x3f)) | (a >> ((b-64)&0x3f));
				pc = pc + 4;
				break;
			case ROR:
				res = (a >> (b & 0x3f)) | (a << ((b-64)&0x3f));
				pc = pc + 4;
				break;
			case ASR:
				res = a >> (b & 0x3f);
				pc = pc + 4;
				break;
			case ASLI:
				res = a << (Bn & 0x3f);
				pc = pc + 4;
				break;
			case LSRI:
				res = ua >> (Bn & 0x3f);
				pc = pc + 4;
				break;
			case ROLI:
				res = (a << (Bn & 0x3f)) | (a >> ((Bn-64)&0x3f));
				pc = pc + 4;
				break;
			case RORI:
				res = (a >> (Bn & 0x3f)) | (a << ((Bn-64)&0x3f));
				pc = pc + 4;
				break;
			case ASRI:
				res = a >> (Bn & 0x3f);
				pc = pc + 4;
				break;
			case SEQ:
				res = a == b;
				pc = pc + 4;
				break;
			case SNE:
				res = a != b;
				pc = pc + 4;
				break;
			case SGT:
				res = a > b;
				pc = pc + 4;
				break;
			case SLE:
				res = a <= b;
				pc = pc + 4;
				break;
			case SGE:
				res = a >= b;
				pc = pc + 4;
				break;
			case SLT:
				res = a <= b;
				pc = pc + 4;
				break;
			case SHI:
				res = ua > ub;
				pc = pc + 4;
				break;
			case SLS:
				res = ua <= ub;
				pc = pc + 4;
				break;
			case SHS:
				res = ua >= ub;
				pc = pc + 4;
				break;
			case SLO:
				res = ua <= ub;
				pc = pc + 4;
				break;
			default: pc = pc + 4;
			}
			break;
		case BTFLD:
			switch((ir >> 29) & 7) {
			case BFEXTU:
				bmask = 0;
				for (nn = 0; nn < me-mb+1; nn ++) {
					bmask = (bmask << 1) | 1;
				}
				res = (a >> mb) & bmask;
				break;
			}
			pc = pc + 4;
			break;
		case LDI:
			BuildConstant();
			res = imm;
			pc = pc + 4;
			break;
		case ADD:
		case ADDU:
			BuildConstant();
			res = a + imm;
			pc = pc+4;
			break;
		case SUB:
		case SUBU:
			BuildConstant();
			res = a - imm;
			pc = pc+4;
			break;
		case CMP:
			BuildConstant();
			if (a < imm)
				res = -1LL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			pc = pc + 4;
			break;
		case CMPU:
			BuildConstant();
			if (ua < (unsigned __int64)imm)
				res = 0xFFFFFFFFFFFFFFFFLL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			pc = pc + 4;
			break;
		case MUL:
			BuildConstant();
			res = a * imm;
			pc = pc + 4;
			break;
		case MULU:
			BuildConstant();
			res = ua * (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case AND:
			BuildConstant();
			res = a & imm;
			pc = pc + 4;
			break;
		case OR:
			BuildConstant();
			res = a | imm;
			pc = pc + 4;
			break;
		case EOR:
			BuildConstant();
			res = a ^ imm;
			pc = pc + 4;
			break;
		case SEQ:
			BuildConstant();
			res = a == imm;
			pc = pc + 4;
			break;
		case SNE:
			BuildConstant();
			res = a != imm;
			pc = pc + 4;
			break;
		case SGT:
			BuildConstant();
			res = a > imm;
			pc = pc + 4;
			break;
		case SLE:
			BuildConstant();
			res = a <= imm;
			pc = pc + 4;
			break;
		case SGE:
			BuildConstant();
			res = a >= imm;
			pc = pc + 4;
			break;
		case SLT:
			BuildConstant();
			res = a <= imm;
			pc = pc + 4;
			break;
		case SHI:
			BuildConstant();
			res = ua > (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case SLS:
			BuildConstant();
			res = ua <= (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case SHS:
			BuildConstant();
			res = ua >= (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case SLO:
			BuildConstant();
			res = ua <= (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case LB:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			pc = pc + 4;
			break;
		case LBU:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			pc = pc + 4;
			break;
		case LBX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			pc = pc + 4;
			break;
		case LBUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			pc = pc + 4;
			break;
		case LC:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			pc = pc + 4;
			break;
		case LCU:
			BuildConstant();
			ad = a + imm;
			res = system1.Read(ad);
			res = (res >> ((ad & 3)<<3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LCX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			pc = pc + 4;
			break;
		case LCUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LH:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHU:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			pc = pc + 4;
			break;
		case LHX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			pc = pc + 4;
			break;
		case LW:
			BuildConstant();
			ad = a + imm;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case LWAR:
			BuildConstant();
			ad = a + imm;
			res = system1.Read(ad,1);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case LWX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case INC:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			res += (ir>> 16)&1 ? 0xFFFFFFFFFFFFFFF0LL | ((ir >> 12) & 0x1F): (ir >> 12) & 0x1F;
			system1.Write(ad,(int)res,0xFFFFFFFF);
			system1.Write(ad+4,(int)(res>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case LEA:
			BuildConstant();
			res = a + imm;
			pc = pc + 4;
			break;
		case LEAX:
			imm = (ir >> 24);
			res = a + (b << sc) + imm;
			pc = pc + 4;
			break;
		case SB:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 5:
				system1.Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 6:
				system1.Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 7:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SBX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 5:
				system1.Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 6:
				system1.Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 7:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SC:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 5:
				system1.Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 6:
				system1.Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 7:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SCX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 5:
				system1.Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 6:
				system1.Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 7:
				system1.Write(ad,(int)regs[Rc],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SH:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1.Write(ad,(int)regs[Rc],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SHX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1.Write(ad,(int)regs[Rc],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SW:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1.Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SWCR:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			nn = system1.Write(ad,(int)regs[Rc],0xFFFFFFFF,1);
			cr0 &= 0xFFFFFFEFFFFFFFFFLL;
			if (nn) cr0 |= 0x1000000000LL;
			system1.Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF,0);
			pc = pc + 4;
			break;
		case SWX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1.Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case POP:
			BuildConstant();
			ad = regs[30];
			regs[30] += 8LL;
			res = system1.Read(ad,0);
			res |= ((unsigned __int64)system1.Read(ad+4,0)) << 32;
			pc = pc + 4;
			break;
		case PUSH:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1.Write(ad,(int)regs[Ra],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Ra]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case PEA:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1.Write(ad,(int)(a+imm),0xFFFFFFFF);
			system1.Write(ad+4,(int)((a+imm)>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case PMW:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = a + imm;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			ad = regs[30];
			system1.Write(ad,(int)(res),0xFFFFFFFF);
			system1.Write(ad+4,(int)((res)>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;

		case BRA:	Rt = 0; pc = pc + ((sir >> 7) << 2); break;
		case BSR:	Rt = 0; regs[31] = pc + 4; pc = pc + ((sir >> 7) << 2); break;
		case RTL:   
			Rt = 0;
			pc = (unsigned int)regs[31];
			regs[30] = regs[30] + (ir >> 17);
			break;
		case RTS:
			Rt = 0;
			a = system1.Read((unsigned int)regs[30]);
			regs[31] = a;
			pc = a;
			regs[30] = regs[30] + (ir >> 17);
			break;
		case JALI:
			BuildConstant();
			ad = a + imm;
			res = pc + 4;
			pc = system1.Read(ad);
			break;
		case JAL:
			BuildConstant();
			ad = a + imm;
			res = pc + 4;
			pc = ad;
			break;
		case BRK:
			switch((ir >> 30)&3) {
			case 0:	
				epc = pc;
				esp = regs[30];
				break;
			case 1:
				dpc = pc;
				dsp = regs[30];
				break;
			case 2:
				ipc = pc;
				isp = regs[30];
				break;
			}
			km = true;
			ad = vbr + (((ir >> 17) & 0x1ff) << 3);
			pc = system1.Read(ad);
			break;
		case Bcc:
			Rt = 0;
			switch((ir >> 12) & 7) {
			case BEQ:
				if (regs[Ra]==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BNE:
				if (regs[Ra]!=0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLT:
				if (regs[Ra] & 0x8000000000000000LL)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLE:
				if ((regs[Ra] & 0x8000000000000000LL) || (regs[Ra]==0))
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGE:
				if ((regs[Ra] & 0x8000000000000000LL)==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGT:
				if (((regs[Ra] & 0x8000000000000000LL)==0) && (regs[Ra]!=0))
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			default:
				pc = pc + 4;
				break;
			}
			break;
		case NOP:	Rt = 0; pc = pc + 4; immcnt = 0; break;
		case IMM:
			Rt = 0;
			pc = pc + 4;
			immcnt = immcnt + 1;
			break;
		default: pc = pc + 4; break;
		}
		//---------------------------------------------------------------------------
		// Writeback stage
		//---------------------------------------------------------------------------
		if (Rt != 0) {
			regs[Rt] = res;
		}
		if (opcode != IMM)
			immcnt = 0;
		regs[0] = 0;
	};
};
