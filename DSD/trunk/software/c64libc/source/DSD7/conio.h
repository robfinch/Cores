
naked inline void outw(register unsigned int port, register int value)
{
     asm {
        sw    r19,[r18]
     }
}
