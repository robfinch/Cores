#include "stdafx.h"
#include "clsUart.h"

void clsUart::Reset()
{
	ls = 0x60;
}
bool clsUart::IsSelected(unsigned int ad)
{
	return (ad & 0xFFFFFFF0LL)==0xFFDC0A00;
}

unsigned int clsUart::Read(unsigned int ad)
{
	if (IsSelected(ad)) {
		switch(ad & 0xF) {
		case 0:		ls &= 0xFE; return rb;
		case 1:		return ls;
		case 2:		return ms;
		case 3:		return is;
		default:	return 0x00;
		}
	}
	else
		return 0;
}

int clsUart::Write(unsigned int ad, unsigned int dat, unsigned int mask)
{
	if (IsSelected(ad)) {
		switch(ad & 0xF) {
		case 0:		tb = dat; ls &= 0x9F; break;
		case 4:		ier = dat; break;
		case 6:		mc = dat; break;
		case 7:		ctrl = dat; break;
		case 9:		cm1 = dat; break;
		case 10:	cm2 = dat; break;
		case 11:	cm3 = dat; break;
		case 12:	fc = dat; break;
		}
	}
	return 0;
}

int clsUart::TxPort()
{
	int d;

	if ((ls & 0x60)==0x60)
		d = 0xff;
	else
		d = tb;
	ls |= 0x60;
	if (ier & 2) {
		irq = true;
		system1.pic1.irqUart = true;
	}
	return d;
}

void clsUart::RxPort(unsigned int dat)
{
	if (ls & 1)
		ls |= 2;
	ls |= 1;
	if (ier & 1) {
		irq = true;
		system1.pic1.irqUart = true;
	}
}
