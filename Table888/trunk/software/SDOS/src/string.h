#ifndef STRING_H
#define STRING_H

byte *memcpy(byte *, byte *, int);
byte *memset(byte *, byte, int);
byte *memchr(byte *, byte, int);
int strlen(char *);
char *strcpy(char *, char *);
char *strncpy(char *, char *, int);
int strncmp(unsigned char *, unsigned char *, int);
char *strchr(char *, char, int);
int printf(char *, ...);

#endif
