// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2018  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// AS64 - Assembler
//  - 64 bit CPU
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
#include "stdafx.h"

char *pinptr;
char lastid[500];
char lastch;
Int128 last_icon;
Int128 ival;
double rval;

int my_isspace(char ch)
{
    if (ch==' ' || ch=='\t' || ch=='\r')
        return 1;
    return 0;
}
int isspaceOrDot(char ch)
{
	return my_isspace(ch) || ch=='.';
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
	return 1;
}
        
int expect(int tk)
{
    if (tk != token) {
        if (tk==tk_comma)
            printf("%d Expecting a , %.60s\r\n", lineno, inptr-30);
    }
    NextToken();
	return 1;
}

void SkipSpaces()
{
    while(my_isspace(*inptr)) inptr++;
}
 
void ScanToEOL()
{
     while(*inptr && *inptr!='\n') inptr++;
     lineno++;
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
void getbase_old(int b)
{
    Int128 i, j, ba;
    i.frac = i.high = i.low = 0;
	ba.frac = 0;
	ba.low = b;
	ba.high = 0;
    while(isalnum(*inptr) || *inptr=='_') {
        if (*inptr=='_') {
            inptr++;
            continue;
        }
        if((j.low = radix36(*inptr)) < b) {
			j.frac = 0;
			j.high = 0;
			Int128::Mul(&i,&i,&ba);
			Int128::Add(&i,&i,&j);
                        //i = i * b + j;
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
*      getbase - get an integer in any base.
*/
void getbase(int b)
{
	Int128 i, j, ba;
	i.frac = i.high = i.low = 0;
	ba.frac = 0;
	ba.low = b;
	ba.high = 0;
	while (isalnum(*inptr) || *inptr == '_' || *inptr == '.') {
		if (*inptr == '_') {
			inptr++;
			continue;
		}
		if (*inptr == '.') {
			inptr++;
			i.frac = j.frac = radix36(*inptr);
			inptr++;
			if (isalnum(*inptr) || *inptr == '_') {
				inptr -= 2;
				break;
			}
			break;
		}
		if ((j.low = radix36(*inptr)) < b) {
			j.frac = 0;
			j.high = 0;
			Int128::Mul(&i, &i, &ba);
			Int128::Add(&i, &i, &j);
			//i = i * b + j;
			inptr++;
		}
		else break;
	}
	if (*inptr == 'L' || *inptr == 'U')	// ignore a 'L'ong suffix and 'U'nsigned
		inptr++;
	ival = i;
	token = tk_icon;
}

/*
 *      getbase - get an integer in base 2.
 */
/*
void getbase2()
{
    Int128 i, j;

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
*/
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
                rval = ival.low;
        if(*inptr == '-') {
                exmul = 0.1;
                inptr++;
                }
        else
                exmul = 10.0;
        getbase(10);
        if(ival.low > 255)
                printf("Error in floating point number.\r\n");
                //error(ERR_FPCON);
        else
                while(ival.low--)
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
                else if(*inptr == 'o' || *inptr == 'O') {
                        inptr++;
                        getbase(8);
                        }
                else getbase(8);
                }
        else    {
                getbase(10);
                if(*inptr == '.') {
                        inptr++;
                        rval = ival.low;    /* float the integer part */
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

//    printf("GetIdentifier: %.30s\r\n", inptr);
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
    "fill", "org", "byte", "message",(char *)NULL
};
static int pseudoTokens[] = {
    tk_align, tk_code, tk_data, tk_tls, tk_rodata,
    tk_fill, tk_org, tk_db, tk_message, tk_none
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
    for (nn = 0; nn < 8; nn++) {
        if (strcmp(buf, pseudos[nn])==0) {
            //inptr = p;
            //token = pseudoTokens[nn];
            return 1;
        }
    }
    return 0;
}

void prevToken()
{
    inptr = pinptr;
}

int NextToken()
{
    pinptr = inptr;    
    do {
        if (*inptr=='\0')
           return token = tk_eof;
        SkipSpaces();                      // skip over leading spaces
        if (*inptr==';') {                 // comment ?
            ScanToEOL();
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
        case '%': inptr++; getbase(2); return token = tk_icon;
        case ',': inptr++; return token = ',';
        case '+':
             if (inptr[1]=='}') {
               inptr += 2;
               return token = tk_end_expand;
             }
             inptr++; return token = '+';
        case '-': inptr++; return token = '-';
        case '/':
             if (inptr[1]=='/') {
                ScanToEOL();
                continue;
             }
             if (inptr[1]=='*') {
             	inptr++;
             	do {
	             	if (inptr[0]=='\0') return token = tk_eof;
             		inptr++;
             	} while(!(inptr[0]=='*' && inptr[1]=='/'));
             	continue;
			 }
             inptr++; 
             return token = '/';
        case '*': inptr++; return token = '*';
        case '#': inptr++; return token = '#';
        case '[': inptr++; return token = '[';
        case ']': inptr++; return token = ']';
        case '(': inptr++; return token = '(';
        case ')': inptr++; return token = ')';
        case '{':
             if (inptr[1]=='+') {
               inptr+=2;
               return token=tk_begin_expand;
             }
             break;
        case ':': inptr++; return token = ':';
        case '\'':
             inptr++;
             ival.low = getsch();
			 ival.high = 0;
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

        case '_':
             if (inptr[1]=='4' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
                return token = tk_4addu;
             }
             if (inptr[1]=='2' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
                return token = tk_2addu;
             }
             if (inptr[1]=='8' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
                return token = tk_8addu;
             }
             if (inptr[1]=='1' && inptr[2]=='6' &&
             (inptr[3]=='a' || inptr[3]=='A') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='d' || inptr[5]=='D') &&
             (inptr[6]=='u' || inptr[6]=='U') &&
             isspace(inptr[7])) {
                inptr += 7;
                return token = tk_16addu;
             }
             if (inptr[1]=='4' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             (inptr[6]=='i' || inptr[6]=='I') &&
             isspace(inptr[7])) {
                inptr += 7;
                return token = tk_4addui;
             }
             if (inptr[1]=='2' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             (inptr[6]=='i' || inptr[6]=='I') &&
             isspace(inptr[7])) {
                inptr += 7;
                return token = tk_2addui;
             }
             if (inptr[1]=='8' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             (inptr[6]=='i' || inptr[6]=='I') &&
             isspace(inptr[7])) {
                inptr += 7;
                return token = tk_8addui;
             }
             if (inptr[1]=='1' && inptr[2]=='6' &&
             (inptr[3]=='a' || inptr[3]=='A') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='d' || inptr[5]=='D') &&
             (inptr[6]=='u' || inptr[6]=='U') &&
             (inptr[7]=='i' || inptr[7]=='I') &&
             isspace(inptr[8])) {
                inptr += 8;
                return token = tk_16addui;
             }
             break;

        // abs add addi addu addui and andi align asr asri
        case 'a':
        case 'A':
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_and;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='u' || inptr[3]=='U') && isspaceOrDot(inptr[4])) {
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
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_addi;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_add;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='g' || inptr[3]=='G') && (inptr[4]=='n' || inptr[4]=='N') && isspace(inptr[5])) {
                inptr += 5;
                return token = tk_align;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_andi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_asri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_asr;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_asli;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_asl;
            }
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='s' || inptr[2]=='S') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_abs;
            }
            break;

        // beq bne bit
        case 'b':
        case 'B':
            if ((inptr[1]=='e' || inptr[1]=='E') && 
                (inptr[2]=='q' || inptr[2]=='Q') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_beq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && 
                (inptr[2]=='q' || inptr[2]=='Q') &&
                (inptr[3]=='i' || inptr[2]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_beqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
                return token = tk_bne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bnei;
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
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_blti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bltui;
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
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_blei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bleui;
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
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bgeui;
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
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgti;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bgtui;
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
            if ((inptr[1]=='i' || inptr[1]=='I') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_bits;
            }
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                inptr += 4;
                return token = tk_db;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='x' || inptr[3]=='X') &&
                (inptr[4]=='t' || inptr[4]=='T') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bfext;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                (inptr[3]=='n' || inptr[3]=='N') &&
                (inptr[4]=='s' || inptr[4]=='S') &&
                 isspace(inptr[5])) {
                inptr += 5;
                return token = tk_bfins;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='x' || inptr[3]=='X') &&
                (inptr[4]=='t' || inptr[4]=='T') &&
                (inptr[5]=='u' || inptr[5]=='U') &&
                 isspace(inptr[6])) {
                inptr += 6;
                return token = tk_bfextu;
            }
            if (gCpu==4) {
                if ((inptr[1]=='r' || inptr[1]=='R') && isspace(inptr[2])) {
                    inptr += 2;
                    return token = tk_br;
                }      
                if ((inptr[1]=='i' || inptr[1]=='I') && 
                    (inptr[2]=='t' || inptr[2]=='T') &&
                     isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_bit;
                }
                if ((inptr[1]=='i' || inptr[1]=='I') && 
                    (inptr[2]=='t' || inptr[2]=='T') &&
                    (inptr[3]=='i' || inptr[3]=='I') &&
                     isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_biti;
                }
            }
			if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='H') {
                if ((inptr[1]=='b' || inptr[1]=='B') && 
                    (inptr[2]=='c' || inptr[2]=='C') &&
                     isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_bbc;
                }
                if ((inptr[1]=='b' || inptr[1]=='B') && 
                    (inptr[2]=='s' || inptr[2]=='S') &&
                     isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_bbs;
                }
			}
            break;

        // call cas chk cmp cmpu code cli com cmpi csrrc csrrs csrrw
        case 'c': case 'C':
			if (gCpu=='F' || gCpu=='G' || gCpu=='H') {
				if ((inptr[1]=='a' || inptr[1]=='A')
					&& (inptr[2]=='c' || inptr[2]=='C')
					&& (inptr[3]=='h' || inptr[3]=='H')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& isspace(inptr[5])) {
						inptr += 5;
						return (token = tk_cache);
				}
			}
			 if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='G' || gCpu=='H') {
                 if ((inptr[1]=='a' || inptr[1]=='A') &&
                     (inptr[2]=='l' || inptr[2]=='L') &&
                     (inptr[3]=='l' || inptr[3]=='L') &&
                     isspace(inptr[4])) {
                     inptr += 4;
                     return token = tk_call;
                 }
                 if ((inptr[1]=='a' || inptr[1]=='A') &&
                     (inptr[2]=='l' || inptr[2]=='L') &&
                     (inptr[3]=='l' || inptr[3]=='L') &&
                     (inptr[4]=='t' || inptr[4]=='T') &&
                     (inptr[5]=='g' || inptr[5]=='G') &&
                     (inptr[6]=='t' || inptr[6]=='T') &&
                     isspace(inptr[7])) {
                     inptr += 7;
                     return token = tk_calltgt;
                 }
			 }
             if (gCpu==4) {
                 if ((inptr[1]=='m' || inptr[1]=='M') &&
                     (inptr[2]=='p' || inptr[2]=='P') &&
                     (inptr[3]=='i' || inptr[3]=='I') &&
                     isspaceOrDot(inptr[4])) {
                     inptr += 4;
                     return token = tk_cmpi;
                 }
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
                 return token = tk_cmpu;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                 inptr += 5;
                 return token = tk_cmpui;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspaceOrDot(inptr[3])) {
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
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
                 return token = tk_com;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_cs;
             }
             if ((inptr[1]=='p' || inptr[1]=='P') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='d' || inptr[4]=='D') &&
                 isspace(inptr[5])) {
                 inptr += 5;
                 return token = tk_cpuid;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_cas;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_chk;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_chki;
             }
             if (gCpu==5 || gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='G' || gCpu=='H') {
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='c' || inptr[4]=='C') &&
                   isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_csrrc;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='d' || inptr[4]=='D') &&
                   isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_csrrd;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='s' || inptr[4]=='S') &&
                   isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_csrrs;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='w' || inptr[4]=='W') &&
                   isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_csrrw;
                   }
             }
             break;

        // db dbnz dc dh dw data div divs divu divi divui ds:
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
			 if (gCpu=='A') {
				 if ((inptr[1]=='d' || inptr[1]=='D') && isspace(inptr[2])) {
					 inptr += 2;
					 return token = tk_dd;
				 }
				 if ((inptr[1]=='o' || inptr[1]=='O') && isspace(inptr[2])) {
					 inptr += 2;
					 return token = tk_do;
				 }
				 if ((inptr[1]=='t' || inptr[1]=='T') && isspace(inptr[2])) {
					 inptr += 2;
					 return token = tk_dt;
				 }
			 }
             if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_dw;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='v' || inptr[2]=='V') && isspaceOrDot(inptr[3])) {
                 inptr += 3;
                 return token = tk_div;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                  isspaceOrDot(inptr[4])) {
                 inptr += 4;
                 return token = tk_divi;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
                 return token = tk_divu;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                 inptr += 5;
                 return token = tk_divui;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='v' || inptr[2]=='V') &&
                 (inptr[3]=='s' || inptr[3]=='S') &&
                 isspaceOrDot(inptr[4])) {
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
             if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='c' || inptr[2]=='C') && (isspace(inptr[3])||inptr[3]=='.')) {
                 inptr += 3;
                 return token = tk_dec;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='_' || inptr[2]=='_') &&
                 (inptr[3]=='h' || inptr[3]=='H') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (inptr[5]=='b' || inptr[4]=='B') &&
                 (inptr[6]=='l' || inptr[4]=='L') &&
                 isspace(inptr[7])) {
                 inptr += 7;
                 return token = tk_dh_htbl;
             }
             break;

        // end eor eori endif endpublic extern equ eret es
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
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
                 return token = tk_eori;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
                 return token = tk_eor;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_end;
             }
             if ((inptr[1]=='n' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='f' || inptr[4]=='F') &&
                 isspace(inptr[5])) {
                 inptr += 5;
                 return token = tk_endif;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_else;
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
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
                 return token = tk_es;
             }
			 if (gCpu==5) {
				 if ((inptr[1]=='r' || inptr[1]=='R') &&
					 (inptr[2]=='e' || inptr[2]=='E') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 isspace(inptr[4])) {
					 inptr += 4;
					 return token = tk_eret;
				 }
			 }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='m' || inptr[3]=='M') &&
                 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_endm;
             }
             break;

        // fill fabs fadd fb__
		// fcmp fcx fdiv fmul fnabs fneg fsub fix2flt flt2fix ftst ftoi
        case 'f': case 'F':
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='l' || inptr[2]=='L') &&
                 (inptr[3]=='l' || inptr[3]=='L') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fill;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='d' || inptr[3]=='D') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fadd;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='b' || inptr[3]=='B') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fsub;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 (inptr[3]=='p' || inptr[3]=='P') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fcmp;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='l' || inptr[3]=='L') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fmul;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='o' || inptr[2]=='O') &&
                 (inptr[3]=='v' || inptr[3]=='V') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fmov;
             }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 (inptr[3]=='v' || inptr[3]=='V') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fdiv;
             }
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (inptr[3]=='2' || inptr[3]=='2') &&
                 (inptr[4]=='f' || inptr[3]=='F') &&
                 (inptr[5]=='l' || inptr[3]=='L') &&
                 (inptr[6]=='t' || inptr[3]=='T') &&
                 (isspace(inptr[7]) || inptr[7]=='.')) {
                 inptr += 7;
                 return token = tk_fix2flt;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='2' || inptr[3]=='2') &&
                 (inptr[4]=='f' || inptr[3]=='F') &&
                 (inptr[5]=='i' || inptr[3]=='I') &&
                 (inptr[6]=='x' || inptr[3]=='X') &&
                 (isspace(inptr[7]) || inptr[7]=='.')) {
                 inptr += 7;
                 return token = tk_flt2fix;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='b' || inptr[2]=='B') &&
                 (inptr[3]=='s' || inptr[3]=='S') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fabs;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='g' || inptr[3]=='G') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_fneg;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='a' || inptr[2]=='A') &&
                 (inptr[3]=='b' || inptr[3]=='B') &&
                 (inptr[4]=='s' || inptr[4]=='S') &&
                 (isspace(inptr[5]) || inptr[5]=='.')) {
                 inptr += 5;
                 return token = tk_fnabs;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
                 return token = tk_fcx;
             }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
                 return token = tk_fdx;
             }
             if ((inptr[1]=='e' || inptr[1]=='E') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
                 return token = tk_fex;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
                 return token = tk_frm;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
                 return token = tk_ftx;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (isspace(inptr[5]))) {
                 inptr += 5;
                 return token = tk_fstat;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
                 (isspace(inptr[4])||inptr[4]=='.')) {
                 inptr += 4;
                 return token = tk_ftst;
             }
			 if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='H') {
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='e' || inptr[2]=='E') &&
					 (inptr[3]=='q' || inptr[3]=='Q') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbeq;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='n' || inptr[2]=='N') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbne;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='l' || inptr[2]=='L') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fblt;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='l' || inptr[2]=='L') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fble;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='g' || inptr[2]=='G') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbgt;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='g' || inptr[2]=='G') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbge;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='r' || inptr[3]=='R') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbor;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='u' || inptr[2]=='U') &&
					 (inptr[3]=='n' || inptr[3]=='N') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_fbun;
				 }
				 if ((inptr[1]=='t' || inptr[1]=='T') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='i' || inptr[3]=='I') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_ftoi;
				 }
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

		// hs hint
        case 'h': case 'H':
			if ((inptr[1]=='I' || inptr[1]=='i') &&
				(inptr[2]=='N' || inptr[2]=='n') &&
				(inptr[3]=='T' || inptr[3]=='t') &&
				isspace(inptr[4])) {
				inptr += 4;
				return (token = tk_hint);
			}
             if (gCpu==4) {
                 if ((inptr[1]=='s' || inptr[1]=='S') &&
                     (inptr[2]==':')) {
                     inptr += 3;
                     return token = tk_hs;
                 }
             }
             break;
             
        // ibne if ifdef ifndef ios inc int iret ipush ipop itof
        case 'i': case 'I':
			if (gCpu=='F' || gCpu=='H') {
				if ((inptr[1]=='b' || inptr[1]=='B') &&
					(inptr[2]=='n' || inptr[2]=='N') &&
					(inptr[3]=='e' || inptr[3]=='E') &&
					isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ibne;
				}
			}
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]==':')) {
                 inptr += 3;
                 return token = tk_ios;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='c' || inptr[2]=='C') &&
                 (isspace(inptr[3]) || inptr[3]=='.')) {
                 inptr += 3;
                 return token = tk_inc;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_int;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
				 isspace(inptr[4])) {
                 inptr += 4;
                 return token = tk_iret;
             }
			 if (gCpu==7) {
				 if ((inptr[1]=='p' || inptr[1]=='P') &&
					 (inptr[2]=='u' || inptr[2]=='U') &&
					 (inptr[3]=='s' || inptr[3]=='S') &&
					 (inptr[4]=='h' || inptr[4]=='H') &&
					 isspace(inptr[5])) {
					 inptr += 5;
					 return token = tk_ipush;
				 }
				 if ((inptr[1]=='p' || inptr[1]=='P') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='p' || inptr[3]=='P') &&
					 isspace(inptr[4])) {
					 inptr += 4;
					 return token = tk_ipop;
				 }
			 }
			 if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='H') {
				 if ((inptr[1]=='t' || inptr[1]=='T') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='f' || inptr[3]=='F') &&
					 (isspace(inptr[4]) || inptr[4]=='.')) {
					 inptr += 4;
					 return token = tk_itof;
				 }
			 }
             if (inptr[1]=='f' || inptr[1]=='F') {
				if ((inptr[2]=='d' || inptr[2]=='D')
					&& (inptr[3]=='e' || inptr[3]=='E')
					&& (inptr[4]=='f' || inptr[3]=='F')
					&& (isspace(inptr[5]) || inptr[5]=='.')) {
						inptr += 5;
						return token = tk_ifdef;
				}
				if ((inptr[2]=='n' || inptr[2]=='N')
					&& (inptr[3]=='d' || inptr[3]=='D')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& (inptr[5]=='f' || inptr[5]=='F')
					&& (isspace(inptr[6]) || inptr[6]=='.')) {
						inptr += 6;
						return token = tk_ifndef;
				}
				if (isspace(inptr[2]) || inptr[2]=='.') {
					inptr += 2;
					return token = tk_if;
				}
             }
             break;

        // jal jgr jmp jsf jsr jsp jci jhi
        case 'j': case 'J':
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='l' || inptr[2]=='L') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jal;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jsr;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='f' || inptr[2]=='F') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jsf;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jmp;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jsp;
             }
             if ((inptr[1]=='g' || inptr[1]=='G') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_jgr;
             }
             if (gCpu==4) {
                if ((inptr[1]=='c' || inptr[1]=='C') &&
                    (inptr[2]=='i' || inptr[2]=='I') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_jci;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') &&
                    (inptr[2]=='i' || inptr[2]=='I') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_jhi;
                }
             }
             break;

        // lb lbu lc lcu lf lh lhu lw ld ldi ldis lea lsr lsri lwar lfd lvb lws lvh lvw ltcb link
        case 'l':
        case 'L':
			if (gCpu=='A') {
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ldd;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ldb;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ldbu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ldw;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ldwu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ldt;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ldtu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ldp;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ldpu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='v' || inptr[2]=='V') &&
					(inptr[3]=='d' || inptr[3]=='D') &&
					(inptr[4]=='a' || inptr[4]=='A') &&
					(inptr[5]=='r' || inptr[5]=='R') &&
					isspace(inptr[6])) {
					inptr += 6;
					return token = tk_ldvdar;
				}  
			}
            if ((inptr[1]=='d' || inptr[1]=='D') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_ld;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && (isspace(inptr[2]) || inptr[2]=='.')) {
                inptr += 2;
                return token = tk_lb;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_lbu;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspaceOrDot(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
                return token = tk_lf;
            }  
            if ((inptr[1]=='v' || inptr[1]=='V') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_lv;
            }  
            if ((inptr[1]=='w' || inptr[1]=='W') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_lw;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_lh;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_lhu;
            }
            if ((inptr[1]=='c' || inptr[1]=='C') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_lc;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_lcu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_ldi;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='n' || inptr[2]=='N') && (inptr[3]=='k' || inptr[3]=='K') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_link;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='s' || inptr[3]=='S') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_ldis;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='a' || inptr[2]=='A') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lea;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lmr;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_lsri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lsr;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_lfd;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='a' || inptr[2]=='A') && (inptr[3]=='r' || inptr[3]=='R') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_lwar;
            }
			if (gCpu=='F' || gCpu=='G' || gCpu=='H') {
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='b' || inptr[2]=='B') && isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return (token = tk_lvb);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='c' || inptr[2]=='C') && isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return (token = tk_lvc);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='h' || inptr[2]=='H') && isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return (token = tk_lvh);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='w' || inptr[2]=='W') && isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return (token = tk_lvw);
                }
                if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return (token = tk_lwr);
                }
			}
            if (gCpu==4) {
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lvb;
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lvc;
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='h' || inptr[2]=='H') && isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lvh;
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='w' || inptr[2]=='W') && isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lvw;
                }
                if ((inptr[1]=='v' || inptr[1]=='V') &&
                    (inptr[2]=='w' || inptr[2]=='W') &&
                    (inptr[3]=='a' || inptr[3]=='A') &&
                    (inptr[4]=='r' || inptr[4]=='R') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_lvwar;
                }
                if ((inptr[1]=='w' || inptr[1]=='W') &&
                    (inptr[2]=='s' || inptr[2]=='S') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lws;
                }  
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='p' || inptr[3]=='P') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_loop;
                }  
                if ((inptr[1]=='l' || inptr[1]=='L') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lla;
                }  
                if ((inptr[1]=='l' || inptr[1]=='L') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    (inptr[3]=='x' || inptr[3]=='X') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_llax;
                }  
            }
			if (gCpu==7) {
				if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='b' || inptr[3]=='B') && isspace(inptr[4])) {
					inptr += 4;
					return token = tk_ltcb;
				}
			}
            break;

        // max mod modu modi modui mov mul muli mulu mului mtspr mfspr mtfp mffp message memdb memsb
        case 'm': case 'M':
            if ((inptr[1]=='a' || inptr[1]=='A') && (inptr[2]=='x' || inptr[2]=='X') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_max;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='v' || inptr[2]=='V') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_mov;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_mul;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_mulu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_mului;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_muli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_mod;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_modu;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_modi;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_modui;
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
            if ((inptr[1]=='t' || inptr[1]=='T') &&
                (inptr[2]=='f' || inptr[2]=='F') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_mtfp;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') &&
                (inptr[2]=='f' || inptr[2]=='F') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_mffp;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                (inptr[4]=='a' || inptr[4]=='A') &&
                (inptr[5]=='g' || inptr[5]=='G') &&
                (inptr[6]=='e' || inptr[6]=='E') &&
                isspace(inptr[7])) {
                inptr += 7;
                return token = tk_message;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') &&
                (inptr[2]=='2' || inptr[2]=='2') &&
                (inptr[3]=='f' || inptr[3]=='F') &&
                (inptr[4]=='l' || inptr[4]=='L') &&
                (inptr[5]=='t' || inptr[5]=='T') &&
                isspace(inptr[6])) {
                inptr += 6;
                return token = tk_mv2flt;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') &&
                (inptr[2]=='2' || inptr[2]=='2') &&
                (inptr[3]=='f' || inptr[3]=='F') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                (inptr[5]=='x' || inptr[5]=='X') &&
                isspace(inptr[6])) {
                inptr += 6;
                return token = tk_mv2fix;
            }
            if (gCpu==4) {
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='m' || inptr[2]=='M') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    (inptr[4]=='b' || inptr[4]=='B') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_memdb;
                }
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='m' || inptr[2]=='M') &&
                    (inptr[3]=='s' || inptr[3]=='S') &&
                    (inptr[4]=='b' || inptr[4]=='B') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_memsb;
                }
            }
			if (gCpu=='A') {
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    (inptr[3]=='k' || inptr[3]=='K') &&
                    (inptr[4]=='1' || inptr[4]=='1') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_mark1;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    (inptr[3]=='k' || inptr[3]=='K') &&
                    (inptr[4]=='2' || inptr[4]=='2') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_mark2;
                }
			}
            if ((inptr[1]=='a' || inptr[1]=='A') &&
                (inptr[2]=='r' || inptr[2]=='R') &&
                (inptr[3]=='c' || inptr[3]=='C') &&
                (inptr[4]=='o' || inptr[4]=='O') &&
                isspace(inptr[5])) {
                inptr += 5;
                return token = tk_macro;
            }
            break;

        // not neg nop
        case 'n': case 'N':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_not;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='g' || inptr[2]=='G') && isspaceOrDot(inptr[3])) {
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
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='i' || inptr[2]=='I') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_ori;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_or;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_org;
            }
            break;

        // pea push pop php plp public
        case 'p': case 'P':
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='h' || inptr[3]=='H') &&
                isspace(inptr[4]) || inptr[4]=='.') {
                inptr += 4;
                return token = tk_push;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3]) || inptr[3]=='.') {
                inptr += 3;
                return token = tk_pop;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_pea;
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
            if (gCpu==4) {
                if (isdigit(inptr[1]) && (inptr[2]=='.' || inptr[2]==',' || isspace(inptr[2]))) {
                    inptr += 1;
                    return token = tk_pred;
                }
                if (isdigit(inptr[1]) && isdigit(inptr[2]) && (inptr[3]=='.' || inptr[3]==',' || isspace(inptr[3]))) {
                    inptr += 1;
                    return token = tk_pred;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_pand;
                }
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_por;
                }
                if ((inptr[1]=='e' || inptr[1]=='R') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='r' || inptr[3]=='R') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_peor;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    (inptr[4]=='c' || inptr[4]=='C') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_pandc;
                }
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    (inptr[3]=='c' || inptr[3]=='C') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_porc;
                }
                if ((inptr[1]=='n' || inptr[1]=='N') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    (inptr[3]=='n' || inptr[3]=='N') &&
                    (inptr[4]=='d' || inptr[4]=='D') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_pnand;
                }
                if ((inptr[1]=='n' || inptr[1]=='N') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='r' || inptr[3]=='R') &&
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_pnor;
                }
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='o' || inptr[3]=='O') &&
                    (inptr[4]=='r' || inptr[4]=='R') &&
                    isspace(inptr[5])) {
                    inptr += 5;
                    return token = tk_penor;
                }
            }
            break;

        // ret rex rol roli ror rori rtd rte rtf rts rti rtl rodata
        case 'r': case 'R':
			if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='H') {
				if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
					inptr += 3;
					return token = tk_ret;
				}
				if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='x' || inptr[2]=='X') && isspace(inptr[3])) {
					inptr += 3;
					return token = tk_rex;
				}
			}
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='s' || inptr[2]=='S') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rts;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='f' || inptr[2]=='F') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rtf;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='l' || inptr[2]=='L') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rtl;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_rol;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_roli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_ror;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_rori;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rti;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rte;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_rtd;
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
        
        // sb sc sf sh sw sxb sxc sxh sub subi subu subui shl shli shr shru shrui sei smr ss:
        // seq seqi sne snei sge sgei sgt sgti slt slti sle slei sgeu sgeui sgtu sgtui sltu sltui sleu sleui
        // swcr sfd sts sync sws stcmp stmov srai srli stcb sv
		// DSD9: stb stw stp std
        case 's': case 'S':
			if (gCpu=='A') {
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_std;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					(inptr[3]=='c' || inptr[3]=='C') &&
					(inptr[4]=='r' || inptr[4]=='R') &&
					isspace(inptr[5])) {
					inptr += 5;
					return token = tk_stdcr;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_stb;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_stp;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_stt;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					isspace(inptr[3])) {
					inptr += 3;
					return token = tk_stw;
				}  
			}
            if ((inptr[1]=='w' || inptr[1]=='W') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_sw;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_sb;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_sc;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspaceOrDot(inptr[2])) {
                inptr += 2;
                return token = tk_sh;
            }  
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspace(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
                return token = tk_sf;
            }  
            if ((inptr[1]=='u' || inptr[1]=='U') && 
                (inptr[2]=='b' || inptr[2]=='B') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_subui;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_subi;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='u' || inptr[3]=='U') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_subu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_sub;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sfd;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_shli;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_shl;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_shrui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_shru;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                isspaceOrDot(inptr[3])) {
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
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_seq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_seqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_sne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_snei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_sge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_sgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sgti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_sle;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_slei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_slt;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_slti;
            }

            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sgeui;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_sgtui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_sleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_sltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
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
            if ((inptr[1]=='v' || inptr[1]=='V') && isspace(inptr[2])) {
                inptr += 2;
                return token = tk_sv;
            }  
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='s' || inptr[2]=='S') && 
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_sys;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && 
                (inptr[2]=='p' || inptr[2]=='P') && 
                isspace(inptr[3])) {
                inptr += 3;
                return token = tk_stp;
            }
            if (gCpu==4) {
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='b' || inptr[3]=='B') && 
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_stsb;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='c' || inptr[3]=='C') && 
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_stsc;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='h' || inptr[3]=='H') && 
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_stsh;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='w' || inptr[3]=='W') && 
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_stsw;
                }
                if ((inptr[1]=='w' || inptr[1]=='W') &&
                    (inptr[2]=='s' || inptr[2]=='S') &&
                    isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_sws;
                }  
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='c' || inptr[2]=='C') && 
                    (inptr[3]=='m' || inptr[3]=='M') && 
                    (inptr[4]=='p' || inptr[4]=='P') && 
                    inptr[5]=='.') {
                    inptr += 6;
                    return token = tk_stcmp;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='m' || inptr[2]=='M') && 
                    (inptr[3]=='o' || inptr[3]=='O') && 
                    (inptr[4]=='v' || inptr[4]=='V') && 
                    inptr[5]=='.') {
                    inptr += 6;
                    return token = tk_stmov;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='e' || inptr[3]=='E') && 
                    (inptr[4]=='t' || inptr[4]=='T') && 
                    inptr[5]=='.') {
                    inptr += 6;
                    return token = tk_stset;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') && 
                    (inptr[2]=='r' || inptr[2]=='R') && 
                    (inptr[3]=='i' || inptr[3]=='I') && 
                    isspace(inptr[4])) {
                    inptr += 4;
                    return token = tk_shri;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') && 
                    (inptr[2]=='r' || inptr[2]=='R') && 
                    isspaceOrDot(inptr[3])) {
                    inptr += 3;
                    return token = tk_shr;
                }
            }
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='n' || inptr[2]=='N') && 
                (inptr[3]=='c' || inptr[3]=='C') && 
                isspace(inptr[4])) {
                inptr += 4;
                return token = tk_sync;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='r' || inptr[3]=='R') && isspace(inptr[4])) {
                inptr += 4;
                return token = tk_swcr;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                inptr += 3;
                return token = tk_swc;
            }
            // RiSC-V opcodes
            // slli srli srai
            if (gCpu==5) {
              if ((inptr[1]=='l' || inptr[1]=='L') && 
                  (inptr[2]=='l' || inptr[2]=='L') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
                  return token = tk_slli;
              }
              if ((inptr[1]=='r' || inptr[1]=='R') && 
                  (inptr[2]=='a' || inptr[2]=='A') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
                  return token = tk_srai;
              }
              if ((inptr[1]=='r' || inptr[1]=='R') && 
                  (inptr[2]=='l' || inptr[2]=='L') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
                  return token = tk_srli;
              }
            }
			// DSD7
			if (gCpu==7) {
				if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='b' || inptr[3]=='B') && isspace(inptr[4])) {
					inptr += 4;
					return token = tk_stcb;
				}
			}
            break;

        // tgt to tlbdis tlben tlbpb tlbrd tlbrdreg tlbwi tlbwr tlbwrreg
        case 't': case 'T':
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 isspace(inptr[2])) {
                 inptr += 2;
                 return token = tk_to;
             }
			 if (gCpu=='A') {
                 if ((inptr[1]=='g' || inptr[1]=='G') &&
                     (inptr[2]=='t' || inptr[2]=='T') &&
                     isspace(inptr[3])) {
                     inptr += 3;
                     return token = tk_tgt;
                 }
			 }
             if (gCpu==4) {
                 if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='t' || inptr[2]=='T') &&
                     isspace(inptr[3])) {
                     inptr += 3;
                     return token = tk_tst;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='d' || inptr[3]=='D') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     (inptr[5]=='s' || inptr[5]=='S') &&
                     isspace(inptr[6])) {
                     inptr += 6;
                     return token = tk_tlbdis;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='e' || inptr[3]=='E') &&
                     (inptr[4]=='n' || inptr[4]=='N') &&
                     isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_tlben;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='p' || inptr[3]=='P') &&
                     (inptr[4]=='b' || inptr[4]=='B') &&
                     isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_tlbpb;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='r' || inptr[3]=='R') &&
                     (inptr[4]=='d' || inptr[4]=='D') &&
                     isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_tlbrd;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='r' || inptr[3]=='R') &&
                     (inptr[4]=='d' || inptr[4]=='D') &&
                     (inptr[5]=='r' || inptr[5]=='R') &&
                     (inptr[6]=='e' || inptr[6]=='E') &&
                     (inptr[7]=='g' || inptr[7]=='G') &&
                     isspace(inptr[8])) {
                     inptr += 8;
                     return token = tk_tlbrdreg;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_tlbwi;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='r' || inptr[4]=='R') &&
                     isspace(inptr[5])) {
                     inptr += 5;
                     return token = tk_tlbwr;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='r' || inptr[4]=='R') &&
                     (inptr[5]=='r' || inptr[5]=='R') &&
                     (inptr[6]=='e' || inptr[6]=='E') &&
                     (inptr[7]=='g' || inptr[7]=='G') &&
                     isspace(inptr[8])) {
                     inptr += 8;
                     return token = tk_tlbwrreg;
                 }
             }
             break;
		
		// unlink
		case 'u': case 'U':
            if ((inptr[1]=='n' || inptr[1]=='N') &&
				(inptr[2]=='l' || inptr[2]=='L') &&
				(inptr[3]=='i' || inptr[3]=='I') &&
				(inptr[4]=='n' || inptr[4]=='N') &&
				(inptr[5]=='k' || inptr[5]=='K') &&
				isspace(inptr[6])) {
                inptr += 6;
                return token = tk_unlink;
            }
			break;

		// vadd vdiv vmul vsub
		case 'v': case 'V':
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='d' || inptr[2]=='D') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vadd;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='d' || inptr[2]=='D') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vadds;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='n' || inptr[2]=='N') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vand;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='n' || inptr[2]=='N') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vands;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') &&
				(inptr[2]=='i' || inptr[2]=='I') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vdiv;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') &&
				(inptr[2]=='i' || inptr[2]=='I') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vdivs;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vmov;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='l' || inptr[3]=='L') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vmul;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='l' || inptr[3]=='L') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vmuls;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
				(inptr[2]=='r' || inptr[2]=='R') &&
				isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_vor;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
				(inptr[2]=='r' || inptr[2]=='R') &&
				(inptr[3]=='s' || inptr[3]=='S') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vors;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='b' || inptr[3]=='B') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vsub;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='b' || inptr[3]=='B') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vsubs;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='r' || inptr[3]=='R') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_vxor;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='r' || inptr[3]=='R') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
                return token = tk_vxors;
            }
			break;

        // wai
        case 'w': case 'W':
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                 inptr += 3;
                 return token = tk_wai;
             }
             break;

        // xor xori
        case 'x': case 'X':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
                return token = tk_xori;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
                return token = tk_xor;
            }
            break;

        // zs:
        case 'z': case 'Z':
            if (gCpu==4) {
                if ((inptr[1]=='s'||inptr[1]=='S') && inptr[2]==':') {
                    inptr += 3;
                    return token = tk_zs;
                }
                if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='b' || inptr[2]=='B') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
                    return token = tk_zxb;
                }
                if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='c' || inptr[2]=='C') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
                    return token = tk_zxc;
                }
                if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='h' || inptr[2]=='h') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
                    return token = tk_zxh;
                }
            }
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
    case 'g': case 'G':
        if ((inptr[1]=='P' || inptr[1]=='p') && !isIdentChar(inptr[2])) {
            inptr += 2;
            NextToken();
            return 249;
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
// Return the register number or -1 if not a register.
// ----------------------------------------------------------------------------

int getFPRegister()
{
    int reg;

    while(isspace(*inptr)) inptr++;
	if (*inptr=='$')
		inptr++;
    switch(*inptr) {
    case 'f': case 'F':
         if (inptr[1]=='p' || inptr[1]=='P') {
         if (isdigit(inptr[2])) {
             reg = inptr[2]-'0';
             if (isdigit(inptr[3])) {
                 reg = 10 * reg + (inptr[3]-'0');
                 if (isdigit(inptr[4])) {
                     reg = 10 * reg + (inptr[4]-'0');
                     if (isIdentChar(inptr[5]))
                         return -1;
                     inptr += 5;
                     NextToken();
                     return reg;
                 }
                 else if (isIdentChar(inptr[4]))
                     return -1;
                 else {
                     inptr += 4;
                     NextToken();
                     return reg;
                 }
             }
             else if (isIdentChar(inptr[3]))
                 return -1;
             else {
                 inptr += 3;
                 NextToken();
                 return reg;
             }
         }
         else return -1;
         }
         else return -1;
    default:
        return -1;
    }
    return -1;
}

// ----------------------------------------------------------------------------
// Return the FP round mode.
// ----------------------------------------------------------------------------

int getFPRoundMode()
{
    while(isspace(*inptr) || *inptr==',') inptr++;
    switch(*inptr) {
    case 'r': case 'R':
         if ((inptr[1]=='n' || inptr[1]=='N') &&
             (inptr[2]=='e' || inptr[2]=='E') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 0;
         }
         if ((inptr[1]=='t' || inptr[1]=='T') &&
             (inptr[2]=='z' || inptr[2]=='Z') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 1;
         }
         if ((inptr[1]=='d' || inptr[1]=='D') &&
             (inptr[2]=='n' || inptr[2]=='N') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 2;
         }
         if ((inptr[1]=='u' || inptr[1]=='U') &&
             (inptr[2]=='p' || inptr[2]=='P') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 3;
         }
         if ((inptr[1]=='m' || inptr[1]=='M') &&
             (inptr[2]=='m' || inptr[2]=='M') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 4;
         }
         if ((inptr[1]=='f' || inptr[1]=='F') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             !isIdentChar(inptr[3]))
         {
             inptr += 3;
             NextToken();
             return 7;
         }
    default:
        return 7;
    }
    return 7;
}

// ----------------------------------------------------------------------------
// Get the friendly name of a special purpose register.
// ----------------------------------------------------------------------------

int getSprRegister()
{
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
             if (gCpu==889)
                return 0x2F;
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
    
    // es
    case 'e': case 'E':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x25;
         }
         break;
    
    // fs
    case 'f': case 'F':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x26;
         }
         if ((inptr[1]=='a' || inptr[1]=='A') &&
             (inptr[2]=='u' || inptr[2]=='U') &&
             (inptr[3]=='l' || inptr[3]=='L') &&
             (inptr[4]=='t' || inptr[4]=='T') &&
             (inptr[5]=='_' || inptr[5]=='_') &&
             (inptr[6]=='p' || inptr[6]=='P') &&
             (inptr[7]=='c' || inptr[7]=='C') &&
             !isIdentChar(inptr[8])) {
             inptr += 8;
             NextToken();
             return 0x08;
         }
         break;

    // GDT gs
    case 'g': case 'G':
         if ((inptr[1]=='d' || inptr[1]=='D') &&
             (inptr[2]=='t' || inptr[2]=='T') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x19;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x27;
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

    // ios ivno
    case 'i': case 'I':
         if ((inptr[1]=='o' || inptr[1]=='O') &&
             (inptr[2]=='s' || inptr[2]=='S') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x2B;
         }
         if ((inptr[1]=='v' || inptr[1]=='V') &&
             (inptr[2]=='n' || inptr[2]=='N') &&
             (inptr[3]=='o' || inptr[3]=='O') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x0C;
         }
         break;

    // LDT
    case 'l': case 'L':
         if ((inptr[1]=='d' || inptr[1]=='D') &&
             (inptr[2]=='t' || inptr[2]=='T') &&
             !isIdentChar(inptr[3])) {
             inptr += 3;
             NextToken();
             return 0x18;
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
    // ss ss_ll srand1 srand2
    case 's': case 'S':
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             (inptr[2]=='_' || inptr[2]=='_') &&
             (inptr[3]=='l' || inptr[3]=='L') &&
             (inptr[4]=='l' || inptr[4]=='L') &&
             !isIdentChar(inptr[5])) {
             inptr += 5;
             NextToken();
             return 0x1A;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             if (gCpu==889)
                return 0x2E;
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

    // tick ts
    case 't': case 'T':
         if ((inptr[1]=='i' || inptr[1]=='I') &&
             (inptr[2]=='c' || inptr[2]=='C') &&
             (inptr[3]=='k' || inptr[3]=='K') &&
             !isIdentChar(inptr[4])) {
             inptr += 4;
             NextToken();
             return 0x00;
         }
         if ((inptr[1]=='s' || inptr[1]=='S') &&
             !isIdentChar(inptr[2])) {
             inptr += 2;
             NextToken();
             return 0x2C;
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

