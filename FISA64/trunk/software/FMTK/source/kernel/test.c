#include "types.h"

__int16 readyQ[8];
TCB tcbs[256];

int iirl(int var, TCB *q)
{
    
    readyQ[var] = q - tcbs;
}
