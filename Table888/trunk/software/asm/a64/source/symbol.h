#ifndef SYMBOL_H
#define SYMBOL_H

typedef struct {
    char name[128];
    int64_t value;
    char segment;
    char defined;
    char phaserr;
} SYM;

SYM *find_symbol(char *name);
SYM *new_symbol(char *name);
void DumpSymbols();

#endif
