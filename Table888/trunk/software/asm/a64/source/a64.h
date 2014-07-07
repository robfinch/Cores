#ifndef A64_H
#define A64_H

#include <inttypes.h>
#include "token.h"

enum {
    codeseg = 0,
    dataseg = 1,
    stackseg = 2,
    rodataseg = 3,
    tlsseg = 4,
    bssseg = 5,
    constseg = 6,
};

extern FILE *ofp, *vfp;
extern int64_t start_address;
extern char first_org;
extern int bGen;
extern int segment;

extern int gCpu;
extern char lastid[500];
extern char current_label[500];
extern int64_t last_icon;
extern int64_t ival;
extern char *inptr;
extern char *stptr;
extern int lineno;
extern int64_t code_address;
extern int64_t bss_address;
extern int segprefix;
extern char masterFile[10000000];
extern uint8_t binfile[10000000];
extern int binndx;
extern int binstart;


extern int64_t expr();
void Table888_processMaster();

#endif
