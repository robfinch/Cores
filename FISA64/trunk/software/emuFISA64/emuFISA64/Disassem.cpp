#include "stdafx.h"
#include <string>
#include "Disassem.h"


unsigned int insn;
unsigned int ad;
unsigned int imm1,imm2;
int immcnt;

std::string Ra()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 7) & 0x1f,buf,10));
	return str;
}

std::string Rb()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 17) & 0x1f,buf,10));
	return str;
}

std::string Rt()
{
	char buf[40];
	std::string str;
	str = "R" + std::string(_itoa((insn >> 12) & 0x1f,buf,10));
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

static std::string DisassemConstant()
{
    static char buf[50];
    int sir;

    sir = insn;
    if (immcnt == 1) {
        sprintf(buf,"$%X", (imm1 << 15)|(insn>>17));
    }
    else
        sprintf(buf,"$%X", (sir >> 17));
    return std::string(buf);
}


static std::string DisassemBraDisplacement()
{
    static char buf[50];
    int sir;

    sir = insn;
    sprintf(buf,"$%X", ((sir >> 7) <<2) + ad);
    return std::string(buf);
}


static std::string DisassemBccDisplacement()
{
    static char buf[50];
    int sir;

    sir = insn;
    sprintf(buf,"$%X", ((sir >> 17) <<2) + ad);
    return std::string(buf);
}


static std::string DisassemMemAddress()
{
    static char buf[50];
    int sir;
	std::string str;

    sir = insn;
	str = DisassemConstant();
    if (((insn >> 7) & 0x1F) != 0)
        sprintf(buf,"[R%d]\r\n",((insn >> 7) & 0x1F));
    else
        sprintf(buf,"\r\n");
    return str+std::string(buf);
}

static std::string DisassemIndexedAddress()
{
    static char buf[50];
    int sir;
	std::string str;
	int Ra = (insn >> 7) & 0x1f;
	int Rb = (insn >> 17) & 0x1f;
	int sc = (insn >> 22) & 3;
	int offs = (insn >> 24);

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


std::string Disassem(std::string sad, std::string sinsn)
{
	char buf[20];
	std::string str;
	static int first = 1;

	if (first) {
		immcnt = 0;
		first = 0;
	}

	ad = strtoul(sad.c_str(),0,16);
	insn = strtoul(sinsn.c_str(),0,16);
	switch(insn & 0x7F)
	{
	case RR:
		switch((insn >> 25) & 0x7f)
		{
		case CPUID:
			str = "CPUID " + Rt() + "," + Ra() + ",#" + _itoa((insn>>17) & 0x0f, buf, 16);
			immcnt = 0;
			return str;
		case ADD:
			str = "ADD   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case ADDU:
			str = "ADDU  " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case SUB:
			str = "SUB   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case SUBU:
			str = "SUBU  " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case CMP:
			str = "CMP   " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case CMPU:
			str = "CMPU  " + Rt() + "," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case MUL:
			str = "MUL   " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case MULU:
			str = "MULU  " + Rt() +"," + Ra() + "," + Rb();
			immcnt = 0;
			return str;
		case MTSPR:
			str = "MTSPR " + Spr() + "," + Ra();
			immcnt = 0;
			return str;
		case MFSPR:
			str = "MFSPR " + Rt() + "," + Spr();
			immcnt = 0;
			return str;
		}
		immcnt = 0;
		return "?????";
	case ADD:
		str = "ADD   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case ADDU:
		str = "ADDU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case SUB:
		str = "SUB   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case SUBU:
		str = "SUBU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case CMP:
		str = "CMP   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case CMPU:
		str = "CMPU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case MUL:
		str = "MUL   " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case MULU:
		str = "MULU  " + Rt() +"," + Ra() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;

	case IMM:
		imm2 = imm1;
		imm1 = (insn >> 7);
		immcnt++;
		return "IMM";
	case Bcc:
		switch((insn >> 12) & 0x7) {
		case BEQ:
			str = "BEQ   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		case BNE:
			str = "BNE   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		case BLT:
			str = "BLT   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		case BLE:
			str = "BLE   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		case BGT:
			str = "BGT   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		case BGE:
			str = "BGE   " + Ra() + "," + DisassemBccDisplacement();
			immcnt = 0;
			return str;
		}
		immcnt = 0;
		return "B????";
	case BRA:
		str = "BRA   " + DisassemBraDisplacement();
		immcnt = 0;
		return str;
	case BSR:
		str = "BSR   " + DisassemBraDisplacement();
		immcnt = 0;
		return str;
	case RTL:
		str = "RTL   #" + DisassemConstant();
		immcnt = 0;
		return str;
	case RTS:
		str = "RTS   #" + DisassemConstant();
		immcnt = 0;
		return str;
	case NOP:
		str = "NOP";
		immcnt = 0;
		return str;
	case PUSH:
		immcnt = 0;
		return "PUSH  " + Ra();
	case POP:
		immcnt = 0;
		return "POP   " + Rt();
	case LDI:
		str = "LDI   " + Rt() + ",#" + DisassemConstant();
		immcnt = 0;
		return str;
	case LB:
		str = "LB    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LBU:
		str = "LBU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LC:
		str = "LC    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LCU:
		str = "LCU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LH:
		str = "LH    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LHU:
		str = "LHU   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LW:
		str = "LW    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LEA:
		str = "LEA   " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case LBX:
		str = "LBX   " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LBUX:
		str = "LBUX  " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LCX:
		str = "LCX   " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LCUX:
		str = "LCUX  " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LHX:
		str = "LHX   " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LHUX:
		str = "LHUX   " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case LWX:
		str = "LWX   " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case SB:
		str = "SB    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case SC:
		str = "SC    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case SH:
		str = "SH    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case SW:
		str = "SW    " + Rt() + "," + DisassemMemAddress();
		immcnt = 0;
		return str;
	case SBX:
		str = "SB    " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case SCX:
		str = "SC    " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case SHX:
		str = "SH    " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	case SWX:
		str = "SW    " + Rt() + "," + DisassemIndexedAddress();
		immcnt = 0;
		return str;
	}
	immcnt = 0;
	return "?????";
}

std::string Disassem(unsigned int ad, unsigned int dat)
{
	char buf1[20];
	char buf2[20];

	sprintf(buf1,"%06X", ad);
	sprintf(buf2,"%08X", dat);
	return Disassem(std::string(buf1),std::string(buf2));
}
