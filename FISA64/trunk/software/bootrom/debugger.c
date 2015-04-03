int linendx;
char linebuf[100];
unsigned int dbg_stack[4096];
unsigned int dbctrl;

void dbg_DisplayHelp()
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

unsigned int *GetVBR()
{
    asm {
        mfspr r1,vbr
    }
}

void set_vector(unsigned int vecno, unsigned int rout)
{
     if (vecno > 511) return;
     if ((rout == 0) or ((rout & 3) != 0)) return;
     GetVBR()[vecno] = rout;
}

byte dbg_GetCursorRow()
{
    asm {
        lbu    r1,TCB_hJCB[tr]
        mulu   r1,#JCB_Size
        addui  r1,r1,#JCB_Array
        lbu    r1,JCB_CursorRow[r1]
    }
}

byte dbg_GetCursorCol()
{
    asm {
        lbu    r1,TCB_hJCB[tr]
        mulu   r1,#JCB_Size
        addui  r1,r1,#JCB_Array
        lbu    r1,JCB_CursorCol[r1]
    }
}


unsigned int dbg_GetDBAD(int r)
{
    switch(r) {
    case 0: asm { mfspr  r1,dbad0  } break;
    case 1: asm { mfspr  r1,dbad1  } break;
    case 2: asm { mfspr  r1,dbad2  } break;
    case 3: asm { mfspr  r1,dbad3  } break;
    return 0;
    }
}

void dbg_SetDBAD(int r, unsigned int ad)
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

void dbg_arm(unsigned int dbctrl)
{
     asm {
         lw    r1,24[bp]
         mtspr dbctrl,r1
     }
}

char CvtScreenToAscii(unsigned short int sc)
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

int dbg_GetHexNumber(unsigned int *ad)
{
     char ch;
     unsigned int num;
     int nd;  // number of digits

     num = 0;
     nd = 0;
     while (1) {
           num <<= 4;
           ch = dbg_getchar();
           if (ch >= '0' && ch <= '9')
               num = num | (ch - '0');
           else if (ch >= 'A' && ch <= 'F')
               num = num | (ch - 'A' + 10);
           else if (ch >= 'a' && ch <= 'f')
               num = num | (ch - 'f' + 10);
           else {
                *ad = num;
                return nd;
           }
     }    
}


// Instruction breakpoint

void dbg_ReadSetIB(unsigned int n)
{
   char ch;
   unsigned int ad;

   if (n > 3) return;
   ch = dbg_nextNonSpace();
   if (ch=='=') {
       if (dbg_GetHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbctrl |= (1 << n);
           dbctrl &= ~(0x30000 << (n << 1));
       }
   }
   else if (ch=='?') {
      if (((dbctrl & (0x030000 << (n << 1)))==0) && (dbctrl & (1 << n) == (1 << n)))
          printf("\r\nDBG>ib%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>ib%d <not set>", n);
   }
}


// Data load or store breakpoint

void dbg_ReadSetDB(unsigned int n)
{
   char ch;
   unsigned int ad;

   if (n > 3) return;
   ch = dbg_nextNonSpace();
   if (ch=='=') {
       if (dbg_GetHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbctrl |= (1 << n);
           dbctrl &= ~(0x30000 << (n << 1));
           dbctrl |= 0x30000 << (n << 1);
       }
   }
   else if (ch=='?') {
      if ((dbctrl & (0x030000 << (n << 1)))==(0x030000 << (n << 1)) && (dbctrl & (1 << n) == (1 << n)))
          printf("\r\nDBG>db%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>db%d <not set>", n);
   }
}

// Data store breakpoint

void dbg_ReadSetDSB(unsigned int n)
{
   char ch;
   unsigned int ad;

   if (n > 3) return;
   ch = dbg_nextNonSpace();
   if (ch=='=') {
       if (dbg_GetHexNumber(&ad) > 0) {
           dbg_SetDBAD(n,ad);
           dbctrl |= (1 << n);
           dbctrl &= ~(0x30000 << (n << 1));
           dbctrl |= 0x10000 << (n << 1);
       }
   }
   else if (ch=='?') {
      if ((dbctrl & (0x030000 << (n << 1)))==(0x010000 << (n << 1)) && (dbctrl & (1 << n) == (1 << n)))
          printf("\r\nDBG>dsb%d=%08X\r\n", n, dbg_GetDBAD(n));
      else
          printf("\r\nDBG>dsb%d <not set>", n);
   }
}

void dbg_prompt()
{
     printf("\r\nDBG>");
}

