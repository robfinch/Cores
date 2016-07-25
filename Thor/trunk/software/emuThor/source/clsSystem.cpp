#include "stdafx.h"

extern unsigned int breakpoints[30];
extern unsigned __int64 ibreakpoints[10];
extern bool ib_active[10];
extern bool isRunning;
extern bool stepout, stepover;
extern unsigned int step_depth, stepover_depth;
extern unsigned int stepoverBkpt;
extern unsigned int stepover_pc;
extern bool animate;
extern bool fullspeed;
extern bool runstop;

clsSystem::clsSystem() {
	int nn;
	WriteROM = false;
	for (nn = 0; nn < sizeof(memory); nn+=8) {
		memory[nn>>3] = 0;
	}
	quit = false;
	Reset();
};
void clsSystem::Reset()
{
	int nn;
	WriteROM = false;
	m_z = 88888888;
	m_w = 12345678;
	for (nn = 0; nn < 4096; nn++) {
		VideoMem[nn] = random();
		VideoMemDirty[nn] = true;
	}
	leds = 0;
	write_error = false;
	runstop = false;
	cpu2.system1 = this;
	refscreen = true;
	cpu2.Reset();
	pic1.Reset();
	uart1.Reset();
};
	unsigned __int64 clsSystem::Read(unsigned int ad, int sr) {
		__int64 rr;
		unsigned __int8 sc;
		unsigned __int8 st;
		if ((ad & 0xE0000000)!=0xE0000000)
			ad &= 0x1FFFFFFF;
		if (sr) {
			if (radr1 == 0)
				radr1 = ad;
			else if (radr2 == 0)
				radr2 = ad;
			else {
				if (random()&1)
					radr2 = ad;
				else
					radr1 = ad;
			}
		}
		if (ad < 134217728) {
			return memory[ad >> 3];
		}
		else if ((ad & 0xFFFF0000)==0xFFD00000) {
			rr = VideoMem[(ad>>2)& 0xFFF];
			rr = (rr << 32) | rr;
			return rr;
		}
		else if ((ad & 0xFFFC0000)==0xFFFC0000) {
			return rom[(ad&0x3FFFF)>>3];
		}
		else if (keybd.IsSelected(ad)) {
			switch(ad & 0x1) {
			case 0:
				sc = keybd.Get();
				rr = ((int)sc<<24)|((int)sc << 16)|((int)sc<<8)|sc;
				rr = (rr << 32) | rr;
				break;
			case 1:
				st = keybd.GetStatus();
				rr = ((int)st<<24)|((int)st<<16)|((int)st<<8)|st;
				rr = (rr << 32) | rr;
				keybd_status = st;
				break;
			}
			return rr;
		}
		else if (pic1.IsSelected(ad)) {
			rr = pic1.Read(ad);
			rr = (rr << 48) | (rr << 32) | (rr << 16) | rr;
			return rr;
		}
		else if (uart1.IsSelected(ad)) {
			rr = uart1.Read(ad) & 0xFF;
			rr = (rr << 56) | (rr << 48) || (rr << 40) | (rr << 32)
				 | (rr << 24) | (rr << 16) | (rr << 8) | rr;
			return rr;
		}
		return 0;
	};
	int clsSystem::Write(unsigned int ad, unsigned __int64 dat, unsigned int mask, int cr) {
		int nn;
		int ret;

		if ((ad & 0xE0000000)!=0xE0000000)
			ad &= 0x1FFFFFFF;
		if (cr && (ad!=radr1 && ad!=radr2)) {
			ret = false;
			goto j1;
		}
		if (cr) {
			if (ad==radr1)
				radr1 = 0x00000000;
			if (ad==radr2)
				radr2 = 0x00000000;
		}
		if (ad < 134217728) {
			if (ad >= 0xFFFC0000LL) {
				write_error = true;
				ret = true;
				goto j1;
			}
			if ((ad & 0xfffffff0)==0x00c431a0) {
				ret = true;
			}
			switch(mask) {
			case 0xFF:
				memory[ad>>3] = dat;
				break;
			case 0x1:
				memory[ad >> 3] &= 0xFFFFFFFFFFFFFF00LL;
				memory[ad >> 3] |= dat & 0xFFLL;
				break;
			case 0x2:
				memory[ad >> 3] &= 0xFFFFFFFFFFFF00FFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 8;
				break;
			case 0x4:
				memory[ad >> 3] &= 0xFFFFFFFFFF00FFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 16;
				break;
			case 0x8:
				memory[ad >> 3] &= 0xFFFFFFFF00FFFFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 24;
				break;
			case 0x10:
				memory[ad >> 3] &= 0xFFFFFF00FFFFFFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 32;
				break;
			case 0x20:
				memory[ad >> 3] &= 0xFFFF00FFFFFFFFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 40;
				break;
			case 0x40:
				memory[ad >> 3] &= 0xFF00FFFFFFFFFFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 48;
				break;
			case 0x80:
				memory[ad >> 3] &= 0x00FFFFFFFFFFFFFFLL;
				memory[ad >> 3] |= (dat & 0xFFLL) << 56;
				break;
			case 0x3:
				memory[ad >> 3] &= 0xFFFFFFFFFFFF0000;
				memory[ad >> 3] |= dat & 0xFFFFLL;
				break;
			case 0x6:
				memory[ad >> 3] &= 0xFFFFFFFFFF0000FF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 8;
				break;
			case 0xC:
				memory[ad >> 3] &= 0xFFFFFFFF0000FFFF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 16;
			case 0x18:
				break;
				memory[ad >> 3] &= 0xFFFFFF0000FFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 24;
				break;
			case 0x30:
				memory[ad >> 3] &= 0xFFFF0000FFFFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 32;
				break;
			case 0x60:
				memory[ad >> 3] &= 0xFF0000FFFFFFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 40;
				break;
			case 0xC0:
				memory[ad >> 3] &= 0x0000FFFFFFFFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFLL) << 48;
				break;
			case 0x0F:
				memory[ad >> 3] &= 0xFFFFFFFF00000000;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 0;
				break;
			case 0x1E:
				memory[ad >> 3] &= 0xFFFFFF00000000FF;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 8;
				break;
			case 0x3C:
				memory[ad >> 3] &= 0xFFFF00000000FFFF;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 16;
				break;
			case 0x78:
				memory[ad >> 3] &= 0xFF00000000FFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 24;
				break;
			case 0xF0:
				memory[ad >> 3] &= 0x00000000FFFFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 32;
				break;
			case 0xE0:
				memory[ad >> 3] &= 0x000000FFFFFFFFFF;
				memory[ad >> 3] |= (dat & 0xFFFFFFFFLL) << 40;
				break;
			}
		}
		else if ((ad & 0xFFFFFF00)==0xFFDC0600) {
			if (dat==32)
				printf("hi there");
			leds = dat;
		}
		else if ((ad & 0xFFFF0000)==0xFFD00000) {
			VideoMem[(ad>>2)& 0xFFF] = dat;
			VideoMemDirty[(ad>>2)&0xfff] = true;
			refscreen = true;
		}
		else if ((ad & 0xFFFF0000)==0xFFD10000) {
			DBGVideoMem[(ad>>2)& 0xFFF] = dat;
			DBGVideoMemDirty[(ad>>2)&0xfff] = true;
			refscreen = true;
		}
		else if ((ad & 0xFFFC0000)==0xFFFC0000 && WriteROM) {
			rom[(ad&0x3FFFF)>>3] = dat;
		}
		else if (keybd.IsSelected(ad)) {
			switch(ad & 1) {
			case 1:	keybd_status = 0; pic1.irqKeyboard = keybd.GetStatus()==0x80; break;
			}
		}
		else if (pic1.IsSelected(ad)) {
			pic1.Write(ad,dat,0x3);
		}
		else if (uart1.IsSelected(ad)) {
			uart1.Write(ad,dat,0x1);
		}
		else if (sevenseg.IsSelected(ad)) {
			sevenseg.Write(ad,dat);
		}
		ret = true;
