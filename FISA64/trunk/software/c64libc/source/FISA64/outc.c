
void outc(unsigned int port, int value)
{
     asm {
        lw    r1,24[bp]
        lw    r2,32[bp]
        sc    r2,[r1]
     }
}
