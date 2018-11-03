#include "stdafx.h"
#include <string>
#include "Instructions.h"
#include "Disassem.h"


unsigned int insn;
unsigned int imm1,imm2;
int immcnt;
int opcode;

std::string Ra()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 6) & 0x1f,buf,10));
	return str;
}

std::string Rb()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 11) & 0x1f,buf,10));
	return str;
}

std::string Rc()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 16) & 0x1f,buf,10));
	return str;
}

std::string Rt()
{
	char buf[40];
	std::string str;
	if ((insn & 0x3f)==IRR) {
		if ((insn >> 26)==IMOV)
			str = "R" + std::string(_itoa((insn >> 11) & 0x1f,buf,10));
		else
			str = "R" + std::string(_itoa((insn >> 16) & 0x1f,buf,10));
	}
	else
		str = "R" + std::string(_itoa((insn >> 11) & 0x1f,buf,10));
	return str;
}

std::string Rt4()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa(((insn >> 12) & 0xf)|((insn & 1) << 4),buf,10));
	return str;
}

std::string FPa()
{
	char buf[40];
	std::string str;
	str = "FP" + std::string(_itoa((insn >> 6) & 0x1f,buf,10));
	return str;
}

std::string FPb()
{
	char buf[40];
	std::string str;
	str = "FP" + std::string(_itoa((insn >> 11) & 0x1f,buf,10));
	return str;
}

std::string FPt()
{
	char buf[40];
	std::string str;
	str = "FP" + std::string(_itoa((insn >> 16) & 0x1f,buf,10));
	return str;
}

std::string Bn()
{
	char buf[40];
	std::string str;
	str = "B" + std::string(_itoa((insn >> 11) & 0x3f,buf,10));
	return str;
}

std::string Sa()
{
	char buf[40];
	std::string str;
	str = std::string(_itoa((insn >> 16) & 0x3f,buf,16));
	return str;
}

std::string IncAmt()
{
	char buf[40];
	std::string str;
	str = std::string(_itoa((insn >> 12) & 0x1f,buf,16));
	return str;
}

std::string Spr()
{
	char buf[40];
	int spr;

	std::string str;
	spr = (insn >> 17) & 0xFf;
	switch(spr) {
	case 0: str = "CR0"; break;
	case 4: str = "TICK"; break;
	case 7: str = "DPC"; break;
	case 8: str = "IPC"; break;
	case 9: str = "EPC"; break;
	case 10: str = "VBR"; break;
	case 11: str = "BEAR"; break;
	case 12: str = "VECNO"; break;
	case 15: str = "ISP"; break;
	case 16: str = "DSP"; break;
	case 17: str = "ESP"; break;
	case 50: str = "DBAD0"; break;
	case 51: str = "DBAD1"; break;
	case 52: str = "DBAD2"; break;
	case 53: str = "DBAD3"; break;
	case 54: str = "DBCTRL"; break;
	case 55: str = "DBSTAT"; break;
	default:	str = std::string(_itoa(spr,buf,10));
	}
	return str;
}

static std::string CallConstant()
{
    static char buf[50];
    int sir;

    sir = insn;
    sprintf(buf,"$%X", (sir >> 6) << 2);
    return std::string(buf);
}

static std::string DisassemConstant()
{
    static char buf[50];
    int sir;

    sir = insn;
    if (immcnt == 1) {
        sprintf(buf,"$%X", (imm1 << 16)|(insn>>16));
    }
    else
        sprintf(buf,"$%X", (sir >> 16));
    return std::string(buf);
}


static std::string DisassemConstant9()
{
    static char buf[50];
    int sir;

    sir = insn;
    sprintf(buf,"$%X", ((sir >> 7) & 0x1ff)<< 3);
    return std::string(buf);
}


static std::string DisassemConstant4()
{
    static char buf[50];
    int sir;

    sir = insn;
	sir >>= 12;
	sir &= 0xF;
	if (sir&8)
		sir |= 0xFFFFFFF0;
    sprintf(buf,"$%X", sir);
    return std::string(buf);
}


static std::string DisassemConstant4x8()
{
    static char buf[50];
    int sir;

    sir = insn;
	sir >>= 12;
	if (sir&0x8)
		sir |= 0xFFFFFFF0;
	sir <<= 3;
    sprintf(buf,"$%X", sir);
    return std::string(buf);
}


static std::string DisassemConstant4u()
{
    static char buf[50];
    int sir;

    sir = insn;
	sir >>= 12;
	sir &= 0xF;
    sprintf(buf,"$%X", sir);
    return std::string(buf);
}


static std::string DisassemBccDisplacement(unsigned int bad)
{
    static char buf[50];
    int sir;
	int brdisp;

    sir = insn;
	brdisp = (((sir >> 22) << 3) | ((sir & 1) << 2));
    sprintf(buf,"$%X", brdisp + bad + 4);
    return (std::string(buf));
}


static std::string DisassemMemAddress()
{
    static char buf[50];
    int sir;
	std::string str;

    sir = insn;
	str = DisassemConstant();
    if (((insn >> 6) & 0x1F) != 0)
        sprintf(buf,"[R%d]",((insn >> 6) & 0x1F));
    else
        sprintf(buf,"");
    return str+std::string(buf);
}

