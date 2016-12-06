#include "C:\Cores4\DSD\trunk\software\c64libc\source\DSD7\io.h"

#define PIC               0xFFDC0FC0
#define PIC_IE            0xFFDC0FC2
#define PIC_ES            0xFFDC0FC8
#define PIC_RSTE          0xFFDC0FCA

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
     outw(PIC_ES, 0x4000000C);  //timer interrupt(s) are edge sensitive
     if (getCPU()==1)
          outw(PIC_IE, 0xC000000F);  //enable keyboard reset, timer interrupts
     else
          outw(PIC_IE, 0x4000000B);  //enable keyboard reset, timer interrupts
}

