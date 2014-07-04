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
        printf("Syntax error.\r\n");
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
        case '$': inptr++; getbase(16); return tk_icon;
        case '%': inptr++; getbase(2); return tk_icon;
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
        // add addu addui and andi align asri
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
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_add;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='g' || inptr[3]=='G') && (inptr[4]=='n' || inptr[4]=='N') && isspace(inptr[5])) {
                inptr += 5;
                return token = tk_align;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && 
                (inptr[2]=='d' || inptr[2]=='D') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_addui;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_andi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_asri;
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
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ble;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bgt;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='n' || inptr[2]=='N') &&
                (inptr[3]=='z' || inptr[3]=='Z') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_brnz;
            }
            if (inptr[1]=='r' && inptr[2]=='k' && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_brk;
            }
            break;
        // cmp code cli
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
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_cs;
             }
             break;

        // db dc dh dw data div divs divu ds:
        case 'd': case 'D':
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
             break;

        // end eor
        case 'e': case 'E':
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

        // mod modu mov mul mulu mtspr mfspr
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
        // not
        case 'n': case 'N':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_not;
            }
            break;

        // or org
        case 'o': case 'O':
            if ((inptr[1]=='r' || inptr[1]=='R') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_or;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_org;
            }
            break;
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
        // rts rti rodata
        case 'r': case 'R':
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='s' || inptr[2]=='S') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rts;
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
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_subu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && 
                (inptr[2]=='b' || inptr[2]=='B') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_subui;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sub;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_shli;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sei;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_smr;
            }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_ss;
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

// Return the register number or -1 if not a register.
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
    case 's': case 'S':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 255;
        }
    case 't': case 'T':
        if ((inptr[1]=='R' || inptr[1]=='r') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 252;
        }
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
    case 'p': case 'P':
        if ((inptr[1]=='c' || inptr[1]=='C') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 254;
        }
    default:
        return -1;
    }
}

