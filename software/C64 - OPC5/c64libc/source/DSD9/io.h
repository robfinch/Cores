#ifndef _IO_H
#define _IO_H

naked inline int in8(register unsigned int port)
{
     asm {
		ldb	  r1,[r18]
     }
}

naked inline int in8u(register unsigned int port)
{
     asm {
		ldbu  r1,[r18]
     }
}

naked inline int in16(register unsigned int port)
{
     asm {
		ldw	  r1,[r18]
     }
}

naked inline int in16u(register unsigned int port)
{
     asm {
		ldwu  r1,[r18]
     }
}

naked inline int in32(register unsigned int port)
{
     asm {
		ldt	  r1,[r18]
     }
}

naked inline int in32u(register unsigned int port)
{
     asm {
		ldtu  r1,[r18]
     }
}

naked inline void out8(register unsigned int port, register int value)
{
     asm {
        stb    r19,[r18]
     }
}

naked inline void out16(register unsigned int port, register int value)
{
     asm {
        stw   r19,[r18]
     }
}

naked inline void out32(register unsigned int port, register int value)
{
     asm {
        stt   r19,[r18]
     }
}

naked inline int getCPU()
{
	asm {
		csrrw	r1,#1,r0
	}
}

#endif
