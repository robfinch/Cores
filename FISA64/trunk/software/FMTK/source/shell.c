extern pascal void putch(char ch);
pascal char CvtScreenToAscii(unsigned short int sc);
extern void printf();
extern char getchar();
extern int FMTK_StartTask(int,int,int (*)(),int,int);
extern int debugger_task();
extern pascal int prtdbl(double,int,int,char);

int sh_linendx;
char sh_linebuf[100];

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
    int taskno;
    int (*ad)();
    int pri,cpu,parm,job;

    ch = sh_getchar();
    switch (ch) {
    case 'd':
         FMTK_StartTask(040,0,debugger_task,0,0);
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
         nd = sh_getHexNumber(&taskno);
         if (nd > 0) {
             FMTK_KillTask(taskno);
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
             FMTK_StartTask(pri,cpu,ad,parm,job);
         }
         break;        
    }
    return 0;
}

int sh_parse()
{
    sh_linendx = 0;
    if (sh_linebuf[0]=='$' && sh_linebuf[1]=='>')
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
        for (nn = 0; nn < 84; nn++)
            sh_linebuf[nn] = CvtScreenToAscii(screen[row * 84 + nn] & 0x3ff);
        sh_parse();
    }
}
