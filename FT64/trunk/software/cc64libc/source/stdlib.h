#ifndef _STDLIB
#define _STDLIB
#ifndef _YVALS
#include <yvals.h>
//#define _NULL	((void *)0)
//#define _Sizet	int
#endif


#define NULL	_NULL
#define EXIT_FAILURE	_EXFAIL
#define EXIT_SUCCESS	0
#define MB_CUR_MAX		_Mbcurmax
#define RAND_MAX		32767

#ifndef _SIZET
#define _SIZET
typedef _Sizet size_t;
#endif
#ifndef _WCHART
#define _WCHART
// wchar_t is a type in C64
//typedef _Wchart wchar_t;
#endif
typedef struct {
	int quot;
	int rem;
} div_t;
typedef struct {
	long quot;
	long rem;
} ldiv_t;
typedef int _Cmpfun(const void *, const void *);
typedef struct {
	unsigned char _State;
	unsigned short _Wchar;
} _Mbsave;


void abort(void);
int abs(register int);
int atexit(void (*)(void));
double atof(const char *);
int atoi(const char *);
long atol(const char *);
void bsearch(const void *, const void *, size_t, size_t, _Cmpfun *);
void *calloc(size_t, size_t);
div_t div(register int, register int);
void exit(int);
void free(void *);
char *getenv(const char *);
long labs(register long);
ldiv_t ldiv(register long, register long);
void *malloc(size_t);
int mblen(const char *, size_t);
size_t mbstowcs(wchar_t *,  const char *, size_t);
int mbtowc(wchar_t *, const char *, size_t);

//void qsort(void *, size_t, size_t, _Cmpfun *);

int rand(int);
void *realloc(void *, size_t);
void srand(register unsigned int);
double strtod(const char *, char **);
long strtol(const char *, char **, int);
unsigned long strtoul(const char *, char **, int);
int system(const char *);
size_t wcstombs(char *, const wchar_t *, size_t);
int wctomb(char *, wchar_t);
int _Mbtowc(wchar_t *, const char *, size_t, _Mbsave *);
double _Stod(const char *, char **);
unsigned long _Stoul(const char *, char **, int);
int _Wctomb(char *, wchar_t, char *);
extern char _Mbcurmax, _Wcxtomb;
extern _Mbsave _Mbxlen, _Mbxtowc;
extern unsigned long _Randseed;

#define atof(s)	_Stod(s, 0)
#define atoi(s)	(int)_Stoul(s,0,10)
#define atol(s)	(long)_Stoul(s,0,10)
#define mblen(s,n)	_Mbtowc(0,s,n,&_Mbxlen)
#define mbtowc(pwc,s,n)	_Mbtowc(pwc,s,n,&_Mbxtowc)
#define srand(seed)	(void)(_Randseed = (seed))
#define strtod(s,endptr)	_Stod(s, endptr)
#define strtoul(s, endptr, base)	_Stoul(s,endptr,base)
#define wctomb(s,wchar)	_Wctomb(s,wchar,&_Wcxtomb)
#endif
