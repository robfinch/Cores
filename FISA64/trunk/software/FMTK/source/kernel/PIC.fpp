
// Get the vector base register

unsigned int *GetVBR()
{
    asm {
        mfspr r1,vbr
    }
}


// Set an IRQ vector
// The vector is checked for the two LSB's begin zero which is necessary
// for a code address.

void set_vector(unsigned int vecno, unsigned int rout)
{
     if (vecno > 511) return;
     if ((rout == 0) || ((rout & 3) != 0)) return;
     GetVBR()[vecno] = rout;
}
