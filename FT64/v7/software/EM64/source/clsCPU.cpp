#include "stdafx.h"
#include <stdio.h>

void clsCPU::Reset()
	{
		int nn;
		km = true;
		brk = 0;
		im = true;
		irq = false;
		nmi = false;
		StatusHWI = false;
		isRunning = false;
		for (nn = 0; nn < 64; nn++)
			regs[0][nn] = 0;
		rgs = 8;
		pc = 0xFFFC0100;
		vbr = 0;
		tick = 0;
		rvecno = 0;
		regLR = 29;
	};
	void clsCPU::BuildConstant() {
		sir = ir;
		imm1 = (sir >> 16);
		imm2 = (sir&0x80000000) ? 0xFFFFFFFF : 0x00000000;
		imm = ((__int64)imm2 << 32) | imm1;
	};
	void clsCPU::Step()
	{
		unsigned int ad, opc;
		unsigned __int64 irx, iry, irz;
		int nn;
		int sc;
		int ir21;
		int brdisp;
		int broffs;
		__int64 imm4,imm9,imm9bra;
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
			// Read the pc in three characters as the address may be character aligned.
			irx = system1->Read(pc);
			irx = (irx >> ((pc & 3LL)<<3LL)) & 0xFFFFLL;
			iry = system1->Read(pc+2);
			iry = (iry >> (((pc+2LL) & 3LL)<<3LL)) & 0xFFFFLL;
			irz = system1->Read(pc + 4);
			irz = (irz >> (((pc + 4LL) & 3LL) << 3LL)) & 0xFFFFLL;
			sir = ir = (irz << 32LL) | (iry << 16LL) | irx;
//			sir = ir = system1->Read(pc);
		}
		ir21 = (ir >> 21) & 0x1F;
		if (ir21 & 0x10)
			ir21 |= 0xFFFFFFE0L;
		if (pc != pcs[0]) {
			for (nn = 39; nn >= 0; nn--)
				pcs[nn] = pcs[nn-1];
			pcs[0] = pc;
		}
		imm4 = (ir >> 12) & 15;
		imm9 = ((ir >> 7) & 0x1ff) << 3;	// For RTS2
		if (imm4 & 0x8)
			imm4 |= 0xFFFFFFFFFFFFFFF0LL;
		imm9bra = ((ir >> 7) & 0x1ff) ;	// For BRAS
		if (imm9bra & 0x100)
			imm9bra |= 0xFFFFFFFFFFFFFF00LL;
		brdisp = (ir >> 28) & 0xf;
		broffs = (((ir >> 23) & 0x1f) << 3) | (((ir >> 16) & 3) << 1);
