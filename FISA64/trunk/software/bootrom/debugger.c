extern pascal void set_vector(int, unsigned int);
extern pascal void putch(char ch);
extern void printf();

int linendx;
char linebuf[100];
unsigned int dbg_stack[1024];
unsigned int dbg_dbctrl;
unsigned int regs[32];
unsigned int cr0save;
int ssm;
int repcount;
unsigned int curaddr;
unsigned int cursz;
unsigned int curfill;
char curfmt;
unsigned int currep;
unsigned int muol;    // max units on line
unsigned byte *bmem;
unsigned char *cmem;
unsigned short int *hmem;
unsigned int *wmem;


static void dbg_DisplayHelp()
{
     printf("\r\n'?' queries the status of a breakpoint register as in:");
     printf("\r\nDBG>i2?");
     printf("\r\nFollowing a breakpoint register with an '=' assigns ");
     printf("\r\nan address to it.");
     printf("\r\nDBG>i1=12345678     will assign 12345678 to i1");
     printf("\r\nThere are a total of four breakpoint registers (0-3).");
     printf("\r\nPrefix the register number with an 'i' to indicate an");
     printf("\r\ninstruction breakpoint or a 'd' to indicate a data");
     printf("\r\nbreakpoint. Prefix the register number with 'ds' to");
     printf("\r\nindicate a data store only breakpoint.");
     printf("\r\nSetting a register to zero will clear the breakpoint.");
     printf("\r\nOnce the debug registers are set it is necessary to ");
     printf("\r\narm debugging mode using the 'a' command.");
     printf("\r\nType 'q' to quit.");
     printf("\r\nDBG>");
}


byte dbg_GetCursorRow()
{
    asm {
        ldi    r6,#3   ; Get cursor position
        sys    #410
        lsr    r1,r1,#8
    }
}

byte dbg_GetCursorCol()
{
    asm {
        ldi    r6,#3
        sys    #410
        and    r1,r1,#$FF
    }
}

void dbg_HomeCursor()
{
     asm {
         ldi   r6,#2
         ldi   r1,#0
         ldi   r2,#0
         sys   #410
     }
}

pascal unsigned int dbg_GetDBAD(int r)
{
    switch(r) {
    case 0: asm { mfspr  r1,dbad0  } break;
    case 1: asm { mfspr  r1,dbad1  } break;
    case 2: asm { mfspr  r1,dbad2  } break;
    case 3: asm { mfspr  r1,dbad3  } break;
    return 0;
    }
}

pascal void dbg_SetDBAD(int r, unsigned int ad)
{
     switch(r) {
     case 0: asm {
          lw    r1,32[bp]
          mtspr dbad0,r1
          }
          break;
     case 1: asm {
          lw    r1,32[bp]
          mtspr dbad1,r1
          }
          break;
     case 2: asm {
          lw    r1,32[bp]
          mtspr dbad2,r1
          }
          break;
     case 3: asm {
          lw    r1,32[bp]
          mtspr dbad3,r1
          }
          break;
     }
}

pascal void dbg_arm(unsigned int dbg_dbctrl)
{
     asm {
         lw    r1,24[bp]
         mtspr dbctrl,r1
     }
}

pascal char CvtScreenToAscii(unsigned short int sc)
{
     asm {
         lw    r1,24[bp]
         ldi   r6,#$21         ; screen to ascii
         sys   #410
     }
}

