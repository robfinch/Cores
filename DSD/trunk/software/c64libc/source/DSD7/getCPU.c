// Return the which CPU is active.

naked int getCPU()
{
     asm {
         cpuid r1,r0
         rts
     };
}
