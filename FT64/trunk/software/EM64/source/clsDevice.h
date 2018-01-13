#pragma once

// Generic system device

class clsDevice
{
public:
	clsDevice(void) {};
	void Reset() {};
	bool IsSelected(unsigned int ad) { return false; };
	unsigned int Read(unsigned int ad) { return 0xDEADDEAD; };
	int Write(unsigned int ad, unsigned int dat, unsigned int mask) {};
	// Read the device and optionally set an address reservation.
	unsigned int Read(unsigned int ad, int sr) { return 0xDEADDEAD; };
	// Write the device and optionally clear an address reservation.
	int Write(unsigned int ad, unsigned int dat, unsigned int mask, int cr) {};
	void Step(void) {};
};
