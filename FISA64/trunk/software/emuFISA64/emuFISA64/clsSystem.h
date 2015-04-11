#pragma once

extern char refscreen;

class clsSystem
{
public:
	unsigned int memory[33554432];
	unsigned long VideoMem[4096];
	unsigned int leds;
	int m_z;
	int m_w;

	clsSystem() {
		int nn;
		m_z = 88888888;
		m_w = 12345678;
		for (nn = 0; nn < 4096; nn++)
			VideoMem[nn] = random();
	};
	unsigned int Read(unsigned int ad) {
		if (ad < 134217728) {
			return memory[ad >> 2];
		}
	};
	void Write(unsigned int ad, unsigned int dat, unsigned int mask) {
		if (ad < 134217728) {
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
	};
 	int random() {
		m_z = 36969 * (m_z & 65535) + (m_z >> 16);
		m_w = 18000 * (m_w & 65535) + (m_w >> 16);
		return (m_z << 16) + m_w;
	};
};
