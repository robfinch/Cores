#include "stdafx.h"

extern clsPIC pic1;

clsSystem::clsSystem() {
		int nn;
		m_z = 88888888;
		m_w = 12345678;
		for (nn = 0; nn < 4096; nn++) {
			VideoMem[nn] = random();
			VideoMemDirty[nn] = true;
		}
		write_error = false;
		runstop = false;
		cpu1.system1 = this;
		refscreen = true;
	};
	unsigned int clsSystem::Read(unsigned int ad, int sr) {
		int rr;
		unsigned __int8 sc;
		unsigned __int8 st;
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
			return memory[ad >> 2];
		}
		else if ((ad & 0xFFFF0000)==0xFFD00000) {
			return VideoMem[(ad>>2)& 0xFFF];
		}
		else if ((ad & 0xFFFFFFF0)==0xFFDC0000) {
			switch(ad & 0x1) {
			case 0:
				sc = keybd.Pop();
				rr = ((int)sc<<24)|((int)sc << 16)|((int)sc<<8)|sc;
				break;
			case 1:
				st = keybd.GetStatus();
				rr = ((int)st<<24)|((int)st<<16)|((int)st<<8)|st;
				keybd_status = st;
				break;
			}
			return rr;
		}
		else if ((ad & 0xFFFFFFC0)==0xFFDC0FC0) {
			return pic1.Read(ad);
		}
		return 0;
	};
	int clsSystem::Write(unsigned int ad, unsigned int dat, unsigned int mask, int cr) {
		int nn;
		int ret;
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
			if (ad >= 0x10000 && ad < 0x20000) {
				write_error = true;
				ret = true;
				goto j1;
			}
			switch(mask) {
			case 0xFFFFFFFF:
				memory[ad>>2] = dat;
				break;
			case 0x000000FF:
				memory[ad >> 2] &= 0xFFFFFF00;
				memory[ad >> 2] |= dat & 0xFF;
				break;
			case 0x0000FF00:
				memory[ad >> 2] &= 0xFFFF00FF;
				memory[ad >> 2] |= (dat & 0xFF) << 8;
				break;
			case 0x00FF0000:
				memory[ad >> 2] &= 0xFF00FFFF;
				memory[ad >> 2] |= (dat & 0xFF) << 16;
				break;
			case 0xFF000000:
				memory[ad >> 2] &= 0x00FFFFFF;
				memory[ad >> 2] |= (dat & 0xFF) << 24;
				break;
			case 0x0000FFFF:
				memory[ad >> 2] &= 0xFFFF0000;
				memory[ad >> 2] |= dat & 0xFFFF;
				break;
			case 0x00FFFF00:
				memory[ad >> 2] &= 0xFF0000FF;
				memory[ad >> 2] |= (dat & 0xFFFF) << 8;
				break;
			case 0xFFFF0000:
				memory[ad >> 2] &= 0x0000FFFF;
				memory[ad >> 2] |= (dat & 0xFFFF) << 16;
				break;
			}
		}
		else if ((ad & 0xFFFFFF00)==0xFFDC0600) {
			leds = dat;
		}
		else if ((ad & 0xFFFF0000)==0xFFD00000) {
			VideoMem[(ad>>2)& 0xFFF] = dat;
			VideoMemDirty[(ad>>2)&0xfff] = true;
			refscreen = true;
		}
		else if ((ad & 0xFFFFFFF0)==0xFFDC0000) {
			switch(ad & 1) {
			case 1:	keybd_status = 0;
			}
		}
		else if ((ad & 0xFFFFFFC0)==0xFFDC0FC0) {
			pic1.Write(ad,dat);
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