dc:
		//---------------------------------------------------------------------------
		// Decode stage
		//---------------------------------------------------------------------------
		if (((ir >> 7) & 1) == 1)
			ir = DecompressInstruction(ir);
		opcode = ir & 0x3F;
		func = ir >> 26;
		Ra = (ir >> 8) & 0x1f;
		Rt = (ir >> 13) & 0x1f;
		Rb = (ir >> 18) & 0x1F;
		Rc = (ir >> 23) & 0x1f;
		if (opcode==ICALL)
			Rt = regLR;
		Bn = (ir >> 16) & 0x3f;
		sc = (ir >> 21) & 3;
		mb = (ir >> 16) & 0x3f;
		me = (ir >> 22) & 0x3f;

		a = opera.ai = regs[Ra][rgs];
		b = operb.ai = regs[Rb][rgs];
		c = operc.ai = regs[Rc][rgs];
		ua = a;
		ub = b;
		res = 0;
		opcode = ir & 0x3f;
		opc = pc;
		pc = pc + 4;

		//---------------------------------------------------------------------------
		// Execute stage
		//---------------------------------------------------------------------------
		switch(opcode) {
		case IRR:
			switch(ir >> 26) {
			case ISEI:  im = a|imm; break;
			case IRTI:
				km = ipc & 1;
				pc = ipc & -2;
				regs[30][rgs] = isp;
				StatusHWI = false;
				imcd = 4;
				break;
			case IWAIT:	if (irq || nmi) break;
			case IADD:
				res = a + b;
				break;
			case ISUB:
				res = a - b;
				break;
			case ICMP:
				switch((ir >> 23) & 7) {
				case 0:
					if (a < b)
						res = -1LL;
					else if (a == b)
						res=0LL;
					else
						res=1LL;
					break;
				case 2: res = a==b ? 1 : 0; break;
				case 3:	res = a!=b ? 1 : 0; break;
				case 4: res = a < b ? 1 : 0; break;
				case 5:	res = a >= b ? 1 : 0; break;
				case 6:	res = a <= b ? 1 : 0; break;
				case 7:	res = a > b ? 1 : 0; break;
				}
				break;
			case ICMPU:
				switch((ir >> 23) & 7) {
				case 0:
					if (ua < ub)
						res = -1LL;
					else if (ua == ub)
						res=0LL;
					else
						res=1LL;
					break;
				case 4: res = ua < ub ? 1 : 0; break;
				case 5:	res = ua >= ub ? 1 : 0; break;
				case 6:	res = ua <= ub ? 1 : 0; break;
				case 7:	res = ua > ub ? 1 : 0; break;
				}
				break;
			// ToDo: return high order 64 bits of product
			case IMUL:
				res = a * b;
				break;
			case IMULSU:
				res = a * ub;
				break;
			case IMULU:
				res = ua * ub;
				break;
			case IDIVMOD:
				if (((ir >> 24) & 3)==1)
					res = a % b;
				else
					res = a / b;
				break;
			case IDIVMODU:
				if (((ir >> 24) & 3)==1)
					res = ua % ub;
				else
					res = ua / ub;
				break;
			case IDIVMODSU:
				if (((ir >> 24) & 3)==1)
					res = a % ub;
				else
					res = a / ub;
				break;
			case IAND:
				res = a & b;
				break;
			case IOR:
				res = a | b;
				break;
			case IXOR:
				res = a ^ b;
				break;
			case INAND:
				res = ~(a & b);
				break;
			case INOR:
				res = ~(a | b);
				break;
			case IXNOR:
				res = ~(a ^ b);
				break;
			case ILBX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
				if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
				break;
			case ILBUX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
				break;
			case ILCX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
				if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
				break;
			case ILCUX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
				break;
			case ILHX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3));
				if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
				break;
			case ILHUX:
				ad = a + (b << sc);
				res = (system1->Read(ad) >> ((ad & 3)<<3));
				res &= 0x00000000FFFFFFFFLL;
				break;
			case ILWX:
				ad = a + (b << sc);
				res = system1->Read(ad);
				res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
				break;
			case ISBX:
				Rt = 0;
				ad = a + (b << sc);
				switch(ad & 7) {
				case 0:
					system1->Write(ad,(int)c,0x1);
					break;
				case 1:
					system1->Write(ad,(int)c,0x2);
					break;
				case 2:
					system1->Write(ad,(int)c,0x4);
					break;
				case 3:
					system1->Write(ad,(int)c,0x8);
					break;
				case 4:
					system1->Write(ad,(int)c,0x1);
					break;
				case 5:
					system1->Write(ad,(int)c,0x2);
					break;
				case 6:
					system1->Write(ad,(int)c,0x4);
					break;
				case 7:
					system1->Write(ad,(int)c,0x8);
					break;
				}
				break;
			case ISCX:
				Rt = 0;
				ad = a + (b << sc);
				switch(ad & 7) {
				case 0:
					system1->Write(ad,(int)c,0x3);
					break;
				case 1:
					system1->Write(ad,(int)c,0x6);
					break;
				case 2:
					system1->Write(ad,(int)c,0xC);
					break;
				case 3:
					system1->Write(ad,(int)c,0x8);
					break;
				case 4:
					system1->Write(ad,(int)c,0x3);
					break;
				case 5:
					system1->Write(ad,(int)c,0x6);
					break;
				case 6:
					system1->Write(ad,(int)c,0xC);
					break;
				case 7:
					system1->Write(ad,(int)c,0x8);
					break;
				}
				break;
			case IMOV:
				{
					int d3 = (ir >> 23) & 7;
					int rgs1 = (ir >> 16) & 0x3f;
					switch(d3) {
					case 0:
						regs[Rt][rgs1] = regs[Ra][rgs];
						res = regs[Ra][rgs];
						Rt = 0;
						break;
					case 1:
						res = regs[Ra][rgs1];
						break;
					case 7:
						res = regs[Ra][rgs];
						break;
					}
				}
				break;
			case ISHX:
				Rt = 0;
				ad = a + (b << sc);
				system1->Write(ad,(int)c,0xF);
				break;
			case ISWX:
				Rt = 0;
				ad = a + (b << sc);
				system1->Write(ad,(int)c,0xF);
				system1->Write(ad+4,(int)(c>>32),0xF);
				break;
			case ISHIFT:
				switch((ir >> 22) & 0xF) {
				case ISHL:
					res = ua << (b & 0x3f);
					break;
				case ISHR:
					res = ua >> (b & 0x3f);
					break;
				case IASL:
					res = a << (b & 0x3f);
					break;
				case IASR:
					res = a >> (b & 0x3f);
					break;
				case IROL:
					res = (a << (b & 0x3f)) | (a >> ((64-b)&0x3f));
					break;
				case IROR:
					res = (a >> (b & 0x3f)) | (a << ((64-b)&0x3f));
					break;
				case ISHLI:
					res = ua << (Bn & 0x3f);
					break;
				case ISHRI:
					res = ua >> (Bn & 0x3f);
					break;
				case IASLI:
					res = a << (Bn & 0x3f);
					break;
				case IASRI:
					res = a >> (Bn & 0x3f);
					break;
				case IROLI:
					res = (ua << (Bn & 0x3f)) | (ua >> ((64-Bn)&0x3f));
					break;
				case IRORI:
					res = (ua >> (Bn & 0x3f)) | (ua << ((64-Bn)&0x3f));
					break;
				default: ;
				}
				break;
			}
			break;
		case ICHK:
			Rt = 0;
			r1 = a >= b;
			r2 = a < c;
			res = r1 && r2;
			if (!res) {
				ir = 0x03cc0f38;
				goto dc;
			}
			break;
		case IBTFLD:
			bmask = 0;
			for (nn = 0; nn < me-mb+1; nn ++) {
				bmask = (bmask << 1) | 1;
			}
			switch((ir >> 28) & 15) {
			case IBFSET:
				bmask <<= mb;
				res = a | bmask << mb;
				break;
			case IBFCLR:
				bmask <<= mb;
				res = a & ~(bmask << mb);
				break;
			case IBFCHG:
				bmask <<= mb;
				res = a ^ (bmask << mb);
				break;
			case IBFINS:
				bmask <<= mb;
				c &= ~(bmask << mb);
				res = c | ((a & bmask) << mb);
				break;
			case IBFINSI:
				bmask <<= mb;
				c &= ~(bmask << mb);
				res = c | ((Ra & bmask) << mb);
				break;
			case IBFEXT:
				res = (a >> mb) & bmask;
				if ((res & ((bmask + 1) >> 1)) != 0) res |= ~bmask;
				break;
			case IBFEXTU:
				res = (a >> mb) & bmask;
				break;
			}
			break;
		case IADD:
			BuildConstant();
			res = a + imm;
			break;
		case ISUB:
			BuildConstant();
			res = a - imm;
			break;
		case ICMP:
			BuildConstant();
			if (a < imm)
				res = -1LL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			break;
		case ICMPU:
			BuildConstant();
			if (ua < imm)
				res = 0xFFFFFFFFFFFFFFFFLL;
			else if (a==imm)
				res = 0LL;
			else
				res = 1LL;
			break;
		case IMUL:
			BuildConstant();
			res = a * imm;
			break;
		case IMULU:
			BuildConstant();
			res = ua * imm;
			break;
		case IMULSU:
			BuildConstant();
			res = a * imm;
			break;
		case IDIVI:
			BuildConstant();
			res = a / imm;
			break;
		case IDIVUI:
			BuildConstant();
			res = ua / imm;
			break;
		case IDIVSUI:
			BuildConstant();
			res = a / imm;
			break;
		case IMODI:
			BuildConstant();
			res = a % imm;
			break;
		case IMODUI:
			BuildConstant();
			res = ua % imm;
			break;
		case IMODSUI:
			BuildConstant();
			res = a % imm;
			break;
		case IAND:
			BuildConstant();
			res = a & imm;
			break;
		case IOR:
			BuildConstant();
			res = a | imm;
			break;
		case IXOR:
			BuildConstant();
			res = a ^ imm;
			break;
		case IQOPI:
			switch((ir >> 8) & 7) {
			case IQOR:
				switch((ir >> 6) & 3) {
				case 0:	res = b | (ir >> 16); break;
				case 1: res = b | (ir & 0xffff0000); break;
				case 2: res = b | (__int64)(ir & 0xffff0000) << 16; break;
				case 3:	res = b | (__int64)(ir & 0xffff0000) << 32; break;
				}
				break;
			}
			break;
		case IFLOAT:
			switch(ir >> 26) {
			case IFADD:
				dres.ad = opera.ad + operb.ad;
				break;
			case IFSUB:
				dres.ad = opera.ad - operb.ad;
				break;
			case IFCMP:
				if (opera.ad < operb.ad)
					res = -1;
				else if (opera.ad==operb.ad)
					res = 0;
				else
					res = 1;
				break;
			case IFMUL:
				dres.ad = opera.ad * operb.ad;
				break;
			case IFDIV:
				dres.ad = opera.ad / operb.ad;
				break;
			case IFMOV:
				dres.ad = opera.ad;
				break;
			case IFNEG:
				dres.ad = -opera.ad;
				break;
			case IFABS:
				dres.ai = opera.ai & 0x7FFFFFFFFFFFFFFFLL;
				break;
			}
			break;
		case ILB:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			if (res & 0x80) res |= 0xFFFFFFFFFFFFFF00LL;
			break;
		case ILBU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFF;
			break;
		case ILC:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3)) & 0xFFFF;
			if (res & 0x8000) res |= 0xFFFFFFFFFFFF0000LL;
			break;
		case ILCU:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res = (res >> ((ad & 3)<<3)) & 0xFFFF;
			break;
		case ILH:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			if (res & 0x80000000LL) res |= 0xFFFFFFFF00000000LL;
			break;
		case ILHU:
			BuildConstant();
			ad = a + imm;
			res = (system1->Read(ad) >> ((ad & 3)<<3));
			res &= 0x00000000FFFFFFFFLL;
			break;
		case ILW:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			break;
		case ILWR:
			BuildConstant();
			ad = a + imm;
			res = system1->Read(ad,1);
			res |= ((unsigned __int64)system1->Read(ad+4)) << 32;
			break;
		case ISB:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1->Write(ad,(int)b,0x1);
				break;
			case 1:
				system1->Write(ad,(int)b,0x2);
				break;
			case 2:
				system1->Write(ad,(int)b,0x4);
				break;
			case 3:
				system1->Write(ad,(int)b,0x8);
				break;
			case 4:
				system1->Write(ad,(int)b,0x1);
				break;
			case 5:
				system1->Write(ad,(int)b,0x2);
				break;
			case 6:
				system1->Write(ad,(int)b,0x4);
				break;
			case 7:
				system1->Write(ad,(int)b,0x8);
				break;
			}
			break;
		case ISC:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			switch(ad & 7) {
			case 0:
				system1->Write(ad,(int)b,0x3);
				break;
			case 1:
				system1->Write(ad,(int)b,0x6);
				break;
			case 2:
				system1->Write(ad,(int)b,0xC);
				break;
			case 3:
				system1->Write(ad,(int)b,0x8);
				break;
			case 4:
				system1->Write(ad,(int)b,0x3);
				break;
			case 5:
				system1->Write(ad,(int)b,0x6);
				break;
			case 6:
				system1->Write(ad,(int)b,0xC);
				break;
			case 7:
				system1->Write(ad,(int)b,0x8);
				break;
			}
			break;
		case ISH:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)b,0xF);
			break;
		case ISW:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			system1->Write(ad,(int)b,0xF);
			system1->Write(ad+4,(int)(b>>32),0xF);
			break;
		case ISWC:
			Rt = 0;
			BuildConstant();
			ad = a + imm;
			nn = system1->Write(ad,(int)b,0xF,1);
			cr0 &= 0xFFFFFFEFFFFFFFFFLL;
			if (nn) cr0 |= 0x1000000000LL;
			system1->Write(ad+4,(int)(b>>32),0xF,0);
			break;
		case ICALL:
			Rt = regLR;
			res = pc;
			regs[regLR][rgs] = pc;
			pc = ((ir >> 6) << 2) | (pc & 0xf0000000);
			break;
		case IRET:
			BuildConstant();
			pc = b;
			res = a + imm;
			regs[Ra][rgs] = a + imm;
			break;
		case IJMP:
			pc = ((ir >> 6) << 2) | (pc & 0xf0000000);
			break;
		case IJAL:
			BuildConstant();
			ad = a + imm;
			res = pc;
			pc = ad & -4LL;
			break;
		case IBRK:
			switch((ir >> 30)&3) {
			case 0:	
				epc = opc|km;
				esp = regs[30][rgs];
				break;
			case 1:
				dpc = opc|km;
				dsp = regs[30][rgs];
				break;
			case 2:
				ipc = (immcnt==10) ? (opc-2)|km : (opc - immcnt * 4)|km;
				isp = regs[30][rgs];
				StatusHWI = true;
				im = true;
				break;
			}
			km = true;
			rvecno = (ir >> 17) & 0x1ff;
			ad = vbr + (((ir >> 17) & 0x1ff) << 3);
			pc = system1->Read(ad);
			break;
		// Branch on bit set or clear
		case IBBc0:
		case IBBc1:
			Rt = 0;
			brdisp = (((sir >> 22) << 3) | ((ir & 1) << 2));
			if (((ir >> 17) & 7)==1) {
				if ((a & (1LL << ((ir >> 16) & 0x3f)))==0)
					pc = pc + brdisp;
			}
			else {
				if ((a & (1LL << ((ir >> 16) & 0x3f)))!=0)
					pc = pc + brdisp;
			}
			break;
		case IBcc0:
		case IBcc1:
			Rt = 0;
			brdisp = (((sir >> 22) << 3) | ((ir & 1) << 2));
			switch((ir >> 16) & 7) {
			case IBEQ:
				if (a==b)
					pc = pc + brdisp;
				break;
			case IBNE:
				if (a!=b)
					pc = pc + brdisp;
				break;
			case IBLT:
				if (a < b)
					pc = pc + brdisp;
				break;
			case IBGE:
				if (a >= b)
					pc = pc + brdisp;
				break;
			case IBLTU:
				if (ua < ub)
					pc = pc + brdisp;
				break;
			case IBGEU:
				if (ua <= ub)
					pc = pc + brdisp;
				break;
			default:
				break;
			}
			break;
		case INOP:	Rt = 0; immcnt = 0; break;
		default: break;
		}
		//---------------------------------------------------------------------------
		// Writeback stage
		//---------------------------------------------------------------------------
		if (Rt != 0) {
			if (Rt==31 && res==0xC48EE0) {
				regs[Rt][rgs] <= res;
				printf("hi there");
			}
			regs[Rt][rgs] = res;
		}
		for (nn = 0; nn < 64; nn++)
			regs[0][nn] = 0;
	};

