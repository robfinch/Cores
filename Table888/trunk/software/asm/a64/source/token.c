#include <inttypes.h>
#include <stdio.h>
#include <ctype.h>
#include "a64.h"

char *pinptr;
char lastid[500];
char lastch;
int64_t last_icon;
int64_t ival;
double rval;

int my_isspace(char ch)
{
    if (ch==' ' || ch=='\t' || ch=='\r')
        return 1;
    return 0;
}

int isFirstIdentChar(char ch)
{
    return isalpha(ch) || ch=='_';
}

int isIdentChar(char ch)
{
    return isalnum(ch) || ch=='_';
}

int need(int tk)
{
    if (tk != token) {
        printf("Syntax error (%d).\r\n", lineno);
        printf("Line:%.60s\r\n", stptr);
    }
}
        
int expect(int tk)
{
    if (tk != token) {
        if (tk==tk_comma)
            printf("Expecting a ,\r\n");
    }
    NextToken();
}

void SkipSpaces()
{
    while(my_isspace(*inptr)) inptr++;
}
 
void ScanToEOL()
{
     while(*inptr && *inptr!='\n') inptr++;
}

int64_t radix36(char c)
{
	if(isdigit(c))
            return c - '0';
    if(c >= 'a' && c <= 'z')
            return c - 'a' + 10;
    if(c >= 'A' && c <= 'Z')
            return c - 'A' + 10;
    return -1;
}

/*
 *      getbase - get an integer in any base.
 */
void getbase(int b)
{
    register int64_t i, j;
    i = 0;
    while(isalnum(*inptr) || *inptr=='_') {
        if (*inptr=='_') {
            inptr++;
            continue;
        }
        if((j = radix36(*inptr)) < b) {
                        i = i * b + j;
                        inptr++;
                        }
                else break;
                }
		if (*inptr=='L' || *inptr=='U')	// ignore a 'L'ong suffix and 'U'nsigned
			inptr++;
    ival = i;
    token = tk_icon;
}

      
/*
 *      getbase - get an integer in base 2.
 */
void getbase2()
{
    uint64_t i, j;

    i = 0;
    while(*inptr=='0' || *inptr=='1' || *inptr=='_') {
        if (*inptr=='_') {
            inptr++;
            continue;
        }
        j = *inptr - '0';
        i = (i + i) | j;
        inptr++;
   }
   if (*inptr=='L' || *inptr=='U')	// ignore a 'L'ong suffix and 'U'nsigned
       inptr++;
    ival = i;
    token = tk_icon;
}

//
// getfrac - get fraction part of a floating number.
//
void getfrac()
{       
	double frmul;
    frmul = 0.1;
    while(isdigit(*inptr)) {
        rval += frmul * (*inptr - '0');
        inptr++;
        frmul *= 0.1;
    }
}
 
/*
 *      getexp - get exponent part of floating number.
 *
 *      this algorithm is primative but usefull.  Floating
 *      exponents are limited to +/-255 but most hardware
 *      won't support more anyway.
 */
void getexp()
{       double  expo, exmul;
        expo = 1.0;
        if(token != tk_rconst)
                rval = ival;
        if(*inptr == '-') {
                exmul = 0.1;
                inptr++;
                }
        else
                exmul = 10.0;
        getbase(10);
        if(ival > 255)
                printf("Error in floating point number.\r\n");
                //error(ERR_FPCON);
        else
                while(ival--)
                        expo *= exmul;
        rval *= expo;
}
/*
 *      getnum - get a number from input.
 *
 *      getnum handles all of the numeric input. it accepts
 *      decimal, octal, hexidecimal, and floating point numbers.
 */
void getnum()
{
     register int    i;
        i = 0;
        if(*inptr == '0') {
                inptr++;
                if(*inptr == 'x' || *inptr == 'X') {
                        inptr++;
                        getbase(16);
                        }
                else getbase(8);
                }
        else    {
                getbase(10);
                if(*inptr == '.') {
                        inptr++;
                        rval = ival;    /* float the integer part */
                        getfrac();      /* add the fractional part */
                        token = tk_rconst;
                        }
                if(*inptr == 'e' || *inptr == 'E') {
                        inptr++;
                        getexp();       /* get the exponent */
                        }
				// Ignore 'U' unsigned suffix
				if (*inptr=='U' || *inptr=='u') {
					inptr++;
				}
				}
				
}

