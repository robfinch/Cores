#pragma once
#include "clsThor.h"
// Test System Emulator
//
// Emulates the test system that the Thor processor is part of.
// Currently the screen display is not fully implemented as an
// emulation. The register set isn't present.
// Other devices present in the system are aggregated into the
// clsSystem class.

extern char refscreen;
extern unsigned int dataBreakpoints[30];
extern int numDataBreakpoints;
extern bool runstop;
extern volatile unsigned __int8 keybd_status;
extern volatile unsigned __int8 keybd_scancode;

class clsSystem
{
public:
	unsigned __int64 memory[16777216];	// 128 MB
	unsigned __int64 rom[32768];
	unsigned long VideoMem[4096];
	bool VideoMemDirty[4096];
	unsigned long DBGVideoMem[4096];
	bool DBGVideoMemDirty[4096];
	unsigned int leds;
	int m_z;
	int m_w;
	char write_error;
	unsigned int radr1;
	unsigned int radr2;
	bool WriteROM;
	bool quit;
	clsThor cpu2;
	clsPIC pic1;
	clsUart uart1;
	clsKeyboard keybd;
	clsSevenSeg sevenseg;

	clsSystem();
	void Reset();
	unsigned __int64 Read(unsigned int ad, int sr=0);
	unsigned __int64 ReadByte(unsigned int ad);
	unsigned __int64 ReadChar(unsigned int ad);
	unsigned __int64 ReadHalf(unsigned int ad);
	int Write(unsigned int ad, unsigned __int64 dat, unsigned int mask, int cr=0);
 	int random();
	void Run();
	void Step();
};
