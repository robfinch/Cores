#pragma once
#include "clsDevice.h"
#include "clsKeyboard.h"
extern char refscreen;
extern unsigned int dataBreakpoints[30];
extern int numDataBreakpoints;
extern int runstop;
extern clsKeyboard keybd;
extern volatile unsigned __int8 keybd_status;
extern volatile unsigned __int8 keybd_scancode;

class clsSystem
{
public:
	unsigned int memory[33554432];
	unsigned int scratchpad[8192];
	unsigned int rom[32768];
	unsigned long VideoMem[4096];
	bool VideoMemDirty[4096];
	unsigned int leds;
	int m_z;
	int m_w;
	char write_error;
	unsigned int radr1;
	unsigned int radr2;

	clsSystem();
	void Reset();
	unsigned __int64 ReadInsn(unsigned __int64 pc);
	unsigned int Read(unsigned int ad, int sr=0);
	int Write(unsigned int ad, unsigned int dat, unsigned int mask, int cr=0);
 	int random();
};
