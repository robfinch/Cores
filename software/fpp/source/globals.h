#ifndef GLOBALS_H
#define GLOBALS_H

#ifdef ALLOC
#  define E
#  define I(x) x
#else
#  define E extern
#  define I(x)
#endif

E char *identchars I(= "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@?0123456789");
extern SHashTbl HashInfo;   // Hash table for storing macro definitions
E char *inptr;              // pointer to current character in input buffer
E buf_t* inbuf;             // input buffer
extern int errors;          // number of errors that occurred
E int warnings;             // number of warnings
E FILE *fin, * ofp;         // current input and output file pointers
E FILE *fdbg;               // file pointer for debug info
E int verbose I(=0);
E int ShowLines I(=0);
E int debug I(= 0);
E int syntax I(= 0);        // stores the selected syntax
E int npass I(=0);          // number of passes to perform-1
E int collect I(=0);        // Tells the input to collect up lines of text for a macro
E int in_comment I(= 0);    // Indicates if the input is in a comment
extern int rep_def_cnt;     // Repeat block definition counter
extern int rept_inst;       // Repeat block instance counter
extern int inst;            // def instance counter
extern int mac_depth;       // nessted macro definition depth
extern int rep_depth;       // nested repeat instance depth
extern char *SkipComments();
extern int IfLevel;
extern int sub_pass;

#endif
