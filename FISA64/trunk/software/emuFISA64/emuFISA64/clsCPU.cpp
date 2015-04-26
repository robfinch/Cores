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
			imm1 = (((xir >> 7) << 18) | ((xir & 7) << 15) | (ir >> 17));
			imm2 = ((xir >> 7) >> 14);
			imm2 = imm2 | ((wir >> 7) << 14) | ((wir & 7) << 11);
		}
		else if (immcnt==1) {
			imm1 = (((xir >> 7) << 18) | ((xir & 7) << 15) | (ir >> 17));
			imm2 = ((xir >> 7) >> 14);
			imm2 = imm2 | (xir&0x80000000 ? 0xFFFFF800 : 0x00000000);
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
		unsigned int irx, iry;
		int nn;
		int sc;
		__int64 imm4,imm9;
		if (imcd > 0) {
			imcd--;
			if (imcd==1)
				im = 0;
		}
		tick = tick + 1;
		//---------------------------------------------------------------------------
		// Instruction Fetch stage
		//---------------------------------------------------------------------------
		wir = xir;
		xir = ir;
		if (nmi && !StatusHWI)
			sir = ir = 0x38 + (0x1E << 7) + (510 << 17) + 0x80000000L;
		else if (irq && ~im && !StatusHWI)
			sir = ir = 0x38 + (0x1E << 7) + (vecno << 17) + 0x80000000L;
		else {
			// Read the pc in two characters as the address may be character aligned.
			irx = system1->Read(pc);
			irx = (irx >> ((pc & 3)<<3)) & 0xFFFF;
			iry = system1->Read(pc+2);
			iry = (iry >> (((pc+2) & 3)<<3)) & 0xFFFF;
			sir = ir = (iry << 16) | irx;
//			sir = ir = system1->Read(pc);
		}
		for (nn = 39; nn >= 0; nn--)
			pcs[nn] = pcs[nn-1];
		pcs[0] = pc;
		imm4 = (ir >> 12) & 15;
		imm9 = ((ir >> 7) & 0x1ff) << 3;	// For RTS2
		if (imm4 & 0x8)
			imm4 |= 0xFFFFFFFFFFFFFFF0LL;
dc:
		//---------------------------------------------------------------------------
		// Decode stage
		//---------------------------------------------------------------------------
		opcode = ir & 0x7F;
		func = ir >> 25;
		Ra = (ir >> 7) & 0x1f;
		Rb = (ir >> 17) & 0x1F;
		Rt = (ir >> 12) & 0x1f;
		Rc = (ir >> 12) & 0x1f;
		Bn = (ir >> 17) & 0x3f;
		spr = (ir >> 17) & 0xff;
		sc = (ir >> 22) & 3;
		mb = (ir >> 17) & 0x3f;
		me = (ir >> 23) & 0x3f;

		if ((opcode==RR && (func >= 0x60 && func< 0x70)) || opcode==PUSHF || opcode==FADD || opcode==FSUB||opcode==FCMP || opcode==FMUL || opcode==FDIV)
			opera.ad = dregs[Ra];
		else
			a = opera.ai = regs[Ra];
		if ((opcode==RR && (func >= 0x60 && func< 0x70)) || opcode==FADD || opcode==FSUB||opcode==FCMP || opcode==FMUL || opcode==FDIV)
			operb.ad = dregs[Rb];
		else
			b = operb.ai = regs[Rb];
		if ((opcode==RR && (func >= 0x60 && func< 0x70)) || opcode==SFD || opcode==SFDX)
			operc.ad = dregs[Rc];
		else
			c = operc.ai = regs[Rc];
		if ((opcode==RR && (func >= 0x60 && func< 0x70)) ||
			opcode==POPF ||
			opcode==LFD || opcode==LFDX ||
			opcode==FADD || opcode==FSUB|| opcode==FMUL || opcode==FDIV || opcode==LDFI)
			Rt |= 32;
		ua = opera.ai;
		ub = b;
		res = 0;
		opcode = ir & 0x7f;
		if (((opcode >> 3)==6) || (opcode==MOV2) || (opcode==MOV2+1) || (opcode==ADDQ))
			pc = pc + 2;
		else
			pc = pc + 4;
		//---------------------------------------------------------------------------
		// Execute stage
		//---------------------------------------------------------------------------
		switch(opcode) {
		case RR:
			switch(ir >> 25) {
			case CPUID:	// for now cpuid return 0
				res = 0;
				break;
			case PCTRL:
				Rt = 0;
				switch((ir >> 17) & 0x1f) {
				case SEI:  im = true; pc = pc + 4; break;
				case CLI:  im = false; pc = pc + 4; break;
				case WAI:	if (irq || nmi) pc = pc + 4; break;
				case RTI:
					km = ipc & 1;
					pc = ipc & -2;
					regs[30] = isp;
					StatusHWI = false;
					imcd = 4;
					break;
				case RTD:
					km = dpc & 1;
					pc = dpc & -2;
					regs[30] = dsp;
					break;
				case RTE:
					km = epc & 1;
					pc = epc & -2;
					regs[30] = esp;
					break;
				default: ;
				}
				break;
			case MTSPR:
				Rt = 0;
				switch(spr) {
				case 0: cr0 = a; break;
				case 7: dpc = (unsigned int)a; break;
				case 8: ipc = (unsigned int)a; break;
				case 9: epc = (unsigned int)a; break;
				case 10: vbr = (unsigned int)a; break;
				case 15: isp = (unsigned int)a; break;
				case 16: dsp = (unsigned int)a; break;
				case 17: esp = (unsigned int)a; break;
				case 50: dbad0 = (unsigned int)a; break;
				case 51: dbad1 = (unsigned int)a; break;
				case 52: dbad2 = (unsigned int)a; break;
				case 53: dbad3 = (unsigned int)a; break;
				case 54: dbctrl = a; break;
				case 55: dbstat = a; break;
				default: ;
				}
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
				break;
			case SXB:
				res = (a & 0xff) | ((a & 0x80) ? 0xFFFFFFFFFFFFFF00LL : 0x0);
				break;
			case SXC:
				res = (a & 0xFFFF) | ((a & 0x8000) ? 0xFFFFFFFFFFFF0000LL : 0x0);
				break;
			case SXH:
				res = (a & 0xFFFFFFFF) | ((a & 0x80000000) ? 0xFFFFFFFF00000000LL : 0x0);
				break;
			case ADD:
			case ADDU:
				res = a + b;
				break;
			case SUB:
			case SUBU:
				res = a - b;
				break;
			case CMP:
				if (a < b)
					res = -1LL;
				else if (a == b)
					res=0LL;
				else
					res=1LL;
				break;
			case CMPU:
				if (ua < ub)
					res = -1LL;
				else if (ua == ub)
					res=0LL;
				else
					res=1LL;
				break;
			case MUL:
				res = a * b;
				break;
			case MULU:
				res = ua * ub;
				break;
			case DIV:
				res = a / b;
				break;
			case DIVU:
				res = ua / ub;
				break;
			case MOD:
				res = a % b;
				break;
			case MODU:
				res = ua % ub;
				break;
			case AND:
				res = a & b;
				break;
			case OR:
				res = a | b;
				break;
			case EOR:
				res = a ^ b;
				break;
			case NOT:
				res = !a;
				break;
			case NAND:
				res = ~(a & b);
				break;
			case NOR:
				res = ~(a | b);
				break;
			case ENOR:
				res = ~(a ^ b);
				break;
			case FMOV:
				dres.ad = opera.ad;
				break;
			case FNEG:
				dres.ad = -opera.ad;
				break;
			case FABS:
				dres.ai = opera.ai & 0x7FFFFFFFFFFFFFFFLL;
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
				break;
			case ASL:
				res = a << (b & 0x3f);
				break;
			case LSR:
				res = ua >> (b & 0x3f);
				break;
			case ROL:
				res = (a << (b & 0x3f)) | (a >> ((64-b)&0x3f));
				break;
			case ROR:
				res = (a >> (b & 0x3f)) | (a << ((64-b)&0x3f));
				break;
			case ASR:
				res = a >> (b & 0x3f);
				break;
			case ASLI:
				res = a << (Bn & 0x3f);
				break;
			case LSRI:
				res = ua >> (Bn & 0x3f);
				break;
			case ROLI:
				res = (ua << (Bn & 0x3f)) | (ua >> ((64-Bn)&0x3f));
				break;
			case RORI:
				res = (ua >> (Bn & 0x3f)) | (ua << ((64-Bn)&0x3f));
				break;
			case ASRI:
				res = a >> (Bn & 0x3f);
				break;
			default: ;
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
				if ((res & ((bmask + 1) >> 1)) != 0) res |= ~bmask;
				break;
			case BFEXTU:
				res = (a >> mb) & bmask;
				break;
			}
			break;
		case MOV2:
		case MOV2+1:
			Rt = ((ir >> 12) & 0xf) | ((ir & 1) << 4);
			res = a;
			break;
		case ADDQ:
			Rt = (ir >> 7) & 0x1f;
			res = a + ((ir >> 12) & 0xF);
			break;
		case LDI:
			BuildConstant();
			res = imm;
			break;
		case LDFI:
			BuildConstant();
			dres.ai = imm;
			break;
		case LDIQ:
			Rt = (ir >> 7) & 0x1f;
			res = (ir >> 12) & 0xF;
			if (ir & 0x8000)
				res |= 0xFFFFFFFFFFFFFFF0LL;
			break;
		case ADD:
		case ADDU:
			BuildConstant();
			res = a + imm;
			break;
		case SUB:
		case SUBU:
			BuildConstant();
			res = a - imm;
			break;
		case CMP:
			BuildConstant();
			if (a < imm)
				res = -1LL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			break;
		case CMPU:
			BuildConstant();
			if (ua < (unsigned __int64)imm)
				res = 0xFFFFFFFFFFFFFFFFLL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			break;
		case CHKI:
			BuildConstant();
			Rt = 0;
			r1 = a >= c;
			r2 = a < imm;
			res = r1 && r2;
			if (!res) {
				ir = 0x03cc0f38;
				goto dc;
			}
			break;
		case MUL:
			BuildConstant();
			res = a * imm;
			break;
		case MULU:
			BuildConstant();
			res = ua * (unsigned __int64)imm;
			break;
		case DIV:
			BuildConstant();
			res = a / imm;
			break;
		case DIVU:
			BuildConstant();
			res = ua / (unsigned __int64)imm;
			break;
		case MOD:
			BuildConstant();
			res = a % imm;
			break;
		case MODU:
			BuildConstant();
			res = ua % (unsigned __int64)imm;
			break;
		case AND:
			BuildConstant();
			res = a & imm;
			break;
		case OR:
			BuildConstant();
			res = a | imm;
			break;
		case EOR:
			BuildConstant();
			res = a ^ imm;
			break;
		case FADD:
			dres.ad = opera.ad + operb.ad;
			break;
		case FSUB:
			dres.ad = opera.ad - operb.ad;
			break;
		case FCMP:
			if (opera.ad < operb.ad)
				res = -1;
			else if (opera.ad==operb.ad)
				res = 0;
			else
				res = 1;
			break;
		case FMUL:
			dres.ad = opera.ad * operb.ad;
			break;
		case FDIV:
			dres.ad = opera.ad / operb.ad;
			break;
		case LB:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			break;
		case LBU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			break;
		case LBX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			break;
		case LBUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			break;
		case LC:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			break;
		case LCU:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res = (res >> ((ad & 3)<<3)) & 0xFFFF;
			break;
		case LCX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			break;
		case LCUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			break;
		case LH:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			break;
		case LHU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			break;
		case LHX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			break;
		case LHUX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			break;
		case LW:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			break;
		case LFD:
			BuildConstant();
			ad = a + imm;
			dres.ai = system1->Read(ad);
			dres.ai |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			break;
		case LWAR:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad,1);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			break;
		case LWX:
		case LFDX:
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
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
			break;
		case LEA:
			BuildConstant();
			res = a + imm;
			break;
		case LEAX:
			imm = (ir >> 24);
			res = a + (b << sc) + imm;
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
			break;
		case SH:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			break;
		case SHX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			break;
		case SW:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			break;
		case SFD:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)operc.ai,0xFFFFFFFF);
			system1->Write(ad+4,(int)(operc.ai>>32),0xFFFFFFFF);
			break;
		case SWCR:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			nn = system1->Write(ad,(int)regs[Rc],0xFFFFFFFF,1);
			cr0 &= 0xFFFFFFEFFFFFFFFFLL;
			if (nn) cr0 |= 0x1000000000LL;
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF,0);
			break;
		case SWX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1->Write(ad,(int)regs[Rc],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Rc]>>32),0xFFFFFFFF);
			break;
		case SFDX:
			Rt = 0;
			imm = (ir >> 24);
			ad = a + (b << sc) + imm;
			system1->Write(ad,(int)operc.ai,0xFFFFFFFF);
			system1->Write(ad+4,(int)(operc.ai>>32),0xFFFFFFFF);
			break;
		case POP:
			BuildConstant();
			ad = (unsigned int)regs[30];
			regs[30] += 8LL;
			res = system1->Read(ad,0);
			res |= ((unsigned __int64)system1->Read(ad+4,0)) << 32;
			break;
		case POPF:
			BuildConstant();
			ad = (unsigned int)regs[30];
			regs[30] += 8LL;
			dres.ai = system1->Read(ad,0);
			dres.ai |= ((unsigned __int64)system1->Read(ad+4,0)) << 32;
			break;
		case PUSHPOP:
			switch((ir>>12)&15) {
			case 0:
				regs[30] -= 8LL;
				Rt = 0;
				ad = regs[30];
				system1->Write(ad,(int)regs[Ra],0xFFFFFFFF);
				system1->Write(ad+4,(int)(regs[Ra]>>32),0xFFFFFFFF);
				break;
			case 1:
				regs[30] -= 8LL;
				Rt = 0;
				ad = regs[30];
				system1->Write(ad,(int)opera.ai,0xFFFFFFFF);
				system1->Write(ad+4,(int)(opera.ai>>32),0xFFFFFFFF);
				break;
			case 2:
				Rt = (ir >> 7) & 0x1f;
				ad = (unsigned int)regs[30];
				regs[30] += 8LL;
				res = system1->Read(ad,0);
				res |= ((unsigned __int64)system1->Read(ad+4,0)) << 32;
				break;
			case 3:
				Rt = ((ir >> 7) & 0x1f) | 32;
				ad = (unsigned int)regs[30];
				regs[30] += 8LL;
				dres.ai = system1->Read(ad,0);
				dres.ai |= ((unsigned __int64)system1->Read(ad+4,0)) << 32;
				break;
			}
			break;
		case PUSH:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1->Write(ad,(int)regs[Ra],0xFFFFFFFF);
			system1->Write(ad+4,(int)(regs[Ra]>>32),0xFFFFFFFF);
			break;
		case PUSHF:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1->Write(ad,(int)opera.ai,0xFFFFFFFF);
			system1->Write(ad+4,(int)(opera.ai>>32),0xFFFFFFFF);
			break;
		case PEA:
			BuildConstant();
			regs[30] -= 8LL;
			Rt = 0;
			ad = regs[30];
			system1->Write(ad,(int)(a+imm),0xFFFFFFFF);
			system1->Write(ad+4,(int)((a+imm)>>32),0xFFFFFFFF);
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
			break;

		case BRA:	Rt = 0; pc = pc - 4 + ((sir >> 7) << 1); break;
		case BSR:	Rt = 0; regs[31] = pc; pc = pc - 4 + ((sir >> 7) << 1); break;
		case RTL:   
			BuildConstant();
			Rt = 0;
			pc = (unsigned int)regs[31];
			regs[30] = regs[30] + imm;
			break;
		case RTL2:   
			Rt = 0;
			pc = (unsigned int)regs[31];
			regs[30] = regs[30] + imm9;
			break;
		case RTS:
			BuildConstant();
			Rt = 31;
			a = system1->Read((unsigned int)regs[30],0);
			res = a;
			pc = a;
			regs[30] = regs[30] + imm;
			break;
		case RTS2:
			Rt = 31;
			a = system1->Read((unsigned int)regs[30],0);
			res = a;
			pc = a;
			regs[30] = regs[30] + imm9;
			break;
		case JALI:
			BuildConstant();
			ad = a + imm;
			res = pc + 4;
			pc = system1->Read(ad);
			break;
		case JAL:
			BuildConstant();
			ad = a + (imm << 1);
			res = pc + 4;
			pc = ad;
			break;
		case BRK:
			switch((ir >> 30)&3) {
			case 0:	
				epc = (pc-4)|km;
				esp = regs[30];
				break;
			case 1:
				dpc = (pc-4)|km;
				dsp = regs[30];
				break;
			case 2:
				ipc = (pc - 4 - immcnt * 4)|km;
				isp = regs[30];
				StatusHWI = true;
				im = true;
				break;
			}
			km = true;
			rvecno = (ir >> 17) & 0x1ff;
			ad = vbr + (((ir >> 17) & 0x1ff) << 3);
			pc = system1->Read(ad);
			break;
		case BEQS:
			Rt = 0;
			if (a==0)
				pc = pc - 2 + (imm4 << 1);
			break;
		case BNES:
			Rt = 0;
			if (a!=0)
				pc = pc - 2 + (imm4 << 1);
			break;
		case Bcc:
			Rt = 0;
			switch((ir >> 12) & 7) {
			case BEQ:
				if (a==0)
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			case BNE:
				if (a!=0)
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			case BLT:
				if (a & 0x8000000000000000LL)
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			case BLE:
				if ((a & 0x8000000000000000LL) || (a==0))
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			case BGE:
				if ((a & 0x8000000000000000LL)==0)
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			case BGT:
				if (((a & 0x8000000000000000LL)==0) && (a!=0))
					pc = pc - 4 + ((sir >> 17) << 1);
				break;
			default:
				break;
			}
			break;
		case NOP:	Rt = 0; immcnt = 0; break;
		case IMM:
		case IMM+1:
		case IMM+2:
		case IMM+3:
		case IMM+4:
		case IMM+5:
		case IMM+6:
		case IMM+7:
			Rt = 0;
			immcnt = immcnt + 1;
			break;
		default: break;
		}
		//---------------------------------------------------------------------------
		// Writeback stage
		//---------------------------------------------------------------------------
		if (Rt != 0) {
			if (Rt & 32) {
				dregs[Rt&31] = dres.ad;
			}
			else {
				if (Rt==32 && (res & 3))
					regs[Rt] = res;
				regs[Rt] = res;
			}
		}
		if (opcode != IMM &&
			opcode!=IMM+1 &&
			opcode!=IMM+2 &&
			opcode!=IMM+3 &&
			opcode!=IMM+4 &&
			opcode!=IMM+5 &&
			opcode!=IMM+6 &&
			opcode!=IMM+7
			)
			immcnt = 0;
		regs[0] = 0;
	};
