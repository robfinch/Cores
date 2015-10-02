#include "StdAfx.h"
#include "clsDisassem.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern clsSystem sys65c816;
extern cls65C816 cpu;

clsDisassem::clsDisassem(void)
{
	e_bit = true;
	m_bit = true;
	x_bit = true;
}

std::string clsDisassem::branch(std::string mne, __int32 ad)
{
	static char buf[300];
	__int8 disp8;
	__int16 disp16;

	disp8 = sys65c816.Read(ad+1);
	bytesUsed = 2;
	sprintf(buf,"%s\t%06X", mne.c_str(),(ad+2 + disp8));
	if (disp8==0xff) {
		disp16 = sys65c816.Read(ad+2);
		bytesUsed = 4;
		sprintf(buf,"%s\t%06X", mne.c_str(),(ad +4 + disp16));
	}
	return std::string(buf);
}

std::string clsDisassem::disassemMnes(__int32 ad)
{
	static char buf[300];
	__int8 disp8;
	__int16 disp16;

	switch(sys65c816.Read(ad)) {
	case REP:
		sprintf(buf, "REP\t#$%02X", sys65c816.Read(ad+1));
		bytesUsed = 2;
		return std::string(buf);
	case SEP:
		sprintf(buf, "SEP\t#$%02X", sys65c816.Read(ad+1));
		bytesUsed = 2;
		return std::string(buf);
	case LDA_IMM:
/*
		if (e_bit) {
			sprintf(buf, "LDA\t#$%02X", sys65c816.Read(ad+1));
			bytesUsed = 2;
			return std::string(buf);
		}
		else
*/
		{
			if (m_bit) {
				sprintf(buf, "LDA\t#$%02X", sys65c816.Read(ad+1));
				bytesUsed = 2;
				return std::string(buf);
			}
			else {
				sprintf(buf, "LDA\t#$%04X", sys65c816.Read16(ad+1));
				bytesUsed = 3;
				return std::string(buf);
			}
		}
		break;
	case STA_ABS:
		sprintf(buf, "STA\t$%04X", sys65c816.Read16(ad+1));
		bytesUsed = 3;
		return std::string(buf);
	case BRA:	return branch("BRA", ad);
	case BEQ:	return branch("BEQ", ad);
	case BNE:	return branch("BNE", ad);
	case BMI:	return branch("BMI", ad);
	case BPL:	return branch("BPL", ad);
	case BRK:	bytesUsed = 1; return "BRK";
	case RTI:	bytesUsed = 1; return "RTI";
	case RTS:	bytesUsed = 1; return "RTS";
	case PHP:	bytesUsed = 1; return "PHP";
	case CLC:	bytesUsed = 1; return "CLC";
	case CLD:	bytesUsed = 1; return "CLD";
	case CLV:	bytesUsed = 1; return "CLV";
	case CLI:	bytesUsed = 1; return "CLI";
	case PLP:	bytesUsed = 1; return "PLP";
	case SEC:	bytesUsed = 1; return "SEC";
	case SED:	bytesUsed = 1; return "SED";
	case SEI:	bytesUsed = 1; return "SEI";
	case PLA:	bytesUsed = 1; return "PLA";
	case PLX:	bytesUsed = 1; return "PLX";
	case PLY:	bytesUsed = 1; return "PLY";
	case TAS:	bytesUsed = 1; return "TAS";
	case TSA:	bytesUsed = 1; return "TSA";
	case INY:	bytesUsed = 1; return "INY";
	case DEY:	bytesUsed = 1; return "DEY";
	case INX:	bytesUsed = 1; return "INX";
	case DEX:	bytesUsed = 1; return "DEX";
	case XCE:	bytesUsed = 1; return "XCE";
	default:	bytesUsed = 1; return "???";
	}
}

std::string clsDisassem::disassem(__int32 ad)
{
	static char buf[300];
	std::string str;
	int nn;

	sprintf(buf, "%06X", ad);
	str = disassemMnes(ad);
	for (nn = 1; nn <= bytesUsed; nn++) {
		sprintf(&buf[strlen(buf)]," %02X", sys65c816.Read(ad+nn-1));
	}
	for (; nn <= 4; nn++) {
		sprintf(&buf[strlen(buf)],"   ");
	}
	sprintf(&buf[strlen(buf)]," %s", str.c_str());
	return std::string(buf);
}

std::string clsDisassem::disassem20(__int32 ad)
{
	int nn, bu;
	std::string str;

	bu = 0;
	str = "";
	for (nn = 0; nn < 20; nn++) {
		str = str + disassem(ad) + "\r\n";
		bu = bu + bytesUsed;
	    ad = ad + bytesUsed;
	}
	bytesUsed = bu;
	return str;
}
