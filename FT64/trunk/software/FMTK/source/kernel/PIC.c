#include "C:\Cores4\DSD\DSD9\trunk\software\c64libc\source\DSD9\io.h"

#define PIC               0xFFDC0F00
#define PIC_IE            0xFFDC0F04
#define PIC_ES            0xFFDC0F10
#define PIC_RSTE          0xFFDC0F14

extern int interrupt_table[512];

// ----------------------------------------------------------------------------
// Set an IRQ vector
// The vector is checked for the two LSB's begin zero which is necessary
// for a code address.
// ----------------------------------------------------------------------------

pascal void set_vector(register unsigned int vecno, register unsigned int rout)
{
     if (vecno > 511) return;
     if (rout == 0) return;
     interrupt_table[vecno] = rout;
}

// ----------------------------------------------------------------------------
// 0 is highest priority, 31 is lowest
// 0    NMI (parity error)
// 1    Keyboard reset button
// 2    1024 Hz timer interrupt
// 3    30Hz timer interrupt
// ...
// 31   keyboard interrupt 
// 
// CPU #1 isn't wired to most IRQ's. There is no 1024Hz interrupt support.
// In fact the only interrupts supported on CPU #1 is the 30Hz time slice,
// parity NMI, and keyboard reset button.
// ----------------------------------------------------------------------------
void InitPIC()
{
	 int n;
	 for (n = 0; n < 32; n = n + 1)
		 out32(PIC+0x80+(n<<2),4);	// set interrupt level 4
     out32(PIC_ES, 0x4000000C);  //timer interrupt(s) are edge sensitive
     if (getCPU()==1)
          out32(PIC_IE, 0xC0000000);  //enable keyboard reset, timer interrupts
     else
          out32(PIC_IE, 0x4000000B);  //enable keyboard reset, timer interrupts
}