/*
 *      getsch - get a character in a quoted string.
 *
 *      this routine handles all of the escape mechanisms
 *      for characters in strings and character constants.
 */
int64_t getsch()        /* return an in-quote character */
{   
        register int64_t i, j;
        if(*inptr == '\n')
                return -1;
        if(*inptr != '\\') {
                i = *inptr;
                inptr++;
                return i;
                }
        inptr++;        /* get an escaped character */
        if(isdigit(*inptr)) {
                i = 0;
                for(j = i = 0;j < 3;++j) {
                        if(*inptr <= '7' && *inptr >= '0')
                                i = (i << 3) + *inptr - '0';
                        else
                                break;
                        inptr++;
                        }
                return i;
                }
        i = *inptr;
        inptr++;
        switch(i) {
                case '\n':
                        inptr++;
                        return getsch();
                case 'b':
                        return '\b';
                case 'f':
                        return '\f';
                case 'n':
                        return '\n';
                case 'r':
                        return '\r';
				case 't':
						return '\t';
                default:
                        return i;
                }
}

int getIdentifier()
{
    int nn;

    if (isFirstIdentChar(*inptr) || (*inptr=='.' && isIdentChar(inptr[1]))) {
        nn = 1;
        lastid[0] = *inptr;
        inptr++;
        while(isIdentChar(*inptr) && nn < sizeof(lastid)-1) {
            lastid[nn] = *inptr;
            inptr++;
            nn++;
        }
        lastid[nn] = '\0';
        return 1;
    }
    else
        return 0;
}

static char *pseudos[] = {
    "align", "code", "data", "tls", "rodata",
    "fill", "org", (char *)NULL
};

int isPseudoOp()
{
    static char buf[500];
    char *p = inptr;
    int nn = 0;

    if (*p=='.') p++;
    if (!isFirstIdentChar(*p))
        return 0;
    while(isIdentChar(*p)) {
        buf[nn] = tolower(*p);
        p++;
        nn++;
    }
    buf[nn] = '\0';
    for (nn = 0; nn < 7; nn++) {
        if (strcmp(buf, pseudos[nn])==0)
            return 1;
    }
    return 0;
}

void prevToken()
{
    inptr = pinptr;
}

