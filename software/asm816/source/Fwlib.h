#ifndef FWLIB_H
#define FWLIB_H
/* -----------------------------------------------------------------------------

   Description :

   Returns :

   Examples :

   Changes
           Author      : R. Finch
           Date        : 92/
           Version     :
           Description : new module

----------------------------------------------------------------------------- */

#undef E
#ifdef ALLOC
#  define E
#  define I(x) x
#else
#  define E extern
#  define I(x)
#endif

#ifndef TRUE
#  define TRUE 1
#  define FALSE 0
#endif

#ifndef NULL
#  define NULL ((void *)0);
#endif

#define isoctal(d)   (((d) >= '0') && ((d) < '8'))

#define ALL    0
#define LINE   1
#define EOL    2

#define PUBLIC
#define PRIVATE   static

#define uint   unsigned int
#define ulong  unsigned long
#define ushort unsigned short
#define uchar  unsigned char

// Screen constants

#define FW_CLRSCREEN 0
#define FW_CLRWINDOW 1


// Field types

#define FW_tTEXT     0
#define FW_tCURRENCY 1
#define FW_tNUMERIC  2
#define FW_tDATE     3
#define FW_tBOOL     4  /* Boolean */
#define FW_tBOB      5  /* Binary object */.
#define FW_tCOUNT    6

struct scrn
{
   int *addr;
   int rows;
   int cols;
   int attr;
   int cx, cy; // cursor x and y position
};

typedef struct scrn stScreen;

struct scrn2
{
   int
      row,
      col,
      width,
      height;

   struct scrn2 *prev;
   int *body;
};

typedef struct scrn2 stScr;

typedef struct {
   unsigned char
      left, top,           // position
      width, height,       // size
      attr,
      nattr,
      mode,
      scrheight, scrwidth, // screen size
      cx, cy;              // cursor position
} STxInfo;

#  ifdef __cplusplus
extern "C" {
#  endif


void ShellSortPtr(void **, int, int (*)(void **, void **));       // Does a shellsort on pointers - like bsort()
void ShellSort(char *, size_t, size_t, int (*)(void *, void *));        // Does a shellsort - like bsort()
void QuickSort(void *, size_t, size_t, int (*)(void *, void *));  // Does a quick sort

void GetCurType(int *);
/*
int inpb(int);
int inpw(int);
void outpb(int, int);
void outpw(int, int);
*/
void SetCurType(int);

int InitDMAChannel(int, long, long, int);

void ClrBuf(int opt);
void ClrScr(int, int, int, int, int);
void ClrWnd(int);
long divl(long, int);
int ferr(char *,...);
char *FormatDollar(double, int);
void GetCurXY(int *, int *);
char *getfld(char *, int, int, int, int, char *);

void GetRTCDate(char *, char *, char *, char *, char *);
void GetRTCTime(char *, char *, char *, int *);
void GetTicks(void);

char *load(char *);
long modl(long, int);
void _outchar(char);
void _outtextf(char *, ...);
void PopScr(void);

void BorderWnd(char *);
void GetWndXY(int *, int *);
int PrintfWnd(char *, ...);
int PutchWnd(char, int);
void PutsWnd(char *);
void WndXY(int, int);

void BufMovTo(int, int);
int PrintfBuf(char *);
void PutsBuf(char *);
int PutchBuf(char);

void printv(FILE *, char **);

// memory buffer
void memswap(void *, void *, size_t);

int RdScrCh(int, int);
int WrScrCh(int, int, int, int);

//stScrStore far *StoreScr(int, int, int, int);
//void RestoreScr(stScrStore far *);

//stScr *PushScr(int, int, int, int);
int ScrAttr(int);
//stScreen *ScrChar(void);
void bcSetCursorPos(int, int);

void SetRTCDate(char *, char *, char *, char *, char *);
void SetRTCTime(char *, char *, char *, int);

//int sprintf(char *, char *, ...);

char *StrYears(double, char *);
char *rtrim(char *);

void WriteText(char *);

void WrScrStr(int, int, char *, int, int);

int sort(void *, unsigned int, unsigned int, int (*)());

int WinFerr(char *,...);

#ifdef  __cplusplus
};
#endif
#endif

