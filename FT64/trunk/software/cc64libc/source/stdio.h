#ifndef STDIO_H
#define STDIO_H

#ifndef YVALS_H
#include <yvals.h>
#endif

#define NULL	_NULL
#define _IOFBF	0
#define _IOLBF	1
#define _IONBF	2
#define BUFSIZ	512
#define EOF		-1
#define FILENAME_MAX	_FNAMAX
#define FOPEN_MAX		_FOPMAX
#define L_tmpnam		_TNAMX
#define TMP_MAX		32
#define SEEK_SET	0
#define SEEK_CUR	1
#define SEEK_END	2
#define stdin	_Files[0]
#define stdout	_Files[1]
#define stderr	_Files[2]
// type definitions
#ifndef _SIZET
#define _SIZET
typedef _Sizet size_t;
#endif
typedef struct {
	unsigned long _Off;
} fpos_t;
typedef struct {
	unsigned short _Mode;
	short _Handle;
	unsigned byte *_Buf, *_Bend, *_Next;
	unsigned byte *_Rend, *_Rsave, *_Wend;
	unsigned char _Back[2], _Cbuf, _Nback;
	char *_Tmpnam;
} FILE;
// declarations
void clearerr(FILE *f);
int fclose(FILE *f);
int feof(FILE *f);
int ferror(FILE *f);
int fflush(FILE *f);
int fgetc(FILE *f);
int fgetpos(FILE *f, fpos_t *p);
char *fgets(char *p, int n, FILE *f);
FILE *fopen(char *p, char *q);
int fprintf(FILE *f, char *);
int fputc(int n, FILE *f);
int fputs(char *p, FILE *f);
size_t fread(void *p, size_t n, size_t m, FILE *f);
FILE *freopen(char *p, char *q, FILE *f);
int fscanf(FILE *f, char *);
int fseek(FILE *f, long p, int n);
int fsetpos(FILE *f, fpos_t *p);
long ftell(FILE *f);
size_t fwrite(void *v, size_t n, size_t m, FILE *f);
int getc(FILE *f);
int getchar(void);
char *gets(char *p);
void perror(char *p);
int printf(char *p);
int putc(int n, FILE *f);
int putchar(int ch);
int puts(char *p);
int remove(char *n);
int rename(char *n);
void rewind(FILE *f);
int scanf(char *);
void setbuf(FILE *f, char *p);
int setvbuf(FILE *, char *, int, size_t);
int sprintf(char *p, char *q);
int sscanf(char *p, char *q);
FILE *tmpfile(void);
char *tmpnam(char *p);
int ungetc(int n, FILE *f);
int vfprintf(FILE *f, char *p, char *q);
int vprintf(char *p, char *q);
long _Fgpos(FILE *f, fpos_t *p);
int _Fspos(FILE *f, fpos_t *p, long n, int m);
extern FILE *_Files[FOPEN_MAX];

// Macro overrides
#define fgetpos(str, ptr)	(int)_Fgpos(str,ptr)
#define fseek(str,off,way)	_Fspos(str, _NULL, off, way)
#define fsetpos(str, ptr)	_Fspos(str, ptr, 0L, 0)
#define ftell(str)			_Fgpos(str, _NULL)
#define getc(str)			((str)->_Next < (str)->_Rend ? *(str)->_Next++ : (getc)(str))
//#define getchar()			(_Files[0]->_Next < _Files[0]->_Rend ? *_Files[0]->_Next++ : (getchar)())
#define putc(c,str)			((str)->_Next < (str)->_Wend ? (*(str)->_Next++ = c) : (putc)(c,str))
#define putchar(c)			(_Files[1]->_Next < _Files[1]->_Wend ? (*_Files[1]->_Next++ = c) : (putchar)(c))


pascal void putch(register char ch);
pascal void putnum(register int num, register int wid, register char sep, register char padchar);
pascal void puthexnum(register int num, register int wid, register int ul, register char padchar);
pascal int putstr(register char *p, register int max);
int getchar2( );

//int getchar( );
int printf(char *, ...);

#endif