j1:
		for (nn = 0; nn < numDataBreakpoints; nn++) {
			if (ad==dataBreakpoints[nn]) {
				runstop = true;
			}
		}
		return ret;
	};
 	int clsSystem::random() {
		m_z = 36969 * (m_z & 65535) + (m_z >> 16);
		m_w = 18000 * (m_w & 65535) + (m_w >> 16);
		return (m_z << 16) + m_w;
	};

unsigned __int64 clsSystem::ReadByte(unsigned int ad) {
unsigned __int64 dat = Read(ad);
	return (dat >> ((ad & 7) * 8)) & 0xFFLL;
}
unsigned __int64 clsSystem::ReadChar(unsigned int ad) {
unsigned __int64 dat = Read(ad);
	return (dat >> ((ad & 7) * 8)) & 0xFFFFLL;
}
unsigned __int64 clsSystem::ReadHalf(unsigned int ad) {
unsigned __int64 dat = Read(ad);
	return (dat >> ((ad & 7) * 8)) & 0xFFFFFFFFLL;
}


void clsSystem::Step() {
	uart1.Step();
	keybd.Step();
	pic1.Step();
	cpu2.Step();
}

void clsSystem::Run() {
	int nn,kk;
	int xx;

	do {
		if (isRunning) {
		//			if (cpu2.pc > 134217727) {
			if (cpu2.pc < 0xFFFC0000LL && cpu2.pc & 0x1000 != 0x1000) {
				isRunning = false;
				continue;
			}
			if (cpu2.pc == stepoverBkpt) {
				stepoverBkpt = 0;
				isRunning = false;
				continue;
			}
			for (kk = 0; kk < 5; kk++) {
				if (cpu2.pc == ibreakpoints[kk] && ib_active[kk]) {
					isRunning = false;
					continue;
				}
			}
			if (system1.write_error==true) {
				isRunning = false;
				continue;
			//				this->lblWriteErr->Visible = true;
			}
			// Runstop becomes active when a data breakpoint is hit.
			if (runstop) {
				isRunning = false;
				runstop = false;
				continue;
			}
			cpu2.Step();
			pic1.Step();
			if (stepout) {
				if (cpu2.rts && cpu2.sub_depth < step_depth) {
					isRunning = false;
					stepout = false;
					continue;
				}
			}
			if (stepover) {
				if (cpu2.pc > stepover_pc && cpu2.sub_depth==stepover_depth) {
					isRunning = false;
					stepover = false;
					continue;
				}
			}
					/*
				if (cpu2.pc == stepoverBkpt) {
					stepoverBkpt = 0;
					cpu2.isRunning = false;
					UpdateListBox(cpu2.pc-32);
					return;
				}
				for (kk = 0; kk < numBreakpoints; kk++) {
					if (cpu2.pc == breakpoints[kk]) {
						cpu2.isRunning = false;
							UpdateListBox(cpu2.pc-32);
						return;
					}
				}
					cpu2.Step();
     				pic1.Step();
					UpdateListBox(cpu2.pc-32);
					*/
			//			 UpdateListBox(cpu2.pc-32);
		}
	} while (false);	// !quit
}
