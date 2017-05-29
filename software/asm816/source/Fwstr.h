#ifndef FWSTR_H
#define FWSTR_H
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

long AsciiToBCD(char *);                  // Returns BCD value of ASCIIz string.
int *AsciiToUc(int *, char *);            // converts ASCIIz to unicode
void BCDToAscii(char *, long);            // Converts BCD value to ASCIIz string
char *BinToAscii(int, int);               // Converts character codes to ASCIIz string
int esc(char **);                         // map escape sequence to character code
//char *itoa(int, char *, int);             // Converts integer to ASCIIz string
//char *ltoa(long, char *, int);            // Converts long to ASCIIz string
char *ltrim(char *);                      // trims spaces from left of string
char *rtrim(char *);                      // trims spaces from right of string
char *trim(char *);                       // trims spaces from both left and right of string
char *strexpand(char *, char *);
//char *strdup(char *);                   // duplicates string
int strmat(const char *, const char *, ...);          // matches substrings within string
int strimat(const char *, const char *, ...);		  // case insensitive match
int strmcat(char *, int, ...);            // concatonates multiple strings
//unsigned long strtoul(char *, char **, int, int);
unsigned long stoul(char *, char **);     // convert string to unsigned long
uint64_t stouxl(const char *, const char **); // convert string to unsigned 64 bit
int *UcSet(int *, int, unsigned int);     // unicode strset
int UcPrintf(int *, int *, ...);          // unicode sprintf
int UcLen(int *);                         // unicode strlen
int *ucrev(int *);
char *UcToAscii(char *, int *);           // converts unicode to ASCIIz
//char *ultoa(unsigned long, char *, int);  // converts unsigned long to string
//char *utoa(unsigned int, char *, int);    // converts unsigned int to string

//void *memchr(const void *, int, size_t);
//int memcmp(const void *, const void *, size_t);
//void *memcpy(void *, const void *, size_t);
//void *memset(void *, int, size_t);
#ifdef  __cplusplus
};
#endif

#endif
