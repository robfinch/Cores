#include "kernel\const.h"
#include "kernel\config.h"
#include "kernel\types.h"
#include "kernel\proto.h"
#include "kernel\glo.h"

extern pascal void putch(char ch);
extern pascal char ScreenToAscii(unsigned short int sc);
extern void printf();
extern char getchar();
extern int FMTK_StartTask(int,int,int (*)(),int,int);
extern int debugger_task();
extern pascal int prtdbl(double,int,int,char);
extern int sprite_main();
extern __leaf int isdigit(char);

int sh_linendx;
char sh_linebuf[100];
char sh_nextNonSpace();
char sh_getchar();

char sh_getchar()
{
  char ch;

  ch = -1;
  if (sh_linendx < 84) {
    ch = sh_linebuf[sh_linendx];
    sh_linendx++;
  }
  return ch;
}

char sh_nextNonSpace()
{
  char ch;

  while (sh_linendx < 84) {
    ch = sh_getchar();
    if (ch!=' ' || ch==-1)
      return ch;
  }
  return -1;
}


pascal int sh_getHexNumber(unsigned int *ad)
{
  char ch;
  unsigned int num;
  int nd;  // number of digits

  num = 0;
  nd = 0;
  sh_nextNonSpace();
  sh_linendx--;
  while (1) {
    ch = sh_getchar();
    if (ch >= '0' && (ch <= '9'))
      num = (num << 4) | (ch - '0');
    else if (ch >= 'A' && ch <= 'F')
      num = (num << 4) | (ch - 'A' + 10);
    else if (ch >= 'a' && ch <= 'f')
      num = (num << 4) | (ch - 'a' + 10);
    else {
      *ad = num;
      return nd;
    }
    nd = nd + 1;
  }    
}


pascal int sh_getDecNumber(int *n)
{
  int num;
  char ch;
  int nd;

  if (n==(int *)0) return 0;
  num = 0;
  nd = 0;
  while(isdigit(ch=sh_getchar())) {
    num = num * 10 + (ch - '0');
    nd++;
  }
  sh_linendx--;
  *n = num;
  return nd;
}



int sh_parse_line()
{
  char ch;
  int nd;
  int threadno;
  int (*ad)();
  int pri,cpu,parm,job;
  int info;

  ch = sh_getchar();
  switch (ch) {
  case 'd':
    info = (040 << 48) | (job << 32) | (cpu);
    FMTK_StartThread(debugger_task,8192,malloc(8192),null,info);
    break;
  case 't':
    DumpTaskList();
    return 0;
  case 'k':
    if ((ch=sh_getchar())=='i') {
      if ((ch = sh_getchar())=='l') {
        if ((ch = sh_getchar())=='l') {
        }
      }
    }
    nd = sh_getHexNumber(&threadno);
    if (nd > 0) {
      FMTK_KillThread(threadno);
    }
    return 0;
  case 'j':
    nd = sh_getHexNumber(&ad);
    if (nd > 0)
      (*ad)();
    break;   
  case 's':
    ch = sh_getchar();
    if (ch=='t') {
      nd = sh_getDecNumber(&pri);
      if (nd <= 0) break;
      nd = sh_getDecNumber(&cpu);
      if (nd <= 0) break;
      nd = sh_getHexNumber(&ad);
      if (nd <= 0) break;
      nd = sh_getHexNumber(&parm);
      if (nd <= 0) break;
      nd = sh_getHexNumber(&job);
      if (nd <= 0) break;
      info = (pri << 48) | (job << 32) | (cpu);
      FMTK_StartThread(ad,8192,malloc(8192),null,info);
    }
    break;        
  }
  return 0;
}

int sh_parse()
{
  sh_linendx = 0;
  if (sh_linebuf[0]=='$' &&& sh_linebuf[1]=='>')
    sh_linendx = 2;
  return sh_parse_line();
}


int shell()
{
  unsigned __int32 *screen;
  int nn;
  int row;
  int col;
  char ch;

  screen = (unsigned short int *)0xFFD00000;
  RequestIOFocus(ACBPtrs[1]);
  FMTK_StartTask(055,0,sprite_main,0,1);
  //printf("%10.6E",3.141592653589793238);
  forever {
    printf("\r\n$>");
    forever {
      ch = getchar();
      if (ch==0x0D)
        break;
      putch(ch);
    }
    row = dbg_GetCursorRow();
    col = dbg_GetCursorCol();
    for (nn = 0; nn < 80; nn++)
    sh_linebuf[nn] = ScreenToAscii(screen[row * 80 + nn] & 0x3ff);
    printf("%.80s", sh_linebuf);
    sh_parse();
  }
}