int dbg_parse_line()
{
    char ch;
    unsigned int ad;

    linendx = 0;
    if (linebuf[0]=='D' && linebuf[1]=='B' && linebuf[2]=='G' && linebuf[3]=='>')
        linendx = 4;
    ch = linebuf[linendx];
    linendx++;
    switch (ch) {
    case '?': dbg_DisplayHelp(); break;
    case 'q': return 1;
    case 'a': dbg_arm(dbctrl); break;
    case 'i':
         ch = dbg_getchar();
         switch(ch) {
         case '?':  // query instruction breakpoints
              if (((dbctrl & 0x030000)==0) && (dbctrl & 1) == 1)
                  printf("i0=%08X\r\n", dbg_GetDBAD(0));
              if (((dbctrl & 0x300000)==0) && (dbctrl & 2) == 2)
                  printf("i1=%08X\r\n", dbg_GetDBAD(1));
              if (((dbctrl & 0x3000000)==0) && (dbctrl & 4) == 4)
                  printf("i2=%08X\r\n", dbg_GetDBAD(2));
              if (((dbctrl & 0x30000000)==0) && (dbctrl & 8) == 8)
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
         case '?':  // query instruction breakpoints
              if (((dbctrl & 0x030000)==0x30000) && (dbctrl & 1) == 1)
                  printf("d0=%08X\r\n", dbg_GetDBAD(0));
              if (((dbctrl & 0x300000)==0x300000) && (dbctrl & 2) == 2)
                  printf("d1=%08X\r\n", dbg_GetDBAD(1));
              if (((dbctrl & 0x3000000)==0x3000000) && (dbctrl & 4) == 4)
                  printf("d2=%08X\r\n", dbg_GetDBAD(2));
              if (((dbctrl & 0x30000000)==0x30000000) && (dbctrl & 8) == 8)
                  printf("d2=%08X\r\n", dbg_GetDBAD(3));
              break;
          case '0':  dbg_ReadSetDB(0); break;
          case '1':  dbg_ReadSetDB(1); break;
          case '2':  dbg_ReadSetDB(2); break;
          case '3':  dbg_ReadSetDB(3); break;
          case '?':
              if (((dbctrl & 0x030000)==0x30000) && (dbctrl & 1) == 1)
                  printf("db0=%08X\r\n", dbg_GetDBAD(0));
              if (((dbctrl & 0x300000)==0x300000) && (dbctrl & 2) == 2)
                  printf("db1=%08X\r\n", dbg_GetDBAD(1));
              if (((dbctrl & 0x3000000)==0x3000000) && (dbctrl & 4) == 4)
                  printf("db2=%08X\r\n", dbg_GetDBAD(2));
              if (((dbctrl & 0x30000000)==0x30000000) && (dbctrl & 8) == 8)
                  printf("db2=%08X\r\n", dbg_GetDBAD(3));
              break;
         case 's':
              ch = dbg_getchar();
              switch(ch) {
              case '?':
                  if (((dbctrl & 0x030000)==0x10000) && (dbctrl & 1) == 1)
                      printf("ds0=%08X\r\n", dbg_GetDBAD(0));
                  if (((dbctrl & 0x300000)==0x100000) && (dbctrl & 2) == 2)
                      printf("ds1=%08X\r\n", dbg_GetDBAD(1));
                  if (((dbctrl & 0x3000000)==0x1000000) && (dbctrl & 4) == 4)
                      printf("ds2=%08X\r\n", dbg_GetDBAD(2));
                  if (((dbctrl & 0x30000000)==0x10000000) && (dbctrl & 8) == 8)
                      printf("ds2=%08X\r\n", dbg_GetDBAD(3));
                  break;
              case '0':  dbg_ReadSetDSB(0); break;
              case '1':  dbg_ReadSetDSB(1); break;
              case '2':  dbg_ReadSetDSB(2); break;
              case '3':  dbg_ReadSetDSB(3); break;
              }
         }
         break;
    }
}

// ----------------------------------------------------------------------------
// Debug IRQ
//    Saves all the registers on the debug stack, then calls the debugger()
// routine. When the user is finished with the debugger routine all the
// registers are restored then an RTI executed.
// ----------------------------------------------------------------------------

naked dbg_irq()
{
     asm {
         lea   sp,dbg_stack+4088
         push  r0
         push  r1
         push  r2
         push  r3
         push  r4
         push  r5
         push  r6
         push  r7
         push  r8
         push  r9
         push  r10
         push  r11
         push  r12
         push  r13
         push  r14
         push  r15
         push  r16
         push  r17
         push  r18
         push  r19
         push  r20
         push  r21
         push  r22
         push  r23
         push  r25
         push  r26
         push  r27
         push  r28
         push  r29
         push  r31

         mfspr r1,dbctrl
         push  r1
         mtspr dbctrl,r0
         mfspr r1,dpc
         push  r1
         bsr   debugger
         addui sp,sp,#16
         
         pop   r31
         pop   r29
         pop   r28
         pop   r27
         pop   r26
         pop   r25
         pop   r23
         pop   r22
         pop   r21
         pop   r20
         pop   r19
         pop   r18
         pop   r17
         pop   r16
         pop   r15
         pop   r14
         pop   r13
         pop   r12
         pop   r11
         pop   r10
         pop   r9
         pop   r8
         pop   r7
         pop   r6
         pop   r5
         pop   r4
         pop   r3
         pop   r2
         pop   r1
         pop   r0
         rti
     }
}

void debugger(unsigned int ad, unsigned int ctrlreg)
{
     char ch;
     int row, col;
     unsigned short int *screen;
     int nn;
     
     screen = (unsigned short int *)0xFFD00000;
     if (ad)
        disassem20(ad,ad);
     while (1) {
         printf("\r\nDBG>");
         do {
              ch = getchar();
              if (ch == 0x0d)
                  break;
              putch(ch);
         } while (1);
         row = dbg_GetCursorRow();
         col = dbg_GetCursorCol();
         for (nn = 0; nn < 84; nn++)
             linebuf[nn] = CvtScreenToAscii(screen[row * 84 + nn] & 0x3ff);
         if (dbg_parse_line()==1)
             break;
     }     
}

void dbg_init() {
     set_vector(496,dbg_irq);
}

