#include "stdafx.h"

void clsCPU::Reset()
	{
		km = true;
		brk = 0;
		im = true;
		irq = false;
		nmi = false;
		StatusHWI = false;
		isRunning = false;
		regs[0] = 0;
		pc = 0x10000;
		vbr = 0;
		tick = 0;
		rvecno = 0;
	};
	void clsCPU::BuildConstant() {
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
	void clsCPU::Step()
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
		if (nmi & !StatusHWI)
			sir = ir = 0x38 + (0x1E << 7) + (510 << 17) + 0x80000000L;
		else if (irq & ~im & !StatusHWI)
			sir = ir = 0x38 + (0x1E << 7) + (vecno << 17) + 0x80000000L;
		else
			sir = ir = system1->Read(pc);
		for (nn = 39; nn >= 0; nn--)
			pcs[nn] = pcs[nn-1];
		pcs[0] = pc;
dc:
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
		c = regs[Rc];
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
					km = ipc & 1;
					pc = ipc & -4;
					regs[30] = isp;
					StatusHWI = false;
					break;
				case RTD:
					km = dpc & 1;
					pc = dpc & -4;
					regs[30] = dsp;
					break;
				case RTE:
					km = epc & 1;
					pc = epc & -4;
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
				default: ;
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
				case 12: res = rvecno; break;
				case 15: res = isp; break;
				case 16: res = dsp; break;
				case 17: res = esp; break;
				case 50: res = dbad0; break;
				case 51: res = dbad1; break;
				case 52: res = dbad2; break;
				case 53: res = dbad3; break;
				case 54: res = dbctrl; break;
				case 55: res = dbstat; break;
				default: res = 0;
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
			case DIV:
				res = a / b;
				pc = pc + 4;
				break;
			case DIVU:
				res = ua / ub;
				pc = pc + 4;
				break;
			case MOD:
				res = a % b;
				pc = pc + 4;
				break;
			case MODU:
				res = ua % ub;
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
			case NOT:
				res = !a;
				pc = pc + 4;
				break;
			case NAND:
				res = ~(a & b);
				pc = pc + 4;
				break;
			case NOR:
				res = ~(a | b);
				pc = pc + 4;
				break;
			case ENOR:
				res = ~(a ^ b);
				pc = pc + 4;
				break;
			case CHK:
				Rt = 0;
				r1 = a >= c;
				r2 = a < b;
				res = r1 && r2;
				if (!res) {
					ir = 0x03cc0f38;
					goto dc;
				}
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
				res = (a << (b & 0x3f)) | (a >> ((64-b)&0x3f));
				pc = pc + 4;
				break;
			case ROR:
				res = (a >> (b & 0x3f)) | (a << ((64-b)&0x3f));
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
				res = (ua << (Bn & 0x3f)) | (ua >> ((64-Bn)&0x3f));
				pc = pc + 4;
				break;
			case RORI:
				res = (ua >> (Bn & 0x3f)) | (ua << ((64-Bn)&0x3f));
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
			bmask = 0;
			for (nn = 0; nn < me-mb+1; nn ++) {
				bmask = (bmask << 1) | 1;
			}
			switch((ir >> 29) & 7) {
			case BFSET:
				bmask <<= mb;
				res = a | bmask << mb;
				break;
			case BFCLR:
				bmask <<= mb;
				res = a & ~(bmask << mb);
				break;
			case BFCHG:
				bmask <<= mb;
				res = a ^ (bmask << mb);
				break;
			case BFINS:
				bmask <<= mb;
				c &= ~(bmask << mb);
				res = c | ((a & bmask) << mb);
				break;
			case BFINSI:
				bmask <<= mb;
				c &= ~(bmask << mb);
				res = c | ((Ra & bmask) << mb);
				break;
			case BFEXT:
				res = (a >> mb) & bmask;
				if (res & ((bmask + 1) >> 1) != 0) res |= ~bmask;
				break;
			case BFEXTU:
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
		case CHK:
			BuildConstant();
			Rt = 0;
			r1 = a >= c;
			r2 = a < imm;
			res = r1 && r2;
			if (!res) {
				ir = 0x03cc0f38;
				goto dc;
			}
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
		case DIV:
			BuildConstant();
			res = a / imm;
			pc = pc + 4;
			break;
		case DIVU:
			BuildConstant();
			res = ua / (unsigned __int64)imm;
			pc = pc + 4;
			break;
		case MOD:
			BuildConstant();
			res = a % imm;
			pc = pc + 4;
			break;
		case MODU:
			BuildConstant();
			res = ua % (unsigned __int64)imm;
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
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			pc = pc + 4;
			break;
		case LBU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			pc = pc + 4;
			break;
		case LBX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			pc = pc + 4;
			break;
		case LBUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			pc = pc + 4;
			break;
		case LC:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			pc = pc + 4;
			break;
		case LCU:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res = (res >> ((ad & 3)<<3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LCX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			pc = pc + 4;
			break;
		case LCUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			pc = pc + 4;
			break;
		case LH:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			pc = pc + 4;
			break;
		case LHX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			pc = pc + 4;
			break;
		case LHUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			pc = pc + 4;
			break;
		case LW:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case LWAR:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad,1);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case LWX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			pc = pc + 4;
			break;
		case INC:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			res += (ir>> 16)&1 ? 0xFFFFFFFFFFFFFFF0LL | ((ir >> 12) & 0x1F): (ir >> 12) & 0x1F;
			system1->Write(ad,(int)res,0xFFFFFFFF);
			system1->Write(ad+4,(int)(res>>32),0xFFFFFFFF);
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
				system1->Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 1:
				system1->Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 2:
				system1->Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 3:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1->Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 5:
				system1->Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 6:
				system1->Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 7:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
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
				system1->Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 1:
				system1->Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 2:
				system1->Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 3:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1->Write(ad,(int)regs[Rc],0x000000FF);
				break;
			case 5:
				system1->Write(ad,(int)regs[Rc],0x0000FF00);
				break;
			case 6:
				system1->Write(ad,(int)regs[Rc],0x00FF0000);
				break;
			case 7:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
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
				system1->Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 1:
				system1->Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 2:
				system1->Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 3:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1->Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 5:
				system1->Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 6:
				system1->Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 7:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
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
				system1->Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 1:
				system1->Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 2:
				system1->Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 3:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
				break;
			case 4:
				system1->Write(ad,(int)regs[Rc],0x0000FFFF);
				break;
			case 5:
				system1->Write(ad,(int)regs[Rc],0x00FFFF00);
				break;
			case 6:
				system1->Write(ad,(int)regs[Rc],0xFFFF0000);
				break;
			case 7:
				system1->Write(ad,(int)regs[Rc],0xFF000000);
				break;
			}
			pc = pc + 4;
			break;
		case SH:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SHX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SW:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case SWCR:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			nn = system1->Write(ad,(int)regs[Rc],0xFFFFFFFF,1);
			cr0 &= 0xFFFFFFEFFFFFFFFFLL;
			if (nn) cr0 |= 0x1000000000LL;
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF,0);
			pc = pc + 4;
			break;
		case SWX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case POP:
			BuildConstant();
			ad = (unsigned int)regs[30];
			regs[30] += 8LL;
			res = system1->Read(ad,0);
			res |= ((unsigned __int64)system1->Read(ad+4,0)) << 32;
			pc = pc + 4;
			break;
		case PUSH:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1->Write(ad,(int)regs[Ra],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Ra]>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case PEA:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1->Write(ad,(int)(a+imm),0xFFFFFFFF);
			system1->Write(ad+4,(int)((a+imm)>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;
		case PMW:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = a + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			ad = regs[30];
			system1->Write(ad,(int)(res),0xFFFFFFFF);
			system1->Write(ad+4,(int)((res)>>32),0xFFFFFFFF);
			pc = pc + 4;
			break;

		case BRA:	Rt = 0; pc = pc + ((sir >> 7) << 2); break;
		case BSR:	Rt = 0; regs[31] = pc + 4; pc = pc + ((sir >> 7) << 2); break;
		case RTL:   
			BuildConstant();
			Rt = 0;
			pc = (unsigned int)regs[31];
			regs[30] = regs[30] + imm;
			break;
		case RTS:
			BuildConstant();
			Rt = 0;
			a = system1->Read((unsigned int)regs[30]);
			regs[31] = a;
			pc = a;
			regs[30] = regs[30] + imm;
			break;
		case JALI:
			BuildConstant();
			ad = a + imm;
			res = pc + 4;
			pc = system1->Read(ad);
			break;
		case JAL:
			BuildConstant();
			ad = a + (imm << 2);
			res = pc + 4;
			pc = ad;
			break;
		case BRK:
			switch((ir >> 30)&3) {
			case 0:	
				epc = pc|km;
				esp = regs[30];
				break;
			case 1:
				dpc = pc|km;
				dsp = regs[30];
				break;
			case 2:
				ipc = (pc - immcnt * 4)|km;
				isp = regs[30];
				StatusHWI = true;
				break;
			}
			km = true;
			rvecno = (ir >> 17) & 0x1ff;
			ad = vbr + (((ir >> 17) & 0x1ff) << 3);
			pc = system1->Read(ad);
			break;
		case Bcc:
			Rt = 0;
			switch((ir >> 12) & 7) {
			case BEQ:
				if (a==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BNE:
				if (a!=0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLT:
				if (a & 0x8000000000000000LL)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BLE:
				if ((a & 0x8000000000000000LL) || (a==0))
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGE:
				if ((a & 0x8000000000000000LL)==0)
					pc = pc + ((sir >> 17) << 2);
				else
					pc= pc + 4;
				break;
			case BGT:
				if (((a & 0x8000000000000000LL)==0) && (a!=0))
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
			if (Rt==32 && (res & 3))
				regs[Rt] = res;
			regs[Rt] = res;
		}
		if (opcode != IMM)
			immcnt = 0;
		regs[0] = 0;
	};
