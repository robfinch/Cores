#ifndef _STRING_H
#define _STRING_H

#define null	0

naked char *memcpy(register char *d, register char *s, register int size);
naked int *memcpyW(register int *d, register int *s, register int size);
naked char *memset(register char *p, register char val, register int size);
naked int *memsetW(register int *p, register int val, register int size);
char *memchr(register char *p, register char val, register int n);
char *memmove(register char *dst, register char *src, register int count);
int *memmoveW(register int *dst, register int *src, register int count);
naked int strlen(register char *p);
char *strcpy(register char *d, register char *s);
char *strncpy(register char *d, register char *s, register int size);
int strncmp(register unsigned char *a, register unsigned char *b, register int len);
char *strchr(register char *p, register char val, register int n);

#endif
