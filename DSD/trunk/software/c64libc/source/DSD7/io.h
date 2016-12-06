#ifndef _IO_H
#define _IO_H

naked inline int inh(register unsigned int port)
{
     asm {
		lh	  r1,[r18]
     }
}

naked inline int inhu(register unsigned int port)
{
     asm {
		lhu	  r1,[r18]
     }
}

naked inline int inw(register unsigned int port)
{
     asm {
		lw	  r1,[r18]
     }
}


naked inline void outc(register unsigned int port, register int value)
{
     asm {
        sh    r19,[r18]
     }
}

naked inline void outh(register unsigned int port, register int value)
{
     asm {
        sh    r19,[r18]
     }
}

naked inline void outw(register unsigned int port, register int value)
{
     asm {
        sw    r19,[r18]
     }
}

naked inline int getCPU()
{
	asm {
		csrrw	r1,#1,r0
	}
}

#endif
