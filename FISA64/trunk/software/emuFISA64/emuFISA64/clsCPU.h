#include "Instructions.h"
#include "clsSystem.h"

#pragma once

extern clsSystem system1;

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
	char irq;
	char nmi;
	char im;
	short int vecno;
	unsigned __int64 cr0;
	int Ra,Rb;
	int Rt;
	int spr;
	unsigned int imm1;
	unsigned int imm2;
	char hasPrefix;
	int immcnt;
	unsigned int opcode;
	int i1;
	__int64 a, b, res, imm, sp_res;
	unsigned __int64 ua, ub;

	void Reset()
	{
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
		//---------------------------------------------------------------------------
		// Decode stage
		//---------------------------------------------------------------------------
		Ra = (ir >> 7) & 0x1f;
		Rb = (ir >> 17) & 0x1F;
		Rt = (ir >> 12) & 0x1f;
		spr = (ir >> 17) & 0xff;
		sc = (ir >> 22) & 3;

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
				regs[Rt] = 0;
				pc = pc + 4;
				break;
			case PCTRL:
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
				switch(spr) {
				case 0: cr0 = a;
				case 7: dpc = a;
				case 8: ipc = a;
				case 9: epc = a;
				case 10: vbr = a;
				case 15: isp = a;
				case 16: dsp = a;
				case 17: esp = a;
				case 50: dbad0 = a;
				case 51: dbad1 = a;
				case 52: dbad2 = a;
				case 53: dbad3 = a;
				case 54: dbctrl = a;
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
				case 0: res = cr0;
				case 4: res = tick;
				case 7: res = dpc;
				case 8: res = ipc;
				case 9: res = epc;
				case 10: res = vbr;
				case 15: res = isp;
				case 16: res = dsp;
				case 17: res = esp;
				case 50: res = dbad0;
				case 51: res = dbad1;
				case 52: res = dbad2;
				case 53: res = dbad3;
				case 54: res = dbctrl;
				case 55: res = dbstat;
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
			default: pc = pc + 4;
			}
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
			res = a * imm;
			pc = pc + 4;
			break;
		case MULU:
			res = ua * (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case LB:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFF00;
			pc = pc + 4;
			break;
		case LBU:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFF;
			pc = pc + 4;
			break;
		case LBX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFF00;
			pc = pc + 4;
			break;
		case LBUX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFF;
			pc = pc + 4;
			break;
		case LC:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFFFF;
			if (res & 0x80) res |= 0xFFFF0000;
			pc = pc + 4;
			break;
		case LCU:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LCX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFF0000;
			pc = pc + 4;
			break;
		case LCUX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LH:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHU:
			BuildConstant();
			ad = a + imm;
			res = (system1.Read(ad) >> (ad & 3));
			res &= 0x00000000FFFFFFFFLL;
			pc = pc + 4;
			break;
		case LHX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHUX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = (system1.Read(ad) >> (ad & 3));
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
		case LWX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case LEA:
			BuildConstant();
			res = a + imm;
			pc = pc + 4;
			break;
		case LEAX:
			BuildConstant();
			res = a + (b << sc) + imm;
			pc = pc + 4;
			break;
		case SB:
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rt],0x000000FF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rt],0x0000FF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rt],0x00FF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rt],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)(regs[Rt]>>32),0x000000FF);
				break;
			case 5:
				system1.Write(ad,(int)(regs[Rt]>>32),0x0000FF00);
				break;
			case 6:
				system1.Write(ad,(int)(regs[Rt]>>32),0x00FF0000);
				break;
			case 7:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SBX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rt],0x000000FF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rt],0x0000FF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rt],0x00FF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rt],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)(regs[Rt]>>32),0x000000FF);
				break;
			case 5:
				system1.Write(ad,(int)(regs[Rt]>>32),0x0000FF00);
				break;
			case 6:
				system1.Write(ad,(int)(regs[Rt]>>32),0x00FF0000);
				break;
			case 7:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SC:
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rt],0x0000FFFF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rt],0x00FFFF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rt],0xFFFF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rt],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)(regs[Rt]>>32),0x0000FFFF);
				break;
			case 5:
				system1.Write(ad,(int)(regs[Rt]>>32),0x00FFFF00);
				break;
			case 6:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFFFF0000);
				break;
			case 7:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SCX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			switch(ad & 7) {
			case 0:
				system1.Write(ad,(int)regs[Rt],0x0000FFFF);
				break;
			case 1:
				system1.Write(ad,(int)regs[Rt],0x00FFFF00);
				break;
			case 2:
				system1.Write(ad,(int)regs[Rt],0xFFFF0000);
				break;
			case 3:
				system1.Write(ad,(int)regs[Rt],0xFF000000);
				break;
			case 4:
				system1.Write(ad,(int)(regs[Rt]>>32),0x0000FFFF);
				break;
			case 5:
				system1.Write(ad,(int)(regs[Rt]>>32),0x00FFFF00);
				break;
			case 6:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFFFF0000);
				break;
			case 7:
				system1.Write(ad,(int)(regs[Rt]>>32),0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SH:
			BuildConstant();
			ad = a + imm;
			system1.Write(ad,(int)regs[Rt],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SHX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			system1.Write(ad,(int)regs[Rt],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SW:
			BuildConstant();
			ad = a + imm;
			system1.Write(ad,(int)regs[Rt],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Rt]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SWX:
			BuildConstant();
			ad = a + (b << sc) + imm;
			system1.Write(ad,(int)regs[Rt],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Rt]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case POP:
			BuildConstant();
			ad = regs[30];
			regs[30] += 8LL;
			res = system1.Read(ad);
			res |= ((unsigned __int64)system1.Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case PUSH:
			BuildConstant();
			regs[30] -= 8LL;
			ad = regs[30];
			system1.Write(ad,(int)regs[Rt],0xFFFFFFFF);
			system1.Write(ad+4,(int)(regs[Rt]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case PEA:
			BuildConstant();
			regs[30] -= 8LL;
			ad = regs[30];
			system1.Write(ad,(int)(a+imm),0xFFFFFFFF);
			system1.Write(ad+4,(int)((a+imm)>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case BRA:	pc = pc + ((sir >> 7) << 2); break;
		case BSR:	regs[31] = pc + 4; pc = pc + ((sir >> 7) << 2); break;
		case RTL:   
			pc = (unsigned int)regs[31];
			regs[30] = regs[30] + (ir >> 17);
			break;
		case RTS:
			a = system1.Read((unsigned int)regs[30]);
			regs[31] = a;
			pc = a;
			regs[30] = regs[30] + (ir >> 17);
			break;
		case Bcc:
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
		case NOP:	pc = pc + 4; immcnt = 0; break;
		case IMM:
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