int NextToken()
{
    int nn;

    pinptr = inptr;    
    do {
        if (*inptr=='\0')
           return token = tk_eof;
        SkipSpaces();                      // skip over leading spaces
        if (*inptr==';') {                 // comment ?
            ScanToEOL();
            lineno++;
            continue;
        }
        if (isdigit(*inptr)) {
           getnum();
           return token;
        }
        switch(*inptr) {
        case '.': if (isPseudoOp()) { inptr++; continue; }
                  else if (getIdentifier()) { return token = tk_id; }
                  else { inptr++; continue; }
        case '\n': inptr++; return token = tk_eol;
        case '$': inptr++; getbase(16); return token = tk_icon;
        case '%': inptr++; getbase2(); return token = tk_icon;
        case ',': inptr++; return token = ',';
        case '+': inptr++; return token = '+';
        case '-': inptr++; return token = '-';
        case '/': inptr++; return token = '/';
        case '*': inptr++; return token = '*';
        case '#': inptr++; return token = '#';
        case '[': inptr++; return token = '[';
        case ']': inptr++; return token = ']';
        case '(': inptr++; return token = '(';
        case ')': inptr++; return token = ')';
        case '\'':
             inptr++;
             ival = getsch();
             if (*inptr!='\'')
                 printf("Syntax error - missing close quote.\r\n");
             else
                 inptr++;
             return token = tk_icon;
        case '=':
             if (inptr[1]=='=') { inptr+=2; return token = tk_eq; }
             inptr++; 
             return token = tk_eq;
        case '!':
             if (inptr[1]=='=') { inptr+=2; return token = tk_ne; }
             inptr++; 
             return token = '!';
        case '>':
             if (inptr[1]=='>') { inptr+=2; return token = tk_rshift; }
             if (inptr[1]=='=') { inptr+=2; return token = tk_ge; }
             inptr++; 
             return token = tk_gt;
        case '<':
             if (inptr[1]=='>') { inptr+=2; return token = tk_ne; }
             if (inptr[1]=='<') { inptr+=2; return token = tk_lshift; }
             if (inptr[1]=='=') { inptr+=2; return token = tk_le; }
             inptr++; 
             return token = tk_lt;
        case '~': inptr++; return token = '~';
        case '|':
             if (inptr[1]=='|') { inptr+=2; return token = tk_lor; }
             inptr++;
             return token = '|';
        case '&':
             if (inptr[1]=='&') { inptr+=2; return token = tk_land; }
             inptr++;
             return token = '&';

        // add addi addu addui and andi align asr asri
        case 'a':
        case 'A':
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_and;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_addu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && 
                (inptr[2]=='d' || inptr[2]=='D') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_addui;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_addi;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_add;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='g' || inptr[3]=='G') && (inptr[4]=='n' || inptr[4]=='N') && isspace(inptr[5])) {
                inptr += 5;
                return token = tk_align;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_andi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_asri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_asr;
            }
            break;

        case 'b':
        case 'B':
            if ((inptr[1]=='e' || inptr[1]=='E') && 
                (inptr[2]=='q' || inptr[2]=='Q') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_beq;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bne;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='a' || inptr[2]=='A') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bra;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='z' || inptr[2]=='Z') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_brz;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_blt;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='o' || inptr[2]=='O') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ble;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bleu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgeu;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgtu;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bgtu;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='n' || inptr[2]=='N') &&
                (inptr[3]=='z' || inptr[3]=='Z') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_brnz;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bsr;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bmi;
            }
            if ((inptr[1]=='p' || inptr[1]=='P') && 
                (inptr[2]=='l' || inptr[2]=='L') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bpl;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='c' || inptr[2]=='C') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bvc;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bvs;
            }
            if (inptr[1]=='r' && inptr[2]=='k' && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_brk;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='p' || inptr[2]=='P') &&
                (inptr[3]=='l' || inptr[3]=='L') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bpl;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='m' || inptr[2]=='M') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bmi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bss;
            }
            break;

        // cmp code cli com
        case 'c': case 'C':
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_cmp;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_code;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_cli;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_com;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_cs;
             }
             break;

        // db dbnz dc dh dw data div divs divu ds:
        case 'd': case 'D':
             if ((inptr[1]=='b' || inptr[1]=='B') &&
                 (inptr[2]=='n' || inptr[2]=='N') &&
                 (inptr[3]=='z' || inptr[3]=='Z') &&
                  isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_dbnz;
             }
             if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_db;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_dc;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_dh;
             }
             if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_dw;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='v' || inptr[2]=='V') && isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_div;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_divu;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='s' || inptr[3]=='S') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_div;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_data;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_ds;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') && (inptr[2]=='b' || inptr[2]=='B') && (isspace(inptr[3])||inptr[3]=='.')) {
                 inptr += 3;
                 return token = tk_fill;
             }
             break;

        // end eor eori endpublic extern equ
        case 'e': case 'E':
             if ((inptr[1]=='q' || inptr[1]=='Q') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_equ;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_eori;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_eor;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_end;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='p' || inptr[3]=='P') &&
                 (inptr[4]=='u' || inptr[4]=='U') &&
                 (inptr[5]=='b' || inptr[5]=='B') &&
                 (inptr[6]=='l' || inptr[6]=='L') &&
                 (inptr[7]=='i' || inptr[7]=='I') &&
                 (inptr[8]=='c' || inptr[8]=='C') &&
                 isspace(inptr[9])) {
                 inptr += 9;
                 return token = tk_endpublic;
             }
             if ((inptr[1]=='x' || inptr[1]=='X') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 (inptr[4]=='r' || inptr[4]=='R') &&
                 (inptr[5]=='n' || inptr[5]=='N') &&
                 isspace(inptr[6])) {
                 inptr += 6;
                 return token = tk_extern;
             }
             break;

        // fill
        case 'f': case 'F':
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='l' || inptr[2]=='L') &&
                 (inptr[3]=='l' || inptr[3]=='L') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fill;
             }
             break;

        // gran
        case 'g': case 'G':
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='a' || inptr[2]=='A') &&
                 (inptr[3]=='n' || inptr[3]=='N') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_gran;
             }
             break;

        // jmp jsr
        case 'j': case 'J':
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jsr;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jmp;
             }
             break;

        // lb lbu lc lcu lh lhu lw ldi lea
        case 'l':
        case 'L':
            if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_lb;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lbu;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_lw;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_lh;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lhu;
            }
            if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_lc;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lcu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ldi;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='a' || inptr[2]=='A') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lea;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lmr;
            }
            break;

        // mod modu mov mul muli mulu mului mtspr mfspr
        case 'm': case 'M':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='v' || inptr[2]=='V') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_mov;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_mul;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_mulu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_mului;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_muli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_mod;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_modu;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                (inptr[4]=='r' || inptr[4]=='R') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_mtspr;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                (inptr[4]=='r' || inptr[4]=='R') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_mfspr;
            }
            break;

        // not neg nop
        case 'n': case 'N':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_not;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_neg;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='p' || inptr[2]=='P') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_nop;
            }
            break;

        // or ori org
        case 'o': case 'O':
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ori;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_or;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_org;
            }
            break;

        // push pop php plp public
        case 'p': case 'P':
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='h' || inptr[3]=='H') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_push;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_pop;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_php;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_plp;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='b' || inptr[2]=='B') &&
                (inptr[3]=='l' || inptr[3]=='L') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                (inptr[5]=='c' || inptr[5]=='C') &&
                isspace(inptr[6])) {
                inptr += 6;
                return token = tk_public;
            }
            break;

        // rol roli ror rori rts rti rodata
        case 'r': case 'R':
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='s' || inptr[2]=='S') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rts;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rol;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[3])) {
                inptr += 4;
                return token = tk_roli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ror;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[3])) {
                inptr += 4;
                return token = tk_rori;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rti;
            }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (inptr[5]=='a' || inptr[5]=='A') &&
                 isspace(inptr[6])) {
                 inptr += 6;
                 return token = tk_rodata;
             }
            break;
        
        // sb sc sh sw sxb sxc sxh sub subi subu subui shl shli shr shru shrui sei smr ss:
        // seq seqi sne snei sge sgei sgt sgti slt slti sle slei sgeu sgeui sgtu sgtui sltu sltui sleu sleui
        case 's': case 'S':
            if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sw;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sb;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sc;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sh;
            }  
            if ((inptr[1]=='u' || inptr[1]=='U') && 
                (inptr[2]=='b' || inptr[2]=='B') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_subui;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_subi;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_subu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sub;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_shli;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_shl;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_shrui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_shru;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_shru;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sei;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_smr;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sxb;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sxc;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='h' || inptr[2]=='H') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sxh;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_seq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_seqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_snei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sgti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sle;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_slei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_slt;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_slti;
            }

            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sgeui;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_sgtui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_sleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_sltui;
            }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_ss;
             }
            if ((inptr[1]=='w' || inptr[1]=='W') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_swap;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sw;
            }  
            break;

        // xor xori
        case 'x': case 'X':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_xori;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_xor;
            }
            break;
        }
        // The text wasn't recognized as any of the above tokens. So try for an
        // identifier name.
        if (getIdentifier()) {
            return token = tk_id;
        }
        inptr++;
    } while (*inptr);
    return token = tk_eof;
}