static std::string DisassemMbMe()
{
	static char buf[50];

	sprintf(buf, "#%d,#%d", (insn>>16) & 0x3f,(insn>>22) &0x3f);
	return std::string(buf);
}

static std::string DisassemIndexedAddress()
{
    static char buf[50];
    int sir;
	std::string str;
	int Ra = (insn >> 6) & 0x1f;
	int Rb = (insn >> 11) & 0x1f;
	int sc = (insn >> 21) & 3;
	int offs = 0;

	sc = 1 << sc;

    sir = insn;
	if (offs != 0) {
		sprintf(buf,"$%X",offs);
		str = std::string(buf);
	}
	else
		str = std::string("");
	if (Rb && Ra)
		sprintf(buf,"[R%d+R%d", Ra, Rb);
	else if (Ra) {
		sprintf(buf,"[R%d]", Ra);
		str += std::string(buf);
		return str;
	}
	else if (Rb)
		sprintf(buf,"[R%d", Rb);
	str += std::string(buf);

	if (sc > 1)
		sprintf(buf, "*%d]", sc);
	else
		sprintf(buf,"]");
	str += std::string(buf);
    return str;
}

static std::string DisassemJali()
{
	char buf[50];
	int Ra = (insn >> 7) & 0x1f;
	int Rb = (insn >> 17) & 0x1f;
	int Rt = (insn >> 12) & 0x1f;

	if (Rt==0) {
		sprintf(buf, "JMP   (%s)", DisassemMemAddress().c_str());
	}
	else if (Rt==31) {
		sprintf(buf, "JSR   (%s)", DisassemMemAddress().c_str());
	}
	else {
		sprintf(buf, "JAL   R%d,(%s)",Rt, DisassemMemAddress().c_str());
	}
	return std::string(buf);
}

static std::string DisassemJal()
{
	char buf[50];
	int Ra = (insn >> 6) & 0x1f;
	int Rb = (insn >> 11) & 0x1f;
	int Rt = (insn >> 11) & 0x1f;

	if (Rt==0) {
		sprintf(buf, "JMP   %s", DisassemMemAddress().c_str());
	}
	else {
		sprintf(buf, "JAL   R%d,%s",Rt, DisassemMemAddress().c_str());
	}
	return std::string(buf);
}

static std::string DisassemBrk()
{
	char buf[50];
	sprintf(buf, "BRK   #%d", (insn>>6) & 0x1ff);
	return std::string(buf);
}


