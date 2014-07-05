#ifndef A64_H
#define A64_H

#include <inttypes.h>
#include "token.h"

extern char lastid[500];
extern char current_label[500];
extern int64_t last_icon;
extern int64_t ival;
extern char *inptr;
extern char *stptr;
extern int lineno;

extern int64_t expr();

#endif
