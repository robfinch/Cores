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

// RTF64
static int regSP = 31;
static int regFP = 30;
static int regLR = 29;
static int regXL = 28;
static int regGP = 27;
static int regTP = 26;
static int regCB = 23;

int rtf64_NextToken()
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
					break;
					/*
					inptr++;
					tokenBuffer[tbndx] = '_';
					tbndx++;
					return (token = '_');
					*/
        // abs add addi addu addui and andcm andi align aslx asr asri
        case 'a':
        case 'A':
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_and;
								tbndx++;
								return token = tk_and;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='u' || inptr[3]=='U') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_addu;
								tbndx++;
								return token = tk_addu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && 
                (inptr[2]=='d' || inptr[2]=='D') && 
                (inptr[3]=='u' || inptr[3]=='U') && 
                (inptr[4]=='i' || inptr[4]=='I') && 
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_addui;
								tbndx++;
								return token = tk_addui;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_addi;
								tbndx++;
								return token = tk_addi;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_add;
								tbndx++;
								return token = tk_add;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='i' || inptr[2]=='I') && (inptr[3]=='g' || inptr[3]=='G') && (inptr[4]=='n' || inptr[4]=='N') && isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_align;
								tbndx++;
								return token = tk_align;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='d' || inptr[2]=='D') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_andi;
								tbndx++;
								return token = tk_andi;
            }
						if ((inptr[1] == 'n' || inptr[1] == 'N') &&
							(inptr[2] == 'd' || inptr[2] == 'D') &&
							(inptr[3] == 'c' || inptr[3] == 'C') &&
							(inptr[4] == 'm' || inptr[4] == 'M') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_andcm;
							tbndx++;
							return token = tk_andcm;
						}
						if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
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
						if ((inptr[1] == 's' || inptr[1] == 'S') && (inptr[2] == 'l' || inptr[2] == 'L') && (inptr[3] == 'x' || inptr[3] == 'X') && isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_aslx;
							tbndx++;
							return token = tk_aslx;
						}
						if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='l' || inptr[2]=='L') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_asl;
								tbndx++;
								return token = tk_asl;
            }
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='s' || inptr[2]=='S') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_abs;
								tbndx++;
								return token = tk_abs;
            }
            break;

        // band beq bor bne bit
        case 'b':
        case 'B':
					if ((inptr[1] == 'e' || inptr[1] == 'E') &&
						(inptr[2] == 'q' || inptr[2] == 'Q') &&
						(inptr[3] == 'z' || inptr[2] == 'Z') &&
						isspaceOrDot(inptr[4])) {
						inptr += 4;
						tokenBuffer[tbndx] = tk_beqz;
						tbndx++;
						return token = tk_beqz;
					}
					if ((inptr[1] == 'n' || inptr[1] == 'N') &&
						(inptr[2] == 'e' || inptr[2] == 'E') &&
						(inptr[3] == 'z' || inptr[2] == 'Z') &&
						isspaceOrDot(inptr[4])) {
						inptr += 4;
						tokenBuffer[tbndx] = tk_bnez;
						tbndx++;
						return token = tk_bnez;
					}
					if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='q' || inptr[2]=='Q') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_beq;
								tbndx++;
								return token = tk_beq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && 
                (inptr[2]=='q' || inptr[2]=='Q') &&
                (inptr[3]=='i' || inptr[2]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_beqi;
								tbndx++;
								return token = tk_beqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bne;
								tbndx++;
								return token = tk_bne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bnei;
								tbndx++;
								return token = tk_bnei;
            }
						if (gCpu == RTF64) {
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 'q' || inptr[2] == 'Q') &&
								(inptr[3] == 'z' || inptr[3] == 'Z') &&
								isspaceOrDot(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_beqz;
								tbndx++;
								return token = tk_beqz;
							}
							if ((inptr[1] == 'n' || inptr[1] == 'N') &&
								(inptr[2] == 'e' || inptr[2] == 'E') &&
								(inptr[3] == 'z' || inptr[3] == 'Z') &&
								isspaceOrDot(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_bnez;
								tbndx++;
								return token = tk_bnez;
							}
						}
						if ((inptr[1]=='r' || inptr[1]=='R') &&
                (inptr[2]=='a' || inptr[2]=='A') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bra;
								tbndx++;
								return token = tk_bra;
            }
            if ((inptr[1]=='r' || inptr[1]=='R') && 
                (inptr[2]=='z' || inptr[2]=='Z') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_brz;
								tbndx++;
								return token = tk_brz;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_blt;
								tbndx++;
								return token = tk_blt;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_blti;
								tbndx++;
								return token = tk_blti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bltu;
								tbndx++;
								return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bltui;
								tbndx++;
								return token = tk_bltui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='o' || inptr[2]=='O') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bltu;
								tbndx++;
								return token = tk_bltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ble;
								tbndx++;
								return token = tk_ble;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_blei;
								tbndx++;
								return token = tk_blei;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bleu;
								tbndx++;
								return token = tk_bleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bleui;
								tbndx++;
								return token = tk_bleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bleu;
								tbndx++;
								return token = tk_bleu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bge;
								tbndx++;
								return token = tk_bge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgei;
								tbndx++;
								return token = tk_bgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgeu;
								tbndx++;
								return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bgeui;
								tbndx++;
								return token = tk_bgeui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgeu;
								tbndx++;
								return token = tk_bgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgt;
								tbndx++;
								return token = tk_bgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgti;
								tbndx++;
								return token = tk_bgti;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bgtu;
								tbndx++;
								return token = tk_bgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                 isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bgtui;
								tbndx++;
								return token = tk_bgtui;
            }
            if ((inptr[1]=='h' || inptr[1]=='H') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bgtu;
								tbndx++;
								return token = tk_bgtu;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='r' || inptr[2]=='R') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bsr;
								tbndx++;
								return token = tk_bsr;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bmi;
								tbndx++;
								return token = tk_bmi;
            }
            if ((inptr[1]=='p' || inptr[1]=='P') && 
                (inptr[2]=='l' || inptr[2]=='L') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bpl;
								tbndx++;
								return token = tk_bpl;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='c' || inptr[2]=='C') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bvc;
								tbndx++;
								return token = tk_bvc;
            }
            if ((inptr[1]=='v' || inptr[1]=='V') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bvs;
								tbndx++;
								return token = tk_bvs;
            }
            if (inptr[1]=='r' && inptr[2]=='k' && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_brk;
								tbndx++;
								return token = tk_brk;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && 
                (inptr[2]=='s' || inptr[2]=='S') &&
                 isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bss;
								tbndx++;
								return token = tk_bss;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_bits;
								tbndx++;
								return token = tk_bits;
            }
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='e' || inptr[3]=='E') &&
                 isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_db;
								tbndx++;
								return token = tk_db;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='x' || inptr[3]=='X') &&
                (inptr[4]=='t' || inptr[4]=='T') &&
                 isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_bfext;
								tbndx++;
								return token = tk_bfext;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && 
                (inptr[2]=='i' || inptr[2]=='I') &&
                (inptr[3]=='n' || inptr[3]=='N') &&
                (inptr[4]=='s' || inptr[4]=='S') &&
                 isspaceOrDot(inptr[5])) {
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
                 isspaceOrDot(inptr[6])) {
                inptr += 6;
								tokenBuffer[tbndx] = tk_bfextu;
								tbndx++;
								return token = tk_bfextu;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                  isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_bit;
								tbndx++;
								return token = tk_bit;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && 
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                  isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_biti;
								tbndx++;
								return token = tk_biti;
            }
						if ((inptr[1] == 'c' || inptr[1] == 'C') &&
							(inptr[2] == 'c' || inptr[2] == 'C') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_bcc;
							tbndx++;
							return token = tk_bcc;
						}
						if ((inptr[1] == 'c' || inptr[1] == 'C') &&
							(inptr[2] == 's' || inptr[2] == 'S') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_bcs;
							tbndx++;
							return token = tk_bcs;
						}
						if ((inptr[1] == 'b' || inptr[1] == 'B') &&
							(inptr[2] == 'c' || inptr[2] == 'C') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_bbc;
							tbndx++;
							return token = tk_bbc;
						}
						if ((inptr[1] == 'b' || inptr[1] == 'B') &&
							(inptr[2] == 's' || inptr[2] == 'S') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_bbs;
							tbndx++;
							return token = tk_bbs;
						}
						if ((inptr[1] == 'y' || inptr[1] == 'Y') &&
							(inptr[2] == 't' || inptr[2] == 'T') &&
							(inptr[3] == 'n' || inptr[3] == 'N') &&
							(inptr[4] == 'd' || inptr[4] == 'D') &&
							(inptr[5] == 'x' || inptr[5] == 'X') &&
							isspaceOrDot(inptr[6])) {
							inptr += 6;
							tokenBuffer[tbndx] = tk_bytndx;
							tbndx++;
							return token = tk_bytndx;
						}
						if ((inptr[1] == 'f' || inptr[1] == 'F') &&
							isspaceOrDot(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_bcc;
							tbndx++;
							return token = tk_bcc;
						}
						if ((inptr[1] == 't' || inptr[1] == 'T') &&
							isspaceOrDot(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_bcs;
							tbndx++;
							return token = tk_bcs;
						}
						break;

      // call cas chk cmp cmpu code cli com cmovenz cmpi csrrc csrrs csrrw
      case 'c': case 'C':
				if ((inptr[1]=='a' || inptr[1]=='A')
					&& (inptr[2]=='c' || inptr[2]=='C')
					&& (inptr[3]=='h' || inptr[3]=='H')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& isspaceOrDot(inptr[5])) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_cache;
						tbndx++;
						return (token = tk_cache);
				}
                 if ((inptr[1]=='a' || inptr[1]=='A') &&
                     (inptr[2]=='l' || inptr[2]=='L') &&
                     (inptr[3]=='l' || inptr[3]=='L') &&
                     isspaceOrDot(inptr[4])) {
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
                     isspaceOrDot(inptr[7])) {
                     inptr += 7;
										 tokenBuffer[tbndx] = tk_calltgt;
										 tbndx++;
										 return token = tk_calltgt;
                 }
							if ((inptr[1]=='m' || inptr[1]=='M') &&
								(inptr[2]=='p' || inptr[2]=='P') &&
								(inptr[3]=='i' || inptr[3]=='I') &&
								isspaceOrDot(inptr[4])) {
								inptr += 4;
								tokenBuffer[tbndx] = tk_cmpi;
								tbndx++;
								return token = tk_cmpi;
							}
             if ((inptr[1]=='m' || inptr[1]=='M') &&
                 (inptr[2]=='p' || inptr[2]=='P') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_cmp;
								 tbndx++;
								 return token = tk_cmp;
             }
						 if ((inptr[1] == 'm' || inptr[1] == 'M') &&
							 (inptr[2] == 'p' || inptr[2] == 'P') &&
							 (inptr[3] == 'u' || inptr[3] == 'U') &&
							 isspaceOrDot(inptr[4])) {
							 inptr += 4;
							 tokenBuffer[tbndx] = tk_cmpu;
							 tbndx++;
							 return token = tk_cmpu;
						 }
						 if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_code;
								 tbndx++;
								 return token = tk_code;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_cli;
								 tbndx++;
								 return token = tk_cli;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_com;
								 tbndx++;
								 return token = tk_com;
             }
             if ((inptr[1]=='p' || inptr[1]=='P') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='d' || inptr[4]=='D') &&
                 isspaceOrDot(inptr[5])) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_cpuid;
								 tbndx++;
								 return token = tk_cpuid;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_chk;
								 tbndx++;
								 return token = tk_chk;
             }
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='k' || inptr[2]=='K') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_chki;
								 tbndx++;
								 return token = tk_chki;
             }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='c' || inptr[4]=='C') &&
                   isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrc;
										 tbndx++;
										 return token = tk_csrrc;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='d' || inptr[4]=='D') &&
                   isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrd;
										 tbndx++;
										 return token = tk_csrrd;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='s' || inptr[4]=='S') &&
                   isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrs;
										 tbndx++;
										 return token = tk_csrrs;
               }
               if ((inptr[1]=='s' || inptr[1]=='S') &&
                   (inptr[2]=='r' || inptr[2]=='R') &&
                   (inptr[3]=='r' || inptr[3]=='R') &&
                   (inptr[4]=='w' || inptr[4]=='W') &&
                   isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_csrrw;
										 tbndx++;
										 return token = tk_csrrw;
                   }
							 if ((inptr[1] == 's' || inptr[1] == 'S') &&
								 (inptr[2] == 'r' || inptr[2] == 'R') &&
								 isspaceOrDot(inptr[3])) {
								 inptr += 3;
								 tokenBuffer[tbndx] = tk_csr;
								 tbndx++;
								 return token = tk_csr;
							 }
							 if ((inptr[1] == 'm' || inptr[1] == 'M') &&
								 (inptr[2] == 'o' || inptr[2] == 'O') &&
								 (inptr[3] == 'v' || inptr[3] == 'V') &&
								 (inptr[4] == 'e' || inptr[4] == 'E') &&
								 (inptr[5] == 'n' || inptr[5] == 'N') &&
								 (inptr[6] == 'z' || inptr[6] == 'Z') &&
								 isspaceOrDot(inptr[7])) {
								 inptr += 7;
								 tokenBuffer[tbndx] = tk_cmovenz;
								 tbndx++;
								 return token = tk_cmovenz;
							 }
							 break;

        // db dbnz dc dh dw data dep div divs divu divi divui ds:
        case 'd': case 'D':
          if ((inptr[1]=='b' || inptr[1]=='B') && isspaceOrDot(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_db;
							tbndx++;
							return token = tk_db;
          }
          if ((inptr[1]=='c' || inptr[1]=='C') && isspaceOrDot(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_dc;
							tbndx++;
							return token = tk_dc;
          }
          if ((inptr[1]=='h' || inptr[1]=='H') && isspaceOrDot(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_dh;
							tbndx++;
							return token = tk_dh;
          }
					if (gCpu=='A') {
						if ((inptr[1]=='d' || inptr[1]=='D') && isspaceOrDot(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_dd;
							tbndx++;
							return token = tk_dd;
						}
						if ((inptr[1]=='o' || inptr[1]=='O') && isspaceOrDot(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_do;
							tbndx++;
							return token = tk_do;
						}
						if ((inptr[1]=='t' || inptr[1]=='T') && isspaceOrDot(inptr[2])) {
							inptr += 2;
							tokenBuffer[tbndx] = tk_dt;
							tbndx++;
							return token = tk_dt;
						}
					}
            if ((inptr[1]=='w' || inptr[1]=='W') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_dw;
								tbndx++;
								return token = tk_dw;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') && (inptr[2]=='v' || inptr[2]=='V') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_div;
								tbndx++;
								return token = tk_div;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_divi;
								tbndx++;
								return token = tk_divi;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_divu;
								tbndx++;
								return token = tk_divu;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_divui;
								tbndx++;
								return token = tk_divui;
            }
            if ((inptr[1]=='i' || inptr[1]=='I') &&
                (inptr[2]=='v' || inptr[2]=='V') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_div;
								tbndx++;
								return token = tk_div;
            }
            if ((inptr[1]=='a' || inptr[1]=='A') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='a' || inptr[3]=='A') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_data;
								tbndx++;
								return token = tk_data;
            }
						// Not sure why dcb is defined as a fill here.
						if (gCpu != NVIO && gCpu != RTF64) {
							if ((inptr[1] == 'c' || inptr[1] == 'C') && (inptr[2] == 'b' || inptr[2] == 'B') && (isspaceOrDot(inptr[3]) || inptr[3] == '.')) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_fill;
								tbndx++;
								return token = tk_fill;
							}
						}
             if ((inptr[1]=='h' || inptr[1]=='H') &&
                 (inptr[2]=='_' || inptr[2]=='_') &&
                 (inptr[3]=='h' || inptr[3]=='H') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (inptr[5]=='b' || inptr[4]=='B') &&
                 (inptr[6]=='l' || inptr[4]=='L') &&
                 isspaceOrDot(inptr[7])) {
                 inptr += 7;
								 tokenBuffer[tbndx] = tk_dh_htbl;
								 tbndx++;
								 return token = tk_dh_htbl;
             }
							 if ((inptr[1] == 'c') || inptr[1]=='C') {
								 if ((inptr[2] == 'b' || inptr[2] == 'B') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcb;
									 tbndx++;
									 return (token = tk_dcb);
								 }
								 if ((inptr[2] == 'd' || inptr[2] == 'D') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcd;
									 tbndx++;
									 return (token = tk_dcd);
								 }
								 if ((inptr[2] == 'o' || inptr[2] == 'O') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dco;
									 tbndx++;
									 return (token = tk_dco);
								 }
								 if ((inptr[2] == 'p' || inptr[2] == 'P') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcp;
									 tbndx++;
									 return (token = tk_dcp);
								 }
								 if ((inptr[2] == 't' || inptr[2] == 'T') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dct;
									 tbndx++;
									 return (token = tk_dct);
								 }
								 if ((inptr[2] == 'w' || inptr[2] == 'W') && isspaceOrDot(inptr[3])) {
									 inptr += 3;
									 tokenBuffer[tbndx] = tk_dcw;
									 tbndx++;
									 return (token = tk_dcw);
								 }
							}
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 'c' || inptr[2] == 'C') &&
								(inptr[3] == 't' || inptr[3] == 'T') &&
								(inptr[4] == 'o' || inptr[3] == 'O') &&
								isspaceOrDot(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_decto;
								tbndx++;
								return token = tk_decto;
							}
							if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 'p' || inptr[2] == 'P') && isspaceOrDot(inptr[3])) {
								inptr += 3;
								tokenBuffer[tbndx] = tk_dep;
								tbndx++;
								return token = tk_dep;
							}
						 break;

        // end eor eori endif endpublic ext extern extu equ eret es
        case 'e': case 'E':
             if ((inptr[1]=='q' || inptr[1]=='Q') &&
                 (inptr[2]=='u' || inptr[2]=='U') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_equ;
								 tbndx++;
								 return token = tk_equ;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_eori;
								 tbndx++;
								 return token = tk_eori;
             }
             if ((inptr[1]=='o' || inptr[1]=='O') &&
                 (inptr[2]=='r' || inptr[2]=='R') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_eor;
								 tbndx++;
								 return token = tk_eor;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='d' || inptr[2]=='D') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_end;
								 tbndx++;
								 return token = tk_end;
             }
             if ((inptr[1]=='n' || inptr[1]=='O') &&
                 (inptr[2]=='d' || inptr[2]=='R') &&
                 (inptr[3]=='i' || inptr[3]=='I') &&
                 (inptr[4]=='f' || inptr[4]=='F') &&
                 isspaceOrDot(inptr[5])) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_endif;
								 tbndx++;
								 return token = tk_endif;
             }
             if ((inptr[1]=='l' || inptr[1]=='L') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 isspaceOrDot(inptr[4])) {
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
                 isspaceOrDot(inptr[9])) {
                 inptr += 9;
								 tokenBuffer[tbndx] = tk_endpublic;
								 tbndx++;
								 return token = tk_endpublic;
             }
						 if ((inptr[1] == 'n' || inptr[1] == 'N') &&
							 (inptr[2] == 'd' || inptr[2] == 'D') &&
							 (inptr[3] == 'p' || inptr[3] == 'P') &&
							 (inptr[4] == 'r' || inptr[4] == 'R') &&
							 (inptr[5] == 'o' || inptr[5] == 'O') &&
							 (inptr[6] == 'c' || inptr[6] == 'C') &&
							 isspaceOrDot(inptr[7])) {
							 inptr += 7;
							 tokenBuffer[tbndx] = tk_endproc;
							 tbndx++;
							 return token = tk_endproc;
						 }
						 if ((inptr[1]=='x' || inptr[1]=='X') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='e' || inptr[3]=='E') &&
                 (inptr[4]=='r' || inptr[4]=='R') &&
                 (inptr[5]=='n' || inptr[5]=='N') &&
                 isspaceOrDot(inptr[6])) {
                 inptr += 6;
								 tokenBuffer[tbndx] = tk_extern;
								 tbndx++;
								 return token = tk_extern;
             }
				 if ((inptr[1] == 'c' || inptr[1] == 'C') &&
					 (inptr[2] == 'a' || inptr[2] == 'A') &&
					 (inptr[3] == 'l' || inptr[3] == 'L') &&
					 (inptr[4] == 'l' || inptr[4] == 'L') &&
					 isspaceOrDot(inptr[5])) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_ecall;
					 tbndx++;
					 return token = tk_ecall;
				 }
				 if ((inptr[1]=='r' || inptr[1]=='R') &&
					 (inptr[2]=='e' || inptr[2]=='E') &&
					 (inptr[3]=='t' || inptr[3]=='T') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_eret;
					 tbndx++;
					 return token = tk_eret;
				 }
            if ((inptr[1]=='n' || inptr[1]=='N') &&
              (inptr[2]=='d' || inptr[2]=='D') &&
              (inptr[3]=='m' || inptr[3]=='M') &&
              isspaceOrDot(inptr[4])) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_endm;
							tbndx++;
							return token = tk_endm;
            }
						if ((inptr[1] == 'x' || inptr[1] == 'X') &&
							(inptr[2] == 't' || inptr[2] == 'T') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_ext;
							tbndx++;
							return token = tk_ext;
						}
						if ((inptr[1] == 'x' || inptr[1] == 'X') &&
							(inptr[2] == 't' || inptr[2] == 'T') &&
							(inptr[3] == 'u' || inptr[3] == 'U') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_extu;
							tbndx++;
							return token = tk_extu;
						}
						break;

        // fill fabs fadd fb__
		// fcmp fcx fdiv fmul fnabs fneg fsub fix2flt flt2fix ftst ftoi fxdiv fxmul
        case 'f': case 'F':
          if ((inptr[1]=='i' || inptr[1]=='I') &&
              (inptr[2]=='l' || inptr[2]=='L') &&
              (inptr[3]=='l' || inptr[3]=='L') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fill;
							tbndx++;
							return token = tk_fill;
          }
          if ((inptr[1]=='a' || inptr[1]=='A') &&
              (inptr[2]=='d' || inptr[2]=='D') &&
              (inptr[3]=='d' || inptr[3]=='D') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fadd;
							tbndx++;
							return token = tk_fadd;
          }
          if ((inptr[1]=='s' || inptr[1]=='S') &&
              (inptr[2]=='u' || inptr[2]=='U') &&
              (inptr[3]=='b' || inptr[3]=='B') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fsub;
							tbndx++;
							return token = tk_fsub;
          }
          if ((inptr[1]=='c' || inptr[1]=='C') &&
              (inptr[2]=='m' || inptr[2]=='M') &&
              (inptr[3]=='p' || inptr[3]=='P') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fcmp;
							tbndx++;
							return token = tk_fcmp;
          }
          if ((inptr[1]=='m' || inptr[1]=='M') &&
              (inptr[2]=='u' || inptr[2]=='U') &&
              (inptr[3]=='l' || inptr[3]=='L') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fmul;
							tbndx++;
							return (token = tk_fmul);
          }
          if ((inptr[1]=='m' || inptr[1]=='M') &&
              (inptr[2]=='o' || inptr[2]=='O') &&
              (inptr[3]=='v' || inptr[3]=='V') &&
              (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
              inptr += 4;
							tokenBuffer[tbndx] = tk_fmov;
							tbndx++;
							return token = tk_fmov;
          }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='i' || inptr[2]=='I') &&
                 (inptr[3]=='v' || inptr[3]=='V') &&
                 (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fdiv;
								 tbndx++;
								 return token = tk_fdiv;
             }
						 if ((inptr[1] == 's' || inptr[1] == 'S') &&
							 (inptr[2] == 'q' || inptr[2] == 'Q') &&
							 (inptr[3] == 'r' || inptr[3] == 'R') &&
							 (inptr[4] == 't' || inptr[3] == 'T') &&
							 (isspaceOrDot(inptr[5]) || inptr[5] == '.')) {
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
                 (isspaceOrDot(inptr[7]) || inptr[7]=='.')) {
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
                 (isspaceOrDot(inptr[7]) || inptr[7]=='.')) {
                 inptr += 7;
								 tokenBuffer[tbndx] = tk_flt2fix;
								 tbndx++;
								 return token = tk_flt2fix;
             }
             if ((inptr[1]=='a' || inptr[1]=='A') &&
                 (inptr[2]=='b' || inptr[2]=='B') &&
                 (inptr[3]=='s' || inptr[3]=='S') &&
                 (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fabs;
								 tbndx++;
								 return token = tk_fabs;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='g' || inptr[3]=='G') &&
                 (isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_fneg;
								 tbndx++;
								 return token = tk_fneg;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='a' || inptr[2]=='A') &&
                 (inptr[3]=='b' || inptr[3]=='B') &&
                 (inptr[4]=='s' || inptr[4]=='S') &&
                 (isspaceOrDot(inptr[5]) || inptr[5]=='.')) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_fnabs;
								 tbndx++;
								 return token = tk_fnabs;
             }
             if ((inptr[1]=='c' || inptr[1]=='C') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fcx;
								 tbndx++;
								 return token = tk_fcx;
             }
             if ((inptr[1]=='d' || inptr[1]=='D') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fdx;
								 tbndx++;
								 return token = tk_fdx;
             }
             if ((inptr[1]=='e' || inptr[1]=='E') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_fex;
								 tbndx++;
								 return token = tk_fex;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='m' || inptr[2]=='M') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_frm;
								 tbndx++;
								 return token = tk_frm;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='x' || inptr[2]=='X') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_ftx;
								 tbndx++;
								 return token = tk_ftx;
             }
             if ((inptr[1]=='s' || inptr[1]=='S') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 (inptr[3]=='a' || inptr[3]=='A') &&
                 (inptr[4]=='t' || inptr[4]=='T') &&
                 (isspaceOrDot(inptr[5]))) {
                 inptr += 5;
								 tokenBuffer[tbndx] = tk_fstat;
								 tbndx++;
								 return token = tk_fstat;
             }
             if ((inptr[1]=='t' || inptr[1]=='T') &&
                 (inptr[2]=='s' || inptr[2]=='S') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
                 (isspaceOrDot(inptr[4])||inptr[4]=='.')) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_ftst;
								 tbndx++;
								 return token = tk_ftst;
             }
				 if ((inptr[1]=='t' || inptr[1]=='T') &&
					 (inptr[2]=='o' || inptr[2]=='O') &&
					 (inptr[3]=='i' || inptr[3]=='I') &&
					 (isspaceOrDot(inptr[4])||inptr[4]=='.')) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_ftoi;
					 tbndx++;
					 return token = tk_ftoi;
				 }
			 if ((inptr[1] == 'i' || inptr[1] == 'I') &&
				 (inptr[2] == 'l' || inptr[2] == 'L') &&
				 (inptr[3] == 'e' || inptr[3] == 'E') &&
				 (isspaceOrDot(inptr[4]) || inptr[4] == ':')) {
				 inptr += 4;
				 tokenBuffer[tbndx] = tk_file;
				 tbndx++;
				 return (token = tk_file);
			 }
				 if ((inptr[1] == 's' || inptr[1] == 'S') &&
					 (inptr[2] == 'l' || inptr[2] == 'L') &&
					 (inptr[3] == 't' || inptr[3] == 'T') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fslt;
					 tbndx++;
					 return token = tk_fslt;
				 }
				 if ((inptr[1] == 's' || inptr[1] == 'S') &&
					 (inptr[2] == 'l' || inptr[2] == 'L') &&
					 (inptr[3] == 'e' || inptr[3] == 'E') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fsle;
					 tbndx++;
					 return token = tk_fsle;
				 }
				 if ((inptr[1] == 's' || inptr[1] == 'S') &&
					 (inptr[2] == 'e' || inptr[2] == 'E') &&
					 (inptr[3] == 'q' || inptr[3] == 'Q') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fseq;
					 tbndx++;
					 return token = tk_fseq;
				 }
				 if ((inptr[1] == 'b' || inptr[1] == 'B') &&
					 (inptr[2] == 'e' || inptr[2] == 'E') &&
					 (inptr[3] == 'q' || inptr[3] == 'Q') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbeq;
					 tbndx++;
					 return token = tk_fbeq;
				 }
				 if ((inptr[1] == 'b' || inptr[1] == 'B') &&
					 (inptr[2] == 'n' || inptr[2] == 'N') &&
					 (inptr[3] == 'e' || inptr[3] == 'E') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbne;
					 tbndx++;
					 return token = tk_fbne;
				 }
				 if ((inptr[1] == 'b' || inptr[1] == 'B') &&
					 (inptr[2] == 'g' || inptr[2] == 'G') &&
					 (inptr[3] == 'e' || inptr[3] == 'E') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fbge;
					 tbndx++;
					 return token = tk_fbge;
				 }
				 if ((inptr[1] == 'b' || inptr[1] == 'B') &&
					 (inptr[2] == 'l' || inptr[2] == 'L') &&
					 (inptr[3] == 't' || inptr[3] == 'T') &&
					 isspaceOrDot(inptr[4])) {
					 inptr += 4;
					 tokenBuffer[tbndx] = tk_fblt;
					 tbndx++;
					 return token = tk_fblt;
				 }
				 if ((inptr[1] == 'x' || inptr[1] == 'X') &&
					 (inptr[2] == 'd' || inptr[2] == 'D') &&
					 (inptr[3] == 'i' || inptr[3] == 'I') &&
					 (inptr[4] == 'v' || inptr[4] == 'V') &&
					 (isspaceOrDot(inptr[5]) || inptr[5] == '.')) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_fxdiv;
					 tbndx++;
					 return token = tk_fxdiv;
				 }
				 if ((inptr[1] == 'x' || inptr[1] == 'X') &&
					 (inptr[2] == 'm' || inptr[2] == 'M') &&
					 (inptr[3] == 'u' || inptr[3] == 'U') &&
					 (inptr[4] == 'l' || inptr[4] == 'L') &&
					 (isspaceOrDot(inptr[5]) || inptr[5] == '.')) {
					 inptr += 5;
					 tokenBuffer[tbndx] = tk_fxmul;
					 tbndx++;
					 return token = tk_fxmul;
				 }
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
				if ((inptr[1] == 'l' || inptr[1] == 'L') &&
					(inptr[2] == 'd' || inptr[2] == 'D') &&
					(inptr[3] == 'o' || inptr[3] == 'O') &&
					(isspaceOrDot(inptr[4]) || inptr[4] == '.')) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_fldo;
					tbndx++;
					return token = tk_fldo;
				}
				if ((inptr[1] == 's' || inptr[1] == 'S') &&
					(inptr[2] == 't' || inptr[2] == 'T') &&
					(inptr[3] == 'o' || inptr[3] == 'O') &&
					(isspaceOrDot(inptr[4]))) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_fsto;
					tbndx++;
					return token = tk_fsto;
				}
				break;

        // gran
        case 'g': case 'G':
					if ((inptr[1] == 'c' || inptr[1] == 'C') &&
						(inptr[2] == 's' || inptr[2] == 'S') &&
						(inptr[3] == 'u' || inptr[3] == 'U') &&
						(inptr[4] == 'b' || inptr[4] == 'B') &&
						isspaceOrDot(inptr[5])) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_gcsub;
						tbndx++;
						return token = tk_gcsub;
					}
					if ((inptr[1] == 'c' || inptr[1] == 'C') &&
						(inptr[2] == 'c' || inptr[2] == 'C') &&
						(inptr[3] == 'l' || inptr[3] == 'L') &&
						(inptr[4] == 'r' || inptr[4] == 'R') &&
						isspaceOrDot(inptr[5])) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_gcclr;
						tbndx++;
						return token = tk_gcclr;
					}
					if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='a' || inptr[2]=='A') &&
                 (inptr[3]=='n' || inptr[3]=='N') &&
                 isspaceOrDot(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_gran;
								 tbndx++;
								 return token = tk_gran;
             }
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 't' || inptr[2] == 'T') &&
								(inptr[3] == 'r' || inptr[3] == 'R') &&
								(inptr[4] == 'd' || inptr[4] == 'D') &&
								(inptr[5] == 'y' || inptr[5] == 'Y') &&
								isspaceOrDot(inptr[6])) {
								inptr += 6;
								tokenBuffer[tbndx] = tk_getrdy;
								tbndx++;
								return token = tk_getrdy;
							}
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 't' || inptr[2] == 'T') &&
								(inptr[3] == 't' || inptr[3] == 'T') &&
								(inptr[4] == 'o' || inptr[4] == 'O') &&
								isspaceOrDot(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_getto;
								tbndx++;
								return token = tk_getto;
							}
							if ((inptr[1] == 'e' || inptr[1] == 'E') &&
								(inptr[2] == 't' || inptr[2] == 'T') &&
								(inptr[3] == 'z' || inptr[3] == 'Z') &&
								(inptr[4] == 'l' || inptr[4] == 'L') &&
								isspaceOrDot(inptr[5])) {
								inptr += 5;
								tokenBuffer[tbndx] = tk_getzl;
								tbndx++;
								return token = tk_getzl;
							}
             break;

		// hs hint
    case 'h': case 'H':
			if ((inptr[1]=='I' || inptr[1]=='i') &&
				(inptr[2]=='N' || inptr[2]=='n') &&
				(inptr[3]=='T' || inptr[3]=='t') &&
				isspaceOrDot(inptr[4])) {
				inptr += 4;
				tokenBuffer[tbndx] = tk_hint;
				tbndx++;
				return (token = tk_hint);
			}
      break;
             
      // ibne if ifdef ifndef ios inc int iret ipush ipop isnull itof
      case 'i': case 'I':
				if ((inptr[1] == 's' || inptr[1] == 'S') &&
					(inptr[2] == 'p' || inptr[2] == 'P') &&
					(inptr[3] == 't' || inptr[3] == 'T') &&
					(inptr[4] == 'r' || inptr[4] == 'R') &&
					isspaceOrDot(inptr[5])) {
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
					isspaceOrDot(inptr[6])) {
					inptr += 6;
					tokenBuffer[tbndx] = tk_isnull;
					tbndx++;
					return token = tk_isnull;
				}
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='c' || inptr[2]=='C') &&
                 (isspaceOrDot(inptr[3]))) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_inc;
								 tbndx++;
								 return token = tk_inc;
             }
             if ((inptr[1]=='n' || inptr[1]=='N') &&
                 (inptr[2]=='t' || inptr[2]=='T') &&
                 isspaceOrDot(inptr[3])) {
                 inptr += 3;
								 tokenBuffer[tbndx] = tk_int;
								 tbndx++;
								 return token = tk_int;
             }
             if ((inptr[1]=='r' || inptr[1]=='R') &&
                 (inptr[2]=='e' || inptr[2]=='E') &&
                 (inptr[3]=='t' || inptr[3]=='T') &&
								isspaceOrDot(inptr[4])) {
                 inptr += 4;
								 tokenBuffer[tbndx] = tk_iret;
								 tbndx++;
								 return token = tk_iret;
             }
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='o' || inptr[2]=='O') &&
				(inptr[3]=='f' || inptr[3]=='F') &&
				(isspaceOrDot(inptr[4]) || inptr[4]=='.')) {
				inptr += 4;
				tokenBuffer[tbndx] = tk_itof;
				tbndx++;
				return (token = tk_itof);
			}
      if (inptr[1]=='f' || inptr[1]=='F') {
				if ((inptr[2]=='d' || inptr[2]=='D')
					&& (inptr[3]=='e' || inptr[3]=='E')
					&& (inptr[4]=='f' || inptr[3]=='F')
					&& (isspaceOrDot(inptr[5]) || inptr[5]=='.')) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_ifdef;
						tbndx++;
						return token = tk_ifdef;
				}
				if ((inptr[2]=='n' || inptr[2]=='N')
					&& (inptr[3]=='d' || inptr[3]=='D')
					&& (inptr[4]=='e' || inptr[4]=='E')
					&& (inptr[5]=='f' || inptr[5]=='F')
					&& (isspaceOrDot(inptr[6]) || inptr[6]=='.')) {
						inptr += 6;
						tokenBuffer[tbndx] = tk_ifndef;
						tbndx++;
						return token = tk_ifndef;
				}
				if (isspaceOrDot(inptr[2]) || inptr[2]=='.') {
					inptr += 2;
					tokenBuffer[tbndx] = tk_if;
					tbndx++;
					return token = tk_if;
				}
      }
			 break;

      // jal jmp jsf jsr
      case 'j': case 'J':
				if ((inptr[1]=='s' || inptr[1]=='S') &&
					(inptr[2]=='r' || inptr[2]=='R') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_jsr;
					tbndx++;
					return token = tk_jsr;
				}
				if ((inptr[1] == 'a' || inptr[1] == 'A') &&
					(inptr[2] == 'l' || inptr[2] == 'L') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_jal;
					tbndx++;
					return token = tk_jal;
				}
				if ((inptr[1]=='s' || inptr[1]=='S') &&
					(inptr[2]=='f' || inptr[2]=='F') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_jsf;
					tbndx++;
					return token = tk_jsf;
				}
				if ((inptr[1]=='m' || inptr[1]=='M') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_jmp;
					tbndx++;
					return token = tk_jmp;
				}
				break;

      // lb lbu lc lcu lf lh lhu lw ld ldi ldis lea lsr lsri lwar lfd lvb lws lvh lvw ltcb link
      case 'l':
      case 'L':
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldb;
					tbndx++;
					return token = tk_ldb;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='b' || inptr[2]=='B') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldbu;
					tbndx++;
					return token = tk_ldbu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldw;
					tbndx++;
					return token = tk_ldw;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldwu;
					tbndx++;
					return token = tk_ldwu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldt;
					tbndx++;
					return token = tk_ldt;
				}  
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldo;
					tbndx++;
					return token = tk_ldo;
				}
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					(inptr[3] == 'r' || inptr[3] == 'R') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldor;
					tbndx++;
					return token = tk_ldor;
				}
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'o' || inptr[2] == 'O') &&
					(inptr[3] == 'u' || inptr[3] == 'U') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldou;
					tbndx++;
					return token = tk_ldou;
				}
				if ((inptr[1] == 'd' || inptr[1] == 'D') &&
					(inptr[2] == 'd' || inptr[2] == 'D') &&
					(inptr[3] == 'r' || inptr[3] == 'R') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_lddr;
					tbndx++;
					return token = tk_lddr;
				}
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='t' || inptr[2]=='T') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldtu;
					tbndx++;
					return token = tk_ldtu;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_ldp;
					tbndx++;
					return token = tk_ldp;
				}  
				if ((inptr[1]=='d' || inptr[1]=='D') &&
					(inptr[2]=='p' || inptr[2]=='P') &&
					(inptr[3]=='u' || inptr[3]=='U') &&
					isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_ldpu;
					tbndx++;
					return token = tk_ldpu;
				}  
				if ((inptr[1] == 'r' || inptr[1] == 'R') && isspaceOrDot(inptr[2])) {
					inptr += 2;
					tokenBuffer[tbndx] = tk_lr;
					tbndx++;
					return token = tk_lr;
				}
            if ((inptr[1]=='d' || inptr[1]=='D') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_ld;
								tbndx++;
								return token = tk_ld;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lb;
								tbndx++;
								return token = tk_lb;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lbu;
								tbndx++;
								return token = tk_lbu;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspaceOrDot(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lf;
								tbndx++;
								return token = tk_lf;
            }  
            if ((inptr[1]=='w' || inptr[1]=='W') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lw;
								tbndx++;
								return token = tk_lw;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lh;
								tbndx++;
								return token = tk_lh;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lhu;
								tbndx++;
								return token = tk_lhu;
            }
            if ((inptr[1]=='c' || inptr[1]=='C') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_lc;
								tbndx++;
								return token = tk_lc;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && (inptr[2]=='u' || inptr[2]=='U') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lcu;
								tbndx++;
								return token = tk_lcu;
            }
            if ((inptr[1]=='d' || inptr[1]=='D') && (inptr[2]=='i' || inptr[2]=='I') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_ldi;
								tbndx++;
								return token = tk_ldi;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='a' || inptr[2]=='A') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lea;
								tbndx++;
								return token = tk_lea;
            }
            if ((inptr[1]=='m' || inptr[1]=='M') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lmr;
								tbndx++;
								return token = tk_lmr;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_lsri;
								tbndx++;
								return token = tk_lsri;
            }
            if ((inptr[1]=='s' || inptr[1]=='S') && (inptr[2]=='r' || inptr[2]=='R') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lsr;
								tbndx++;
								return token = tk_lsr;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_lfd;
								tbndx++;
								return token = tk_lfd;
            }
						if ((inptr[1] == 'i' || inptr[1] == 'I') &&
							(inptr[2] == 'n' || inptr[2] == 'N') &&
							(inptr[3] == 'k' || inptr[3] == 'K') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_link;
							tbndx++;
							return token = tk_link;
						}
						if ((inptr[1] == 'd' || inptr[1] == 'D') && (inptr[2] == 'm' || inptr[2] == 'M') && isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_ldm;
							tbndx++;
							return (token = tk_ldm);
						}
						if ((inptr[1]=='l' || inptr[1]=='L') &&
						(inptr[2]=='a' || inptr[2]=='A') &&
						isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_lla;
						tbndx++;
						return token = tk_lla;
					}  
					if ((inptr[1]=='l' || inptr[1]=='L') &&
						(inptr[2]=='a' || inptr[2]=='A') &&
						(inptr[3]=='x' || inptr[3]=='X') &&
						isspaceOrDot(inptr[4])) {
						inptr += 4;
						tokenBuffer[tbndx] = tk_llax;
						tbndx++;
						return token = tk_llax;
					}  
          break;

        // max min mod modu modi modui mov mul muli mulu mului mtspr mfspr mtfp mffp message memdb memsb
        case 'm': case 'M':
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
						if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='v' || inptr[2]=='V') && isspaceOrDot(inptr[3])) {
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
						if ((inptr[1] == 'u' || inptr[1] == 'U') &&
							(inptr[2] == 'l' || inptr[2] == 'L') &&
							(inptr[3] == 'f' || inptr[3] == 'F') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_mulf;
							tbndx++;
							return (token = tk_mulf);
						}
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_mulu;
								tbndx++;
								return token = tk_mulu;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_mului;
								tbndx++;
								return token = tk_mului;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='l' || inptr[2]=='L') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_muli;
								tbndx++;
								return token = tk_muli;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_mod;
								tbndx++;
								return token = tk_mod;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_modu;
								tbndx++;
								return token = tk_modu;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='i' || inptr[3]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_modi;
								tbndx++;
								return token = tk_modi;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='d' || inptr[2]=='D') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_modui;
								tbndx++;
								return token = tk_modui;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='s' || inptr[3]=='S') &&
                (inptr[4]=='a' || inptr[4]=='A') &&
                (inptr[5]=='g' || inptr[5]=='G') &&
                (inptr[6]=='e' || inptr[6]=='E') &&
                isspaceOrDot(inptr[7])) {
                inptr += 7;
								tokenBuffer[tbndx] = tk_message;
								tbndx++;
								return token = tk_message;
            }
						if ((inptr[1]=='e' || inptr[1]=='E') &&
							(inptr[2]=='m' || inptr[2]=='M') &&
							(inptr[3]=='d' || inptr[3]=='D') &&
							(inptr[4]=='b' || inptr[4]=='B') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_memdb;
							tbndx++;
							return token = tk_memdb;
						}
						if ((inptr[1]=='e' || inptr[1]=='E') &&
							(inptr[2]=='m' || inptr[2]=='M') &&
							(inptr[3]=='s' || inptr[3]=='S') &&
							(inptr[4]=='b' || inptr[4]=='B') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_memsb;
							tbndx++;
							return token = tk_memsb;
						}
						if ((inptr[1]=='a' || inptr[1]=='A') &&
							(inptr[2]=='r' || inptr[2]=='R') &&
							(inptr[3]=='k' || inptr[3]=='K') &&
							(inptr[4]=='1' || inptr[4]=='1') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_mark1;
							tbndx++;
							return token = tk_mark1;
						}
						if ((inptr[1]=='a' || inptr[1]=='A') &&
							(inptr[2]=='r' || inptr[2]=='R') &&
							(inptr[3]=='k' || inptr[3]=='K') &&
							(inptr[4]=='2' || inptr[4]=='2') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_mark2;
							tbndx++;
							return token = tk_mark2;
						}
            if ((inptr[1]=='a' || inptr[1]=='A') &&
                (inptr[2]=='c' || inptr[2]=='C') &&
                (inptr[3]=='r' || inptr[3]=='R') &&
                (inptr[4]=='o' || inptr[4]=='O') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_macro;
								tbndx++;
								return (token = tk_macro);
            }
						if ((inptr[1] == 'v' || inptr[1] == 'V') &&
							(inptr[2] == 's' || inptr[2] == 'S') &&
							(inptr[3] == 'e' || inptr[3] == 'E') &&
							(inptr[4] == 'g' || inptr[4] == 'G') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_mvseg;
							tbndx++;
							return token = tk_mvseg;
						}
						if ((inptr[1] == 'v' || inptr[1] == 'V') &&
							(inptr[2] == 'm' || inptr[2] == 'M') &&
							(inptr[3] == 'a' || inptr[3] == 'A') &&
							(inptr[4] == 'p' || inptr[4] == 'P') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_mvmap;
							tbndx++;
							return token = tk_mvmap;
						}
						if ((inptr[1] == 'v' || inptr[1] == 'V') &&
							(inptr[2] == 'c' || inptr[2] == 'C') &&
							(inptr[3] == 'i' || inptr[3] == 'I') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_mvci;
							tbndx++;
							return token = tk_mvci;
						}
						break;

        // not neg nop
        case 'n': case 'N':
          if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_not;
							tbndx++;
							return token = tk_not;
          }
          if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='g' || inptr[2]=='G') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_neg;
							tbndx++;
							return token = tk_neg;
          }
          if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='p' || inptr[2]=='P') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_nop;
							tbndx++;
							return token = tk_nop;
          }
          break;

        // or orcm ori org
        case 'o': case 'O':
					if ((inptr[1] == 'r' || inptr[1] == 'R') &&
						(inptr[2] == 'c' || inptr[2] == 'C') && 
						(inptr[3] == 'm' || inptr[3] == 'M') &&
						isspaceOrDot(inptr[4])) {
						inptr += 5;
						tokenBuffer[tbndx] = tk_orcm;
						tbndx++;
						return token = tk_orcm;
					}
					if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='i' || inptr[2]=='I') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_ori;
							tbndx++;
							return token = tk_ori;
          }
          if ((inptr[1]=='r' || inptr[1]=='R') && isspaceOrDot(inptr[2])) {
              inptr += 2;
							tokenBuffer[tbndx] = tk_or;
							tbndx++;
							return token = tk_or;
          }
          if ((inptr[1]=='r' || inptr[1]=='R') && (inptr[2]=='g' || inptr[2]=='G') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_org;
							tbndx++;
							return token = tk_org;
          }
          break;

        // peekq perm pushq popq ptrdif public
        case 'p': case 'P':
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='s' || inptr[2]=='S') &&
                (inptr[3]=='h' || inptr[3]=='H') &&
                isspaceOrDot(inptr[4]) || inptr[4]=='.') {
                inptr += 4;
								tokenBuffer[tbndx] = tk_push;
								tbndx++;
								return token = tk_push;
            }
            if ((inptr[1]=='o' || inptr[1]=='O') &&
                (inptr[2]=='p' || inptr[2]=='P') &&
                isspaceOrDot(inptr[3]) || inptr[3]=='.') {
                inptr += 3;
								tokenBuffer[tbndx] = tk_pop;
								tbndx++;
								return token = tk_pop;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') &&
                (inptr[2]=='b' || inptr[2]=='B') &&
                (inptr[3]=='l' || inptr[3]=='L') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                (inptr[5]=='c' || inptr[5]=='C') &&
                isspaceOrDot(inptr[6])) {
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
							isspaceOrDot(inptr[6])) {
							inptr += 6;
							tokenBuffer[tbndx] = tk_ptrdif;
							tbndx++;
							return (token = tk_ptrdif);
						}
						if ((inptr[1] == 'a' || inptr[1] == 'A') &&
							(inptr[2] == 'l' || inptr[2] == 'L') &&
							(inptr[3] == 'l' || inptr[3] == 'L') &&
							(inptr[4] == 'o' || inptr[4] == 'O') &&
							(inptr[5] == 'c' || inptr[5] == 'C') &&
							isspaceOrDot(inptr[6])) {
							inptr += 6;
							tokenBuffer[tbndx] = tk_palloc;
							tbndx++;
							return (token = tk_palloc);
						}
						if ((inptr[1] == 'f' || inptr[1] == 'F') &&
							(inptr[2] == 'i' || inptr[2] == 'I') &&
							isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_pfi;
							tbndx++;
							return (token = tk_pfi);
						}
						if ((inptr[1] == 'e' || inptr[1] == 'E') &&
							(inptr[2] == 'e' || inptr[2] == 'E') &&
							(inptr[3] == 'k' || inptr[3] == 'K') &&
							(inptr[4] == 'q' || inptr[4] == 'Q') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_peekq;
							tbndx++;
							return (token = tk_peekq);
						}
						if ((inptr[1] == 'f' || inptr[1] == 'F') &&
							(inptr[2] == 'r' || inptr[2] == 'R') &&
							(inptr[3] == 'e' || inptr[3] == 'E') &&
							(inptr[4] == 'e' || inptr[4] == 'E') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_pfree;
							tbndx++;
							return (token = tk_pfree);
						}
						if ((inptr[1] == 's' || inptr[1] == 'S') &&
							(inptr[2] == 't' || inptr[2] == 'T') &&
							(inptr[3] == 'a' || inptr[3] == 'A') &&
							(inptr[4] == 't' || inptr[4] == 'T') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_pstat;
							tbndx++;
							return (token = tk_pstat);
						}
						if ((inptr[1] == 'u' || inptr[1] == 'U') &&
							(inptr[2] == 's' || inptr[2] == 'S') &&
							(inptr[3] == 'h' || inptr[3] == 'H') &&
							(inptr[4] == 'q' || inptr[4] == 'Q') &&
							isspaceOrDot(inptr[5])) {
							inptr += 5;
							tokenBuffer[tbndx] = tk_pushq;
							tbndx++;
							return (token = tk_pushq);
						}
						if ((inptr[1] == 'o' || inptr[1] == 'O') &&
							(inptr[2] == 'p' || inptr[2] == 'P') &&
							(inptr[3] == 'q' || inptr[3] == 'Q') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_popq;
							tbndx++;
							return (token = tk_popq);
						}
						if ((inptr[1] == 'r' || inptr[1] == 'R') &&
							(inptr[2] == 'o' || inptr[2] == 'O') &&
							(inptr[3] == 'c' || inptr[3] == 'C') &&
							isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_proc;
							tbndx++;
							return (token = tk_proc);
						}
						if ((inptr[1] == 'e' || inptr[1] == 'E') &&
							(inptr[2] == 'r' || inptr[2] == 'R') &&
							(inptr[3] == 'm' || inptr[3] == 'M') &&
							isspaceOrDot(inptr[4]) || inptr[4] == '.') {
							inptr += 4;
							tokenBuffer[tbndx] = tk_perm;
							tbndx++;
							return token = tk_perm;
						}
						break;

        // ret rex rol roli ror rori rtd rte rtf rts rti rtl rodata
        case 'r': case 'R':
					if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 't' || inptr[2] == 'T') && isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_ret;
						tbndx++;
						return token = tk_ret;
					}
					if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='x' || inptr[2]=='X') && isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_rex;
						tbndx++;
						return token = tk_rex;
					}
					if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 'm' || inptr[2] == 'M') && (inptr[3]=='u' || inptr[3]=='U') && isspaceOrDot(inptr[4])) {
						inptr += 4;
						tokenBuffer[tbndx] = tk_remu;
						tbndx++;
						return token = tk_remu;
					}
					if ((inptr[1] == 'e' || inptr[1] == 'E') && (inptr[2] == 'm' || inptr[2] == 'M') && isspaceOrDot(inptr[3])) {
						inptr += 3;
						tokenBuffer[tbndx] = tk_rem;
						tbndx++;
						return token = tk_rem;
					}
					if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='s' || inptr[2]=='S') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rts;
								tbndx++;
								return token = tk_rts;
            }
						if ((inptr[1] == 't' || inptr[1] == 'T') && (inptr[2] == 'l' || inptr[2] == 'L') && isspaceOrDot(inptr[3])) {
							inptr += 3;
							tokenBuffer[tbndx] = tk_rtl;
							tbndx++;
							return token = tk_rtl;
						}
						if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='f' || inptr[2]=='F') && isspaceOrDot(inptr[3])) {
              inptr += 3;
							tokenBuffer[tbndx] = tk_rtf;
							tbndx++;
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
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='i' || inptr[2]=='I') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rti;
								tbndx++;
								return token = tk_rti;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_rte;
								tbndx++;
								return token = tk_rte;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
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
                 isspaceOrDot(inptr[6])) {
                 inptr += 6;
								 tokenBuffer[tbndx] = tk_rodata;
								 tbndx++;
								 return token = tk_rodata;
             }
            break;
        
    // sb sc sf sh sw sxb sxc sxh sub subf subi subu subui shl shli shr shru shrui sei smr ss:
    // seq seqi sne snei sge sgei sgt sgti slt slti sle slei sgeu sgeui sgtu sgtui sltu sltui sleu sleui
    // swcr sfd sts sync sws stcmp stmov srai srli stcb sv
		// DSD9/Itanium: stb stw stp stt std stm sto
    case 's': case 'S':
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='d' || inptr[2]=='D') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_std;
				tbndx++;
				return token = tk_std;
			}  
			if ((inptr[1] == 't' || inptr[1] == 'T') &&
				(inptr[2] == 'h' || inptr[2] == 'H') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_sth;
				tbndx++;
				return token = tk_sth;
			}
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='d' || inptr[2]=='D') &&
				(inptr[3]=='c' || inptr[3]=='C') &&
				(inptr[4]=='r' || inptr[4]=='R') &&
				isspaceOrDot(inptr[5])) {
				inptr += 5;
				tokenBuffer[tbndx] = tk_stdcr;
				tbndx++;
				return token = tk_stdcr;
			}  
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='b' || inptr[2]=='B') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_stb;
				tbndx++;
				return token = tk_stb;
			}  
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='p' || inptr[2]=='P') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_stp;
				tbndx++;
				return token = tk_stp;
			}  
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='t' || inptr[2]=='T') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_stt;
				tbndx++;
				return token = tk_stt;
			}  
			if ((inptr[1]=='t' || inptr[1]=='T') &&
				(inptr[2]=='w' || inptr[2]=='W') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_stw;
				tbndx++;
				return token = tk_stw;
			}  
			if ((inptr[1] == 't' || inptr[1] == 'T') &&
				(inptr[2] == 'o' || inptr[2] == 'O') &&
				(inptr[3] == 'i' || inptr[3] == 'I') &&
				isspaceOrDot(inptr[4])) {
				inptr += 4;
				tokenBuffer[tbndx] = tk_stoi;
				tbndx++;
				return (token = tk_stoi);
			}
			if ((inptr[1] == 't' || inptr[1] == 'T') &&
				(inptr[2] == 'o' || inptr[2] == 'O') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_sto;
				tbndx++;
				return token = tk_sto;
			}
			if ((inptr[1] == 't' || inptr[1] == 'T') &&
				(inptr[2] == 'm' || inptr[2] == 'M') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_stm;
				tbndx++;
				return (token = tk_stm);
			}
			if ((inptr[1] == 'e' || inptr[1] == 'E') &&
				(inptr[2] == 't' || inptr[2] == 'T') &&
				(inptr[3] == 't' || inptr[3] == 'T') &&
				(inptr[4] == 'o' || inptr[3] == 'O') &&
				isspaceOrDot(inptr[5])) {
				inptr += 5;
				tokenBuffer[tbndx] = tk_setto;
				tbndx++;
				return token = tk_setto;
			}
			if ((inptr[1]=='w' || inptr[1]=='W') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sw;
								tbndx++;
								return token = tk_sw;
            }  
            if ((inptr[1]=='b' || inptr[1]=='B') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sb;
								tbndx++;
								return token = tk_sb;
            }  
            if ((inptr[1]=='c' || inptr[1]=='C') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sc;
								tbndx++;
								return token = tk_sc;
            }  
            if ((inptr[1]=='h' || inptr[1]=='H') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sh;
								tbndx++;
								return token = tk_sh;
            }  
            if ((inptr[1]=='f' || inptr[1]=='F') && (isspaceOrDot(inptr[2])||inptr[2]=='.')) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sf;
								tbndx++;
								return token = tk_sf;
            }  
						if ((inptr[1] == 'u' || inptr[1] == 'U') &&
							(inptr[2] == 'b' || inptr[2] == 'B') &&
							(inptr[3] == 'f' || inptr[3] == 'F') && isspaceOrDot(inptr[4])) {
							inptr += 4;
							tokenBuffer[tbndx] = tk_subf;
							tbndx++;
							return token = tk_subf;
						}
						if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_subi;
								tbndx++;
								return token = tk_subi;
            }
            if ((inptr[1]=='u' || inptr[1]=='U') && (inptr[2]=='b' || inptr[2]=='B') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sub;
								tbndx++;
								return token = tk_sub;
            }
            if ((inptr[1]=='f' || inptr[1]=='F') && (inptr[2]=='d' || inptr[2]=='D') && isspaceOrDot(inptr[3])) {
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
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='i' || inptr[2]=='I') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sei;
								tbndx++;
								return token = tk_sei;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='b' || inptr[2]=='B') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxb;
								tbndx++;
								return token = tk_sxb;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='w' || inptr[2]=='W') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxw;
								tbndx++;
								return token = tk_sxw;
            }
            if ((inptr[1]=='x' || inptr[1]=='X') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sxt;
								tbndx++;
								return token = tk_sxt;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_seq;
								tbndx++;
								return token = tk_seq;
            }
            if ((inptr[1]=='e' || inptr[1]=='E') && (inptr[2]=='q' || inptr[2]=='Q') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_seqi;
								tbndx++;
								return token = tk_seqi;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sne;
								tbndx++;
								return token = tk_sne;
            }
            if ((inptr[1]=='n' || inptr[1]=='N') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_snei;
								tbndx++;
								return token = tk_snei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sge;
								tbndx++;
								return token = tk_sge;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgei;
								tbndx++;
								return token = tk_sgei;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sgt;
								tbndx++;
								return token = tk_sgt;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgti;
								tbndx++;
								return token = tk_sgti;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sle;
								tbndx++;
								return token = tk_sle;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='e' || inptr[2]=='E') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
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
            if ((inptr[1]=='l' || inptr[1]=='L') && (inptr[2]=='t' || inptr[2]=='T') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_slti;
								tbndx++;
								return token = tk_slti;
            }

            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgeu;
								tbndx++;
								return token = tk_sgeu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgeui;
								tbndx++;
								return token = tk_sgeui;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sgtu;
								tbndx++;
								return token = tk_sgtu;
            }
            if ((inptr[1]=='g' || inptr[1]=='G') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_sgtui;
								tbndx++;
								return token = tk_sgtui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sleu;
								tbndx++;
								return token = tk_sleu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='e' || inptr[2]=='E') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
                inptr += 5;
								tokenBuffer[tbndx] = tk_sleui;
								tbndx++;
								return token = tk_sleui;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sltu;
								tbndx++;
								return token = tk_sltu;
            }
            if ((inptr[1]=='l' || inptr[1]=='L') &&
                (inptr[2]=='t' || inptr[2]=='T') &&
                (inptr[3]=='u' || inptr[3]=='U') &&
                (inptr[4]=='i' || inptr[4]=='I') &&
                isspaceOrDot(inptr[5])) {
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
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_swap;
								tbndx++;
								return token = tk_swap;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sw;
								tbndx++;
								return token = tk_sw;
            }  
            if ((inptr[1]=='v' || inptr[1]=='V') && isspaceOrDot(inptr[2])) {
                inptr += 2;
								tokenBuffer[tbndx] = tk_sv;
								tbndx++;
								return token = tk_sv;
            }  
            if ((inptr[1]=='y' || inptr[1]=='Y') && 
                (inptr[2]=='s' || inptr[2]=='S') && 
                isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_sys;
								tbndx++;
								return token = tk_sys;
            }
            if ((inptr[1]=='t' || inptr[1]=='T') && 
                (inptr[2]=='p' || inptr[2]=='P') && 
                isspaceOrDot(inptr[3])) {
                inptr += 3;
								tokenBuffer[tbndx] = tk_stp;
								tbndx++;
								return token = tk_stp;
            }
            if (gCpu==4) {
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='b' || inptr[3]=='B') && 
                    isspaceOrDot(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsb;
										tbndx++;
										return token = tk_stsb;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='c' || inptr[3]=='C') && 
                    isspaceOrDot(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsc;
										tbndx++;
										return token = tk_stsc;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='h' || inptr[3]=='H') && 
                    isspaceOrDot(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsh;
										tbndx++;
										return token = tk_stsh;
                }
                if ((inptr[1]=='t' || inptr[1]=='T') && 
                    (inptr[2]=='s' || inptr[2]=='S') && 
                    (inptr[3]=='w' || inptr[3]=='W') && 
                    isspaceOrDot(inptr[4])) {
                    inptr += 4;
										tokenBuffer[tbndx] = tk_stsw;
										tbndx++;
										return token = tk_stsw;
                }
                if ((inptr[1]=='w' || inptr[1]=='W') &&
                    (inptr[2]=='s' || inptr[2]=='S') &&
                    isspaceOrDot(inptr[3])) {
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
                    isspaceOrDot(inptr[4])) {
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
                isspaceOrDot(inptr[4])) {
                inptr += 4;
								tokenBuffer[tbndx] = tk_sync;
								tbndx++;
								return token = tk_sync;
            }
            // RiSC-V opcodes
            // slli srli srai
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
			if (gCpu == 'F') {
				if ((inptr[1] == 'p' || inptr[1] == 'P')
					&& (inptr[2] == 't' || inptr[2] == 'T')
					&& (inptr[3] == 'r' || inptr[3] == 'R')
					&& isspaceOrDot(inptr[4])) {
					inptr += 4;
					tokenBuffer[tbndx] = tk_sptr;
					tbndx++;
					return (token = tk_sptr);
				}
				if ((inptr[1] == 'e' || inptr[1] == 'E') &&
					(inptr[2] == 't' || inptr[2] == 't') &&
					(inptr[3] == 'w' || inptr[3] == 'W') &&
					(inptr[4] == 'b' || inptr[3] == 'B') &&
					isspaceOrDot(inptr[5])) {
					inptr += 5;
					tokenBuffer[tbndx] = tk_setwb;
					tbndx++;
					return token = tk_setwb;
				}
			}
			if ((inptr[1] == 't' || inptr[1] == 'T') &&
				(inptr[2] == 'a' || inptr[2] == 'A') &&
				(inptr[3] == 't' || inptr[3] == 'T') &&
				(inptr[4] == 'q' || inptr[3] == 'Q') &&
				isspaceOrDot(inptr[5])) {
				inptr += 5;
				tokenBuffer[tbndx] = tk_statq;
				tbndx++;
				return token = tk_statq;
			}
			break;

      // tgt to tlbdis tlben tlbpb tlbrd tlbrdreg tlbwi tlbwr tlbwrreg transform tst
			case 't': case 'T':
				if ((inptr[1]=='o' || inptr[1]=='O') &&
					isspaceOrDot(inptr[2])) {
					inptr += 2;
					tokenBuffer[tbndx] = tk_to;
					tbndx++;
					return token = tk_to;
				}
				if ((inptr[1] == 's' || inptr[1] == 'S') && (inptr[2] == 't' || inptr[2] == 'T') &&
					isspaceOrDot(inptr[3])) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_tst;
					tbndx++;
					return token = tk_tst;
				}
			 if (gCpu==4 || gCpu=='F') {
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='d' || inptr[3]=='D') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     (inptr[5]=='s' || inptr[5]=='S') &&
                     isspaceOrDot(inptr[6])) {
                     inptr += 6;
										 tokenBuffer[tbndx] = tk_tlbdis;
										 tbndx++;
										 return token = tk_tlbdis;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='e' || inptr[3]=='E') &&
                     (inptr[4]=='n' || inptr[4]=='N') &&
                     isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlben;
										 tbndx++;
										 return token = tk_tlben;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='p' || inptr[3]=='P') &&
                     (inptr[4]=='b' || inptr[4]=='B') &&
                     isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbpb;
										 tbndx++;
										 return token = tk_tlbpb;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='r' || inptr[3]=='R') &&
                     (inptr[4]=='d' || inptr[4]=='D') &&
                     isspaceOrDot(inptr[5])) {
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
                     isspaceOrDot(inptr[8])) {
                     inptr += 8;
										 tokenBuffer[tbndx] = tk_tlbrdreg;
										 tbndx++;
										 return token = tk_tlbrdreg;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='i' || inptr[4]=='I') &&
                     isspaceOrDot(inptr[5])) {
                     inptr += 5;
										 tokenBuffer[tbndx] = tk_tlbwi;
										 tbndx++;
										 return token = tk_tlbwi;
                 }
                 if ((inptr[1]=='l' || inptr[1]=='L') &&
                     (inptr[2]=='b' || inptr[2]=='B') &&
                     (inptr[3]=='w' || inptr[3]=='W') &&
                     (inptr[4]=='r' || inptr[4]=='R') &&
                     isspaceOrDot(inptr[5])) {
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
                     isspaceOrDot(inptr[8])) {
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
			if ((inptr[1] == 'n' || inptr[1] == 'N') &&
				(inptr[2] == 'l' || inptr[2] == 'L') &&
				(inptr[3] == 'i' || inptr[3] == 'I') &&
				(inptr[4] == 'n' || inptr[4] == 'N') &&
				(inptr[5] == 'k' || inptr[5] == 'K') &&
				isspaceOrDot(inptr[6])) {
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

    // wai
    case 'w': case 'W':
			if ((inptr[1]=='a' || inptr[1]=='A') &&
				(inptr[2]=='i' || inptr[2]=='I') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_wai;
				tbndx++;
				return token = tk_wai;
			}
			if ((inptr[1] == 'f' || inptr[1] == 'F') &&
				(inptr[2] == 'i' || inptr[2] == 'I') &&
				isspaceOrDot(inptr[3])) {
				inptr += 3;
				tokenBuffer[tbndx] = tk_wfi;
				tbndx++;
				return token = tk_wfi;
			}
			if ((inptr[1] == 'y' || inptr[1] == 'Y') &&
				(inptr[2] == 'd' || inptr[2] == 'D') &&
				(inptr[3] == 'n' || inptr[3] == 'N') &&
				(inptr[4] == 'd' || inptr[4] == 'D') &&
				(inptr[5] == 'x' || inptr[5] == 'X') &&
				isspaceOrDot(inptr[6])) {
				inptr += 6;
				tokenBuffer[tbndx] = tk_wydndx;
				tbndx++;
				return (token = tk_wydndx);
			}
			break;

        // xnor xor xori
        case 'x': case 'X':
            if ((inptr[1]=='o' || inptr[1]=='O') && (inptr[2]=='r' || inptr[2]=='R') && (inptr[3]=='i' || inptr[3]=='I') && isspaceOrDot(inptr[4])) {
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
			if ((inptr[1]=='x' || inptr[1]=='X') &&
          (inptr[2]=='b' || inptr[2]=='B') &&
          isspaceOrDot(inptr[3])
          ) {
          inptr += 3;
					tokenBuffer[tbndx] = tk_zxb;
					tbndx++;
					return token = tk_zxb;
        }
				if ((inptr[1] == 'x' || inptr[1] == 'X') &&
					(inptr[2] == 't' || inptr[2] == 'T') &&
					isspaceOrDot(inptr[3])
					) {
					inptr += 3;
					tokenBuffer[tbndx] = tk_zxt;
					tbndx++;
					return token = tk_zxt;
				}
				if ((inptr[1]=='x' || inptr[1]=='X') &&
					(inptr[2]=='w' || inptr[2]=='W') &&
          isspaceOrDot(inptr[3])
          ) {
          inptr += 3;
					tokenBuffer[tbndx] = tk_zxw;
					tbndx++;
					return token = tk_zxw;
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

