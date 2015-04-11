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
