#ifndef CONFIG_H
#define CONFIG_H

// The following is the maximum number of chars the input will fetch at one time.
#define MAXLINE   4000

#define STRAREA   1000000

// The following controls the size of the hash table used to store symbols.
#define MAXMACROS 4001

// The maximum number of arguments associated with a macro.
#define MAX_MACRO_ARGS  100

// The following controls how many times the substituter will loop performing
// substitutions. It is a safety.
#define MAX_SUBS  10000

// (Not yet implemented)
// The following controls when the buffer is slid. If the input pointer is past
// this point, then the buffer will slide to reduce the memory footprint.
// Macro expansions are limited by this size.
#define SLIDE_SZ  4096

#endif