int clsCPU::fnRp(__int64 ir)
{
	switch (ir & 7) {
	case 0: return (1);
	case 1: return (3);
	case 2: return (4);
	case 3: return (11);
	case 4: return (12);
	case 5: return (18);
	case 6: return (19);
	case 7: return (20);
	}
}

__int64 clsCPU::DecompressInstruction(__int64 ir)
{
	__int64 tir;

	tir = 0;
	if (ir & 0x40) {
		switch ((ir >> 12) & 0xF) {
		case 0:	// MOV
			tir |= 0xC2;
			tir |= (ir & 0x1fLL) << 8LL;
			tir |= (((ir & 0x0f00LL) >> 8LL) << 14LL);
			tir |= (((ir & 0x0020LL) >> 5LL) << 13LL);
			tir |= (7 << 23);
			break;
		case 1:	// ADD
			tir |= 0xC2;
			tir |= (ir & 0x1fLL) << 8LL;
			tir |= (ir & 0x1fLL) << 13LL;
			tir |= (((ir & 0x0f00LL) >> 8LL) << 19LL);
			tir |= (((ir & 0x0020LL) >> 5LL) << 18LL);
			tir |= (3 << 23);
			tir |= (IADD << 26);
			break;
		case 2:	// JALR
			tir |= IJAL;
			tir |= (ir & 0x1fLL) << 8;
			tir |= (((ir & 0x0f00LL) >> 8LL) << 14LL);
			tir |= (((ir & 0x0020LL) >> 5LL) << 13LL);
			break;
		case 3:
			tir |= INOP;	// reserved (NOP)
			break;
		case 4:		// LH Rt,d[SP]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (0x31LL << 8LL);
			tir |= (ir & 0x1fLL) << 13LL;
			tir |= (2LL << 18LL);
			tir |= (((ir >> 5LL) & 1LL) << 20LL);
			tir |= (((ir >> 8LL) & 0xFLL) << 21LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 5:		// LW Rt,d[SP]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (0x31LL << 8LL);
			tir |= (ir & 0x1fLL) << 13LL;
			tir |= (4LL << 18LL);
			tir |= (((ir >> 5LL) & 1LL) << 21LL);
			tir |= (((ir >> 8LL) & 0xFLL) << 22LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 6:		// LH Rt,d[FP]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (0x30LL << 8LL);
			tir |= (ir & 0x1fLL) << 13LL;
			tir |= (2LL << 18LL);
			tir |= (((ir >> 5LL) & 1LL) << 20LL);
			tir |= (((ir >> 8LL) & 0xFLL) << 21LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 7:		// LW Rt,d[FP]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (0x30LL << 8LL);
			tir |= (ir & 0x1fLL) << 13LL;
			tir |= (4LL << 18LL);
			tir |= (((ir >> 5LL) & 1LL) << 21LL);
			tir |= (((ir >> 8LL) & 0xFLL) << 22LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 8:		// SH Rb,d[SP]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (31LL << 8LL);
			tir |= (2LL << 13LL);
			tir |= (((ir >> 5LL) & 1LL) << 15LL);
			tir |= (((ir >> 8LL) & 3LL) << 16LL);
			tir |= ((ir & 0x1fLL) << 18LL);
			tir |= (((ir >> 10LL) & 3LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 9:		// SW Rb,d[SP]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (31LL << 8LL);
			tir |= (4LL << 13LL);
			tir |= (((ir >> 5LL) & 1LL) << 16LL);
			tir |= (((ir >> 8LL) & 1LL) << 17LL);
			tir |= ((ir & 0x1fLL) << 18LL);
			tir |= (((ir >> 9LL) & 7LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 10:		// SH Rb,d[FP]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (30LL << 8LL);
			tir |= (2LL << 13LL);
			tir |= (((ir >> 5LL) & 1LL) << 15LL);
			tir |= (((ir >> 8LL) & 3LL) << 16LL);
			tir |= ((ir & 0x1fLL) << 18LL);
			tir |= (((ir >> 10LL) & 3LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 11:		// SW Rb,d[FP]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (30LL << 8LL);
			tir |= (4LL << 13LL);
			tir |= (((ir >> 5LL) & 1LL) << 16LL);
			tir |= (((ir >> 8LL) & 1LL) << 17LL);
			tir |= ((ir & 0x1fLL) << 18LL);
			tir |= (((ir >> 9LL) & 7LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 12:	// LH Rt,d[Ra]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (fnRp(ir & 7LL) << 8LL);
			tir |= (fnRp((((ir >> 8LL) & 0xfLL) << 1LL) | (ir >> 5LL) & 1LL) << 13LL);
			tir |= (2LL << 18LL);
			tir |= (((ir >> 3LL) & 3LL) << 20LL);
			tir |= (((ir >> 10LL) & 3LL) << 22LL);
			tir |= (((ir >> 11LL) & 1LL) << 24LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 13:	// LW Rt,d[Ra]
			tir |= ILx;
			tir |= 0x80LL;
			tir |= (fnRp(ir & 7LL) << 8LL);
			tir |= (fnRp((((ir >> 8LL) & 0xfLL) << 1LL) | (ir >> 5LL) & 1LL) << 13LL);
			tir |= (4LL << 18LL);
			tir |= (((ir >> 3LL) & 3LL) << 21LL);
			tir |= (((ir >> 10LL) & 3LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 14:	// SH Rb,d[Ra]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (fnRp(ir & 7LL) << 8LL);
			tir |= (2LL << 13LL);
			tir |= (((ir >> 3LL) & 3LL) << 15LL);
			tir |= (((ir >> 10LL) & 1LL) << 17LL);
			tir |= (fnRp((((ir >> 8LL) & 0xfLL) << 1LL) | (ir >> 5LL) & 1LL) << 18LL);
			tir |= (((ir >> 11LL) & 1LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 24LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		case 15:	// SW Rb,d[Ra]
			tir |= ISx;
			tir |= 0x80LL;
			tir |= (fnRp(ir & 7LL) << 8LL);
			tir |= (4LL << 13LL);
			tir |= (((ir >> 3LL) & 3LL) << 16LL);
			tir |= (fnRp((((ir >> 8LL) & 0xfLL) << 1LL) | (ir >> 5LL) & 1LL) << 18LL);
			tir |= (((ir >> 10LL) & 1LL) << 23LL);
			tir |= (((ir >> 11LL) & 1LL) << 24LL);
			tir |= (((ir >> 11LL) & 1LL) << 25LL);
			tir |= (((ir >> 11LL) & 1LL) << 26LL);
			tir |= (((ir >> 11LL) & 1LL) << 27LL);
			tir |= (((ir >> 11LL) & 1LL) << 28LL);
			tir |= (((ir >> 11LL) & 1LL) << 29LL);
			tir |= (((ir >> 11LL) & 1LL) << 30LL);
			tir |= (((ir >> 11LL) & 1LL) << 31LL);
			break;
		}
	}
	else {
		switch ((ir >> 12) & 0xF) {
		case 0:	// ADDI
			if ((ir & 0x1fLL) == 0LL)
				tir |= 0x3d;	// NOP
			else if ((ir & 0x1fLL) == 31LL) {	// ADDI SP
				tir |= IADD;
				tir |= 0x80LL;
				tir |= ((ir & 0x1fLL) << 8LL);
				tir |= ((ir & 0x1fLL) << 13LL);
				tir |= (((ir >> 5LL) & 1LL) << 21LL);
				tir |= (((ir >> 8LL) & 0xfLL) << 22LL);
				tir |= (((ir >> 11LL) & 1) << 26LL);
				tir |= (((ir >> 11LL) & 1) << 27LL);
				tir |= (((ir >> 11LL) & 1) << 28LL);
				tir |= (((ir >> 11LL) & 1) << 29LL);
				tir |= (((ir >> 11LL) & 1) << 30LL);
				tir |= (((ir >> 11LL) & 1) << 31LL);
			}
			else {
				tir |= IADD;
				tir |= 0x80LL;
				tir |= ((ir & 0x1fLL) << 8LL);
				tir |= ((ir & 0x1fLL) << 13LL);
				tir |= (((ir >> 5LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xfLL) << 19LL);
				tir |= (((ir >> 11LL) & 1) << 23LL);
				tir |= (((ir >> 11LL) & 1) << 24LL);
				tir |= (((ir >> 11LL) & 1) << 25LL);
				tir |= (((ir >> 11LL) & 1) << 26LL);
				tir |= (((ir >> 11LL) & 1) << 27LL);
				tir |= (((ir >> 11LL) & 1) << 28LL);
				tir |= (((ir >> 11LL) & 1) << 29LL);
				tir |= (((ir >> 11LL) & 1) << 30LL);
				tir |= (((ir >> 11LL) & 1) << 31LL);
			}
			break;
		case 1:
			if ((ir & 0x1fLL) == 0LL) {		// SYS
				tir |= IBRK;
				tir |= 0x80LL;
				tir |= (((ir >> 5LL) & 1LL) << 8LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 9LL);
				tir |= (1LL << 13LL);
				tir |= (1LL << 21LL);
			}
			else {	// LDI
				tir |= IOR;
				tir |= 0x80LL;
				tir |= ((ir & 0x1fLL) << 13LL);
				tir |= (((ir >> 5LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xfLL) << 19LL);
				tir |= (((ir >> 11LL) & 1) << 23LL);
				tir |= (((ir >> 11LL) & 1) << 24LL);
				tir |= (((ir >> 11LL) & 1) << 25LL);
				tir |= (((ir >> 11LL) & 1) << 26LL);
				tir |= (((ir >> 11LL) & 1) << 27LL);
				tir |= (((ir >> 11LL) & 1) << 28LL);
				tir |= (((ir >> 11LL) & 1) << 29LL);
				tir |= (((ir >> 11LL) & 1) << 30LL);
				tir |= (((ir >> 11LL) & 1) << 31LL);
			}
			break;
		case 2:
			if ((ir & 0x1fLL) == 0LL) {		// RET
				tir |= IRET;
				tir |= 0x80LL;
				tir |= (31LL << 8LL);
				tir |= (31LL << 13LL);
				tir |= (29LL << 18LL);
				tir |= (((ir >> 5LL) & 1LL) << 23LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 24LL);
			}
			else {	// ANDI
				tir |= IAND;
				tir |= 0x80LL;
				tir |= ((ir & 0x1fLL) << 8LL);
				tir |= ((ir & 0x1fLL) << 13LL);
				tir |= (((ir >> 5LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 19LL);
				tir |= (((ir >> 11LL) & 1) << 23LL);
				tir |= (((ir >> 11LL) & 1) << 24LL);
				tir |= (((ir >> 11LL) & 1) << 25LL);
				tir |= (((ir >> 11LL) & 1) << 26LL);
				tir |= (((ir >> 11LL) & 1) << 27LL);
				tir |= (((ir >> 11LL) & 1) << 28LL);
				tir |= (((ir >> 11LL) & 1) << 29LL);
				tir |= (((ir >> 11LL) & 1) << 30LL);
				tir |= (((ir >> 11LL) & 1) << 31LL);
			}
			break;
		case 3:	// SHLI
			tir |= 0x82LL;
			tir |= ((ir & 0x1fLL) << 8LL);
			tir |= ((ir & 0x1fLL) << 13LL);
			tir |= (((ir >> 5LL) & 1LL) << 18LL);
			tir |= (((ir >> 8LL) & 0xFLL) << 19LL);
			tir |= (15LL << 26LL);
			break;
		case 4:
			switch ((ir >> 4) & 3) {
			case 0:	// SHRI
				tir |= 0x82;
				tir |= (fnRp(ir & 7LL) << 8LL);
				tir |= (fnRp(ir & 7LL) << 13LL);
				tir |= (((ir >> 3LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 19LL);
				tir |= (1LL << 23LL);
				tir |= (15LL << 26LL);
				break;
			case 1:	// ASRI
				tir |= 0x82;
				tir |= (fnRp(ir & 7LL) << 8LL);
				tir |= (fnRp(ir & 7LL) << 13LL);
				tir |= (((ir >> 3LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 19LL);
				tir |= (3LL << 23LL);
				tir |= (15LL << 26LL);
				break;
			case 2:
				tir |= IOR;
				tir |= 0x80;
				tir |= (fnRp(ir & 7LL) << 8LL);
				tir |= (fnRp(ir & 7LL) << 13LL);
				tir |= (((ir >> 3LL) & 1LL) << 18LL);
				tir |= (((ir >> 8LL) & 0xFLL) << 19LL);
				tir |= (((ir >> 11LL) & 1) << 23LL);
				tir |= (((ir >> 11LL) & 1) << 24LL);
				tir |= (((ir >> 11LL) & 1) << 25LL);
				tir |= (((ir >> 11LL) & 1) << 26LL);
				tir |= (((ir >> 11LL) & 1) << 27LL);
				tir |= (((ir >> 11LL) & 1) << 28LL);
				tir |= (((ir >> 11LL) & 1) << 29LL);
				tir |= (((ir >> 11LL) & 1) << 30LL);
				tir |= (((ir >> 11LL) & 1) << 31LL);
				break;
			case 3:
				switch ((ir >> 10) & 3) {
				case 0:	// SUB
					tir |= 0x82;
					tir |= (fnRp(ir & 7LL) << 8LL);
					tir |= (fnRp(ir & 7LL) << 13LL);
					tir |= (fnRp((((ir >> 8LL) & 3LL) << 1LL) | ((ir >> 3LL) & 1LL)) << 18LL);
					tir |= (3LL << 23LL);
					tir |= (ISUB << 26LL);
					break;
				case 1:	// AND
					tir |= 0x82;
					tir |= (fnRp(ir & 7LL) << 8LL);
					tir |= (fnRp(ir & 7LL) << 13LL);
					tir |= (fnRp((((ir >> 8LL) & 3LL) << 1LL) | ((ir >> 3LL) & 1LL)) << 18LL);
					tir |= (3LL << 23LL);
					tir |= (IAND << 26LL);
					break;
				case 2:	// OR
					tir |= 0x82;
					tir |= (fnRp(ir & 7LL) << 8LL);
					tir |= (fnRp(ir & 7LL) << 13LL);
					tir |= (fnRp((((ir >> 8LL) & 3LL) << 1LL) | ((ir >> 3LL) & 1LL)) << 18LL);
					tir |= (3LL << 23LL);
					tir |= (IOR << 26LL);
					break;
				case 3:	// XOR
					tir |= 0x82;
					tir |= (fnRp(ir & 7LL) << 8LL);
					tir |= (fnRp(ir & 7LL) << 13LL);
					tir |= (fnRp((((ir >> 8LL) & 3LL) << 1LL) | ((ir >> 3LL) & 1LL)) << 18LL);
					tir |= (3LL << 23LL);
					tir |= (IXOR << 26LL);
					break;
				}
				break;
			}
			break;
		case 5:	// CALL
			break;
		case 6:	// reserved
			break;
		// Branches are not compressed! because of DPO addressing
		case 7:
			tir |= IBcc;
			tir |= 0x80LL;
			tir |= ((ir & 3LL) << 16LL);
			tir |= (((ir >> 2LL) & 0xF) << 23LL);
			tir |= (((ir >> 8LL) & 0xF) << 27LL);
			tir |= (((ir >> 11LL) & 1) << 28LL);
			tir |= (((ir >> 11LL) & 1) << 29LL);
			tir |= (((ir >> 11LL) & 1) << 30LL);
			tir |= (((ir >> 11LL) & 1) << 31LL);
			break;
		case 8:
		case 9:
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		case 15:
			break;
		}
	}
	return (tir);
}
