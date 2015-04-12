#pragma once
extern char refscreen;
extern unsigned int dataBreakpoints[30];
extern int numDataBreakpoints;
class clsCPU;
extern int runstop;

class clsSystem
{
public:
	unsigned int memory[33554432];
	unsigned long VideoMem[4096];
	unsigned int leds;
	int m_z;
	int m_w;
	char write_error;
	unsigned int radr1;
	unsigned int radr2;

	clsSystem() {
		int nn;
		m_z = 88888888;
		m_w = 12345678;
		for (nn = 0; nn < 4096; nn++)
			VideoMem[nn] = random();
		write_error = false;
		runstop = false;
	};
	unsigned int Read(unsigned int ad, int sr=0) {
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
		return 0;
	};
	int Write(unsigned int ad, unsigned int dat, unsigned int mask, int cr=0) {
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
			refscreen = true;
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
 	int random() {
		m_z = 36969 * (m_z & 65535) + (m_z >> 16);
		m_w = 18000 * (m_w & 65535) + (m_w >> 16);
		return (m_z << 16) + m_w;
	};
};