// ----------------------------------------------------------------------------
// Return the register number or -1 if not a register.
// ----------------------------------------------------------------------------

int getRegister()
{
    int reg;

    while(isspace(*inptr)) inptr++;
    switch(*inptr) {
    case 'r': case 'R':
         if (isdigit(inptr[1])) {
             reg = inptr[1]-'0';
             if (isdigit(inptr[2])) {
                 reg = 10 * reg + (inptr[2]-'0');
                 if (isdigit(inptr[3])) {
                     reg = 10 * reg + (inptr[3]-'0');
                     if (isIdentChar(inptr[4]))
                         return -1;
                     inptr += 4;
                     NextToken();
                     return reg;
                 }
                 else if (isIdentChar(inptr[3]))
                     return -1;
                 else {
                     inptr += 3;
                     NextToken();
                     return reg;
                 }
             }
             else if (isIdentChar(inptr[2]))
                 return -1;
             else {
                 inptr += 2;
                 NextToken();
                 return reg;
             }
         }
         else return -1;
    case 'b': case 'B':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 253;
        }
        break;
    case 's': case 'S':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 255;
        }
        break;
    case 't': case 'T':
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 252;
        }
        break;
    case 'f': case 'F':
        if ((inptr[1]=='l' || inptr[1]=='L') &&
            (inptr[2]=='g' || inptr[2]=='G') &&
            isdigit(inptr[3]) &&
            !isIdentChar(inptr[4])) {
            reg = inptr[3]-'0' + 244;
            inptr += 4;
            NextToken();
            return reg;
        }
        if ((inptr[1]=='l' || inptr[1]=='L') &&
            isdigit(inptr[2]) &&
            !isIdentChar(inptr[3])) {
            reg = inptr[2]-'0' + 244;
            inptr += 3;
            NextToken();
            return reg;
        }
        break;
    case 'p': case 'P':
        if ((inptr[1]=='c' || inptr[1]=='C') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 254;
        }
        break;
    default:
        return -1;
    }
    return -1;
}

