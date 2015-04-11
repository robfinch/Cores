#include "Instructions.h"
#include "clsSystem.h"

#pragma once

extern clsSystem system1;

// Currently unaligned memory access is not supported.

class clsCPU
{
public:
	char isRunning;
	char brk;
	unsigned int ir, xir, wir;
	int sir;
	unsigned int regsL[32];
	unsigned int regsH[32];
	unsigned int pc;
	unsigned int dpc;
	unsigned int epc;
	unsigned int ipc;
	unsigned int dsp;
	unsigned int esp;
	unsigned int isp;
	int Ra;
	int Rt;
	unsigned int imm1;
	unsigned int imm2;
	char hasPrefix;
	int immcnt;
	unsigned int opcode;

	void Reset()
	{
		brk = 0;
		isRunning = false;
		regsL[0] = 0;
		regsH[0] = 0;
		pc = 0x10000;
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
	};
	void Step()
	{
		unsigned int ad;
		wir = xir;
		xir = ir;
		sir = ir = system1.Read(pc);
		Ra = (ir >> 7) & 0x1f;
		Rt = (ir >> 12) & 0x1f;
		opcode = ir & 0x7f;
		switch(opcode) {
		case RR:
			switch(ir >> 25) {
			case CPUID:	// for now cpuid return 0
				regsL[Rt] = 0;
				regsH[Rt] = 0;
				pc = pc + 4;
				break;
			default: pc = pc + 4;
			}
			break;
		case LDI:
			BuildConstant();
			if (Rt != 0) {
				regsL[Rt] = imm1;
				regsH[Rt] = imm2;
			}
			pc = pc + 4;
			break;
		case LB:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsL[Rt] &= 0x000000FF;
				regsL[Rt] |= regsL[Rt] & 0x80 ? 0xFFFFFF00 : 0x00000000;
				regsH[Rt] = regsL[Rt] & 0x80 ? 0xFFFFFFFF : 0x00000000;
			}
			pc = pc + 4;
			break;
		case LBU:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsL[Rt] &= 0x000000FF;
				regsH[Rt] = 0x00000000;
			}
			pc = pc + 4;
			break;
		case LC:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsL[Rt] &= 0x0000FFFF;
				regsL[Rt] |= regsL[Rt] & 0x8000 ? 0xFFFF0000 : 0x00000000;
				regsH[Rt] = regsL[Rt] & 0x8000 ? 0xFFFFFFFF : 0x00000000;
			}
			pc = pc + 4;
			break;
		case LCU:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsL[Rt] &= 0x0000FFFF;
				regsH[Rt] = 0x00000000;
			}
			pc = pc + 4;
			break;
		case LH:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsH[Rt] = regsL[Rt] & 0x80000000 ? 0xFFFFFFFF : 0x00000000;
			}
			pc = pc + 4;
			break;
		case LHU:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad) >> (ad & 3);
				regsH[Rt] = 0x00000000;
			}
			pc = pc + 4;
			break;
		case LW:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = system1.Read(ad);
				regsH[Rt] = system1.Read(ad+4);
			}
			pc = pc + 4;
			break;
		case LEA:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			if (Rt != 0) {
				regsL[Rt] = ad;
				regsH[Rt] = 0;
			}
			pc = pc + 4;
			break;
		case SB:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			switch(ad & 3) {
			case 0:
				system1.Write(ad,regsL[Rt],0x000000FF);
				break;
			case 1:
				system1.Write(ad,regsL[Rt],0x0000FF00);
				break;
			case 2:
				system1.Write(ad,regsL[Rt],0x00FF0000);
				break;
			case 3:
				system1.Write(ad,regsL[Rt],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SC:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			switch(ad & 3) {
			case 0:
				system1.Write(ad,regsL[Rt],0x0000FFFF);
				break;
			case 1:
				system1.Write(ad,regsL[Rt],0x00FFFF00);
				break;
			case 2:
				system1.Write(ad,regsL[Rt],0xFFFF0000);
				break;
			case 3:
				system1.Write(ad,regsL[Rt],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SH:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			system1.Write(ad,regsL[Rt],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SW:
			BuildConstant();
			ad = imm1 + regsL[Ra];
			system1.Write(ad,regsL[Rt],0xFFFFFFFF);
			system1.Write(ad,regsH[Rt],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case BRA:	pc = pc + ((sir >> 7) << 2); break;
		case BSR:	pc = pc + ((sir >> 7) << 2); regsL[31] = pc; regsH[31] = 0; break;
		case Bcc:
			switch((ir >> 12) & 7) {
			case BEQ:
				if (regsL[Ra]==0 && regsH[Ra]==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BNE:
				if (regsL[Ra]!=0 || regsH[Ra]!=0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLT:
				if (regsH[Ra] & 0x80000000)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLE:
				if ((regsH[Ra] & 0x80000000) || (regsH[Ra]==0 && regsL[Ra]==0))
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGE:
				if ((regsH[Ra] & 0x80000000)==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGT:
				if (((regsH[Ra] & 0x80000000)==0) && (regsH[Ra]!=0 || regsL[Ra]!=0))
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
		if (opcode != IMM)
			immcnt = 0;
		regsL[0] = 0;
		regsH[0] = 0;
	};
};
