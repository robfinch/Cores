#ifndef FLOAT_TRIPLE_H
#define FLOAT_TRIPLE_H

#include <inttypes.h>

typedef struct _tagFloatTriple {
    uint16_t exp;         // exponent
    uint16_t man1;
    uint16_t man2;
    uint16_t man3;
    uint16_t man4;
    uint16_t man5;
} FloatTriple;

#endif
