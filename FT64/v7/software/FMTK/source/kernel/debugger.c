#include <fmtk/const.h>
#include <fmtk/device.h>

extern pascal void set_vector(int, unsigned int);
extern void dbg_printf(char *,...);
extern __int8 DBGCursorRow;
extern __int8 DBGCursorCol;
extern int linendx;
extern char linebuf[96];
extern unsigned int dbg_dbctrl;
extern unsigned int regfile[32];
//unsigned int cr0save;
extern int ssm;
extern int repcount;
extern unsigned int curaddr;
extern unsigned int cursz;
extern unsigned int curfill;
extern char curfmt;
extern unsigned int currep;
extern unsigned int muol;    // max units on line
extern unsigned byte *bmem;
extern unsigned char *cmem;
extern unsigned short int *hmem;
extern unsigned int *wmem;


static void dbg_DisplayHelp()
{
   dbg_printf("\r\n'?' queries the status of a breakpoint register as in:");
   dbg_printf("\r\nDBG>i2?");
   dbg_printf("\r\nFollowing a breakpoint register with an '=' assigns ");
   dbg_printf("\r\nan address to it.");
   dbg_printf("\r\nDBG>i1=12345678     will assign 12345678 to i1");
   dbg_printf("\r\nThere are a total of four breakpoint registers (0-3).");
   dbg_printf("\r\nPrefix the register number with an 'i' to indicate an");
   dbg_printf("\r\ninstruction breakpoint or a 'd' to indicate a data");
   dbg_printf("\r\nbreakpoint. Prefix the register number with 'ds' to");
   dbg_printf("\r\nindicate a data store only breakpoint.");
   dbg_printf("\r\nSetting a register to zero will clear the breakpoint.");
   dbg_printf("\r\nOnce the debug registers are set it is necessary to ");
   dbg_printf("\r\narm debugging mode using the 'a' command.");
   dbg_printf("\r\nType 'q' to quit.");
   dbg_printf("\r\nDBG>");
}


byte DBGGetCursorRow()
{
	return (DBGCursorRow);
}

byte DBGGetCursorCol()
{
	return (DBGCursorCol);
}

