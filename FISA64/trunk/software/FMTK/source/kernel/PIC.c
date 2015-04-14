
#define PIC               0xFFDC0FC0
#define PIC_IE            0xFFDC0FC4
#define PIC_ES            0xFFDC0FD0
#define PIC_RSTE          0xFFDC0FD4

// ----------------------------------------------------------------------------
// Get the vector base register
// ----------------------------------------------------------------------------

unsigned int *GetVBR()
{
    asm {
        mfspr r1,vbr
    }
}


// ----------------------------------------------------------------------------
// Set an IRQ vector
// The vector is checked for the two LSB's begin zero which is necessary
// for a code address.
// ----------------------------------------------------------------------------

void set_vector(unsigned int vecno, unsigned int rout)
{
     if (vecno > 511) return;
     if ((rout == 0) || ((rout & 3) != 0)) return;
     GetVBR()[vecno] = rout;
}

// ----------------------------------------------------------------------------
// 0 is highest priority, 15 is lowest
// 0    NMI (parity error)
// 1    Keyboard reset button
// 2    1024 Hz timer interrupt
// 3    30Hz timer interrupt
// ...
// 15   keyboard interrupt 
// 
// CPU #1 isn't wired to most IRQ's. There is no 1024Hz interrupt support.
// In fact the only interrupts supported on CPU #1 is the 30Hz time slice,
// parity NMI, and keyboard reset button.
// ----------------------------------------------------------------------------
void InitPIC()
{
     outh(PIC_ES, 0x000C);  //timer interrupt(s) are edge sensitive
     if (getCPU()==0)
          outh(PIC_IE, 0x000F);  //enable keyboard reset, timer interrupts
     else
          outh(PIC_IE, 0x000B);  //enable keyboard reset, timer interrupts
}

