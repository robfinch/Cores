#pragma once

class clsSystem
{
public:
	unsigned int memory[33554432];
	unsigned int leds;

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
	}
};