char dbg_getchar()
{
     char ch;
     
     ch = -1;
     if (linendx < 84) {
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

     while (linendx < 84) {
           ch = dbg_getchar();
           if (ch!=' ' || ch==-1)
               return ch;
     }
     return -1;
}

char dbg_nextSpace()
{
    char ch;

    do {
      ch = dbg_getchar();
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
           ch = dbg_getchar();
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
          printf("\r\nDBG>i%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>i%d <not set>", n);
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
          printf("\r\nDBG>d%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>d%d <not set>", n);
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
          printf("\r\nDBG>ds%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>ds%d <not set>", n);
   }
}

static void DispRegs()
{
     printf("\r\nr1=%X r2=%X r3=%X r4=%X\r\n", regs[1], regs[2], regs[3], regs[4]);
     printf("r5=%X r6=%X r7=%X r8=%X\r\n", regs[5], regs[6], regs[7], regs[8]);
     printf("r9=%X r10=%X r11=%X r12=%X\r\n", regs[9], regs[10], regs[11], regs[12]);
     printf("r13=%X r14=%X r15=%X r16=%X\r\n", regs[13], regs[14], regs[15], regs[16]);
     printf("r17=%X r18=%X r19=%X r20=%X\r\n", regs[17], regs[18], regs[19], regs[20]);
     printf("r21=%X r22=%X r23=%X tr=%X\r\n", regs[21], regs[22], regs[23], regs[24]);
     printf("r25=%X r26=%X r27=%X r28=%X\r\n", regs[25], regs[26], regs[27], regs[28]);
     printf("r29=%X sp=%X lr=%X\r\n", regs[29], regs[30], regs[31]);
}

static pascal void DispReg(int r)
{
     printf("r%d=%X\r\n", r, regs[r]);
}

void dbg_prompt()
{
     printf("\r\nDBG>");
}

pascal int dbg_getDecNumber(int *n)
{
    int num;
    char ch;
    int nd;

    if (n==(int *)0) return 0;
    num = 0;
    nd = 0;
     while(isdigit(ch=dbg_getchar())) {
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

     ch = dbg_getchar();
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
                         regs[regno] = val;
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
     ch = dbg_getchar();
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
          ch = dbg_getchar();
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
        ch = dbg_getchar();
        switch (ch) {
        case -1: return;
        case ' ': break;
        case '?': dbg_DisplayHelp(); break;
        case 'q': return 1;
        case 'a': dbg_arm(dbg_dbctrl); break;
        case 'i':
             ch = dbg_getchar();
             switch(ch) {
             case '?':  // query instruction breakpoints
                  if (((dbg_dbctrl & 0x030000)==0) && (dbg_dbctrl & 1) == 1)
                      printf("i0=%08X\r\n", dbg_GetDBAD(0));
                  if (((dbg_dbctrl & 0x300000)==0) && (dbg_dbctrl & 2) == 2)
                      printf("i1=%08X\r\n", dbg_GetDBAD(1));
                  if (((dbg_dbctrl & 0x3000000)==0) && (dbg_dbctrl & 4) == 4)
                      printf("i2=%08X\r\n", dbg_GetDBAD(2));
                  if (((dbg_dbctrl & 0x30000000)==0) && (dbg_dbctrl & 8) == 8)
                      printf("i2=%08X\r\n", dbg_GetDBAD(3));
                  break;
             case '0':  dbg_ReadSetIB(0); break;
             case '1':  dbg_ReadSetIB(1); break;
             case '2':  dbg_ReadSetIB(2); break;
             case '3':  dbg_ReadSetIB(3); break;
             }
             break;
        case 'd':
             ch = dbg_getchar();
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
                  printf("\r\n");
                  if (((dbg_dbctrl & 0x030000)==0x30000) && (dbg_dbctrl & 1) == 1)
                      printf("d0=%08X\r\n", dbg_GetDBAD(0));
                  if (((dbg_dbctrl & 0x300000)==0x300000) && (dbg_dbctrl & 2) == 2)
                      printf("d1=%08X\r\n", dbg_GetDBAD(1));
                  if (((dbg_dbctrl & 0x3000000)==0x3000000) && (dbg_dbctrl & 4) == 4)
                      printf("d2=%08X\r\n", dbg_GetDBAD(2));
                  if (((dbg_dbctrl & 0x30000000)==0x30000000) && (dbg_dbctrl & 8) == 8)
                      printf("d2=%08X\r\n", dbg_GetDBAD(3));
                  break;
              case '0':  dbg_ReadSetDB(0); break;
              case '1':  dbg_ReadSetDB(1); break;
              case '2':  dbg_ReadSetDB(2); break;
              case '3':  dbg_ReadSetDB(3); break;
              case 's':
                  ch = dbg_getchar();
                  switch(ch) {
                  case '?':
                      if (((dbg_dbctrl & 0x030000)==0x10000) && (dbg_dbctrl & 1) == 1)
                          printf("ds0=%08X\r\n", dbg_GetDBAD(0));
                      if (((dbg_dbctrl & 0x300000)==0x100000) && (dbg_dbctrl & 2) == 2)
                          printf("ds1=%08X\r\n", dbg_GetDBAD(1));
                      if (((dbg_dbctrl & 0x3000000)==0x1000000) && (dbg_dbctrl & 4) == 4)
                          printf("ds2=%08X\r\n", dbg_GetDBAD(2));
                      if (((dbg_dbctrl & 0x30000000)==0x10000000) && (dbg_dbctrl & 8) == 8)
                          printf("ds2=%08X\r\n", dbg_GetDBAD(3));
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
             ch = dbg_getchar();
             if (ch=='s') {
                  ch = dbg_getchar();
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
             ch = dbg_getchar();
             if (ch=='/')
                 dbg_getDumpFormat();
             ch = dbg_getchar();
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
             ch = dbg_getchar();
             if (ch=='/') {
                 dbg_getDumpFormat();
             }
             switch(curfmt) {
             case 'i':
                  printf("\r\n");
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
                      printf("\r\n");
                  }
                  break;
             case 'x':
                  for (nn = 0; nn < currep; nn++) {
                      if (getcharNoWait()==3)
                         break;
                      if ((nn % muol)==0) {
                          switch(cursz) {
                          case 'b': printf("\r\n%06X ", curaddr+nn); break;
                          case 'c': printf("\r\n%06X ", curaddr+nn*2); break;
                          case 'h': printf("\r\n%06X ", curaddr+nn*4); break;
                          case 'w': printf("\r\n%06X ", curaddr+nn*8); break;
                          }
                      }
                      asm {; right here ; };
                      switch(cursz) {
                      case 'b': printf("%02X ", bmem[curaddr+nn]); break;
                      case 'c': printf("%04X ", cmem[curaddr/2+nn]); break;
                      case 'h': printf("%08X ", hmem[curaddr/4+nn]); break;
                      case 'w': printf("%016X ", wmem[curaddr/8+nn]); break;
                      }
                  }
                  switch(cursz) {
                  case 'b': curaddr += nn; break;
                  case 'c': curaddr += nn * 2; break;
                  case 'h': curaddr += nn * 4; break;
                  case 'w': curaddr += nn * 8; break;
                  }
                  printf("\r\n");
                  break;
             }
        }
    }
    return 0;
}

// ----------------------------------------------------------------------------
// Debug IRQ
//    Saves all the registers in debug reg area, then calls the debugger()
// routine. When the user is finished with the debugger routine all the
// registers are restored then an RTD executed.
// ----------------------------------------------------------------------------

naked dbg_irq()
{
     asm {
         lea   sp,dbg_stack_+8192-8
         sw    r1,regs_+8
         sw    r2,regs_+16
         sw    r3,regs_+24
         sw    r4,regs_+32
         sw    r5,regs_+40
         sw    r6,regs_+48
         sw    r7,regs_+56
         sw    r8,regs_+64
         sw    r9,regs_+72
         sw    r10,regs_+80
         sw    r11,regs_+88
         sw    r12,regs_+96
         sw    r13,regs_+104
         sw    r14,regs_+112
         sw    r15,regs_+120
         sw    r16,regs_+128
         sw    r17,regs_+136
         sw    r18,regs_+144
         sw    r19,regs_+152
         sw    r20,regs_+160
         sw    r21,regs_+168
         sw    r22,regs_+176
         sw    r23,regs_+184
         sw    r24,regs_+192
         sw    r25,regs_+200
         sw    r26,regs_+208
         sw    r27,regs_+216
         sw    r28,regs_+224
         sw    r29,regs_+232
         sw    r30,regs_+240
         sw    r31,regs_+248
         mfspr r1,cr0
         sw    r1,cr0save_

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger_
         addui sp,sp,#16
         
         lw    r1,cr0save_
         mtspr cr0,r1
         lw    r1,regs_+8
         lw    r2,regs_+16
         lw    r3,regs_+24
         lw    r4,regs_+32
         lw    r5,regs_+40
         lw    r6,regs_+48
         lw    r7,regs_+56
         lw    r8,regs_+64
         lw    r9,regs_+72
         lw    r10,regs_+80
         lw    r11,regs_+88
         lw    r12,regs_+96
         lw    r13,regs_+104
         lw    r14,regs_+112
         lw    r15,regs_+120
         lw    r16,regs_+128
         lw    r17,regs_+136
         lw    r18,regs_+144
         lw    r19,regs_+152
         lw    r20,regs_+160
         lw    r21,regs_+168
         lw    r22,regs_+176
         lw    r23,regs_+184
         lw    r24,regs_+192
         lw    r25,regs_+200
         lw    r26,regs_+208
         lw    r27,regs_+216
         lw    r28,regs_+224
         lw    r29,regs_+232
         lw    r30,regs_+240
         lw    r31,regs_+248
         rtd
     }
}


int debugger_task()
{
    debugger(0,0);
    return 0;
}

void debugger(unsigned int ad, unsigned int ctrlreg)
{
     char ch;
     int row, col;
     unsigned short int *screen;
     int nn;
     
     dbg_dbctrl = ctrlreg;
     screen = (unsigned short int *)0xFFD00000;
     ad = ad & 0xFFFFFFFFFFFFFFFCL;
     if (ad)
        disassem20(ad-16,ad);
     forever {
         printf("\r\nDBG>");
         do {
              ch = getchar();
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
                       asm {
                           bsr ClearScreen_
                       }
                       dbg_HomeCursor();
                       break;
                  }
                  putch(ch);
              }
         } while (1);
         row = dbg_GetCursorRow();
         col = dbg_GetCursorCol();
         for (nn = 0; nn < 84; nn++)
             linebuf[nn] = CvtScreenToAscii(screen[row * 84 + nn] & 0x3ff);
         if (dbg_parse_begin()==1)
             break;
     }     
}

void dbg_init() {
        asm {
            ldi   r1,#60
            sc    r1,LEDS
        }
     set_vector(496,dbg_irq);     // breakpoint interrupt
        asm {
            ldi   r1,#61
            sc    r1,LEDS
        }
     set_vector(495,dbg_irq);     // single step interrupt
        asm {
            ldi   r1,#62
            sc    r1,LEDS
        }
     ssm = 0;
     bmem = (unsigned byte *)0;
     cmem = (unsigned char *)0;
     hmem = (unsigned short int *)0;
     wmem = (unsigned int *)0;
        asm {
            ldi   r1,#66
            sc    r1,LEDS
        }
     curaddr = 0x10000;
     muol = 16;
     cursz = 'b';
     curfmt = 'x';
     currep = 1;
     dbg_dbctrl = 0;
        asm {
            ldi   r1,#69
            sc    r1,LEDS
        }
}

