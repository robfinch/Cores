
#include "FloatTriple.h"

FloatTriple FAC1;
FloatTriple FAC2;
FloatTriple E;

static void normalize(FloatTriple *FAC)
{
     while ((FAC->man1 & 0xC000 == 0xC000) || (FAC->man1 & 0xC000 == 0x0000)) {
        if (FAC->exp==0x0000)
            return;
        FAC->exp--;
        FAC->man1 << 1;
        FAC->man1 |= ((FAC->man2 >> 15) & 1);        
        FAC->man2 << 1;
        FAC->man2 |= ((FAC->man3 >> 15) & 1);
        FAC->man3 << 1;
        FAC->man3 |= ((FAC->man4 >> 15) & 1);
        FAC->man4 << 1;
        FAC->man4 |= ((FAC->man5 >> 15) & 1);
        FAC->man5 << 1;
     }
}

static void denormalize(FloatTriple *FAC)
{
    FAC->man5 >>= 1;
    FAC->man5 |= (FAC->man4 & 1) << 15;
    FAC->man4 >>= 1;
    FAC->man4 |= (FAC->man3 & 1) << 15;
    FAC->man3 >>= 1;
    FAC->man3 |= (FAC->man2 & 1) << 15;
    FAC->man2 >>= 1;
    FAC->man2 |= (FAC->man1 & 1) << 15;
    FAC->man1 >>= 1;
    if (FAC->man1 & 0x4000)
       FAC->man1 |= 0x8000;
    FAC->exp++;
}

static uint32_t add()
{
     uint32_t temp;

     temp = FAC1.man5 + FAC2.man5;
     FAC1.man5 = temp & 0xffff;
     temp = FAC1.man4 + FAC2.man4 + ((temp >> 16) & 1);
     FAC1.man4 = temp & 0xffff;
     temp = FAC1.man3 + FAC2.man3 + ((temp >> 16) & 1);
     FAC1.man3 = temp & 0xffff;
     temp = FAC1.man2 + FAC2.man2 + ((temp >> 16) & 1);
     FAC1.man2 = temp & 0xffff;
     temp = FAC1.man1 + FAC2.man1 + ((temp >> 16) & 1);
     FAC1.man1 = temp & 0xffff;
     return temp;
}

static uint32_t neg(FloatTriple *FAC)
{
     uint32_t temp;

     FAC->man5 ^= 0xffff;
     FAC->man4 ^= 0xffff;
     FAC->man3 ^= 0xffff;
     FAC->man2 ^= 0xffff;
     FAC->man1 ^= 0xffff;
     temp = FAC->man5 + 1;
     FAC->man5 = temp & 0xffff;
     temp = FAC->man4 + ((temp >> 16) & 1);
     FAC->man4 = temp & 0xffff;
     temp = FAC->man3 + ((temp >> 16) & 1);
     FAC->man3 = temp & 0xffff;
     temp = FAC->man2 + ((temp >> 16) & 1);
     FAC->man2 = temp & 0xffff;
     temp = FAC->man1 + ((temp >> 16) & 1);
     FAC->man1 = temp & 0xffff;
}

// FAC2 - FAC1

void FTSub()
{
     neg(&FAC1);
     FTAdd();
}

void FTAdd()
{
     uint32_t tmp;   // used to detect carry
     int sign1,sign2;

     if (FAC1.exp - FAC2.exp > 80)
         return;
     if (FAC2.exp - FAC1.exp > 80) {
         FAC1.exp = FAC2.exp;
         FAC1.man1 = FAC2.man1;
         FAC1.man2 = FAC2.man2;
         FAC1.man3 = FAC2.man3;
         FAC1.man4 = FAC2.man4;
         FAC1.man5 = FAC2.man5;
         return ;
     }
     while (FAC1.exp > FAC2.exp)
         denormalize(&FAC2);
     while (FAC1.exp < FAC2.exp)
         denormalize(&FAC1);
     sign1 = FAC1.man1 & 0x8000;
     sign2 = FAC2.man1 & 0x8000;
     // exponents are now equal
     tmp = add();
     // check for overflow, can only happen if adding and signs the same
     if (sign1==sign2) {
         if ((FAC1.man1 & 0x8000) != sign1) { // sign of result is different
             denormalize(&FAC1);
             FAC1.man1 &= 0x7fff;
             FAC1.man1 |= ((tmp >> 1) & 0x8000);     // add in carry bit
             return;
         }
     }
     normalize(&FAC1);
}

void FTMultiply()
{
    uint32_t temp;
    int sign;
    int count;
    int doAdd;

    sign = FAC1.man1 ^ FAC2.man1;
    temp = FAC1.exp + FAC2.exp;
    // Check for overflow
    if (temp >> 16) {
        FAC1.exp = 0xffff;
        if (sign & 0x8000) {
            FAC1.man1 = 0x8000;
            FAC1.man2 = 0x0000;
            FAC1.man3 = 0x0000;
            FAC1.man4 = 0x0000;
            FAC1.man5 = 0x0000;
        }
        else {
            FAC1.man1 = 0x7FFF;
            FAC1.man2 = 0xFFFF;
            FAC1.man3 = 0xFFFF;
            FAC1.man4 = 0xFFFF;
            FAC1.man5 = 0xFFFF; 
        }
        return;
    }
    // Make operands positive
    if (FAC1.man1 & 0x8000)
       neg(&FAC1);
    if (FAC2.man1 & 0x8000)
       neg(&FAC2);
    E.exp = FAC1.exp;
    E.man1 = FAC1.man1;
    E.man2 = FAC1.man2;
    E.man3 = FAC1.man3;
    E.man4 = FAC1.man4;
    E.man5 = FAC1.man5;
    FAC1.exp = temp & 0xffff;
    FAC1.man1 = 0;
    FAC1.man2 = 0;
    FAC1.man3 = 0;
    FAC1.man4 = 0;
    FAC1.man5 = 0;
    for (count = 79; count >= 0; count--) {
        doAdd = E.man5 & 1;
        E.man5 >> 1;
        E.man5 |= (E.man4 & 1) << 15;
        E.man4 >> 1;
        E.man4 |= (E.man3 & 1) << 15;
        E.man3 >> 1;
        E.man3 |= (E.man2 & 1) << 15;
        E.man2 >> 1;
        E.man2 |= (E.man1 & 1) << 15;
        E.man1 >> 1;
        E.man1 |= (FAC1.man5 & 1) << 15;
        FAC1.man5 >>= 1;
        FAC1.man5 |= (FAC1.man4 & 1) << 15;
        FAC1.man4 >>= 1;
        FAC1.man4 |= (FAC1.man3 & 1) << 15;
        FAC1.man3 >>= 1;
        FAC1.man3 |= (FAC1.man2 & 1) << 15;
        FAC1.man2 >>= 1;
        FAC1.man2 |= (FAC1.man1 & 1) << 15;
        FAC1.man1 >>= 1;
        if (doAdd)
            add();
    }
    // Correct the sign
    if (sign & 0x8000)
       neg(&FAC1);    
    normalize(&FAC1);
}
