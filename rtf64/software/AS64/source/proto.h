#pragma once

char *GetName(int);
void process_macro();
void doif();
void doifdef();
void doifndef();
void doelse();
void doendif();
bool IsNBit128(Int128&, Int128&);
void process_dcp();
void process_dcd();
void process_dct();
void process_dcw();
void process_dco();
// tokenizer
void getnum();
int my_isspace(char ch);
int isspaceOrDot(char ch);
int isFirstIdentChar(char ch);
int isIdentChar(char ch);
int need(int tk);
int expect(int tk);
void SkipSpaces();
void ScanToEOL();
int64_t radix36(char c);
void getbase(int b);
void getfrac();
void getexp();
int64_t getsch();
int getIdentifier();
void getString();
int isPseudoOp();
void SymbolInitForPass();
void rtf64_processMaster();
int rtf64_NextToken();

int64_t expr_def(int64_t* def);