std::string Disassem(std::string sad, std::string sinsn, unsigned int dad, unsigned int *ad1)
{
	char buf[20];
	std::string str;
	static int first = 1;
	int Rbb = (insn >> 11) & 0x1f;

	if (first) {
		immcnt = 0;
		first = 0;
	}

	insn = strtoul(sinsn.c_str(),0,16);
	opcode = insn & 0x3f;
	*ad1 = dad + 4;
	switch(opcode)
	{
	case IRR:
		switch((insn >> 26) & 0x3f)
		{
		case ISEI:	str = "SEI"; break;
		case IWAIT:	str = "WAI"; break;
		case IRTI:	str = "RTI"; break;
		case IADD:
			str = "ADD   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case ISUB:
			str = "SUB   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case ICMP:
			str = "CMP   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case ICMPU:
			str = "CMPU  " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IMUL:
			str = "MUL   " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IMULU:
			str = "MULU  " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IMULSU:
			str = "MULSU " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IDIVMOD:
			str = "DIVMOD" + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IDIVMODU:
			str = "DIVMODU" + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IDIVMODSU:
			str = "DIVMODSU" + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IAND:
			str = "AND   " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IOR:
			if (Rbb==0)
				str = "MOV   " + Rt() +"," + Ra();
			else
				str = "OR    " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IXOR:
			str = "XOR   " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case IMOV:
			{
				int d3 = (insn >> 23) & 7;
				switch(d3) {
				case 2:
					str = "MOV   " + Rt() + ":x," + Ra();
					break;
				case 3:
					str = "MOV   " + Rt() + "," + Ra() + ":x";
					break;
				case 7:
				default:
					str = "MOV   " + Rt() + "," + Ra();
					break;
				}
				immcnt = 0;
			}
			return (str);
		case ILBX:
			str = "LBX   " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILBUX:
			str = "LBUX  " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILCX:
			str = "LCX   " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILCUX:
			str = "LCUX  " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILHX:
			str = "LHX   " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILHUX:
			str = "LHUX   " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ILWX:
			str = "LWX   " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ISBX:
			str = "SB    " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ISCX:
			str = "SC    " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ISHX:
			str = "SH    " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ISWX:
			str = "SW    " + Rt() + "," + DisassemIndexedAddress();
			immcnt = 0;
			return str;
		case ISHIFT:
			switch((insn >> 22) & 0xF) {
			case ISHL:
				str = "SHL   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case ISHR:
				str = "SHR   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case IASL:
				str = "ASL   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case IASR:
				str = "ASR   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case IROL:
				str = "ROL   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case IROR:
				str = "ROR   " + Rt() +"," + Ra() + "," + Rb();
				immcnt = 0;
				return str;
			case ISHLI:
				str = "SHL   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			case ISHRI:
				str = "SHR   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			case IASLI:
				str = "ASL   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			case IASRI:
				str = "ASL   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			case IROLI:
				str = "ROL   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			case IRORI:
				str = "ROR   " + Rt() +"," + Ra() + ",#" + Sa();
				immcnt = 0;
				return str;
			}
			break;
		}
		break;
	case IBTFLD:
		switch((insn >> 29)&7) {
		case IBFSET:	str = "BFSET  " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		case IBFCLR:	str = "BFCLR  " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		case IBFCHG:	str = "BFCHG  " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		case IBFINS:	str = "BFINS  " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
//		case BFINSI:	str = "BFINSI " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		case IBFEXT:	str = "BFEXT  " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		case IBFEXTU:	str = "BFEXTU " + Rt() + "," + Ra() + "," + DisassemMbMe(); break;
		}
		immcnt = 0;
		return str;
	case IQOPI:
		switch((insn >> 8) & 7) {
		case 0:	str = "QOR   " + Rt() + ",#" + DisassemConstant(); break;
		}
		return str;
	case ICHK:
		str = "CHK   " + Rt() +"," + Ra() + "," + Bn();
		immcnt = 0;
		return str;
	case IADD:
		str = "ADD   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case ICMP:
		str = "CMP   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case ICMPU:
		str = "CMPU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMUL:
		str = "MUL   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMULU:
		str = "MULU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMULSU:
		str = "MULSU " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IDIVI:
		str = "DIV   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IDIVUI:
		str = "DIVU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IDIVSUI:
		str = "DIVSU " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMODI:
		str = "MOD   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMODUI:
		str = "MODU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IMODSUI:
		str = "MODSU " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IAND:
		str = "AND   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IOR:
		if ((insn >> 16) == 0)
			str = "MOV   " + Rt() + "," + Ra();
		else
			str = "OR    " + Rt() + "," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IXOR:
		str = "EOR   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case IFLOAT:
		switch ((insn>>26)&0x3f) {
		case IFADD:
			str = "FADD  " + FPt() +"," + FPa() + "," + FPb();
			immcnt = 0;
			return str;
		case IFSUB:
			str = "FSUB  " + FPt() +"," + FPa() + "," + FPb();
			immcnt = 0;
			return str;
		case IFCMP:
			str = "FCMP  " + Rt() +"," + FPa() + "," + FPb();
			immcnt = 0;
			return str;
		case IFMUL:
			str = "FMUL  " + FPt() +"," + FPa() + "," + FPb();
			immcnt = 0;
			return str;
		case IFDIV:
			str = "FDIV  " + FPt() +"," + FPa() + "," + FPb();
			immcnt = 0;
			return str;
		case IFMOV:
			str = "FMOV  " + FPt() +"," + FPa();
			immcnt = 0;
			return str;
		case IFNEG:
			str = "FNEG  " + FPt() +"," + FPa();
			immcnt = 0;
			return str;
		case IFABS:
			str = "FABS  " + FPt() +"," + FPa();
			immcnt = 0;
			return str;
		}
		break;
	case IBcc0:
	case IBcc1:
		switch((insn >> 16) & 0x7) {
		case IBEQ:
			str = "BEQ   " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		case IBNE:
			str = "BNE   " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		case IBLT:
			str = "BLT   " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		case IBGE:
			str = "BGE   " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		case IBLTU:
			str = "BLTU  " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		case IBGEU:
			str = "BGEU  " + Ra() + "," + Rb() + "," + DisassemBccDisplacement(dad);
			immcnt = 0;
			return str;
		}
		immcnt = 0;
		return "B????";
	case ICALL:
		str = "CALL  " + CallConstant();
		return (str);
	case IJMP:
		str = "JMP   " + CallConstant();
		return (str);
	case IJAL:
		str = DisassemJal();
		immcnt = 0;
		return str;
	case IRET:
		str = "RET   #" + DisassemConstant();
		immcnt = 0;
		return str;
	case IBRK:
		str = DisassemBrk();
		immcnt = 0;
		return str;
	case INOP:
		str = "NOP";
		immcnt = 0;
		return str;
	case ILB:
		str = "LB    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILBU:
		str = "LBU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILC:
		str = "LC    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILCU:
		str = "LCU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILH:
		str = "LH    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILHU:
		str = "LHU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILW:
		str = "LW    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ILWR:
		str = "LWAR  " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ISB:
		str = "SB    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ISC:
		str = "SC    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ISH:
		str = "SH    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ISW:
		str = "SW    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case ISWC:
		str = "SWC   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	}
	immcnt = 0;
	return "?????";
}

std::string Disassem(unsigned int ad, unsigned int dat, unsigned int *ad1)
{
	char buf1[20];
	char buf2[20];

	sprintf(buf1,"%06X", ad);
	sprintf(buf2,"%08X", dat);
	return (Disassem(std::string(buf1),std::string(buf2),ad,ad1));
}