pascal unsigned int dbg_GetDBAD(int r)
{
  switch(r) {
  case 0: __asm { csrrd  r1,#$018,r0  } break;
  case 1: __asm { csrrd  r1,#$019,r0  } break;
  case 2: __asm { csrrd  r1,#$01A,r0  } break;
  case 3: __asm { csrrd  r1,#$01B,r0  } break;
  return (0);
  }
}

pascal void dbg_SetDBAD(int r, unsigned int ad)
{
     switch(r) {
     case 0: asm {
          lw    r1,40[fp]
          csrrw	r0,#$018,r1
          }
          break;
     case 1: asm {
          lw    r1,40[fp]
          csrrw	r0,#$019,r1
          }
          break;
     case 2: asm {
          lw    r1,40[fp]
          csrrw	r0,#$01A,r1
          }
          break;
     case 3: asm {
          lw    r1,40[fp]
          csrrw	r0,#$01B,r1
          }
          break;
     }
}

pascal void dbg_arm(unsigned int dbg_dbctrl)
{
   __asm {
     lw    r1,32[fp]
     crsrw	r0,#$01C,r1	; dbg_ctrl
   }
}

char dbg_getchar2()
{
   char ch;
   
   ch = -1;
   if (linendx < 48) {
     ch = linebuf[linendx];
     linendx++;
   }
   return ch;
}

void ignore_blanks()
{
   char ch;
   
   do {
     ch = linebuf[linendx];
     linendx++;
   } while (ch == ' ');
}

void dbg_ungetch()
{
   if (linendx > 0)
     linendx--;
}

char dbg_nextNonSpace()
{
   char ch;

   while (linendx < 48) {
     ch = dbg_getchar2();
     if (ch!=' ' || ch==-1)
         return ch;
   }
   return -1;
}

char dbg_nextSpace()
{
  char ch;

  do {
    ch = dbg_getchar2();
    if (ch==-1)
         break;
  } while (ch != ' ');
  return ch;
}

pascal int dbg_getHexNumber(unsigned int *ad)
{
	char ch;
	unsigned int num;
	int nd;  // number of digits

	num = 0;
	nd = 0;
	dbg_nextNonSpace();
	linendx--;
	while (1) {
		ch = dbg_getchar2();
		if (ch >= '0' && ch <= '9')
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


// Instruction breakpoint

pascal void dbg_ReadSetIB(unsigned int n)
{
   char ch;
   unsigned int ad;


   ch = dbg_nextNonSpace();

   if (ch=='=') {
       if (dbg_getHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbg_dbctrl |= (1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
       }
       else {
           dbg_SetDBAD(n,0);
           dbg_dbctrl &= ~(1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
       }
   }
   else if (ch=='?') {
      if (((dbg_dbctrl & (0x030000 << (n << 1)))==0) && (dbg_dbctrl & (1 << n) == (1 << n)))
          dbg_printf("\r\nDBG>i%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          dbg_printf("\r\nDBG>i%d <not set>", n);
   }
}

// Data load or store breakpoint

pascal void dbg_ReadSetDB(unsigned int n)
{
   char ch;
   unsigned int ad;

   if (n > 3) return;
   ch = dbg_nextNonSpace();
   if (ch=='=') {
       if (dbg_getHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbg_dbctrl |= (1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
           dbg_dbctrl |= 0x30000 << (n << 1);
       }
       else {
           dbg_SetDBAD(n,0);
           dbg_dbctrl &= ~(1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
       }
   }
   else if (ch=='?') {
      if ((dbg_dbctrl & (0x030000 << (n << 1)))==(0x030000 << (n << 1)) && (dbg_dbctrl & (1 << n) == (1 << n)))
          dbg_printf("\r\nDBG>d%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          dbg_printf("\r\nDBG>d%d <not set>", n);
   }
}

// Data store breakpoint

pascal void dbg_ReadSetDSB(unsigned int n)
{
   char ch;
   unsigned int ad;

   if (n > 3) return;
   ch = dbg_nextNonSpace();
   if (ch=='=') {
       if (dbg_getHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbg_dbctrl |= (1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
           dbg_dbctrl |= 0x10000 << (n << 1);
       }
       else {
           dbg_SetDBAD(n,0);
           dbg_dbctrl &= ~(1 << n);
           dbg_dbctrl &= ~(0x30000 << (n << 1));
       }
   }
   else if (ch=='?') {
      if ((dbg_dbctrl & (0x030000 << (n << 1)))==(0x010000 << (n << 1)) && (dbg_dbctrl & (1 << n) == (1 << n)))
          dbg_printf("\r\nDBG>ds%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          dbg_printf("\r\nDBG>ds%d <not set>", n);
   }
}

static void DispRegs()
{
     dbg_printf("\r\nr1=%X r2=%X r3=%X r4=%X\r\n", regfile[1], regfile[2], regfile[3], regfile[4]);
     dbg_printf("r5=%X r6=%X r7=%X r8=%X\r\n", regfile[5], regfile[6], regfile[7], regfile[8]);
     dbg_printf("r9=%X r10=%X r11=%X r12=%X\r\n", regfile[9], regfile[10], regfile[11], regfile[12]);
     dbg_printf("r13=%X r14=%X r15=%X r16=%X\r\n", regfile[13], regfile[14], regfile[15], regfile[16]);
     dbg_printf("r17=%X r18=%X r19=%X r20=%X\r\n", regfile[17], regfile[18], regfile[19], regfile[20]);
     dbg_printf("r21=%X r22=%X r23=%X tr=%X\r\n", regfile[21], regfile[22], regfile[23], regfile[24]);
     dbg_printf("r25=%X r26=%X r27=%X r28=%X\r\n", regfile[25], regfile[26], regfile[27], regfile[28]);
     dbg_printf("r29=%X sp=%X lr=%X\r\n", regfile[29], regfile[30], regfile[31]);
}

static pascal void DispReg(int r)
{
     dbg_printf("r%d=%X\r\n", r, regfile[r]);
}

void dbg_prompt()
{
     dbg_printf("\r\nDBG>");
}

pascal int dbg_getDecNumber(int *n)
{
    int num;
    char ch;
    int nd;

    if (n==(int *)0) return 0;
    num = 0;
    nd = 0;
     while(isdigit(ch=dbg_getchar2())) {
        num = num * 10 + (ch - '0');
        nd++;
    }
    linendx--;
    *n = num;
    return nd;
}

void dbg_processReg()
{
     char ch;
     int regno;
     unsigned int val;
     int nd;

     ch = dbg_getchar2();
     switch(ch) {
     case '?': DispRegs(); break;
     default:
         if (isdigit(ch)) {
             linendx--;
             regno = dbg_getDecNumber();
             ch = dbg_nextNonSpace();
             switch(ch) {
             case '?':
                  DispReg(regno);
                  return;
             case '=':
                  nd = dbg_getHexNumber(&val);  
                  if (nd > 0) {
                         regfile[regno] = val;
                  }
                  return;
             default:
                  return;
             }
         }
         return;
     }
}

int dbg_parse_begin()
{
    linendx = 0;
    if (linebuf[0]=='D' && linebuf[1]=='B' && linebuf[2]=='G' && linebuf[3]=='>')
        linendx = 4;
    return dbg_parse_line();
}

void dbg_getDumpFormat()
{
     int nn;
     char ch;
     unsigned int ui;
     unsigned int ad;

     nn = dbg_getDecNumber(&ui);
     if (nn > 0) currep = ui;
     ch = dbg_getchar2();
     switch(ch) {
     case 'i':
          curfmt = 'i';
          nn = dbg_getHexNumber(&ad);
          if (nn > 0)
              curaddr = ad;
          break;
     case 's':
          curfmt = 's';
          nn = dbg_getHexNumber(&ad);
          if (nn > 0)
             curaddr = ad;
          break;
     case 'x':
          curfmt = 'x';
          ch = dbg_getchar2();
          switch(ch) {
          case 'b': cursz = 'b'; muol = 16; break;
          case 'c': cursz = 'c'; muol = 8; break;
          case 'h': cursz = 'h'; muol = 4; break;
          case 'w': cursz = 'w'; muol = 2; break;
          default: linendx--;
          }
          nn = dbg_getHexNumber(&ad);
          if (nn > 0) curaddr = ad;
          break;
     }
}

int dbg_parse_line()
{
    char ch;
    unsigned int ad;
    unsigned int ln;
    unsigned int regno;
    unsigned int ui;
    int nn;
    int n2;

    while (linendx < 84) {
        ch = dbg_getchar2();
        switch (ch) {
        case -1: return;
        case ' ': break;
        case '?': dbg_DisplayHelp(); break;
        case 'q': return 1;
        case 'a': dbg_arm(dbg_dbctrl); break;
        case 'i':
             ch = dbg_getchar2();
             switch(ch) {
             case '?':  // query instruction breakpoints
                  if (((dbg_dbctrl & 0x030000)==0) && (dbg_dbctrl & 1) == 1)
                      dbg_printf("i0=%08X\r\n", dbg_GetDBAD(0));
                  if (((dbg_dbctrl & 0x300000)==0) && (dbg_dbctrl & 2) == 2)
                      dbg_printf("i1=%08X\r\n", dbg_GetDBAD(1));
                  if (((dbg_dbctrl & 0x3000000)==0) && (dbg_dbctrl & 4) == 4)
                      dbg_printf("i2=%08X\r\n", dbg_GetDBAD(2));
                  if (((dbg_dbctrl & 0x30000000)==0) && (dbg_dbctrl & 8) == 8)
                      dbg_printf("i2=%08X\r\n", dbg_GetDBAD(3));
                  break;
             case '0':  dbg_ReadSetIB(0); break;
             case '1':  dbg_ReadSetIB(1); break;
             case '2':  dbg_ReadSetIB(2); break;
             case '3':  dbg_ReadSetIB(3); break;
             }
             break;
        case 'd':
             ch = dbg_getchar2();
             switch(ch) {
             case 'i':
                  dbg_nextSpace();
                  nn = dbg_getHexNumber(&ad);
                  if (nn > 0) {
                      n2 = dbg_getDecNumber(&ln);
                      if (n2 > 0) {
                          for (; n2 > 0; n2--)
                              disassem(&ad,0);
                      }
                      else
                          disassem20(ad,0);
                  }
                  break;
             case '?':  // query instruction breakpoints
                  dbg_printf("\r\n");
                  if (((dbg_dbctrl & 0x030000)==0x30000) && (dbg_dbctrl & 1) == 1)
                      dbg_printf("d0=%08X\r\n", dbg_GetDBAD(0));
                  if (((dbg_dbctrl & 0x300000)==0x300000) && (dbg_dbctrl & 2) == 2)
                      dbg_printf("d1=%08X\r\n", dbg_GetDBAD(1));
                  if (((dbg_dbctrl & 0x3000000)==0x3000000) && (dbg_dbctrl & 4) == 4)
                      dbg_printf("d2=%08X\r\n", dbg_GetDBAD(2));
                  if (((dbg_dbctrl & 0x30000000)==0x30000000) && (dbg_dbctrl & 8) == 8)
                      dbg_printf("d2=%08X\r\n", dbg_GetDBAD(3));
                  break;
              case '0':  dbg_ReadSetDB(0); break;
              case '1':  dbg_ReadSetDB(1); break;
              case '2':  dbg_ReadSetDB(2); break;
              case '3':  dbg_ReadSetDB(3); break;
              case 's':
                  ch = dbg_getchar2();
                  switch(ch) {
                  case '?':
                      if (((dbg_dbctrl & 0x030000)==0x10000) && (dbg_dbctrl & 1) == 1)
                          dbg_printf("ds0=%08X\r\n", dbg_GetDBAD(0));
                      if (((dbg_dbctrl & 0x300000)==0x100000) && (dbg_dbctrl & 2) == 2)
                          dbg_printf("ds1=%08X\r\n", dbg_GetDBAD(1));
                      if (((dbg_dbctrl & 0x3000000)==0x1000000) && (dbg_dbctrl & 4) == 4)
                          dbg_printf("ds2=%08X\r\n", dbg_GetDBAD(2));
                      if (((dbg_dbctrl & 0x30000000)==0x10000000) && (dbg_dbctrl & 8) == 8)
                          dbg_printf("ds2=%08X\r\n", dbg_GetDBAD(3));
                      break;
                  case '0':  dbg_ReadSetDSB(0); break;
                  case '1':  dbg_ReadSetDSB(1); break;
                  case '2':  dbg_ReadSetDSB(2); break;
                  case '3':  dbg_ReadSetDSB(3); break;
                  }
                  break;
              default:
                  dbg_nextSpace();
                  dbg_SetDBAD(0,0);
                  dbg_SetDBAD(1,0);
                  dbg_SetDBAD(2,0);
                  dbg_SetDBAD(3,0);
                  dbg_arm(0);
                  break;
             }
             break;
        case 'r': dbg_processReg(); break;
        case 's':
             ch = dbg_getchar2();
             if (ch=='s') {
                  ch = dbg_getchar2();
                  if (ch=='-') {
                      dbg_dbctrl &= 0x3FFFFFFFFFFFFFFFL;
                      dbg_arm(dbg_dbctrl);
                      ssm = 0;
                  }
                  else if (ch=='+' || ch=='m') {
                      dbg_dbctrl |= 0x4000000000000000L;                 
                      dbg_arm(dbg_dbctrl);
                      ssm = 1;
                      return 1;
                  }
             }
             break;
        case 'f':
             ch = dbg_getchar2();
             if (ch=='/')
                 dbg_getDumpFormat();
             ch = dbg_getchar2();
             if (ch==',') {
                 if (curfmt=='x')
                     nn = dbg_getHexNumber(&ui);
                 else
                     nn = dbg_getDecNumber(&ui);
                 if (nn > 0)
                     curfill = ui;
             }
             switch(curfmt) {
             case 'x':
                  switch(cursz) {
                  case 'b':
                       for (nn = 0; nn < currep; nn++)
                           bmem[ad+nn] = curfill;
                       break;
                  case 'c':
                       for (nn = 0; nn < currep; nn++)
                           cmem[ad/2+nn] = curfill;
                       break;
                  case 'h':
                       for (nn = 0; nn < currep; nn++)
                           hmem[ad/4+nn] = curfill;
                       break;
                  case 'w':
                       for (nn = 0; nn < currep; nn++)
                           wmem[ad/8+nn] = curfill;
                       break;
                  }
             }
             break;
        case 'x':
             ch = dbg_getchar2();
             if (ch=='/') {
                 dbg_getDumpFormat();
             }
             switch(curfmt) {
             case 'i':
                  dbg_printf("\r\n");
                  for (nn = 0; nn < currep; nn++) {
                      if (getcharNoWait()==3)
                         break;
                      disassem(&curaddr,0);
                  }
                  break;
             case 's':
                  for (nn = 0; nn < currep; nn++) {
                      if (getcharNoWait()==3)
                         break;
                      curaddr += putstr(&cmem[curaddr/2],84) * 2;
                      dbg_printf("\r\n");
                  }
                  break;
             case 'x':
                  for (nn = 0; nn < currep; nn++) {
                      if (getcharNoWait()==3)
                         break;
                      if ((nn % muol)==0) {
                          switch(cursz) {
                          case 'b': dbg_printf("\r\n%06X ", curaddr+nn); break;
                          case 'c': dbg_printf("\r\n%06X ", curaddr+nn*2); break;
                          case 'h': dbg_printf("\r\n%06X ", curaddr+nn*4); break;
                          case 'w': dbg_printf("\r\n%06X ", curaddr+nn*8); break;
                          }
                      }
                      asm {; right here ; };
                      switch(cursz) {
                      case 'b': dbg_printf("%02X ", bmem[curaddr+nn]); break;
                      case 'c': dbg_printf("%04X ", cmem[curaddr/2+nn]); break;
                      case 'h': dbg_printf("%08X ", hmem[curaddr/4+nn]); break;
                      case 'w': dbg_printf("%016X ", wmem[curaddr/8+nn]); break;
                      }
                  }
                  switch(cursz) {
                  case 'b': curaddr += nn; break;
                  case 'c': curaddr += nn * 2; break;
                  case 'h': curaddr += nn * 4; break;
                  case 'w': curaddr += nn * 8; break;
                  }
                  dbg_printf("\r\n");
                  break;
             }
        }
    }
    return 0;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

int debugger_task()
{
    debugger(0,0);
    return 0;
}

void debugger(unsigned int ad, unsigned int ctrlreg)
{
     char ch;
     int row, col;
     unsigned int *screen;
     int nn;
     
     dbg_dbctrl = ctrlreg;
     screen = (unsigned int *)0xFFFFFFFFFFD00000L;
     ad = ad & 0xFFFFFFFFFFFFFFFEL;
     if (ad)
        disassem24(ad-16,ad);
     forever {
         dbg_printf("\r\nDBG>");
         do {
              ch = DBGGetKey(1);
              if (ssm) {
                  if (ch=='s') {
                     dbg_dbctrl &= 0x3FFFFFFFFFF0FFFEL;  // turn off a breakpoint
                     dbg_dbctrl |= 0x4000000000000000L;   // turn single step mode back
                     dbg_arm(dbg_dbctrl);                 // on on return
                     return;
                  }
                  if (ch=='-' || ch==3) {
                      ssm = 0;
                      dbg_dbctrl &= 0x3FFFFFFFFFFFFFFFL;
                      dbg_arm(dbg_dbctrl);
                      return;
                  }
                  if (ch=='n') {
                      ssm = 2;
                      dbg_dbctrl &= 0x3FFFFFFFFFF0FFFFL;  // turn off single step mode
                      dbg_dbctrl |= 0x80001;              // and set a breakpoint
                      if (((bmem[ad] & 0x7f)==0x7c) and ((bmem[ad+4] & 0x7f)==0x7c))
                          ad += 12;
                      else if ((bmem[ad] & 0x7f)==0x7c)
                          ad += 8;
                      else
                          ad += 4;
                      dbg_SetDBAD(0,ad);            // for the next address
                      dbg_arm(dbg_dbctrl);
                      return;
                  }
              }
              else {
                  if (ch == 0x0d)
                      break;
                  if (ch== 0x0C) // CTRL-L
                  {
                       DBGClearScreen();
                       DBGHomeCursor();
                       break;
                  }
                  DBGDisplayChar(ch);
              }
         } while (1);
         row = DBGGetCursorRow();
         col = DBGGetCursorCol();
         for (nn = 0; nn < 48; nn++)
             linebuf[nn] = screen[__mulf(row, 48) + nn] & 0xff;
         if (dbg_parse_begin()==1)
             break;
     }     
}

void dbg_init()
{
   ssm = 0;
   bmem = (unsigned byte *)0;
   cmem = (unsigned char *)0;
   hmem = (unsigned short int *)0;
   wmem = (unsigned int *)0;
   curaddr = 0x10000;
   muol = 16;
   cursz = 'b';
   curfmt = 'x';
   currep = 1;
   dbg_dbctrl = 0;
}


int dbg_CmdProc(int cmd, int cmdParm1, int cmdParm2, int cmdParm3, int cmdParm4)
{
	int val;
	int err = E_Ok;

	switch(cmd) {
	case DVC_GetUnit:
		val = DBGGetKey(0);
		*(int *)cmdParm1 = val;
		break;
	case DVC_PutUnit:
		DBGDisplayChar(cmdParm1);
		break;
	case DVC_PeekUnit:
		val = DBGGetKey(0);
		*(int *)cmdParm1 = val;
		break;
	case DVC_Open:
		if (cmdParm4)
			*(int *)cmdParm4 = 0;
		else
			err = E_Arg;
		break;
	case DVC_Close:
		break;
	case DVC_Status:
		*(int *)cmdParm1 = 0;
		break;
	case DVC_Nop:
		break;
	case DVC_Setup:
		break;
	case DVC_Initialize:
		dbg_init();
		break;
	case DVC_FlushInput:
		break;
	case DVC_IsRemoveable:
		*(int *)cmdParm1 = 0;
		break;
	default:
		return err = E_BadDevOp;
	}
	return (err);
}
