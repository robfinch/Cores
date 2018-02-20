
void outh(unsigned int port, int value)
{
     asm {
        lw    r1,32[bp]
        lw    r2,40[bp]
        sh    r2,zs:[r1]
     }
}
