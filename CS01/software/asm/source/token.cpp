// ============================================================================
//        __
//   \\__/ o\    (C) 2014-2020  Robert Finch, Waterloo
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
char laststr[500];
char lastch;
Int128 last_icon;
Int128 ival;
double rval;
int16_t token2;
int32_t reg;

// FT64
static int regSP = 31;
static int regFP = 30;
static int regLR = 29;
static int regXL = 28;
static int regGP = 27;
static int regTP = 26;
static int regCB = 23;

int64_t tokenBuffer[5000000];
int tbndx;
char litpool[10000000];
int lpndx = 0;

int my_isspace(char ch)
{
    if (ch==' ' || ch=='\t' || ch=='\r')
        return (1);
    return (0);
}
int isspaceOrDot(char ch)
{
	ch &= 0x7f;
	return (my_isspace(ch) || ch=='.');
}

int isFirstIdentChar(char ch)
{
	ch &= 0x7f;
  return (isalpha(ch) || ch=='_');
}

int isIdentChar(char ch)
{
	ch &= 0x7f;
	return (isalnum(ch) || ch=='_');
}

int need(int tk)
{
    if (tk != token) {
        printf("Syntax error %s.%d.\r\n", currentFilename, lineno);
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
            return c - 'a' + 10LL;
    if(c >= 'A' && c <= 'Z')
            return c - 'A' + 10LL;
    return -1LL;
}

/*
 *      getbase - get an integer in any base.
 */
void getbase(int b)
{
    Int128 i, j, ba;
    i.high = i.low = 0LL;
	ba.low = b;
	ba.high = 0LL;
    while(isalnum(*inptr) || *inptr=='_') {
        if (*inptr=='_') {
            inptr++;
            continue;
        }
        if((j.low = radix36(*inptr)) < b) {
			j.high = 0LL;
			Int128::Mul(&i,&i,&ba);
			Int128::Add(&i,&i,&j);
                        //i = i * b + j;
                        inptr++;
                        }
                else break;
                }
		if (*inptr=='L' || *inptr=='U')	// ignore a 'L'ong suffix and 'U'nsigned
			inptr++;
		// Make an Int80 really negative
		if ((ival.high >> 15) & 1)
			ival.high |= 0xFFFFFFFFFFFF0000LL;
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

void getString()
{
	int nn;

	nn = 0;
	while (*inptr && *inptr != '"' && *inptr != '\n' && nn < sizeof(laststr) - 2) {
		laststr[nn] = *inptr;
		nn++;
		inptr++;
	}
	inptr++;
	laststr[nn] = '\0';
}

static char *pseudos[] = {
    "align", "code", "data", "tls", "rodata", "file",
		"fill", "org", "byte", "message",(char *)NULL
};
static int pseudoTokens[] = {
    tk_align, tk_code, tk_data, tk_tls, tk_rodata, tk_file,
    tk_fill, tk_org, tk_db, tk_message, tk_none
};

int isPseudoOp()
{
  static char buf[500];
  char *p = inptr;
  int nn = 0;

  if (*p=='.') p++;
  if (!isFirstIdentChar(*p))
    return (0);
  while(isIdentChar(*p)) {
    buf[nn] = tolower(*p);
    p++;
    nn++;
  }
  buf[nn] = '\0';
  for (nn = 0; nn < 9; nn++) {
    if (strcmp(buf, pseudos[nn])==0) {
      //inptr = p;
      //token = pseudoTokens[nn];
      return (1);
    }
  }
  return (0);
}

void prevToken()
{
    inptr = pinptr;
}

int NextToken()
{
	char ch;
	char *p;
	char *sp;
	unsigned int64_t n;
	SYM *sym;

	token2 = tk_nop;
	// Under construction: tokens are stored in a buffer
	if (false && pass > 3 && gCpu=='F') {
		token = tokenBuffer[tbndx];
		tbndx++;
		switch (token) {
		case tk_strconst:
			n = tokenBuffer[tbndx];
			tbndx++;
			n |= tokenBuffer[tbndx] << 16;
			tbndx++;
			sp = &litpool[n];
			strcpy(laststr, sp);
			return (token);
		case tk_id:
			n = (int64_t)tokenBuffer[tbndx];
			tbndx++;
			n |= (int64_t)tokenBuffer[tbndx] << 16LL;
			tbndx++;
			strcpy(lastid, &litpool[n]);
			return (token);
		case tk_icon:
			n = tokenBuffer[tbndx];
			tbndx++;
			n |= tokenBuffer[tbndx] << 16;
			tbndx++;
			n |= (int64_t)tokenBuffer[tbndx] << 32LL;
			tbndx++;
			n |= (int64_t)tokenBuffer[tbndx] << 48LL;
			tbndx++;
			ival.low = n;
			ival.high = 0;
			return (token);
		case tk_rconst:
			n = tokenBuffer[tbndx];
			tbndx++;
			n |= tokenBuffer[tbndx] << 16;
			tbndx++;
			n |= (int64_t)tokenBuffer[tbndx] << 32LL;
			tbndx++;
			n |= (int64_t)tokenBuffer[tbndx] << 48LL;
			tbndx++;
			ival.low = n;
			ival.high = 0;
			rval = (double)ival.low;
			return (token);
		default:
			return (token);
		}
	}
    pinptr = inptr;    
		// Need to remove the following line at some point
		tbndx = 0;
    do {
			if (*inptr == '\0') {
				tokenBuffer[tbndx] = tk_eof;
				tbndx++;
				return token = tk_eof;
			}
      SkipSpaces();                      // skip over leading spaces
      if (*inptr==';') {                 // comment ?
          ScanToEOL();
          continue;
      }
			ch = *inptr & 0x7f;
      if (isdigit(ch)) {
        getnum();
				tokenBuffer[tbndx] = token;
				tbndx++;
				tokenBuffer[tbndx] = ival.low;
				tbndx++;
				tokenBuffer[tbndx] = ival.low >> 16LL;
				tbndx++;
				tokenBuffer[tbndx] = ival.low >> 32LL;
				tbndx++;
				tokenBuffer[tbndx] = ival.low >> 48LL;
				tbndx++;
				return (token);
      }
        switch(*inptr) {
				case '"':
					inptr++;
					getString();
					tokenBuffer[tbndx] = tk_strconst;
					tbndx++;
					tokenBuffer[tbndx] = lpndx;
					tbndx++;
					tokenBuffer[tbndx] = lpndx >> 16;
					tbndx++;
					strncpy(&litpool[lpndx], laststr, sizeof(laststr));
					lpndx += strlen(laststr)+1;
					litpool[lpndx - 1] = '\0';
					return (token = tk_strconst);
        case '.':
					if (isPseudoOp()) { inptr++; continue; }
          else if (getIdentifier()) { 
						tokenBuffer[tbndx] = tk_id;
						tbndx++;
						tokenBuffer[tbndx] = lpndx;
						tbndx++;
						tokenBuffer[tbndx] = lpndx >> 16;
						tbndx++;
						strncpy(&litpool[lpndx], lastid, sizeof(lastid));
						lpndx += strlen(lastid) + 1;
						litpool[lpndx - 1] = '\0';
						return (token = tk_id);
					}
          else { inptr++; continue; }
        case '\n': inptr++; 
					tokenBuffer[tbndx] = tk_eol;
					tbndx++;
					return token = tk_eol;
        case '$':
					inptr++;
					p = inptr;
					getbase(16); 
					tokenBuffer[tbndx] = tk_icon;
					tbndx++;
					tokenBuffer[tbndx] = ival.low;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 16LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 32LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 48LL;
					tbndx++;
					//if (ival.low == 0) {
					//	if (inptr == p) {
					//		if (*inptr == 'r' || *inptr == 'R') {
					//			inptr++;
					//			p = inptr;
					//			getbase(10);
					//			if (inptr == p)
					//				return (token = tk_icon);
					//			if (isIdentChar(*inptr))
					//				return (token = tk_icon);
					//			reg = ival.low;
					//			token2 = tk_reg;
					//			return (token = tk_icon);
					//		}
					//		else if (*inptr == 't' || *inptr == 'T') {
					//			inptr++;
					//			p = inptr;
					//			getbase(10);
					//			if (inptr == p)
					//				return (token = tk_icon);
					//			if (isIdentChar(*inptr))
					//				return (token = tk_icon);
					//			reg = ival.low + 5;
					//			token2 = tk_reg;
					//			return (token = tk_icon);
					//		}
					//		else if (*inptr == 's' || *inptr == 'S') {
					//			if (inptr[1] == 'p' || inptr[1] == 'P') {
					//				if (isIdentChar(inptr[2]))
					//					return (token = tk_icon);
					//				token2 = tk_reg;
					//				reg = regSP;
					//			}
					//		}
					//	}
					//}
					//else if (ival.low >= 0xa0 && ival.low <= 0xa4) {
					//	reg = ival.low - 0xa0 + 18;
					//	token2 = tk_reg;
					//}
					return (token = tk_icon);
        case '%':
					inptr++;
					getbase(2);
					tokenBuffer[tbndx] = tk_icon;
					tbndx++;
					tokenBuffer[tbndx] = ival.low;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 16LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 32LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 48LL;
					tbndx++;
					return (token = tk_icon);
        case ',':
					inptr++; 
					tokenBuffer[tbndx] = ',';
					tbndx++;
					return token = ',';
        case '+':
             if (inptr[1]=='}') {
               inptr += 2;
							 tokenBuffer[tbndx] = tk_end_expand;
							 tbndx++;
							 return token = tk_end_expand;
             }
						 if (inptr[1] == '+') {
							 inptr += 2;
							 tokenBuffer[tbndx] = tk_plusplus;
							 tbndx++;
							 return (token = tk_plusplus);
						 }
             inptr++;
						 tokenBuffer[tbndx] = '+';
						 tbndx++;
						 return token = '+';
        case '-':
					if (inptr[1] == '-') {
						inptr += 2;
						tokenBuffer[tbndx] = tk_minusminus;
						tbndx++;
						return (token = tk_minusminus);
					}
					inptr++; 
					tokenBuffer[tbndx] = '-';
					tbndx++;
					return token = '-';
        case '/':
             if (inptr[1]=='/') {
                ScanToEOL();
                continue;
             }
             if (inptr[1]=='*') {
             	inptr++;
             	do {
								if (inptr[0] == '\0') {
									tokenBuffer[tbndx] = tk_eof;
									tbndx++;
									return (token = tk_eof);
								}
             		inptr++;
             	} while(!(inptr[0]=='*' && inptr[1]=='/'));
             	continue;
						}
            inptr++; 
						tokenBuffer[tbndx] = '/';
						tbndx++;
						return (token = '/');
        case '*':
					inptr++;
					tokenBuffer[tbndx] = '*';
					tbndx++;
					return token = '*';
        case '#':
					inptr++;
					tokenBuffer[tbndx] = '#';
					tbndx++;
					return (token = '#');
        case '[': inptr++; 
					tokenBuffer[tbndx] = '[';
					tbndx++;
					return token = '[';
        case ']': inptr++; 
					tokenBuffer[tbndx] = ']';
					tbndx++;
					return token = ']';
        case '(': inptr++; 
					tokenBuffer[tbndx] = '(';
					tbndx++;
					return token = '(';
        case ')': inptr++;
					tokenBuffer[tbndx] = ')';
					tbndx++;
					return token = ')';
        case '{':
             if (inptr[1]=='+') {
               inptr+=2;
							 tokenBuffer[tbndx] = tk_begin_expand;
							 tbndx++;
							 return token=tk_begin_expand;
             }
             break;
        case ':': inptr++; 
					tokenBuffer[tbndx] = ':';
					tbndx++;
					return token = ':';
        case '\'':
          inptr++;
          ival.low = getsch();
					ival.high = 0;
          if (*inptr!='\'')
            printf("Syntax error - missing close quote.\r\n");
          else
            inptr++;
					tokenBuffer[tbndx] = tk_icon;
					tbndx++;
					tokenBuffer[tbndx] = ival.low;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 16LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 32LL;
					tbndx++;
					tokenBuffer[tbndx] = ival.low >> 48LL;
					tbndx++;
					return (token = tk_icon);
        case '=':
             if (inptr[1]=='=') { 
							 inptr+=2;
							 tokenBuffer[tbndx] = tk_eq;
							 tbndx++;
							 return token = tk_eq;
						 }
             inptr++; 
						 tokenBuffer[tbndx] = tk_eq;
						 tbndx++;
						 return token = tk_eq;
        case '!':
             if (inptr[1]=='=') {
							 inptr+=2;
							 tokenBuffer[tbndx] = tk_ne;
							 tbndx++;
							 return token = tk_ne;
						 }
             inptr++; 
						 tokenBuffer[tbndx] = '!';
						 tbndx++;
						 return token = '!';
        case '>':
             if (inptr[1]=='>') {
							 inptr+=2;
							 tokenBuffer[tbndx] = tk_rshift;
							 tbndx++;
							 return token = tk_rshift;
						 }
             if (inptr[1]=='=') {
							 inptr+=2; 
							 tokenBuffer[tbndx] = tk_ge;
							 tbndx++;
							 return token = tk_ge;
						 }
             inptr++; 
						 tokenBuffer[tbndx] = tk_gt;
						 tbndx++;
						 return token = tk_gt;
        case '<':
          if (inptr[1]=='>') { 
						inptr+=2; 
						tokenBuffer[tbndx] = tk_ne;
						tbndx++;
						return token = tk_ne; 
					}
          if (inptr[1]=='<') {
						inptr+=2;
						tokenBuffer[tbndx] = tk_lshift;
						tbndx++;
						return token = tk_lshift;
					}
          if (inptr[1]=='=') { 
						inptr+=2;
						tokenBuffer[tbndx] = tk_le;
						tbndx++;
						return token = tk_le;
					}
          inptr++; 
					tokenBuffer[tbndx] = tk_lt;
					tbndx++;
					return token = tk_lt;
        case '~':
					inptr++;
					tokenBuffer[tbndx] = '~';
					tbndx++;
					return token = '~';
        case '|':
             if (inptr[1]=='|') {
							 inptr+=2;
							 tokenBuffer[tbndx] = tk_lor;
							 tbndx++;
							 return token = tk_lor;
						 }
             inptr++;
						 tokenBuffer[tbndx] = '|';
						 tbndx++;
						 return token = '|';
        case '&':
             if (inptr[1]=='&') {
							 inptr+=2;
							 tokenBuffer[tbndx] = tk_land;
							 tbndx++;
							 return token = tk_land;
						 }
             inptr++;
						 tokenBuffer[tbndx] = '&';
						 tbndx++;
						 return token = '&';
        case '_':
             if (inptr[1]=='4' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_4addu;
								tbndx++;
								return token = tk_4addu;
             }
             if (inptr[1]=='2' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_2addu;
								tbndx++;
								return token = tk_2addu;
             }
             if (inptr[1]=='8' && 
             (inptr[2]=='a' || inptr[2]=='A') &&
             (inptr[3]=='d' || inptr[3]=='D') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='u' || inptr[5]=='U') &&
             isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_8addu;
								tbndx++;
								return token = tk_8addu;
             }
             if (inptr[1]=='1' && inptr[2]=='6' &&
             (inptr[3]=='a' || inptr[3]=='A') &&
             (inptr[4]=='d' || inptr[4]=='D') &&
             (inptr[5]=='d' || inptr[5]=='D') &&
             (inptr[6]=='u' || inptr[6]=='U') &&
             isspace(inptr[7])) {
                inptr += 7;
								tokenBuffer[tbndx] = tk_16addu;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_4addui;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_2addui;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_8addui;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_16addui;
								tbndx++;
								return token = tk_16addui;
             }
             break;

        // abs add addi addu addui and andi align asr asri
        case 'a':
        case 'A':
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_and;
								tbndx++;
								return token = tk_and;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_addu;
								tbndx++;
								return token = tk_addu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && 
                (inptr[2]=='d' || inptr[2]=='D') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_addui;
								tbndx++;
								return token = tk_addui;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_addi;
								tbndx++;
								return token = tk_addi;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_add;
								tbndx++;
								return token = tk_add;
            }
						if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='g' || inptr[3]=='G') && (inptr[4]=='n' || inptr[4]=='N') && isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_align;
								tbndx++;
								return token = tk_align;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_andi;
								tbndx++;
								return token = tk_andi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_asri;
								tbndx++;
								return token = tk_asri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_asr;
								tbndx++;
								return token = tk_asr;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_asli;
								tbndx++;
								return token = tk_asli;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_asl;
								tbndx++;
								return token = tk_asl;
            }
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='s' || inptr[2]=='S') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_abs;
								tbndx++;
								return token = tk_abs;
            }
            break;

        // band beq bor bne bit
        case 'b':
        case 'B':
					if (gCpu == 'F' || gCpu==NVIO) {
						if ((inptr[1] == 'a' || inptr[1] == 'A') &&
							(inptr[2] == 'n' || inptr[2] == 'N') &&
							(inptr[3] == 'd' || inptr[3] == 'D') &&
							isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_band;
							tbndx++;
							return (token = tk_band);
						}
						if ((inptr[1] == 'o' || inptr[1] == 'O') &&
							(inptr[2] == 'r' || inptr[2] == 'R') &&
							isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_bor;
							tbndx++;
							return (token = tk_bor);
						}
						if ((inptr[1] == 'n' || inptr[1] == 'N') &&
							(inptr[2] == 'a' || inptr[2] == 'A') &&
							(inptr[3] == 'n' || inptr[3] == 'N') &&
							(inptr[4] == 'd' || inptr[4] == 'D') &&
							isspace(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_bnand;
							tbndx++;
							return (token = tk_bnand);
						}
						if ((inptr[1] == 'n' || inptr[1] == 'N') &&
							(inptr[2] == 'o' || inptr[2] == 'O') &&
							(inptr[3] == 'r' || inptr[3] == 'R') &&
							isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_bnor;
							tbndx++;
							return (token = tk_bnor);
						}
					}
					if (gCpu == RISCV) {
						if ((inptr[1] == 'e' || inptr[1] == 'E') &&
							(inptr[2] == 'q' || inptr[2] == 'Q') &&
							(inptr[3] == 'z' || inptr[2] == 'Z') &&
							isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_beqz;
							tbndx++;
							return token = tk_beqz;
						}
						if ((inptr[1] == 'n' || inptr[1] == 'N') &&
							(inptr[2] == 'e' || inptr[2] == 'E') &&
							(inptr[3] == 'z' || inptr[2] == 'Z') &&
							isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_bnez;
							tbndx++;
							return token = tk_bnez;
						}
						if ((inptr[1] == 'l' || inptr[1] == 'L') &&
							(inptr[2] == 't' || inptr[2] == 'T') &&
							(inptr[3] == 'z' || inptr[2] == 'Z') &&
							isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_bltz;
							tbndx++;
							return token = tk_bltz;
						}
					}
					if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='q' || inptr[2]=='Q') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_beq;
								tbndx++;
								return token = tk_beq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && 
                (inptr[2]=='q' || inptr[2]=='Q') &&
                (inptr[3]=='i' || inptr[2]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_beqi;
								tbndx++;
								return token = tk_beqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bne;
								tbndx++;
								return token = tk_bne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bnei;
								tbndx++;
								return token = tk_bnei;
            }
						if ((inptr[1]=='r' || inptr[1]=='R') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bra;
								tbndx++;
								return token = tk_bra;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='z' || inptr[2]=='Z') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_brz;
								tbndx++;
								return token = tk_brz;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_blt;
								tbndx++;
								return token = tk_blt;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_blti;
								tbndx++;
								return token = tk_blti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bltu;
								tbndx++;
								return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bltui;
								tbndx++;
								return token = tk_bltui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='o' || inptr[2]=='O') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bltu;
								tbndx++;
								return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ble;
								tbndx++;
								return token = tk_ble;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_blei;
								tbndx++;
								return token = tk_blei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bleu;
								tbndx++;
								return token = tk_bleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bleui;
								tbndx++;
								return token = tk_bleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bleu;
								tbndx++;
								return token = tk_bleu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bge;
								tbndx++;
								return token = tk_bge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgei;
								tbndx++;
								return token = tk_bgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgeu;
								tbndx++;
								return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bgeui;
								tbndx++;
								return token = tk_bgeui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgeu;
								tbndx++;
								return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgt;
								tbndx++;
								return token = tk_bgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgti;
								tbndx++;
								return token = tk_bgti;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgtu;
								tbndx++;
								return token = tk_bgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bgtui;
								tbndx++;
								return token = tk_bgtui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgtu;
								tbndx++;
								return token = tk_bgtu;
            }
						if (gCpu == RISCV) {
							if ((inptr[1] == 'g' || inptr[1] == 'G') &&
								(inptr[2] == 't' || inptr[2] == 'T') &&
								(inptr[3] == 'z' || inptr[3] == 'Z') &&
								isspace(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_bgtz;
								tbndx++;
								return token = tk_bgtz;
							}
						}
						if ((inptr[1]=='r' || inptr[1]=='R') &&
                (inptr[2]=='n' || inptr[2]=='N') &&
                (inptr[3]=='z' || inptr[3]=='Z') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_brnz;
								tbndx++;
								return token = tk_brnz;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bsr;
								tbndx++;
								return token = tk_bsr;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bmi;
								tbndx++;
								return token = tk_bmi;
            }
            if ((inptr[1]=='p' || inptr[1]=='P') && 
                (inptr[2]=='l' || inptr[2]=='L') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bpl;
								tbndx++;
								return token = tk_bpl;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='c' || inptr[2]=='C') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bvc;
								tbndx++;
								return token = tk_bvc;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bvs;
								tbndx++;
								return token = tk_bvs;
            }
            if (inptr[1]=='r' && inptr[2]=='k' && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_brk;
								tbndx++;
								return token = tk_brk;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='p' || inptr[2]=='P') &&
                (inptr[3]=='l' || inptr[3]=='L') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bpl;
								tbndx++;
								return token = tk_bpl;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='m' || inptr[2]=='M') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bmi;
								tbndx++;
								return token = tk_bmi;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bss;
								tbndx++;
								return token = tk_bss;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bits;
								tbndx++;
								return token = tk_bits;
            }
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_db;
								tbndx++;
								return token = tk_db;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='x' || inptr[3]=='X') &&
                (inptr[4]=='t' || inptr[4]=='T') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bfext;
								tbndx++;
								return token = tk_bfext;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                (inptr[3]=='n' || inptr[3]=='N') &&
                (inptr[4]=='s' || inptr[4]=='S') &&
                 isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bfins;
								tbndx++;
								return token = tk_bfins;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='x' || inptr[3]=='X') &&
                (inptr[4]=='t' || inptr[4]=='T') &&
                (inptr[5]=='u' || inptr[5]=='U') &&
                 isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_bfextu;
								tbndx++;
								return token = tk_bfextu;
            }
            if (gCpu==4) {
                if ((inptr[1]=='r' || inptr[1]=='R') && isspace(inptr[2])) {
                    inptr += 2;
										tokenBuffer[tbndx] = tk_br;
										tbndx++;
										return token = tk_br;
                }      
                if ((inptr[1]=='i' || inptr[1]=='I') && 
                    (inptr[2]=='t' || inptr[2]=='T') &&
                     isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_bit;
										tbndx++;
										return token = tk_bit;
                }
                if ((inptr[1]=='i' || inptr[1]=='I') && 
                    (inptr[2]=='t' || inptr[2]=='T') &&
                    (inptr[3]=='i' || inptr[3]=='I') &&
                     isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_biti;
										tbndx++;
										return token = tk_biti;
                }
            }
			if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu==NVIO) {
                if ((inptr[1]=='b' || inptr[1]=='B') && 
                    (inptr[2]=='c' || inptr[2]=='C') &&
                     isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_bbc;
										tbndx++;
										return token = tk_bbc;
                }
                if ((inptr[1]=='b' || inptr[1]=='B') && 
                    (inptr[2]=='s' || inptr[2]=='S') &&
                     isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_bbs;
										tbndx++;
										return token = tk_bbs;
                }
			}
            break;

        // call cas chk cmp cmpu code cli com cmpi csrrc csrrs csrrw
        case 'c': case 'C':
			if (gCpu=='F' || gCpu=='G' || gCpu=='J') {
				if ((inptr[1]=='a' || inptr[1]=='A')
					&& (inptr[2]=='c' || inptr[2]=='C')
					&& (inptr[3]=='h' || inptr[3]=='H')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& isspace(inptr[5])) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_cache;
						tbndx++;
						return (token = tk_cache);
				}
			}
			if (gCpu == GAMBIT || gCpu == GAMBIT_V5) {
				if ((inptr[1] == 'a' || inptr[1] == 'A') &&
					(inptr[2] == 'l' || inptr[2] == 'L') &&
					(inptr[3] == 'l' || inptr[3] == 'L') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_call;
					tbndx++;
					return token = tk_call;
				}
			}
			 if (gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='G' || gCpu=='J' || gCpu==NVIO3 || gCpu==RISCV) {
                 if ((inptr[1]=='a' || inptr[1]=='A') &&
                     (inptr[2]=='l' || inptr[2]=='L') &&
                     (inptr[3]=='l' || inptr[3]=='L') &&
                     isspace(inptr[4])) {
                     inptr += 4;
										 tokenBuffer[tbndx] = tk_call;
										 tbndx++;
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
										 tokenBuffer[tbndx] = tk_calltgt;
										 tbndx++;
										 return token = tk_calltgt;
                 }
			 }
             if (gCpu==4) {
                 if ((inptr[1]=='m' || inptr[1]=='M') &&
                     (inptr[2]=='p' || inptr[2]=='P') &&
                     (inptr[3]=='i' || inptr[3]=='I') &&
                     isspace(inptr[4])) {
                     inptr += 4;
										 tokenBuffer[tbndx] = tk_cmpi;
										 tbndx++;
										 return token = tk_cmpi;
                 }
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_cmpu;
								 tbndx++;
								 return token = tk_cmpu;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 (inptr[3]=='u' || inptr[3]=='U') &&
                 (inptr[4]=='i' || inptr[4]=='I') &&
                 isspace(inptr[5])) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_cmpui;
								 tbndx++;
								 return token = tk_cmpui;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_cmp;
								 tbndx++;
								 return token = tk_cmp;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_code;
								 tbndx++;
								 return token = tk_code;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_cli;
								 tbndx++;
								 return token = tk_cli;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_com;
								 tbndx++;
								 return token = tk_com;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
								 tokenBuffer[tbndx] = tk_cs;
								 tbndx++;
								 return token = tk_cs;
             }
             if ((inptr[1]=='p' || inptr[1]=='P') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='d' || inptr[4]=='D') &&
                 isspace(inptr[5])) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_cpuid;
								 tbndx++;
								 return token = tk_cpuid;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_cas;
								 tbndx++;
								 return token = tk_cas;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_chk;
								 tbndx++;
								 return token = tk_chk;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_chki;
								 tbndx++;
								 return token = tk_chki;
             }
             if (gCpu==5 || gCpu==7 || gCpu=='A' || gCpu=='F' || gCpu=='G' || gCpu=='J') {
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='c' || inptr[4]=='C') &&
                   isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrc;
										 tbndx++;
										 return token = tk_csrrc;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='d' || inptr[4]=='D') &&
                   isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrd;
										 tbndx++;
										 return token = tk_csrrd;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='s' || inptr[4]=='S') &&
                   isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrs;
										 tbndx++;
										 return token = tk_csrrs;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='w' || inptr[4]=='W') &&
                   isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrw;
										 tbndx++;
										 return token = tk_csrrw;
                   }
			   if (gCpu == 'F') {
				   if ((inptr[1] == 'm' || inptr[1] == 'M') &&
					   (inptr[2] == 'o' || inptr[2] == 'O') &&
					   (inptr[3] == 'v' || inptr[3] == 'V') &&
					   (inptr[4] == 'e' || inptr[4] == 'E') &&
					   (inptr[5] == 'n' || inptr[5] == 'N') &&
					   (inptr[6] == 'z' || inptr[6] == 'Z') &&
					   isspace(inptr[7])) {
					   inptr += 7;
						 tokenBuffer[tbndx] = tk_cmovenz;
						 tbndx++;
						 return (token = tk_cmovenz);
				   }
					 if ((inptr[1] == 'm' || inptr[1] == 'M') &&
						 (inptr[2] == 'o' || inptr[2] == 'O') &&
						 (inptr[3] == 'v' || inptr[3] == 'V') &&
						 (inptr[4] == 'f' || inptr[4] == 'F') &&
						 (inptr[5] == 'n' || inptr[5] == 'N') &&
						 (inptr[6] == 'z' || inptr[6] == 'Z') &&
						 isspace(inptr[7])) {
						 inptr += 7;
						 tokenBuffer[tbndx] = tk_cmovfnz;
						 tbndx++;
						 return (token = tk_cmovfnz);
					 }
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
							tokenBuffer[tbndx] = tk_dbnz;
							tbndx++;
							return token = tk_dbnz;
          }
          if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_db;
							tbndx++;
							return token = tk_db;
          }
          if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_dc;
							tbndx++;
							return token = tk_dc;
          }
          if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_dh;
							tbndx++;
							return token = tk_dh;
          }
					if (gCpu=='A') {
						if ((inptr[1]=='d' || inptr[1]=='D') && isspace(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_dd;
							tbndx++;
							return token = tk_dd;
						}
						if ((inptr[1]=='o' || inptr[1]=='O') && isspace(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_do;
							tbndx++;
							return token = tk_do;
						}
						if ((inptr[1]=='t' || inptr[1]=='T') && isspace(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_dt;
							tbndx++;
							return token = tk_dt;
						}
					}
            if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_dw;
								tbndx++;
								return token = tk_dw;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='v' || inptr[2]=='V') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_div;
								tbndx++;
								return token = tk_div;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_divi;
								tbndx++;
								return token = tk_divi;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_divu;
								tbndx++;
								return token = tk_divu;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_divui;
								tbndx++;
								return token = tk_divui;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_div;
								tbndx++;
								return token = tk_div;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='a' || inptr[3]=='A') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_data;
								tbndx++;
								return token = tk_data;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') &&
                (inptr[2]==':')) {
                inptr+=3;
								tokenBuffer[tbndx] = tk_ds;
								tbndx++;
								return token = tk_ds;
            }
						// Not sure why dcb is defined as a fill here.
						if (gCpu != NVIO) {
							if ((inptr[1] == 'c' || inptr[1] == 'C') && (inptr[2] == 'b' || inptr[2] == 'B') && (isspace(inptr[3]) || inptr[3] == '.')) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_fill;
								tbndx++;
								return token = tk_fill;
							}
						}
             if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='c' || inptr[2]=='C') && (isspace(inptr[3])||inptr[3]=='.')) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_dec;
								 tbndx++;
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
								 tokenBuffer[tbndx] = tk_dh_htbl;
								 tbndx++;
								 return token = tk_dh_htbl;
             }
						 if (gCpu == 'F') {
							 if ((inptr[1] == 'i' || inptr[1] == 'I') &&
								 (inptr[2] == 'v' || inptr[2] == 'V') &&
								 (inptr[3] == 'w' || inptr[3] == 'W') &&
								 (inptr[4] == 'a' || inptr[4] == 'A') &&
								 (inptr[5] == 'i' || inptr[4] == 'I') &&
								 (inptr[6] == 't' || inptr[4] == 'T') &&
								 isspace(inptr[7])) {
								 inptr += 7;
								 tokenBuffer[tbndx] = tk_divwait;
								 tbndx++;
								 return (token = tk_divwait);
							 }
						 }
						 if (gCpu == GAMBIT || gCpu == GAMBIT_V5) {
							 if ((inptr[1] == 'c') || inptr[1] == 'C') {
								 if ((inptr[2] == 'b' || inptr[2] == 'B') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcb;
									 tbndx++;
									 return (token = tk_dcb);
								 }
								 if ((inptr[2] == 'w' || inptr[2] == 'W') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcw;
									 tbndx++;
									 return (token = tk_dcw);
								 }
							 }
						 }
						 if (gCpu == NVIO || gCpu == DSD9 || gCpu==RISCV) {
							 if ((inptr[1] == 'c') || inptr[1]=='C') {
								 if ((inptr[2] == 'b' || inptr[2] == 'B') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcb;
									 tbndx++;
									 return (token = tk_dcb);
								 }
								 if ((inptr[2] == 'd' || inptr[2] == 'D') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcd;
									 tbndx++;
									 return (token = tk_dcd);
								 }
								 if ((inptr[2] == 'o' || inptr[2] == 'O') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dco;
									 tbndx++;
									 return (token = tk_dco);
								 }
								 if ((inptr[2] == 'p' || inptr[2] == 'P') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcp;
									 tbndx++;
									 return (token = tk_dcp);
								 }
								 if ((inptr[2] == 't' || inptr[2] == 'T') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dct;
									 tbndx++;
									 return (token = tk_dct);
								 }
								 if ((inptr[2] == 'w' || inptr[2] == 'W') && isspace(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcw;
									 tbndx++;
									 return (token = tk_dcw);
								 }
							 }
						 }
						 if (gCpu == RISCV) {
							 if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								 (inptr[2] == 'c' || inptr[2] == 'C') &&
								 (inptr[3] == 't' || inptr[3] == 'T') &&
								 (inptr[4] == 'o' || inptr[3] == 'O') &&
								 isspace(inptr[5])) {
								 inptr += 5;
								 tokenBuffer[tbndx] = tk_decto;
								 tbndx++;
								 return token = tk_decto;
							 }
						 }
						 break;

        // ecall end eor eori endif endpublic extern equ eret es
        case 'e': case 'E':
             if ((inptr[1]=='q' || inptr[1]=='Q') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_equ;
								 tbndx++;
								 return token = tk_equ;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_eori;
								 tbndx++;
								 return token = tk_eori;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_eor;
								 tbndx++;
								 return token = tk_eor;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_end;
								 tbndx++;
								 return token = tk_end;
             }
             if ((inptr[1]=='n' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='f' || inptr[4]=='F') &&
                 isspace(inptr[5])) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_endif;
								 tbndx++;
								 return token = tk_endif;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_else;
								 tbndx++;
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
								 tokenBuffer[tbndx] = tk_endpublic;
								 tbndx++;
								 return token = tk_endpublic;
             }
             if ((inptr[1]=='x' || inptr[1]=='X') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 (inptr[4]=='r' || inptr[4]=='R') &&
                 (inptr[5]=='n' || inptr[5]=='N') &&
                 isspace(inptr[6])) {
                 inptr += 6;
								 tokenBuffer[tbndx] = tk_extern;
								 tbndx++;
								 return token = tk_extern;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
								 tokenBuffer[tbndx] = tk_es;
								 tbndx++;
								 return token = tk_es;
             }
			 if (gCpu==RISCV) {
				 if ((inptr[1] == 'c' || inptr[1] == 'C') &&
					 (inptr[2] == 'a' || inptr[2] == 'A') &&
					 (inptr[3] == 'l' || inptr[3] == 'L') &&
					 (inptr[4] == 'l' || inptr[4] == 'L') &&
					 isspace(inptr[5])) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_ecall;
					 tbndx++;
					 return token = tk_ecall;
				 }
				 if ((inptr[1]=='r' || inptr[1]=='R') &&
					 (inptr[2]=='e' || inptr[2]=='E') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 isspace(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_eret;
					 tbndx++;
					 return token = tk_eret;
				 }
			 }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='m' || inptr[3]=='M') &&
                 isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_endm;
								 tbndx++;
								 return token = tk_endm;
             }
             break;

        // fill fabs fadd fb__
		// fcmp fcx fdiv fmul fnabs fneg fsub fix2flt flt2fix ftst ftoi fxdiv fxmul
        case 'f': case 'F':
             if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='l' || inptr[2]=='L') &&
                 (inptr[3]=='l' || inptr[3]=='L') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fill;
								 tbndx++;
								 return token = tk_fill;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='d' || inptr[3]=='D') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fadd;
								 tbndx++;
								 return token = tk_fadd;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='b' || inptr[3]=='B') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fsub;
								 tbndx++;
								 return token = tk_fsub;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 (inptr[3]=='p' || inptr[3]=='P') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fcmp;
								 tbndx++;
								 return token = tk_fcmp;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='l' || inptr[3]=='L') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fmul;
								 tbndx++;
								 return token = tk_fmul;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='o' || inptr[2]=='O') &&
                 (inptr[3]=='v' || inptr[3]=='V') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fmov;
								 tbndx++;
								 return token = tk_fmov;
             }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 (inptr[3]=='v' || inptr[3]=='V') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fdiv;
								 tbndx++;
								 return token = tk_fdiv;
             }
						 if ((inptr[1] == 's' || inptr[1] == 'S') &&
							 (inptr[2] == 'q' || inptr[2] == 'Q') &&
							 (inptr[3] == 'r' || inptr[3] == 'R') &&
							 (inptr[4] == 't' || inptr[3] == 'T') &&
							 (isspace(inptr[5]) || inptr[5] == '.')) {
							 inptr += 5;
							 tokenBuffer[tbndx] = tk_fsqrt;
							 tbndx++;
							 return token = tk_fsqrt;
						 }
						 if ((inptr[1]=='i' || inptr[1]=='I') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (inptr[3]=='2' || inptr[3]=='2') &&
                 (inptr[4]=='f' || inptr[3]=='F') &&
                 (inptr[5]=='l' || inptr[3]=='L') &&
                 (inptr[6]=='t' || inptr[3]=='T') &&
                 (isspace(inptr[7]) || inptr[7]=='.')) {
                 inptr += 7;
								 tokenBuffer[tbndx] = tk_fix2flt;
								 tbndx++;
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
								 tokenBuffer[tbndx] = tk_flt2fix;
								 tbndx++;
								 return token = tk_flt2fix;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='b' || inptr[2]=='B') &&
                 (inptr[3]=='s' || inptr[3]=='S') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fabs;
								 tbndx++;
								 return token = tk_fabs;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='g' || inptr[3]=='G') &&
                 (isspace(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fneg;
								 tbndx++;
								 return token = tk_fneg;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='a' || inptr[2]=='A') &&
                 (inptr[3]=='b' || inptr[3]=='B') &&
                 (inptr[4]=='s' || inptr[4]=='S') &&
                 (isspace(inptr[5]) || inptr[5]=='.')) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_fnabs;
								 tbndx++;
								 return token = tk_fnabs;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fcx;
								 tbndx++;
								 return token = tk_fcx;
             }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fdx;
								 tbndx++;
								 return token = tk_fdx;
             }
             if ((inptr[1]=='e' || inptr[1]=='E') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fex;
								 tbndx++;
								 return token = tk_fex;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_frm;
								 tbndx++;
								 return token = tk_frm;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspace(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_ftx;
								 tbndx++;
								 return token = tk_ftx;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (isspace(inptr[5]))) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_fstat;
								 tbndx++;
								 return token = tk_fstat;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
                 (isspace(inptr[4])||inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_ftst;
								 tbndx++;
								 return token = tk_ftst;
             }
			 if (gCpu==7 || gCpu=='A' || gCpu=='F') {
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='e' || inptr[2]=='E') &&
					 (inptr[3]=='q' || inptr[3]=='Q') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbeq;
					 tbndx++;
					 return token = tk_fbeq;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='n' || inptr[2]=='N') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbne;
					 tbndx++;
					 return token = tk_fbne;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='l' || inptr[2]=='L') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fblt;
					 tbndx++;
					 return token = tk_fblt;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='l' || inptr[2]=='L') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fble;
					 tbndx++;
					 return token = tk_fble;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='g' || inptr[2]=='G') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbgt;
					 tbndx++;
					 return token = tk_fbgt;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='g' || inptr[2]=='G') &&
					 (inptr[3]=='e' || inptr[3]=='E') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbge;
					 tbndx++;
					 return token = tk_fbge;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='r' || inptr[3]=='R') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbor;
					 tbndx++;
					 return token = tk_fbor;
				 }
				 if ((inptr[1]=='b' || inptr[1]=='B') &&
					 (inptr[2]=='u' || inptr[2]=='U') &&
					 (inptr[3]=='n' || inptr[3]=='N') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbun;
					 tbndx++;
					 return token = tk_fbun;
				 }
				 if ((inptr[1]=='t' || inptr[1]=='T') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='i' || inptr[3]=='I') &&
					 (isspace(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_ftoi;
					 tbndx++;
					 return token = tk_ftoi;
				 }
			 }
			 if ((inptr[1] == 'i' || inptr[1] == 'I') &&
				 (inptr[2] == 'l' || inptr[2] == 'L') &&
				 (inptr[3] == 'e' || inptr[3] == 'E') &&
				 (isspace(inptr[4]) || inptr[4] == ':')) {
				 inptr += 4;
				 tokenBuffer[tbndx] = tk_file;
				 tbndx++;
				 return (token = tk_file);
			 }
			 if (gCpu == 'F') {
				 if ((inptr[1] == 's' || inptr[1] == 'S') &&
					 (inptr[2] == 'l' || inptr[2] == 'L') &&
					 (inptr[3] == 't' || inptr[3] == 'T') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fslt;
					 tbndx++;
					 return token = tk_fslt;
				 }
				 if ((inptr[1] == 'x' || inptr[1] == 'X') &&
					 (inptr[2] == 'd' || inptr[2] == 'D') &&
					 (inptr[3] == 'i' || inptr[3] == 'I') &&
					 (inptr[4] == 'v' || inptr[4] == 'V') &&
					 (isspace(inptr[5]) || inptr[5] == '.')) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_fxdiv;
					 tbndx++;
					 return token = tk_fxdiv;
				 }
				 if ((inptr[1] == 'x' || inptr[1] == 'X') &&
					 (inptr[2] == 'm' || inptr[2] == 'M') &&
					 (inptr[3] == 'u' || inptr[3] == 'U') &&
					 (inptr[4] == 'l' || inptr[4] == 'L') &&
					 (isspace(inptr[5]) || inptr[5] == '.')) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_fxmul;
					 tbndx++;
					 return token = tk_fxmul;
				 }
			 }
				if (gCpu == RISCV) {
					if ((inptr[1] == 'e' || inptr[1] == 'E')
						&& (inptr[2] == 'q' || inptr[2] == 'Q')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_feq;
						tbndx++;
						return token = tk_feq;
					}
					if ((inptr[1] == 'l' || inptr[1] == 'L')
						&& (inptr[2] == 'e' || inptr[2] == 'E')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_fle;
						tbndx++;
						return token = tk_fle;
					}
					if ((inptr[1] == 'l' || inptr[1] == 'L')
						&& (inptr[2] == 't' || inptr[2] == 'T')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_flt;
						tbndx++;
						return token = tk_flt;
					}
					if ((inptr[1]=='l' || inptr[1]=='L')
						&& (inptr[2]=='w' || inptr[2]=='W')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_flw;
						tbndx++;
						return token = tk_flw;
					}
					if ((inptr[1] == 's' || inptr[1] == 'S')
						&& (inptr[2] == 'w' || inptr[2] == 'W')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_fsw;
						tbndx++;
						return token = tk_fsw;
					}
					if ((inptr[1] == 'c' || inptr[1] == 'C')
						&& (inptr[2] == 'v' || inptr[2] == 'V')
						&& (inptr[3] == 't' || inptr[3] == 'T')
						&& isspaceOrDot(inptr[4])) {
						inptr += 4;
						tokenBuffer[tbndx] = tk_fcvt;
						tbndx++;
						return token = tk_fcvt;
					}
					if ((inptr[1] == 'm' || inptr[1] == 'M')
						&& (inptr[2] == 'v' || inptr[2] == 'V')
						&& isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_fmv;
						tbndx++;
						return token = tk_fmv;
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
								 tokenBuffer[tbndx] = tk_gran;
								 tbndx++;
								 return token = tk_gran;
             }
						 if (gCpu == RISCV) {
							 if ((inptr[1] == 'c' || inptr[1] == 'C') &&
								 (inptr[2] == 's' || inptr[2] == 'S') &&
								 (inptr[3] == 'u' || inptr[3] == 'U') &&
								 (inptr[4] == 'b' || inptr[4] == 'B') &&
								 isspace(inptr[5])) {
								 inptr += 5;
								 tokenBuffer[tbndx] = tk_gcsub;
								 tbndx++;
								 return token = tk_gcsub;
							 }
							 if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								 (inptr[2] == 't' || inptr[2] == 'T') &&
								 (inptr[3] == 'r' || inptr[3] == 'R') &&
								 (inptr[4] == 'd' || inptr[4] == 'D') &&
								 (inptr[5] == 'y' || inptr[5] == 'Y') &&
								 isspace(inptr[6])) {
								 inptr += 6;
								 tokenBuffer[tbndx] = tk_getrdy;
								 tbndx++;
								 return token = tk_getrdy;
							 }
							 if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								 (inptr[2] == 't' || inptr[2] == 'T') &&
								 (inptr[3] == 't' || inptr[3] == 'T') &&
								 (inptr[4] == 'o' || inptr[4] == 'O') &&
								 isspace(inptr[5])) {
								 inptr += 5;
								 tokenBuffer[tbndx] = tk_getto;
								 tbndx++;
								 return token = tk_getto;
							 }
							 if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								 (inptr[2] == 't' || inptr[2] == 'T') &&
								 (inptr[3] == 'z' || inptr[3] == 'Z') &&
								 (inptr[4] == 'l' || inptr[4] == 'L') &&
								 isspace(inptr[5])) {
								 inptr += 5;
								 tokenBuffer[tbndx] = tk_getzl;
								 tbndx++;
								 return token = tk_getzl;
							 }
						 }
             break;

		// hs hint
        case 'h': case 'H':
			if ((inptr[1]=='I' || inptr[1]=='i') &&
				(inptr[2]=='N' || inptr[2]=='n') &&
				(inptr[3]=='T' || inptr[3]=='t') &&
				isspace(inptr[4])) {
				inptr += 4;
				tokenBuffer[tbndx] = tk_hint;
				tbndx++;
				return (token = tk_hint);
			}
             if (gCpu==4) {
                 if ((inptr[1]=='s' || inptr[1]=='S') &&
                     (inptr[2]==':')) {
                     inptr += 3;
										 tokenBuffer[tbndx] = tk_hs;
										 tbndx++;
										 return token = tk_hs;
                 }
             }
             break;
             
        // ibne if ifdef ifndef ios inc int iret ipush ipop isnull itof
        case 'i': case 'I':
			if (gCpu=='F') {
				if ((inptr[1]=='b' || inptr[1]=='B') &&
					(inptr[2]=='n' || inptr[2]=='N') &&
					(inptr[3]=='e' || inptr[3]=='E') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ibne;
					tbndx++;
					return token = tk_ibne;
				}
				if ((inptr[1] == 's' || inptr[1] == 'S') &&
					(inptr[2] == 'p' || inptr[2] == 'P') &&
					(inptr[3] == 't' || inptr[3] == 'T') &&
					(inptr[4] == 'r' || inptr[4] == 'R') &&
					isspace(inptr[5])) {
					inptr += 5;
					tokenBuffer[tbndx] = tk_isptr;
					tbndx++;
					return token = tk_isptr;
				}
				if ((inptr[1] == 's' || inptr[1] == 'S') &&
					(inptr[2] == 'n' || inptr[2] == 'N') &&
					(inptr[3] == 'u' || inptr[3] == 'U') &&
					(inptr[4] == 'l' || inptr[4] == 'L') &&
					(inptr[5] == 'l' || inptr[5] == 'L') &&
					isspace(inptr[6])) {
					inptr += 6;
					tokenBuffer[tbndx] = tk_isnull;
					tbndx++;
					return token = tk_isnull;
				}
			}
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]==':')) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_ios;
								 tbndx++;
								 return token = tk_ios;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='c' || inptr[2]=='C') &&
                 (isspace(inptr[3]) || inptr[3]=='.')) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_inc;
								 tbndx++;
								 return token = tk_inc;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_int;
								 tbndx++;
								 return token = tk_int;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
								isspace(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_iret;
								 tbndx++;
								 return token = tk_iret;
             }
			 if (gCpu==7) {
				 if ((inptr[1]=='p' || inptr[1]=='P') &&
					 (inptr[2]=='u' || inptr[2]=='U') &&
					 (inptr[3]=='s' || inptr[3]=='S') &&
					 (inptr[4]=='h' || inptr[4]=='H') &&
					 isspace(inptr[5])) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_ipush;
					 tbndx++;
					 return token = tk_ipush;
				 }
				 if ((inptr[1]=='p' || inptr[1]=='P') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='p' || inptr[3]=='P') &&
					 isspace(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_ipop;
					 tbndx++;
					 return token = tk_ipop;
				 }
			 }
			 if (gCpu==7 || gCpu=='A' || gCpu=='F') {
				 if ((inptr[1]=='t' || inptr[1]=='T') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='f' || inptr[3]=='F') &&
					 (isspace(inptr[4]) || inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_itof;
					 tbndx++;
					 return (token = tk_itof);
				 }
			 }
       if (inptr[1]=='f' || inptr[1]=='F') {
				if ((inptr[2]=='d' || inptr[2]=='D')
					&& (inptr[3]=='e' || inptr[3]=='E')
					&& (inptr[4]=='f' || inptr[3]=='F')
					&& (isspace(inptr[5]) || inptr[5]=='.')) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_ifdef;
						tbndx++;
						return token = tk_ifdef;
				}
				if ((inptr[2]=='n' || inptr[2]=='N')
					&& (inptr[3]=='d' || inptr[3]=='D')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& (inptr[5]=='f' || inptr[5]=='F')
					&& (isspace(inptr[6]) || inptr[6]=='.')) {
						inptr += 6;
						tokenBuffer[tbndx] = tk_ifndef;
						tbndx++;
						return token = tk_ifndef;
				}
				if (isspace(inptr[2]) || inptr[2]=='.') {
					inptr += 2;
					tokenBuffer[tbndx] = tk_if;
					tbndx++;
					return token = tk_if;
				}
             }
			 if (gCpu == RISCV) {
				 if ((inptr[1] == 'n' || inptr[1] == 'N') &&
					 (inptr[2] == 's' || inptr[2] == 'S') &&
					 (inptr[3] == 'r' || inptr[3] == 'R') &&
					 (inptr[4] == 'd' || inptr[4] == 'D') &&
					 (inptr[5] == 'y' || inptr[5] == 'Y') &&
					 isspace(inptr[6])) {
					 inptr += 6;
					 tokenBuffer[tbndx] = tk_insrdy;
					 tbndx++;
					 return token = tk_insrdy;
				 }
			 }
			 break;

        // jal jgr jmp jsf jsr jsp jci jhi
        case 'j': case 'J':
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='l' || inptr[2]=='L') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jal;
								 tbndx++;
								 return token = tk_jal;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jsr;
								 tbndx++;
								 return token = tk_jsr;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='f' || inptr[2]=='F') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jsf;
								 tbndx++;
								 return token = tk_jsf;
             }
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jmp;
								 tbndx++;
								 return token = tk_jmp;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jsp;
								 tbndx++;
								 return token = tk_jsp;
             }
             if ((inptr[1]=='g' || inptr[1]=='G') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_jgr;
								 tbndx++;
								 return token = tk_jgr;
             }
             if (gCpu==4) {
                if ((inptr[1]=='c' || inptr[1]=='C') &&
                    (inptr[2]=='i' || inptr[2]=='I') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_jci;
										tbndx++;
										return token = tk_jci;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') &&
                    (inptr[2]=='i' || inptr[2]=='I') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_jhi;
										tbndx++;
										return token = tk_jhi;
                }
             }
             break;

        // lb lbu lc lcu lf lh lhu lw ld ldi ldis lea lsr lsri lwar lfd lvb lws lvh lvw ltcb link
        case 'l':
        case 'L':
					if (gCpu == GAMBIT_V5) {
						if ((inptr[1] == 'd' || inptr[1] == 'D') &&
							isspace(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_ld;
							tbndx++;
							return token = tk_ld;
						}
						if ((inptr[1] == 'd' || inptr[1] == 'D') &&
							(inptr[2] == 'b' || inptr[2] == 'B') &&
							isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_ldb;
							tbndx++;
							return token = tk_ldb;
						}
						if ((inptr[1] == 'd' || inptr[1] == 'D') &&
							(inptr[2] == 'f' || inptr[2] == 'F') &&
							isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_ldf;
							tbndx++;
							return (token = tk_ldf);
						}
					}
				if (gCpu=='A' || gCpu==NVIO || gCpu==NVIO3 || gCpu==RISCV) {
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldd;
					tbndx++;
					return token = tk_ldd;
				}  
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'h' || inptr[2] == 'H') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldh;
					tbndx++;
					return token = tk_ldh;
				}
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldb;
					tbndx++;
					return token = tk_ldb;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldbu;
					tbndx++;
					return token = tk_ldbu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldw;
					tbndx++;
					return token = tk_ldw;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldwu;
					tbndx++;
					return token = tk_ldwu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldt;
					tbndx++;
					return token = tk_ldt;
				}  
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldo;
					tbndx++;
					return token = tk_ldo;
				}
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					(inptr[3] == 'u' || inptr[3] == 'U') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldou;
					tbndx++;
					return token = tk_ldou;
				}
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'd' || inptr[2] == 'D') &&
					(inptr[3] == 'r' || inptr[3] == 'R') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_lddr;
					tbndx++;
					return token = tk_lddr;
				}
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldtu;
					tbndx++;
					return token = tk_ldtu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldp;
					tbndx++;
					return token = tk_ldp;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldpu;
					tbndx++;
					return token = tk_ldpu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='v' || inptr[2]=='V') &&
					(inptr[3]=='d' || inptr[3]=='D') &&
					(inptr[4]=='a' || inptr[4]=='A') &&
					(inptr[5]=='r' || inptr[5]=='R') &&
					isspace(inptr[6])) {
					inptr += 6;
					tokenBuffer[tbndx] = tk_ldvdar;
					tbndx++;
					return token = tk_ldvdar;
				}  
			}
			if (gCpu == RISCV) {
				if ((inptr[1] == 'r' || inptr[1] == 'R') && isspace(inptr[2])) {
					inptr += 2;
					tokenBuffer[tbndx] = tk_lr;
					tbndx++;
					return token = tk_lr;
				}
			}
            if ((inptr[1]=='d' || inptr[1]=='D') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_ld;
								tbndx++;
								return token = tk_ld;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lb;
								tbndx++;
								return token = tk_lb;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lbu;
								tbndx++;
								return token = tk_lbu;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspace(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lf;
								tbndx++;
								return token = tk_lf;
            }  
            if ((inptr[1]=='v' || inptr[1]=='V') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lv;
								tbndx++;
								return token = tk_lv;
            }  
            if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lw;
								tbndx++;
								return token = tk_lw;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lh;
								tbndx++;
								return token = tk_lh;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lhu;
								tbndx++;
								return token = tk_lhu;
            }
            if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lc;
								tbndx++;
								return token = tk_lc;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && (inptr[2]=='u' || inptr[2]=='U') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lcu;
								tbndx++;
								return token = tk_lcu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ldi;
								tbndx++;
								return token = tk_ldi;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='n' || inptr[2]=='N') && (inptr[3]=='k' || inptr[3]=='K') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_link;
								tbndx++;
								return token = tk_link;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='s' || inptr[3]=='S') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_ldis;
								tbndx++;
								return token = tk_ldis;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='a' || inptr[2]=='A') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lea;
								tbndx++;
								return token = tk_lea;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lmr;
								tbndx++;
								return token = tk_lmr;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_lsri;
								tbndx++;
								return token = tk_lsri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lsr;
								tbndx++;
								return token = tk_lsr;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lfd;
								tbndx++;
								return token = tk_lfd;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='a' || inptr[2]=='A') && (inptr[3]=='r' || inptr[3]=='R') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_lwar;
								tbndx++;
								return token = tk_lwar;
            }
			if (gCpu=='F' || gCpu=='G') {
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvb;
										tbndx++;
										return (token = tk_lvb);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvc;
										tbndx++;
										return (token = tk_lvc);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='h' || inptr[2]=='H') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvh;
										tbndx++;
										return (token = tk_lvh);
                }
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='w' || inptr[2]=='W') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvw;
										tbndx++;
										return (token = tk_lvw);
                }
                if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lwr;
										tbndx++;
										return (token = tk_lwr);
                }
			}
            if (gCpu==4 || gCpu=='F') {
                if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvb;
										tbndx++;
										return token = tk_lvb;
                }
				if ((inptr[1] == 'v' || inptr[1] == 'V') 
					&& (inptr[2] == 'b' || inptr[2] == 'B')
					&& (inptr[3] == 'u' || inptr[3] == 'U')
					&& isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_lvbu;
					tbndx++;
					return token = tk_lvbu;
				}
				if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvc;
										tbndx++;
										return token = tk_lvc;
                }
				if ((inptr[1] == 'v' || inptr[1] == 'V')
					&& (inptr[2] == 'c' || inptr[2] == 'C')
					&& (inptr[3] == 'u' || inptr[3] == 'U')
					&& isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_lvcu;
					tbndx++;
					return token = tk_lvcu;
				}
				if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='h' || inptr[2]=='H') && isspace(inptr[3])) {
                    inptr += 3;
                    return token = tk_lvh;
                }
				if ((inptr[1] == 'v' || inptr[1] == 'V')
					&& (inptr[2] == 'h' || inptr[2] == 'H')
					&& (inptr[3] == 'u' || inptr[3] == 'U')
					&& isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_lvhu;
					tbndx++;
					return token = tk_lvhu;
				}
				if ((inptr[1]=='v' || inptr[1]=='V') && (inptr[2]=='w' || inptr[2]=='W') && isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lvw;
										tbndx++;
										return token = tk_lvw;
                }
                if ((inptr[1]=='v' || inptr[1]=='V') &&
                    (inptr[2]=='w' || inptr[2]=='W') &&
                    (inptr[3]=='a' || inptr[3]=='A') &&
                    (inptr[4]=='r' || inptr[4]=='R') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_lvwar;
										tbndx++;
										return token = tk_lvwar;
                }
                if ((inptr[1]=='w' || inptr[1]=='W') &&
                    (inptr[2]=='s' || inptr[2]=='S') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lws;
										tbndx++;
										return token = tk_lws;
                }  
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='p' || inptr[3]=='P') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_loop;
										tbndx++;
										return token = tk_loop;
                }  
                if ((inptr[1]=='l' || inptr[1]=='L') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_lla;
										tbndx++;
										return token = tk_lla;
                }  
                if ((inptr[1]=='l' || inptr[1]=='L') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    (inptr[3]=='x' || inptr[3]=='X') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_llax;
										tbndx++;
										return token = tk_llax;
                }  
            }
			if (gCpu==7) {
				if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='b' || inptr[3]=='B') && isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ltcb;
					tbndx++;
					return token = tk_ltcb;
				}
			}
            break;

        // max min mod modu modi modui mov mul muli mulu mului mtspr mfspr mtfp mffp message memdb memsb mfu mtu
        case 'm': case 'M':
					if (gCpu == GAMBIT_V5) {
						if ((inptr[1] == 'o' || inptr[1] == 'O')
							&& (inptr[2]=='v' || inptr[2]=='V')
							&& (inptr[3]=='s' || inptr[3]=='S')
							&& (inptr[4]=='x' || inptr[4]=='X')
							&& isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_movsx;
							tbndx++;
							return token = tk_movsx;
						}
						if ((inptr[1] == 'o' || inptr[1] == 'O')
							&& (inptr[2] == 'v' || inptr[2] == 'V')
							&& (inptr[3] == 'z' || inptr[3] == 'Z')
							&& (inptr[4] == 'x' || inptr[4] == 'X')
							&& isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_movzx;
							tbndx++;
							return token = tk_movzx;
						}
					}
					if ((inptr[1]=='a' || inptr[1]=='A') && (inptr[2]=='x' || inptr[2]=='X') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_max;
								tbndx++;
								return (token = tk_max);
            }
						if ((inptr[1] == 'i' || inptr[1] == 'I') && (inptr[2] == 'n' || inptr[2] == 'N') && isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_min;
							tbndx++;
							return (token = tk_min);
						}
						if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='v' || inptr[2]=='V') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_mov;
								tbndx++;
								return token = tk_mov;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_mul;
								tbndx++;
								return (token = tk_mul);
            }
						if (gCpu == 'F') {
							if ((inptr[1] == 'u' || inptr[1] == 'U') &&
								(inptr[2] == 'l' || inptr[2] == 'L') &&
								(inptr[3] == 'f' || inptr[3] == 'F') &&
								isspaceOrDot(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_mulf;
								tbndx++;
								return (token = tk_mulf);
							}
						}
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_mulu;
								tbndx++;
								return token = tk_mulu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_mului;
								tbndx++;
								return token = tk_mului;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_muli;
								tbndx++;
								return token = tk_muli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_mod;
								tbndx++;
								return token = tk_mod;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_modu;
								tbndx++;
								return token = tk_modu;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_modi;
								tbndx++;
								return token = tk_modi;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_modui;
								tbndx++;
								return token = tk_modui;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                (inptr[4]=='r' || inptr[4]=='R') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_mtspr;
								tbndx++;
								return token = tk_mtspr;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                (inptr[4]=='r' || inptr[4]=='R') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_mfspr;
								tbndx++;
								return token = tk_mfspr;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') &&
                (inptr[2]=='f' || inptr[2]=='F') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_mtfp;
								tbndx++;
								return token = tk_mtfp;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') &&
                (inptr[2]=='f' || inptr[2]=='F') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_mffp;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_message;
								tbndx++;
								return token = tk_message;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') &&
                (inptr[2]=='2' || inptr[2]=='2') &&
                (inptr[3]=='f' || inptr[3]=='F') &&
                (inptr[4]=='l' || inptr[4]=='L') &&
                (inptr[5]=='t' || inptr[5]=='T') &&
                isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_mv2flt;
								tbndx++;
								return token = tk_mv2flt;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') &&
                (inptr[2]=='2' || inptr[2]=='2') &&
                (inptr[3]=='f' || inptr[3]=='F') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                (inptr[5]=='x' || inptr[5]=='X') &&
                isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_mv2fix;
								tbndx++;
								return token = tk_mv2fix;
            }
            if (gCpu==4 || gCpu=='F' || gCpu=='J' || gCpu==GAMBIT_V5) {
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='m' || inptr[2]=='M') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    (inptr[4]=='b' || inptr[4]=='B') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_memdb;
										tbndx++;
										return token = tk_memdb;
                }
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='m' || inptr[2]=='M') &&
                    (inptr[3]=='s' || inptr[3]=='S') &&
                    (inptr[4]=='b' || inptr[4]=='B') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_memsb;
										tbndx++;
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
										tokenBuffer[tbndx] = tk_mark1;
										tbndx++;
										return token = tk_mark1;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    (inptr[3]=='k' || inptr[3]=='K') &&
                    (inptr[4]=='2' || inptr[4]=='2') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_mark2;
										tbndx++;
										return token = tk_mark2;
                }
			}
            if ((inptr[1]=='a' || inptr[1]=='A') &&
                (inptr[2]=='c' || inptr[2]=='C') &&
                (inptr[3]=='r' || inptr[3]=='R') &&
                (inptr[4]=='o' || inptr[4]=='O') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_macro;
								tbndx++;
								return (token = tk_macro);
            }
						if (gCpu == RISCV) {
							if ((inptr[1] == 'v' || inptr[1] == 'V') &&
								(inptr[2] == 's' || inptr[2] == 'S') &&
								(inptr[3] == 'e' || inptr[3] == 'E') &&
								(inptr[4] == 'g' || inptr[4] == 'G') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_mvseg;
								tbndx++;
								return token = tk_mvseg;
							}
							if ((inptr[1] == 'v' || inptr[1] == 'V') &&
								(inptr[2] == 'm' || inptr[2] == 'M') &&
								(inptr[3] == 'a' || inptr[3] == 'A') &&
								(inptr[4] == 'p' || inptr[4] == 'P') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_mvmap;
								tbndx++;
								return token = tk_mvmap;
							}
							if ((inptr[1] == 'r' || inptr[1] == 'R') &&
								(inptr[2] == 'e' || inptr[2] == 'E') &&
								(inptr[3] == 't' || inptr[3] == 'T') &&
								isspace(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_mret;
								tbndx++;
								return token = tk_mret;
							}
							if ((inptr[1] == 'f' || inptr[1] == 'F') &&
								(inptr[2] == 'u' || inptr[2] == 'U') &&
								isspace(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_mfu;
								tbndx++;
								return token = tk_mfu;
							}
							if ((inptr[1] == 't' || inptr[1] == 'T') &&
								(inptr[2] == 'u' || inptr[2] == 'U') &&
								isspace(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_mtu;
								tbndx++;
								return token = tk_mtu;
							}
						}
            break;

        // not neg nop
        case 'n': case 'N':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_not;
								tbndx++;
								return token = tk_not;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_neg;
								tbndx++;
								return token = tk_neg;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='p' || inptr[2]=='P') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_nop;
								tbndx++;
								return token = tk_nop;
            }
            break;

        // or ori org
        case 'o': case 'O':
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ori;
								tbndx++;
								return token = tk_ori;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_or;
								tbndx++;
								return token = tk_or;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='g' || inptr[2]=='G') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_org;
								tbndx++;
								return token = tk_org;
            }
            break;

        // palloc pfree pea peekq push pop php plp pstat public
        case 'p': case 'P':
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='h' || inptr[3]=='H') &&
                isspace(inptr[4]) || inptr[4]=='.') {
                inptr += 4;
								tokenBuffer[tbndx] = tk_push;
								tbndx++;
								return token = tk_push;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3]) || inptr[3]=='.') {
                inptr += 3;
								tokenBuffer[tbndx] = tk_pop;
								tbndx++;
								return token = tk_pop;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_pea;
								tbndx++;
								return token = tk_pea;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_php;
								tbndx++;
								return token = tk_php;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_plp;
								tbndx++;
								return token = tk_plp;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='b' || inptr[2]=='B') &&
                (inptr[3]=='l' || inptr[3]=='L') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                (inptr[5]=='c' || inptr[5]=='C') &&
                isspace(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_public;
								tbndx++;
								return (token = tk_public);
            }
						if ((inptr[1] == 't' || inptr[1] == 'T') &&
							(inptr[2] == 'r' || inptr[2] == 'R') &&
							(inptr[3] == 'd' || inptr[3] == 'D') &&
							(inptr[4] == 'i' || inptr[4] == 'I') &&
							(inptr[5] == 'f' || inptr[5] == 'F') &&
							isspace(inptr[6])) {
							inptr += 6;
							tokenBuffer[tbndx] = tk_ptrdif;
							tbndx++;
							return (token = tk_ptrdif);
						}
						if (gCpu==4) {
                if (isdigit(inptr[1]) && (inptr[2]=='.' || inptr[2]==',' || isspace(inptr[2]))) {
                    inptr += 1;
										tokenBuffer[tbndx] = tk_pred;
										tbndx++;
										return token = tk_pred;
                }
                if (isdigit(inptr[1]) && isdigit(inptr[2]) && (inptr[3]=='.' || inptr[3]==',' || isspace(inptr[3]))) {
                    inptr += 1;
										tokenBuffer[tbndx] = tk_pred;
										tbndx++;
										return token = tk_pred;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_pand;
										tbndx++;
										return token = tk_pand;
                }
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_por;
										tbndx++;
										return token = tk_por;
                }
                if ((inptr[1]=='e' || inptr[1]=='R') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='r' || inptr[3]=='R') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_peor;
										tbndx++;
										return token = tk_peor;
                }
                if ((inptr[1]=='a' || inptr[1]=='A') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='d' || inptr[3]=='D') &&
                    (inptr[4]=='c' || inptr[4]=='C') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_pandc;
										tbndx++;
										return token = tk_pandc;
                }
                if ((inptr[1]=='o' || inptr[1]=='O') &&
                    (inptr[2]=='r' || inptr[2]=='R') &&
                    (inptr[3]=='c' || inptr[3]=='C') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_porc;
										tbndx++;
										return token = tk_porc;
                }
                if ((inptr[1]=='n' || inptr[1]=='N') &&
                    (inptr[2]=='a' || inptr[2]=='A') &&
                    (inptr[3]=='n' || inptr[3]=='N') &&
                    (inptr[4]=='d' || inptr[4]=='D') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_pnand;
										tbndx++;
										return token = tk_pnand;
                }
                if ((inptr[1]=='n' || inptr[1]=='N') &&
                    (inptr[2]=='o' || inptr[2]=='O') &&
                    (inptr[3]=='r' || inptr[3]=='R') &&
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_pnor;
										tbndx++;
										return token = tk_pnor;
                }
                if ((inptr[1]=='e' || inptr[1]=='E') &&
                    (inptr[2]=='n' || inptr[2]=='N') &&
                    (inptr[3]=='o' || inptr[3]=='O') &&
                    (inptr[4]=='r' || inptr[4]=='R') &&
                    isspace(inptr[5])) {
                    inptr += 5;
										tokenBuffer[tbndx] = tk_penor;
										tbndx++;
										return token = tk_penor;
                }
            }
						if (gCpu == RISCV) {
							if ((inptr[1] == 'a' || inptr[1] == 'A') &&
								(inptr[2] == 'l' || inptr[2] == 'L') &&
								(inptr[3] == 'l' || inptr[3] == 'L') &&
								(inptr[4] == 'o' || inptr[4] == 'O') &&
								(inptr[5] == 'c' || inptr[5] == 'C') &&
								isspace(inptr[6])) {
								inptr += 6;
								tokenBuffer[tbndx] = tk_palloc;
								tbndx++;
								return (token = tk_palloc);
							}
							if ((inptr[1] == 'f' || inptr[1] == 'F') &&
								(inptr[2] == 'i' || inptr[2] == 'I') &&
								isspace(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_pfi;
								tbndx++;
								return (token = tk_pfi);
							}
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 'e' || inptr[2] == 'E') &&
								(inptr[3] == 'k' || inptr[3] == 'K') &&
								(inptr[4] == 'q' || inptr[4] == 'Q') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_peekq;
								tbndx++;
								return (token = tk_peekq);
							}
							if ((inptr[1] == 'f' || inptr[1] == 'F') &&
								(inptr[2] == 'r' || inptr[2] == 'R') &&
								(inptr[3] == 'e' || inptr[3] == 'E') &&
								(inptr[4] == 'e' || inptr[4] == 'E') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_pfree;
								tbndx++;
								return (token = tk_pfree);
							}
							if ((inptr[1] == 's' || inptr[1] == 'S') &&
								(inptr[2] == 't' || inptr[2] == 'T') &&
								(inptr[3] == 'a' || inptr[3] == 'A') &&
								(inptr[4] == 't' || inptr[4] == 'T') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_pstat;
								tbndx++;
								return (token = tk_pstat);
							}
							if ((inptr[1] == 'u' || inptr[1] == 'U') &&
								(inptr[2] == 's' || inptr[2] == 'S') &&
								(inptr[3] == 'h' || inptr[3] == 'H') &&
								(inptr[4] == 'q' || inptr[4] == 'Q') &&
								isspace(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_pushq;
								tbndx++;
								return (token = tk_pushq);
							}
							if ((inptr[1] == 'o' || inptr[1] == 'O') &&
								(inptr[2] == 'p' || inptr[2] == 'P') &&
								(inptr[3] == 'q' || inptr[3] == 'Q') &&
								isspace(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_popq;
								tbndx++;
								return (token = tk_popq);
							}
						}
						break;

        // ret rem rex rol roli ror rori rtd rte rtf rts rti rtl rodata
        case 'r': case 'R':
					if (gCpu == 7 || gCpu == 'A' || gCpu == 'F' || gCpu == 'J' || gCpu==NVIO3 || gCpu == RISCV || gCpu==GAMBIT_V5) {
						if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 't' || inptr[2] == 'T') && isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_ret;
							tbndx++;
							return token = tk_ret;
						}
					}
					if (gCpu == 7 || gCpu == 'A' || gCpu == 'F' || gCpu == 'J') {
						if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='x' || inptr[2]=='X') && isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_rex;
							tbndx++;
							return token = tk_rex;
						}
					}
					if (gCpu == RISCV) {
						if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 'm' || inptr[2] == 'M') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_remu;
							tbndx++;
							return token = tk_remu;
						}
						if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 'm' || inptr[2] == 'M') && isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_rem;
							tbndx++;
							return token = tk_rem;
						}
						if ((inptr[1] == 'm' || inptr[1] == 'M') &&
							(inptr[2] == 'v' || inptr[2] == 'V') &&
							(inptr[3] == 'r' || inptr[3] == 'R') &&
							(inptr[4] == 'd' || inptr[4] == 'D') &&
							(inptr[5] == 'y' || inptr[5] == 'Y') &&
							isspace(inptr[6])) {
							inptr += 6;
							tokenBuffer[tbndx] = tk_rmvrdy;
							tbndx++;
							return token = tk_rmvrdy;
						}
					}
					if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='s' || inptr[2]=='S') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rts;
								tbndx++;
								return token = tk_rts;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='f' || inptr[2]=='F') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rtf;
								tbndx++;
						}
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='l' || inptr[2]=='L') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rtl;
								tbndx++;
								return token = tk_rtl;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rol;
								tbndx++;
								return token = tk_rol;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_roli;
								tbndx++;
								return token = tk_roli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ror;
								tbndx++;
								return token = tk_ror;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_rori;
								tbndx++;
								return token = tk_rori;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rti;
								tbndx++;
								return token = tk_rti;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rte;
								tbndx++;
								return token = tk_rte;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rtd;
								tbndx++;
								return token = tk_rtd;
            }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (inptr[5]=='a' || inptr[5]=='A') &&
                 isspace(inptr[6])) {
                 inptr += 6;
								 tokenBuffer[tbndx] = tk_rodata;
								 tbndx++;
								 return token = tk_rodata;
             }
			 if (gCpu == 'F') {
				 if ((inptr[1] == 'e' || inptr[1] == 'E') &&
					 (inptr[2] == 'd' || inptr[2] == 'D') &&
					 (inptr[3] == 'o' || inptr[3] == 'O') &&
					 (inptr[4] == 'r' || inptr[4] == 'R') &&
					 isspace(inptr[5])) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_redor;
					 tbndx++;
					 return token = tk_redor;
				 }
			 }
            break;
        
        // sb sc sf sh sw sxb sxc sxh sub subi subu subui shl shli shr shru shrui sei smr ss:
        // seq seqi sne snei sge sgei sgt sgti slt slti sle slei sgeu sgeui sgtu sgtui sltu sltui sleu sleui
        // swcr sfd sts sync sws stcmp stmov srai srli stcb sv
		// DSD9/Itanium: stb stw stp stt std sto
        case 's': case 'S':
					if (gCpu == GAMBIT || gCpu == GAMBIT_V5) {
						if ((inptr[1] == 't' || inptr[1] == 'T') && isspace(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_st;
							tbndx++;
							return token = tk_st;
						}
						if ((inptr[1] == 't' || inptr[1] == 'T') &&
							(inptr[2] == 'b' || inptr[2] == 'B') &&
							isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_stb;
							tbndx++;
							return token = tk_stb;
						}
						if ((inptr[1] == 't' || inptr[1] == 'T') &&
							(inptr[2] == 'f' || inptr[2] == 'F') &&
							isspace(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_stf;
							tbndx++;
							return (token = tk_stf);
						}
					}
			if (gCpu==DSD9 || gCpu=='J' || gCpu==NVIO3 || gCpu==RISCV) {
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_std;
					tbndx++;
					return token = tk_std;
				}  
				if ((inptr[1] == 't' || inptr[1] == 'T') &&
					(inptr[2] == 'h' || inptr[2] == 'H') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_sth;
					tbndx++;
					return token = tk_sth;
				}
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='d' || inptr[2]=='D') &&
					(inptr[3]=='c' || inptr[3]=='C') &&
					(inptr[4]=='r' || inptr[4]=='R') &&
					isspace(inptr[5])) {
					inptr += 5;
					tokenBuffer[tbndx] = tk_stdcr;
					tbndx++;
					return token = tk_stdcr;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_stb;
					tbndx++;
					return token = tk_stb;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_stp;
					tbndx++;
					return token = tk_stp;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_stt;
					tbndx++;
					return token = tk_stt;
				}  
				if ((inptr[1]=='t' || inptr[1]=='T') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_stw;
					tbndx++;
					return token = tk_stw;
				}  
				if ((inptr[1] == 't' || inptr[1] == 'T') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_sto;
					tbndx++;
					return token = tk_sto;
				}
			}
			if (gCpu == RISCV) {
				if ((inptr[1] == 'c' || inptr[1] == 'C') && isspace(inptr[2])) {
					inptr += 2;
					tokenBuffer[tbndx] = tk_sc;
					tbndx++;
					return token = tk_sc;
				}
				if ((inptr[1] == 'e' || inptr[1] == 'E') &&
					(inptr[2] == 't' || inptr[2] == 'T') &&
					(inptr[3] == 't' || inptr[3] == 'T') &&
					(inptr[4] == 'o' || inptr[3] == 'O') &&
					isspace(inptr[5])) {
					inptr += 5;
					tokenBuffer[tbndx] = tk_setto;
					tbndx++;
					return token = tk_setto;
				}
			}
			if ((inptr[1]=='w' || inptr[1]=='W') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sw;
								tbndx++;
								return token = tk_sw;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sb;
								tbndx++;
								return token = tk_sb;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sc;
								tbndx++;
								return token = tk_sc;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sh;
								tbndx++;
								return token = tk_sh;
            }  
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspace(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sf;
								tbndx++;
								return token = tk_sf;
            }  
            if ((inptr[1]=='u' || inptr[1]=='U') && 
                (inptr[2]=='b' || inptr[2]=='B') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_subui;
								tbndx++;
								return token = tk_subui;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_subi;
								tbndx++;
								return token = tk_subi;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='u' || inptr[3]=='U') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_subu;
								tbndx++;
								return token = tk_subu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sub;
								tbndx++;
								return token = tk_sub;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sfd;
								tbndx++;
								return token = tk_sfd;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_shli;
								tbndx++;
								return token = tk_shli;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_shl;
								tbndx++;
								return token = tk_shl;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_shrui;
								tbndx++;
								return token = tk_shrui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_shru;
								tbndx++;
								return token = tk_shru;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='r' || inptr[2]=='R') && 
                isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_shru;
								tbndx++;
								return token = tk_shru;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='i' || inptr[2]=='I') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sei;
								tbndx++;
								return token = tk_sei;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_smr;
								tbndx++;
								return token = tk_smr;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='b' || inptr[2]=='B') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxb;
								tbndx++;
								return token = tk_sxb;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxc;
								tbndx++;
								return token = tk_sxc;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='h' || inptr[2]=='H') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxh;
								tbndx++;
								return token = tk_sxh;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_seq;
								tbndx++;
								return token = tk_seq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_seqi;
								tbndx++;
								return token = tk_seqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sne;
								tbndx++;
								return token = tk_sne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_snei;
								tbndx++;
								return token = tk_snei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sge;
								tbndx++;
								return token = tk_sge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgei;
								tbndx++;
								return token = tk_sgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sgt;
								tbndx++;
								return token = tk_sgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgti;
								tbndx++;
								return token = tk_sgti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sle;
								tbndx++;
								return token = tk_sle;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_slei;
								tbndx++;
								return token = tk_slei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_slt;
								tbndx++;
								return (token = tk_slt);
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_slti;
								tbndx++;
								return token = tk_slti;
            }

            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgeu;
								tbndx++;
								return token = tk_sgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgeui;
								tbndx++;
								return token = tk_sgeui;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgtu;
								tbndx++;
								return token = tk_sgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_sgtui;
								tbndx++;
								return token = tk_sgtui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sleu;
								tbndx++;
								return token = tk_sleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_sleui;
								tbndx++;
								return token = tk_sleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sltu;
								tbndx++;
								return token = tk_sltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspace(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_sltui;
								tbndx++;
								return token = tk_sltui;
            }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]==':')) {
                 inptr+=3;
								 tokenBuffer[tbndx] = tk_ss;
								 tbndx++;
								 return token = tk_ss;
             }
            if ((inptr[1]=='w' || inptr[1]=='W') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                (inptr[3]=='p' || inptr[3]=='P') &&
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_swap;
								tbndx++;
								return token = tk_swap;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sw;
								tbndx++;
								return token = tk_sw;
            }  
            if ((inptr[1]=='v' || inptr[1]=='V') && isspace(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sv;
								tbndx++;
								return token = tk_sv;
            }  
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='s' || inptr[2]=='S') && 
                isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sys;
								tbndx++;
								return token = tk_sys;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && 
                (inptr[2]=='p' || inptr[2]=='P') && 
                isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_stp;
								tbndx++;
								return token = tk_stp;
            }
			if (gCpu == 'F') {
				if ((inptr[1] == 'w' || inptr[1] == 'W') &&
					(inptr[2] == 'p' || inptr[2] == 'P') &&
					isspace(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_swp;
					tbndx++;
					return token = tk_swp;
				}
			}
            if (gCpu==4) {
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='b' || inptr[3]=='B') && 
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsb;
										tbndx++;
										return token = tk_stsb;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='c' || inptr[3]=='C') && 
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsc;
										tbndx++;
										return token = tk_stsc;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='h' || inptr[3]=='H') && 
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsh;
										tbndx++;
										return token = tk_stsh;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='w' || inptr[3]=='W') && 
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsw;
										tbndx++;
										return token = tk_stsw;
                }
                if ((inptr[1]=='w' || inptr[1]=='W') &&
                    (inptr[2]=='s' || inptr[2]=='S') &&
                    isspace(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_sws;
										tbndx++;
										return token = tk_sws;
                }  
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='c' || inptr[2]=='C') && 
                    (inptr[3]=='m' || inptr[3]=='M') && 
                    (inptr[4]=='p' || inptr[4]=='P') && 
                    inptr[5]=='.') {
                    inptr += 6;
										tokenBuffer[tbndx] = tk_stcmp;
										tbndx++;
										return token = tk_stcmp;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='m' || inptr[2]=='M') && 
                    (inptr[3]=='o' || inptr[3]=='O') && 
                    (inptr[4]=='v' || inptr[4]=='V') && 
                    inptr[5]=='.') {
                    inptr += 6;
										tokenBuffer[tbndx] = tk_stmov;
										tbndx++;
										return token = tk_stmov;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='e' || inptr[3]=='E') && 
                    (inptr[4]=='t' || inptr[4]=='T') && 
                    inptr[5]=='.') {
                    inptr += 6;
										tokenBuffer[tbndx] = tk_stset;
										tbndx++;
										return token = tk_stset;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') && 
                    (inptr[2]=='r' || inptr[2]=='R') && 
                    (inptr[3]=='i' || inptr[3]=='I') && 
                    isspace(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_shri;
										tbndx++;
										return token = tk_shri;
                }
                if ((inptr[1]=='h' || inptr[1]=='H') && 
                    (inptr[2]=='r' || inptr[2]=='R') && 
                    isspaceOrDot(inptr[3])) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_shr;
										tbndx++;
										return token = tk_shr;
                }
            }
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='n' || inptr[2]=='N') && 
                (inptr[3]=='c' || inptr[3]=='C') && 
                isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sync;
								tbndx++;
								return token = tk_sync;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='r' || inptr[3]=='R') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_swcr;
								tbndx++;
								return token = tk_swcr;
            }
            if ((inptr[1]=='w' || inptr[1]=='W') && (inptr[2]=='c' || inptr[2]=='C') && isspace(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_swc;
								tbndx++;
								return token = tk_swc;
            }
            // RiSC-V opcodes
            // slli srli srai
            if (gCpu==RISCV) {
							if ((inptr[1] == 'l' || inptr[1] == 'L') &&
								(inptr[2] == 'l' || inptr[2] == 'L') &&
								isspaceOrDot(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_sll;
								tbndx++;
								return token = tk_sll;
							}
							if ((inptr[1]=='l' || inptr[1]=='L') &&
                  (inptr[2]=='l' || inptr[2]=='L') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
									tokenBuffer[tbndx] = tk_slli;
									tbndx++;
									return token = tk_slli;
              }
							if ((inptr[1] == 'r' || inptr[1] == 'R') &&
								(inptr[2] == 'a' || inptr[2] == 'A') &&
								isspaceOrDot(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_sra;
								tbndx++;
								return token = tk_sra;
							}
							if ((inptr[1]=='r' || inptr[1]=='R') &&
                  (inptr[2]=='a' || inptr[2]=='A') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
									tokenBuffer[tbndx] = tk_srai;
									tbndx++;
									return token = tk_srai;
              }
							if ((inptr[1] == 'r' || inptr[1] == 'R') &&
								(inptr[2] == 'l' || inptr[2] == 'L') &&
								isspaceOrDot(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_srl;
								tbndx++;
								return token = tk_srl;
							}
							if ((inptr[1]=='r' || inptr[1]=='R') &&
                  (inptr[2]=='l' || inptr[2]=='L') && 
                  (inptr[3]=='i' || inptr[3]=='I') && 
                  isspaceOrDot(inptr[4])) {
                  inptr += 4;
									tokenBuffer[tbndx] = tk_srli;
									tbndx++;
									return token = tk_srli;
              }
            }
			// DSD7
			if (gCpu==7) {
				if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='c' || inptr[2]=='C') && (inptr[3]=='b' || inptr[3]=='B') && isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_stcb;
					tbndx++;
					return token = tk_stcb;
				}
			}
			if (gCpu == 'F') {
				if ((inptr[1] == 'p' || inptr[1] == 'P')
					&& (inptr[2] == 't' || inptr[2] == 'T')
					&& (inptr[3] == 'r' || inptr[3] == 'R')
					&& isspace(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_sptr;
					tbndx++;
					return (token = tk_sptr);
				}
				if ((inptr[1] == 'e' || inptr[1] == 'E') &&
					(inptr[2] == 't' || inptr[2] == 't') &&
					(inptr[3] == 'w' || inptr[3] == 'W') &&
					(inptr[4] == 'b' || inptr[3] == 'B') &&
					isspace(inptr[5])) {
					inptr += 5;
					tokenBuffer[tbndx] = tk_setwb;
					tbndx++;
					return token = tk_setwb;
				}
			}
      break;

        // tgt to tlbdis tlben tlbpb tlbrd tlbrdreg tlbwi tlbwr tlbwrreg transform
        case 't': case 'T':
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 isspace(inptr[2])) {
                 inptr += 2;
								 tokenBuffer[tbndx] = tk_to;
								 tbndx++;
								 return token = tk_to;
             }
			 if (gCpu=='A') {
                 if ((inptr[1]=='g' || inptr[1]=='G') &&
                     (inptr[2]=='t' || inptr[2]=='T') &&
                     isspace(inptr[3])) {
                     inptr += 3;
										 tokenBuffer[tbndx] = tk_tgt;
										 tbndx++;
										 return token = tk_tgt;
                 }
			 }
			 if (gCpu == 4) {
				 if ((inptr[1] == 's' || inptr[1] == 'S') && (inptr[2] == 't' || inptr[2] == 'T') &&
					 isspace(inptr[3])) {
					 inptr += 3;
					 tokenBuffer[tbndx] = tk_tst;
					 tbndx++;
					 return token = tk_tst;
				 }
			 }
			 if (gCpu==4 || gCpu=='F') {
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='d' || inptr[3]=='D') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     (inptr[5]=='s' || inptr[5]=='S') &&
                     isspace(inptr[6])) {
                     inptr += 6;
										 tokenBuffer[tbndx] = tk_tlbdis;
										 tbndx++;
										 return token = tk_tlbdis;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='e' || inptr[3]=='E') &&
                     (inptr[4]=='n' || inptr[4]=='N') &&
                     isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlben;
										 tbndx++;
										 return token = tk_tlben;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='p' || inptr[3]=='P') &&
                     (inptr[4]=='b' || inptr[4]=='B') &&
                     isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbpb;
										 tbndx++;
										 return token = tk_tlbpb;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='r' || inptr[3]=='R') &&
                     (inptr[4]=='d' || inptr[4]=='D') &&
                     isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbrd;
										 tbndx++;
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
										 tokenBuffer[tbndx] = tk_tlbrdreg;
										 tbndx++;
										 return token = tk_tlbrdreg;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbwi;
										 tbndx++;
										 return token = tk_tlbwi;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='r' || inptr[4]=='R') &&
                     isspace(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbwr;
										 tbndx++;
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
										 tokenBuffer[tbndx] = tk_tlbwrreg;
										 tbndx++;
										 return token = tk_tlbwrreg;
                 }
             }
						 if (gCpu == 'F') {
							 if ((inptr[1] == 'r' || inptr[1] == 'R') &&
								 (inptr[2] == 'a' || inptr[2] == 'A') &&
								 (inptr[3] == 'n' || inptr[3] == 'N') &&
								 (inptr[4] == 's' || inptr[4] == 'S') &&
								 (inptr[5] == 'f' || inptr[5] == 'F') &&
								 (inptr[6] == 'o' || inptr[6] == 'O') &&
								 (inptr[7] == 'r' || inptr[7] == 'R') &&
								 (inptr[8] == 'm' || inptr[8] == 'M') &&
								 isspaceOrDot(inptr[9])) {
								 inptr += 9;
								 tokenBuffer[tbndx] = tk_transform;
								 tbndx++;
								 return token = tk_transform;
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
								tokenBuffer[tbndx] = tk_unlink;
								tbndx++;
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
								tokenBuffer[tbndx] = tk_vadd;
								tbndx++;
								return token = tk_vadd;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='d' || inptr[2]=='D') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vadds;
								tbndx++;
								return token = tk_vadds;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='n' || inptr[2]=='N') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vand;
								tbndx++;
								return token = tk_vand;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='n' || inptr[2]=='N') &&
				(inptr[3]=='d' || inptr[3]=='D') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vands;
								tbndx++;
								return token = tk_vands;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') &&
				(inptr[2]=='i' || inptr[2]=='I') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vdiv;
								tbndx++;
								return token = tk_vdiv;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') &&
				(inptr[2]=='i' || inptr[2]=='I') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vdivs;
								tbndx++;
								return token = tk_vdivs;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='v' || inptr[3]=='V') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vmov;
								tbndx++;
								return token = tk_vmov;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='l' || inptr[3]=='L') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vmul;
								tbndx++;
								return token = tk_vmul;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='l' || inptr[3]=='L') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vmuls;
								tbndx++;
								return token = tk_vmuls;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
				(inptr[2]=='r' || inptr[2]=='R') &&
				isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_vor;
								tbndx++;
								return token = tk_vor;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
				(inptr[2]=='r' || inptr[2]=='R') &&
				(inptr[3]=='s' || inptr[3]=='S') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vors;
								tbndx++;
								return token = tk_vors;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='b' || inptr[3]=='B') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vsub;
								tbndx++;
								return token = tk_vsub;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') &&
				(inptr[2]=='u' || inptr[2]=='U') &&
				(inptr[3]=='b' || inptr[3]=='B') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vsubs;
								tbndx++;
								return token = tk_vsubs;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='r' || inptr[3]=='R') &&
				isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_vxor;
								tbndx++;
								return token = tk_vxor;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='r' || inptr[3]=='R') &&
				(inptr[4]=='s' || inptr[4]=='S') &&
				isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_vxors;
								tbndx++;
								return token = tk_vxors;
            }
			break;

        // wai wfi
        case 'w': case 'W':
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 isspace(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_wai;
								 tbndx++;
								 return token = tk_wai;
             }
						 if (gCpu == RISCV) {
							 if ((inptr[1] == 'f' || inptr[1] == 'F') &&
								 (inptr[2] == 'i' || inptr[2] == 'I') &&
								 isspace(inptr[3])) {
								 inptr += 3;
								 tokenBuffer[tbndx] = tk_wfi;
								 tbndx++;
								 return token = tk_wfi;
							 }
						 }
						 break;

        // xnor xor xori
        case 'x': case 'X':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspace(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_xori;
								tbndx++;
								return token = (tk_xori);
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_xor;
								tbndx++;
								return (token = tk_xor);
            }
			if (
				(inptr[1] == 'n' || inptr[1] == 'N')
				&& (inptr[2] == 'o' || inptr[2] == 'O')
				&& (inptr[3] == 'r' || inptr[3] == 'R')
				&& isspaceOrDot(inptr[4])) {
				inptr += 4;
				tokenBuffer[tbndx] = tk_xnor;
				tbndx++;
				return (token = tk_xnor);
			}
			break;

        // zs:
        case 'z': case 'Z':
			if (gCpu == 4 || gCpu == 'F') {
				if ((inptr[1] == 's' || inptr[1] == 'S') && inptr[2] == ':') {
					inptr += 3;
					tokenBuffer[tbndx] = tk_zs;
					tbndx++;
					return token = tk_zs;
				}
			}
			if (gCpu == 4 || gCpu == 'F') {
				if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='b' || inptr[2]=='B') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_zxb;
										tbndx++;
										return token = tk_zxb;
                }
                if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='c' || inptr[2]=='C') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_zxc;
										tbndx++;
										return token = tk_zxc;
                }
                if ((inptr[1]=='x' || inptr[1]=='X') &&
                    (inptr[2]=='h' || inptr[2]=='h') &&
                    isspace(inptr[3])
                    ) {
                    inptr += 3;
										tokenBuffer[tbndx] = tk_zxh;
										tbndx++;
										return token = tk_zxh;
                }
            }
        }
        // The text wasn't recognized as any of the above tokens. So try for an
        // identifier name.
				p = inptr;
        if (getIdentifier()) {
					SYM *sym;
					char *q;
					if (sym = find_symbol(lastid)) {
						if (sym->isMacro) {
							Arglist args;
							args.Get();
							q = sym->macro->SubArgs(&args);
							Macro::Substitute(q, inptr-p);
							inptr = p;
							continue;
						}
					}
					tokenBuffer[tbndx] = tk_id;
					tbndx++;
					tokenBuffer[tbndx] = lpndx;
					tbndx++;
					tokenBuffer[tbndx] = lpndx >> 16;
					tbndx++;
					strncpy(&litpool[lpndx], lastid, sizeof(lastid));
					lpndx += strlen(lastid) + 1;
					litpool[lpndx - 1] = '\0';
					//n = GetSymNdx(sym);
					//tokenBuffer[tbndx] = n;
					//tbndx++;
					//tokenBuffer[tbndx] = n >> 16;
					//tbndx++;
          return (token = tk_id);
        }
        inptr++;
    } while (*inptr);
    return (token = tk_eof);
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