// ----------------------------------------------------------------------------
// Get the friendly name of a special purpose register.
// ----------------------------------------------------------------------------

int getSprRegister()
{
    int reg;

    while(isspace(*inptr)) inptr++;
    switch(*inptr) {

    // bithist biterr
    case 'b': case 'B':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='t' || inptr[2]=='T') &&
             (inptr[3]=='e' || inptr[3]=='E') &&
             (inptr[4]=='r' || inptr[4]=='R') &&
             (inptr[5]=='r' || inptr[5]=='R') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 0x0E;
         }
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='t' || inptr[2]=='T') &&
             (inptr[3]=='h' || inptr[3]=='H') &&
             (inptr[4]=='i' || inptr[4]=='I') &&
             (inptr[5]=='s' || inptr[5]=='S') &&
             (inptr[6]=='t' || inptr[6]=='T') &&
             !isIdentChar(inptr[7])) {
             inptr += 7;
             NextToken();
             return 0x0F;
         }
         break;

    // cs clk cr0 cr3
    case 'c': case 'C':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x20;
         }
         if ((inptr[1]=='l' || inptr[1]=='L') &&
             (inptr[2]=='k' || inptr[2]=='K') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x06;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='0') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x05;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='3') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x04;
         }
         break;

    // ds
    case 'd': case 'D':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x21;
         }
         break;

    // history
    case 'h': case 'H':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='s' || inptr[2]=='S') &&
             (inptr[3]=='t' || inptr[3]=='T') &&
             (inptr[4]=='o' || inptr[4]=='O') &&
             (inptr[5]=='r' || inptr[5]=='R') &&
             (inptr[6]=='y' || inptr[6]=='Y') &&
             !isIdentChar(inptr[7])) {
             inptr += 7;
             NextToken();
             return 0x0D;
         }
         break;

    // pta
    case 'p': case 'P':
         if ((inptr[1]=='t' || inptr[1]=='T') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x04;
         }
         break;
         
    // rand
    case 'r': case 'R':
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='n' || inptr[2]=='N') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x12;
         }
         break;
    // ss srand1 srand2
    case 's': case 'S':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x22;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='n' || inptr[3]=='N') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='1') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 0x10;
         }
         if ((inptr[1]=='r' || inptr[1]=='R') &&
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='n' || inptr[3]=='N') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='2') &&
             !isIdentChar(inptr[6])) {
             inptr += 6;
             NextToken();
             return 0x11;
         }
         if ((inptr[1]=='p' || inptr[1]=='P') &&
             (inptr[2]=='r' || inptr[2]=='R') &&
             isdigit(inptr[3]) && isdigit(inptr[4]) &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return (inptr[3]-'0')*10 + (inptr[4]-'0');
         }
         break;
    // tick
    case 't': case 'T':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             (inptr[3]=='k' || inptr[3]=='K') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x00;
         }
         break;
    // vbr
    case 'v': case 'V':
         if ((inptr[1]=='b' || inptr[1]=='B') &&
             (inptr[2]=='r' || inptr[2]=='R') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x01;
         }
         break;
    }
    return -1;
}

