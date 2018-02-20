#ifndef _IO_H
#define _IO_H

naked inline int in8(register unsigned int port)
{
     asm {
		lvb	  r1,[r18]
     }
}

naked inline int in8u(register unsigned int port)
{
     asm {
		lvbu  r1,[r18]
     }
}

naked inline int in16(register unsigned int port)
{
     asm {
		lvc	  r1,[r18]
     }
}

naked inline int in16u(register unsigned int port)
{
     asm {
		lvcu  r1,[r18]
     }
}

naked inline int in32(register unsigned int port)
{
     asm {
		lvh  r1,[r18]
     }
}

naked inline int in32u(register unsigned int port)
{
     asm {
		lvhu  r1,[r18]
     }
}

naked inline void out8(register unsigned int port, register int value)
{
     asm {
        sb     r19,[r18]
     }
}

naked inline void out16(register unsigned int port, register int value)
{
     asm {
        sc    r19,[r18]
     }
}

naked inline void out32(register unsigned int port, register int value)
{
     asm {
        sh    r19,[r18]
     }
}

naked inline int getCPU()
{
	asm {
		csrrd	r1,#1,r0
	}
}

#endif
