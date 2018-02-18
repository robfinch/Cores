#include "types.h"

char buf[20];
__int8 getbyte() { return 1 };

int iirl(int var, TCB *q)
{
    unsigned __int8 sc;
        
    sc = getbyte();
    switch(sc) {
    case 1:
         printf("hi1",sc);
         break;
    case 2:
         printf("hi2",sc);
         break;
    case 3:
         printf("hi2",sc);
         break;
    case 4:
         printf("hi2",sc);
         break;
    case 5:
         printf("hi2",sc);
         break;
    case 6:
         printf("hi2",sc);
         printf(buf[sc]);
         printf(buf[sc]);
         printf(buf[sc]);
         printf(buf[sc]);
         printf(buf[sc]);
         break;
    }
}
