#include "stdafx.h"
#include "frmError.h"

extern Finray::RayTracer rayTracer;
static char numstr[100];
static char *numstrptr;
static char backup_token = 0;
extern char master_filebuf[10000000];

using namespace System::Runtime::InteropServices;

namespace Finray {

Parser::Parser()
{
	mfp = 0;
	level = 0;
//	RTFClasses::Random::srand((RANDOM_TYPE)time(NULL));
}

void Parser::Need(int tk) {
	NextToken();
	if (token != tk) {
		throw gcnew Finray::FinrayException(ERR_EXPECT_TOKEN, tk);
	}
}

void Parser::Was(int tk) {
	if (token != tk) {
		throw gcnew Finray::FinrayException(ERR_EXPECT_TOKEN, tk);
	}
}

bool Parser::Test(int tk) {
	char *op;

	op = p;
	NextToken();
	p = op;
	return (token == tk);
}

int Parser::isalnum(char c)
{       return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9');
}

int Parser::isidch(char c) { return isalnum(c) || c == '_' || c == '$'; }
int Parser::isspace(char c) { return c == ' ' || c == '\t' || c == '\n' || c=='\r'; }
int Parser::isdigit(char c) { return (c >= '0' && c <= '9'); }

void Parser::ScanToEOL()
{
	while (p[0] != '\n' && p[0]) p++;
	if (p[0]) p++;
}

/*
 *      getid - get an identifier.
 *
 *      identifiers are any isidch conglomerate
 *      that doesn't start with a numeric character.
 *      this set INCLUDES keywords.
 */
void Parser::getid()
{
	register int    i;
    i = 0;
	lastid[0] = '_';
    while(isidch(p[0])) {
		if(i < 62) {
			lastkw[i] = p[0];
			lastid[i+1] = p[0];
			i++;
        }
		p++;
    }
    lastkw[i] = '\0';
    lastid[i+1] = '\0';
//    lastst = id;
}
 

__int64 Parser::radix36(char c)
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
void Parser::getbase(__int64 b)
{       
        register __int64 i0, i1, i2;
        register __int64 i, j;
        int k;

        i = 0;
        i0 = 0;
        i1 = 0;
        while(isalnum(p[0])) {
                if((j = radix36(p[0])) < b) {
                        i = i * b + j;
                        i2 = i0;
                        for (k = 0; k < b; k++) {
                            i0 = i0 + i2;
                            if (i0 & 0x100000000L) {
                               i0 = i0 - 0x100000000L;
                               i1 = i1 + 1;
                            }
                        }
                        i0 = i0 + j;
                        if (i0 & 0x100000000L) {
                            i0 = i0 - 0x100000000L;
                            i1 = i1 + 1;
                        }
						p++;
                        }
                else break;
                }
		if (p[0]=='L' || p[0]=='U') {	// ignore a 'L'ong suffix and 'U'nsigned
			p++;
		}
        ival = i;
        token = TK_ICONST;
}
 

/*
 *      getfrac - get fraction part of a floating number.
 */
void Parser::getfrac()
{
	double frmul;

    frmul = 0.1;
    while(isdigit(p[0])) {
        rval += frmul * (p[0] - '0');
		p++;
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
void Parser::getexp()
{       double  expo, exmul;
        expo = 1.0;
        if(token != TK_RCONST)
               rval = (double)ival;
        if(p[0] == '-') {
                exmul = 0.1;
				p++;
                }
        else
                exmul = 10.0;
        getbase(10);
        if(ival > 32767)
			throw gcnew Finray::FinrayException(ERR_FPCON,0);
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
void Parser::getnum()
{       register int    i;
        i = 0;

		ival = 0;
		rval = 0.0;
        numstrptr = &numstr[0];
         *numstrptr = p[0];
         numstrptr++; 
        if(p[0] == '0') {
				p++;
                if (p[0]=='.') {
                     goto j1;
				}
                if(p[0] == 'x' || p[0] == 'X') {
						p++;
                        getbase(16);
                        }
                else getbase(8);
                }
        else    {
                getbase(10);
j1:
                if(p[0] == '.') {
						p++;
                        rval = (double)ival;    /* float the integer part */
                        getfrac();      /* add the fractional part */
                        token = TK_RCONST;
                        }
                if(p[0] == 'e' || p[0] == 'E') {
						p++;
                        getexp();       /* get the exponent */
                        }
				// Ignore 'U' unsigned suffix
				if (p[0]=='U' || p[0]=='u') {
//					p++;
				}
				}
    numstrptr[-1]='\0';
    numstrptr = nullptr;
}

void Parser::SkipSpaces()
{
    while( isspace(p[0]) ) 
        p++; 
}

int	Parser::NextToken() {
	while(true) {
		SkipSpaces();
        if( p[0] == 0)
            return token = TK_EOF;
        else if(isdigit(p[0])) {
            getnum();
			if (token==TK_ICONST)
				last_num = (double)ival;
			else
				last_num = rval;
			return token = TK_NUM;
		}
		if (p[0]=='\0')
			return token = TK_EOF;
		if (p[0]=='=') {
			p++;
			if (p[0]=='=') {
				p++;
				return token = TK_EQ;
			}
			return token = '=';
		}
		if (p[0]=='.') {
			p++;
			return token = '.';
		}
		if (p[0]=='-') {
			p++;
			return token = '-';
		}
		if (p[0]=='<') {
			p++;
			if (p[0]=='=') {
				p++;
				return token = TK_LE;
			}
			if (p[0]=='>') {
				p++;
				return token = TK_NE;
			}
			return token = '<';
		}
		if (p[0]=='>') {
			p++;
			if (p[0]=='=') {
				p++;
				return token = TK_GE;
			}
			return token = '>';
		}
		if (p[0]=='{') {
			p++;
			return token = '{';
		}
		if (p[0]=='}') {
			p++;
			return token = '}';
		}
		if (p[0]=='(') {
			p++;
			return token = '(';
		}
		if (p[0]==')') {
			p++;
			return token = ')';
		}
		if (p[0]=='[') {
			p++;
			return token = '[';
		}
		if (p[0]==']') {
			p++;
			return token = ']';
		}
		if (p[0]=='*') {
			p++;
			return token = '*';
		}
		if (p[0]=='+') {
			p++;
			return token = '+';
		}
		if (p[0]=='"') {
			p++;
			return token = '"';
		}
		if (p[0]==',') {
			p++;
			return token = ',';
		}
		if (p[0]=='/' && p[1]=='/') {
			p++;
			ScanToEOL();
			continue;
		}
		if (p[0]=='/' && p[1]=='*') {
			while (!(p[0]=='*' && p[1]=='/') && p[0])
				p++;
			p+=2;
			continue;
		}
		if (p[0]=='/') {
			p++;
			return token = '/';
		}
		if (p[0]=='!') {
			p++;
			if (p[0]=='=') {
				p++;
				return token = TK_NE;
			}
			return token = '!';
		}

		// ambient anti approximate
		if (p[0]=='a') {
			if (p[1]=='m' && p[2]=='b' && p[3]=='i' && p[4]=='e' && p[5]=='n' && p[6]=='t' && !isidch(p[7])) {
				p += 7;
				return token = TK_AMBIENT;
			}
			if (p[1]=='n' && p[2]=='t' && p[3]=='i' && !isidch(p[4])) {
				p += 4;
				return token = TK_ANTI;
			}
			if (p[1]=='p' && p[2]=='p' && p[3]=='r' && p[4]=='o' && p[5]=='x' && p[6]=='i' && p[7]=='m'
				&& p[8]=='a' && p[9]=='t' && p[10]=='e' && !isidch(p[11])) {
					p += 11;
				return token = TK_APPROXIMATE;
			}
		}

		// background brilliance box
		if (p[0]=='b') {
			if (p[0]=='b' && p[1]=='r' && p[2]=='i' && p[3]=='l' && p[4]=='l'
				&& p[5]=='i' && p[6]=='a' && p[7]=='n' && p[8]=='c' && p[9]=='e' && !isidch(p[10])) {
				p += 10;
				return token = TK_BRILLIANCE;
			}
			if (p[0]=='b' && p[1]=='a' && p[2]=='c' && p[3]=='k' && p[4]=='g'
				&& p[5]=='r' && p[6]=='o' && p[7]=='u' && p[8]=='n' && p[9]=='d' && !isidch(p[10])) {
				p += 10;
				return token = TK_BACKGROUND;
			}
			if (p[1]=='o' && p[2]=='x' && !isidch(p[3])) {
				p += 3;
				return token = TK_BOX;
			}
		}
		// camera checker color colour color_map colormethod cone cos cube cylinder
		if (p[0]=='c') {
			if (p[1]=='a' && p[2]=='m' && p[3]=='e' && p[4]=='r' && p[5]=='a' && !isidch(p[6])) {
				p += 6;
				return token = TK_CAMERA;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='r' && !isidch(p[5])) {
				p += 5;
				return token = TK_COLOR;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='r' && p[5]=='_' && 
				p[6]=='m' && p[7]=='a' && p[8]=='p' &&
				!isidch(p[9])) {
				p += 9;
				return token = TK_COLORMAP;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='u' && p[5]=='r' && p[6]=='_' &&
				p[7]=='m' && p[8]=='a' && p[9]=='p' &&
				!isidch(p[10])) {
				p += 10;
				return token = TK_COLORMAP;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='r' &&
				p[5]=='m' && p[6]=='e' && p[7]=='t' && p[8]=='h' && p[9]=='o' && p[10]=='d' &&
				!isidch(p[11])) {
				p += 11;
				return token = TK_COLORMETHOD;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='u' && p[5]=='r' && !isidch(p[6])) {
				p += 6;
				return token = TK_COLOR;
			}
			if (p[1]=='o' && p[2]=='n' && p[3]=='e' && !isidch(p[4])) {
				p += 4;
				return token = TK_CONE;
			}
			if (p[1]=='o' && p[2]=='s' && !isidch(p[3])) {
				p += 3;
				return token = TK_COS;
			}
			if (p[1]=='u' && p[2]=='b' && p[3]=='e' && !isidch(p[4])) {
				p += 4;
				return token = TK_CUBE;
			}
			if (p[1]=='y' && p[2]=='l' && p[3]=='i' && p[4]=='n' && p[5]=='d' && p[6]=='e' && p[7]=='r' && !isidch(p[8])) {
				p += 8;
				return token = TK_CYLINDER;
			}
			if (p[1]=='h' && p[2]=='e' && p[3]=='c' && p[4]=='k' && p[5]=='e' && p[6]=='r' && !isidch(p[7])) {
				p += 7;
				return token = TK_CHECKER;
			}
		}
		// diffuse difference
		if (p[0]=='d') {
			if (p[1]=='i' && p[2]=='f' && p[3]=='f' && p[4]=='u' && p[5]=='s' && p[6]=='e' && !isidch(p[7])) {
				p += 7;
				return token = TK_DIFFUSE;
			}
			if (p[1]=='i' && p[2]=='f' && p[3]=='f' && p[4]=='e' && p[5]=='r' && p[6]=='e' && p[7]=='n' && p[8]=='c' && p[9]=='e' && !isidch(p[10])) {
				p += 10;
				return token = TK_DIFFERENCE;
			}
		}
		// first_frame
		if (p[0]=='f') {
			if (p[1]=='i' && p[2]=='r' && p[3]=='s' && p[4]=='t' && p[5]=='_' &&
				p[6]=='f' && p[7]=='r' && p[8]=='a' && p[9]=='m' && p[10]=='e' &&
				!isidch(p[11])) {
				p += 11;
				return token = TK_FIRSTFRAME;
			}
			if (p[1]=='o' && p[2]=='r' && !isidch(p[3])) {
				p += 3;
				return token = TK_FOR;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='m' && p[4]=='e' && p[5]=='s' && !isidch(p[6])) {
				p += 6;
				return token = TK_FRAMES;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='m' && p[4]=='e' && p[5]=='n' && p[6]=='o' && !isidch(p[7])) {
				p += 7;
				return token = TK_FRAMENO;
			}
		}
		// gradient
		if (p[0]=='g' && p[1]=='r' && p[2]=='a' && p[3]=='d' && p[4]=='i' && p[5]=='e' && p[6]=='n' && p[7]=='t' && !isidch(p[8])) {
			p += 8;
			return token = TK_GRADIENT;
		}
		if (p[0]=='d' && p[1]=='i' && p[2]=='r' && p[3]=='e' && p[4]=='c' && p[5]=='t' && p[6]=='i' && p[7]=='o' && p[8]=='n' && !isidch(p[9])) {
			p += 9;
			return token = TK_DIRECTION;
		}
		// include intersection if
		if (p[0]=='i') {
			if (p[1]=='f' && !isidch(p[2])) {
				p += 2;
				return token = TK_IF;
			}
			if (p[1]=='n' && p[2]=='c' && p[3]=='l' && p[4]=='u' && p[5]=='d' && p[6]=='e' && !isidch(p[7])) {
				p += 7;
				return token = TK_INCLUDE;
			}
			if (p[1]=='n' && p[2]=='t' && p[3]=='e' && p[4]=='r' &&
				p[5]=='s' && p[6]=='e' && p[7]=='c' && p[8]=='t' && p[9]=='i' && p[10]=='o' && p[11]=='n' && !isidch(p[12])) {
				p += 12;
				return token = TK_INTERSECTION;
			}
		}
		// last_frame light light_source location look_at
		if (p[0]=='l') {
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' && !isidch(p[5])) {
				p += 5;
				return token = TK_LIGHT;
			}
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' &&
				p[5]=='_' && p[6]=='s' && p[7]=='o' && p[8]=='u' && p[9]=='r' && p[10]=='c' && p[11]=='e' && !isidch(p[12])) {
				p += 12;
				return token = TK_LIGHT_SOURCE;
			}
			if (p[1]=='o' && p[2]=='c' && p[3]=='a' && p[4]=='t' && p[5]=='i' && p[6]=='o' && p[7]=='n' && !isidch(p[8])) {
				p += 8;
				return token = TK_LOCATION;
			}
			if (p[1]=='o' && p[2]=='o' && p[3]=='k' && p[4]=='_' && p[5]=='a' && p[6]=='t' && !isidch(p[7])) {
				p += 7;
				return token = TK_LOOK_AT;
			}
			if (p[1]=='a' && p[2]=='s' && p[3]=='t' && p[4]=='_' &&
				p[5]=='f' && p[6]=='r' && p[7]=='a' && p[8]=='m' && p[9]=='e' &&
				!isidch(p[10])) {
				p += 10;
				return token = TK_LASTFRAME;
			}
		}

		// no_reflection no_shadow
		if (p[0]=='n') {
			if (p[1]=='o') {
				if (p[2]=='_') {
					if (p[3]=='r' && p[4]=='e' && p[5]=='f' && p[6]=='l' && p[7]=='e' && p[8]=='c'
						&& p[9]=='t' && p[10]=='i' && p[11]=='o' && p[12]=='n' && !isidch(p[13])) {
						p += 13;
						return TK_NO_REFLECTION;
					}
					if (p[3]=='s' && p[4]=='h' && p[5]=='a' && p[6]=='d' && p[7]=='o' && p[8]=='w' && !isidch(p[9])) {
						p += 9;
						return TK_NO_SHADOW;
					}
				}
			}
		}

		// object open
		if (p[0]=='o') {
			if (p[1]=='b' && p[2]=='j' && p[3]=='e' && p[4]=='c' && p[5]=='t' && !isidch(p[6])) {
				p += 6;
				return token = TK_OBJECT;
			}
			if (p[1]=='p' && p[2]=='e' && p[3]=='n' && !isidch(p[4])) {
				p += 4;
				return token = TK_OPEN;
			}
		}
		// pigment plane
		if (p[0]=='p') {
			if (p[1]=='i' && p[2]=='g' && p[3]=='m' && p[4]=='e' && p[5]=='n' && p[6]=='t' && !isidch(p[7])) {
				p += 7;
				return token = TK_PIGMENT;
			}
			if (p[1]=='l' && p[2]=='a' && p[3]=='n' && p[4]=='e' && !isidch(p[5])) {
				p += 5;
				return token = TK_PLANE;
			}
		}
		// quadric
		if (p[0]=='q' && p[1]=='u' && p[2]=='a' && p[3]=='d' && p[4]=='r' && p[5]=='i' && p[6]=='c' && !isidch(p[7])) {
			p += 7;
			return token = TK_QUADRIC;
		}
		// raytracer rectangle reflection rgb rgbf rgbt rgbft right rotate roughness
		if (p[0]=='r') {
			if (p[1]=='g' && p[2]=='b') {
				if (p[3]=='f'){
					if (p[4]=='t' && !isidch(p[5])) {
						p += 5;
						return token = TK_RGBFT;
					}
					if (!isidch(p[4])) {
						p += 4;
						return token = TK_RGBF;
					}
				}
				if (p[3]=='t' && !isidch(p[4])) {
					p += 4;
					return token = TK_RGBT;
				}
				if (!isidch(p[3])) {
					p += 3;
					return token = TK_RGB;
				}
			}
			if (p[1]=='a' && p[2]=='y' && p[3]=='t' && p[4]=='r' && p[5]=='a' && p[6]=='c' && p[7]=='e' && p[8]=='r' && !isidch(p[9])) {
				p += 9;
				return token = TK_RAYTRACER;
			}
			if (p[1]=='e' && p[2]=='c' && p[3]=='t' && p[4]=='a' && p[5]=='n' && p[6]=='g' && p[7]=='l' && p[8]=='e' && !isidch(p[9])) {
				p += 9;
				return token = TK_RECTANGLE;
			}
			if (p[1]=='a' && p[2]=='n' && p[3]=='d' && !isidch(p[4])) {
				p += 4;
				return TK_RAND;
			}
			if (p[1]=='a' && p[2]=='n' && p[3]=='d' && p[4]=='v' && !isidch(p[5])) {
				p += 5;
				return TK_RANDV;
			}
			if (p[1]=='e' && p[2]=='f' && p[3]=='l' && p[4]=='e'
				&& p[5]=='c' && p[6]=='t' && p[7]=='i' && p[8]=='o' && p[9]=='n' && !isidch(p[10])) {
				p += 10;
				return token = TK_REFLECTION;
			}
			if (p[1]=='e' && p[2]=='p' && p[3]=='e' && p[4]=='a' && p[5]=='t' && !isidch(p[6])) {
				p += 6;
				return token = TK_REPEAT;
			}
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' && !isidch(p[5])) {
				p += 5;
				return token = TK_RIGHT;
			}
			if (p[1]=='o' && p[2]=='t' && p[3]=='a' && p[4]=='t' && p[5]=='e' && !isidch(p[6])) {
				p += 6;
				return token = TK_ROTATE;
			}
			if (p[1]=='o' && p[2]=='u' && p[3]=='g' && p[4]=='h' && p[5]=='n' && p[6]=='e' && p[7]=='s' && p[8]=='s' && !isidch(p[9])) {
				p += 9;
				return token = TK_ROUGHNESS;
			}
		}

		// scale sin specular sphere srand
		if (p[0]=='s') {
			if (p[1]=='c' && p[2]=='a' && p[3]=='l' && p[4]=='e' && !isidch(p[5])) {
				p += 5;
				return token = TK_SCALE;
			}
			if (p[1]=='i' && p[2]=='n' && !isidch(p[3])) {
				p += 3;
				return TK_SIN;
			}
			if (p[1]=='p' && p[2]=='e' && p[3]=='c' && p[4]=='u' && p[5]=='l' && p[6]=='a' && p[7]=='r' && !isidch(p[8])) {
				p += 8;
				return token = TK_SPECULAR;
			}
			if (p[1]=='p' && p[2]=='h' && p[3]=='e' && p[4]=='r' && p[5]=='e' && !isidch(p[6])) {
				p += 6;
				return token = TK_SPHERE;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='n' && p[4]=='d' && !isidch(p[5])) {
				p += 5;
				return token = TK_SRAND;
			}
		}

		// texture then to torus translate triangle turbulance
		if (p[0]=='t') {
			if (p[1]=='e' && p[2]=='x' && p[3]=='t' && p[4]=='u' && p[5]=='r' && p[6]=='e' && !isidch(p[7])) {
				p += 7;
				return token = TK_TEXTURE;
			}
			if (p[1]=='h' && p[2]=='e' && p[3]=='n' && !isidch(p[4])) {
				p += 4;
				return token = TK_THEN;
			}
			if (p[1]=='o' && !isidch(p[2])) {
				p += 2;
				return token = TK_TO;
			}
			if (p[1]=='o' && p[2]=='r' && p[3]=='u' && p[4]=='s' && !isidch(p[5])) {
				p += 5;
				return token = TK_TORUS;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='n' && p[4]=='s' && p[5]=='l' && p[6]=='a' && p[7]=='t' && p[8]=='e' && !isidch(p[9])) {
				p += 9;
				return token = TK_TRANSLATE;
			}
			if (p[1]=='r' && p[2]=='i' && p[3]=='a' && p[4]=='n' && p[5]=='g' && p[6]=='l' && p[7]=='e' && !isidch(p[8])) {
				p += 8;
				return token = TK_TRIANGLE;
			}
			if (p[1]=='u' && p[2]=='r' && p[3]=='b' && p[4]=='u' && p[5]=='l' && p[6]=='e' && p[7]=='n' && p[8]=='c' && p[9]=='e' && !isidch(p[10])) {
				p += 10;
				return token = TK_TURBULENCE;
			}
		}
		if (p[0]=='v' && p[1]=='i' && p[2]=='e' && p[3]=='w' && p[4]=='_'
			&& p[5]=='p' && p[6]=='o' && p[7]=='i' && p[8]=='n' && p[9]=='t' && !isidch(p[10])) {
			p += 10;
			return token = TK_VIEW_POINT;
		}
		// union up
		if (p[0]=='u') {
			if (p[1]=='n' && p[2]=='i' && p[3]=='o' && p[4]=='n' && !isidch(p[5])) {
				p += 5;
				return token = TK_UNION;
			}
			if (p[1]=='p' && !isidch(p[2])) {
				p += 2;
				return token = TK_UP;
			}
		}
        if(isidch(p[0])) {
			getid();
			return token = TK_ID;
		}
		throw gcnew Finray::FinrayException(ERR_SYNTAX,1);
	}
}

Value Parser::Unary()
{
	bool minus = false;
	double val = 0;
	double minval,maxval;
	Vector minvalv,maxvalv;
	Symbol *sym;
	char *op;
	Value v, v2;
	Texture *tx;
	AnObject *obj;
	DBL a,b,c,d,e;
	int vc, tk;

	while (true) {
		op = p;
		switch(NextToken()) {

		case TK_ID:
			sym = rayTracer.symbolTable.Find(std::string(lastid));
			if (!sym)
				throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
			return sym->value;

		case TK_RAYTRACER:
			Need('.');
			switch(NextToken()) {
			case TK_FIRSTFRAME:
				v2.i = pRayTracer->first_frame;
				v2.type = TYP_INT;
				return v2;
			case TK_LASTFRAME:
				v2.i = pRayTracer->last_frame;
				v2.type = TYP_INT;
				return v2;
			case TK_FRAMENO:
				v2.i = pRayTracer->frameno;
				v2.type = TYP_INT;
				return v2;
			default:
				throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
			}
			break;

		case TK_RANDV:
			Need('(');
			v = eval();
			if (v.type != TYP_RAND)
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need(',');
			v2 = eval();
			minvalv = v2.v3;
			Need(',');
			v2 = eval();
			maxvalv = v2.v3;
			Need(')');
			v2.v3.x = (maxvalv.x-minvalv.x) * ((RTFClasses::Random*)v.val.obj)->dbl() + minvalv.x;
			v2.v3.y = (maxvalv.y-minvalv.y) * ((RTFClasses::Random*)v.val.obj)->dbl() + minvalv.y;
			v2.v3.z = (maxvalv.x-minvalv.z) * ((RTFClasses::Random*)v.val.obj)->dbl() + minvalv.z;
			v2.type = TYP_VECTOR;
			return v2;

		case TK_SIN:
			Need('(');
			v2 = eval();
			if (v2.type==TYP_INT) {
				v2.d = sin((double)v2.i*PI/180.0);
				v2.type = TYP_NUM;
			}
			else if (v2.type==TYP_NUM)
				v2.d = sin(v2.d*PI/180.0);
			else if (v2.type==TYP_VECTOR) {
				v2.v3 = Vector(sin(v2.v3.x*PI/180.0),sin(v2.v3.y*PI/180.0),sin(v2.v3.z*PI/180.0));
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need(')');
			return v2;

		case TK_COS:
			Need('(');
			v2 = eval();
			if (v2.type==TYP_INT) {
				v2.d = cos((double)v2.i*PI/180.0);
				v2.type = TYP_NUM;
			}
			else if (v2.type==TYP_NUM)
				v2.d = cos(v2.d*PI/180.0);
			else if (v2.type==TYP_VECTOR) {
				v2.v3 = Vector(cos(v2.v3.x*PI/180.0),cos(v2.v3.y*PI/180.0),cos(v2.v3.z*PI/180.0));
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need(')');
			return v2;

			// Fall through
		case '<':
			vc = 0;
			v2 = Addsub();
			if (v2.type==TYP_INT)
				a = (double)v2.i;
			else if (v2.type==TYP_NUM)
				a = v2.d;
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need(',');
			v2 = Addsub();
			if (v2.type==TYP_INT)
				b = (double)v2.i;
			else if (v2.type==TYP_NUM)
				b = v2.d;
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			tk = NextToken();
			if (tk != ',') {
				Was('>');
				v.type = TYP_VECTOR2D;
				v.v2.u = a;
				v.v2.v = b;
				return v;
			}
			v2 = Addsub();
			if (v2.type==TYP_INT)
				c = (double)v2.i;
			else if (v2.type==TYP_NUM)
				c = v2.d;
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			tk = NextToken();
			if (tk != ',') {
				Was('>');
				v.type = TYP_VECTOR;
				v.v3.x = a;
				v.v3.y = b;
				v.v3.z = c;
				return v;
			}
			v2 = Addsub();
			if (v2.type==TYP_INT)
				d = (double)v2.i;
			else if (v2.type==TYP_NUM)
				d = v2.d;
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			tk = NextToken();
			if (tk != ',') {
				Was('>');
				v.type = TYP_VECTOR4D;
				v.v4.v[0] = a;
				v.v4.v[1] = b;
				v.v4.v[2] = c;
				v.v4.v[3] = d;
				return v;
			}
			v2 = Addsub();
			if (v2.type==TYP_INT)
				e = (double)v2.i;
			else if (v2.type==TYP_NUM)
				e = v2.d;
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need('>');
			v.type = TYP_VECTOR5D;
			v.v5.v[0] = a;
			v.v5.v[1] = b;
			v.v5.v[2] = c;
			v.v5.v[3] = d;
			v.v5.v[4] = e;
			return v;

		case '(':
			v2 = eval();
			Need(')');
			switch (v2.type) {
			case TYP_NUM:
				if (minus)
					v2.d = -v2.d;
				break;
			case TYP_INT:
				if (minus)
					v2.i = -v2.i;
				break;
			case TYP_COLOR:
				if (minus)
					v2.c = Color::Neg(v2.c);
				break;
			case TYP_VECTOR:
				if (minus)
					v2.v3 = Vector::Neg(v2.v3);
				break;
			case TYP_VECTOR2D:
				if (minus)
					v2.v2 = Vector2d::Neg(v2.v2);
				break;
			case TYP_VECTOR4D:
				if (minus)
					v2.v4 = Vector4d::Neg(v2.v4);
				break;
			case TYP_VECTOR5D:
				if (minus)
					v2.v5 = Vector5d::Neg(v2.v5);
				break;
			}
			return v2;

		case '-':
		case TK_ANTI:
			minus = !minus;
			break;

		case TK_SRAND:
			Need('(');
			v2 = eval();
			Need(')');
			v2.val.obj = (AnObject *)RTFClasses::Random::srand(v2.i);
			v2.type = TYP_RAND;
			return v2;

		case TK_RAND:
			Need('(');
			v = eval();
			if (v.type != TYP_RAND)
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			Need(',');
			v2 = eval();
			minval = v2.d;
			Need(',');
			v2 = eval();
			maxval = v2.d;
			Need(')');
			last_num = (maxval-minval) * (double)((RTFClasses::Random *)v.val.obj)->dbl() + minval;
			// Fall through
		case TK_NUM:
			v2.d = last_num;
			if (minus)
				v2.d = -v2.d;
			else
				v2.d = v2.d;
			v2.type = TYP_NUM;
			return v2;
/*
		case TK_INT:
			if (minus)
				v2.i = -(int)last_num;
			else
				v2.i = (int)last_num;
			v2.type = TYP_INT;
			return v2;
*/
		case TK_COLOR:
		case TK_RGB:
			v = Addsub();
			if (v.type==TYP_VECTOR) {
				v2.c.r = (float)v.v3.x;
				v2.c.g = (float)v.v3.y;
				v2.c.b = (float)v.v3.z;
				v2.c.f = 0.0f;
				v2.c.t = 0.0f;
			}
			else if (v.type==TYP_COLOR) {
				v2.c = v.c;
			}
			else if (v.type==TYP_NUM) {
				v2.c.r = (float)v.d;
				v2.c.g = (float)v.d;
				v2.c.b = (float)v.d;
				v2.c.f = (float)v.d;
				v2.c.t = (float)v.d;
			}
			else if (v.type==TYP_INT) {
				v2.c.r = (float)v.i;
				v2.c.g = (float)v.i;
				v2.c.b = (float)v.i;
				v2.c.f = (float)v.i;
				v2.c.t = (float)v.i;
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			if (minus)
				v2.c = Color::Neg(v2.c);
			v2.type = TYP_COLOR;
			return v2;

		case TK_RGBF:
			v = Addsub();
			if (v.type==TYP_VECTOR4D) {
				v2.c.r = (float)v.v4.v[0];
				v2.c.g = (float)v.v4.v[1];
				v2.c.b = (float)v.v4.v[2];
				v2.c.f = (float)v.v4.v[3];
			}
			else if (v.type==TYP_COLOR) {
				v2.c = v.c;
			}
			else if (v.type==TYP_NUM) {
				v2.c.r = (float)v.d;
				v2.c.g = (float)v.d;
				v2.c.b = (float)v.d;
				v2.c.f = (float)v.d;
				v2.c.t = (float)v.d;
			}
			else if (v.type==TYP_INT) {
				v2.c.r = (float)v.i;
				v2.c.g = (float)v.i;
				v2.c.b = (float)v.i;
				v2.c.f = (float)v.i;
				v2.c.t = (float)v.i;
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			if (minus)
				v2.c = Color::Neg(v2.c);
			v2.type = TYP_COLOR;
			return v2;

		case TK_RGBT:
			v = Addsub();
			if (v.type==TYP_VECTOR4D) {
				v2.c.r = (float)v.v4.v[0];
				v2.c.g = (float)v.v4.v[1];
				v2.c.b = (float)v.v4.v[2];
				v2.c.f = 0.0f;
				v2.c.t = (float)v.v4.v[3];
			}
			else if (v.type==TYP_COLOR) {
				v2.c = v.c;
			}
			else if (v.type==TYP_NUM) {
				v2.c.r = (float)v.d;
				v2.c.g = (float)v.d;
				v2.c.b = (float)v.d;
				v2.c.f = (float)v.d;
				v2.c.t = (float)v.d;
			}
			else if (v.type==TYP_INT) {
				v2.c.r = (float)v.i;
				v2.c.g = (float)v.i;
				v2.c.b = (float)v.i;
				v2.c.f = (float)v.i;
				v2.c.t = (float)v.i;
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			if (minus)
				v2.c = Color::Neg(v2.c);
			v2.type = TYP_COLOR;
			return v2;

		case TK_RGBFT:
			v = Addsub();
			if (v.type==TYP_VECTOR5D) {
				v2.c.r = (float)v.v5.v[0];
				v2.c.g = (float)v.v5.v[1];
				v2.c.b = (float)v.v5.v[2];
				v2.c.f = (float)v.v5.v[3];
				v2.c.t = (float)v.v5.v[4];
			}
			else if (v.type==TYP_COLOR) {
				v2.c = v.c;
			}
			else if (v.type==TYP_NUM) {
				v2.c.r = (float)v.d;
				v2.c.g = (float)v.d;
				v2.c.b = (float)v.d;
				v2.c.f = (float)v.d;
				v2.c.t = (float)v.d;
			}
			else if (v.type==TYP_INT) {
				v2.c.r = (float)v.i;
				v2.c.g = (float)v.i;
				v2.c.b = (float)v.i;
				v2.c.f = (float)v.i;
				v2.c.t = (float)v.i;
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			if (minus)
				v2.c = Color::Neg(v2.c);
			v2.type = TYP_COLOR;
			return v2;
/*
		case TK_VECTOR:
			v = eval();
			if (v.type==TYP_COLOR) {
				v2.v.x = v.c.r;
				v2.v.y = v.c.g;
				v2.v.z = v.c.b;
			}
			else if (v.type==TYP_VECTOR) {
				v2.v = v.v;
			}
			else if (v.type==TYP_NUM) {
				v2.v.x = v.d;
				v2.v.y = v.d;
				v2.v.z = v.d;
			}
			else if (x.type==TYP_INT) {
				v2.v.x = (double)v.i;
				v2.v.y = (double)v.i;
				v2.v.z = (double)v.i;
			}
			else
				throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
			if (minus)
				v2.v = Vector::Neg(v2.v);
			v2.type = TYP_VECTOR;
			return v2;
*/
		case TK_TEXTURE:
			tx = ParseTexture(nullptr);
			v.type = TYP_TEXTURE;
			v.val.tx = tx;
			return v;

		case TK_COLORMAP:
			v.type = TYP_COLORMAP;
			v.val.cm = ParseColorMap();
			return v;

		case TK_SPHERE:
			obj = (AnObject *)ParseSphere();
			v.type = TYP_SPHERE | (minus ? 0x80 : 0x00);
			v.val.obj = obj;
			return v;

		case TK_TORUS:
			obj = (AnObject *)ParseTorus();
			v.type = TYP_TORUS | (minus ? 0x80 : 0x00);
			v.val.obj = obj;
			return v;

		case TK_CYLINDER:
			obj = (AnObject *)ParseCylinder();
			v.type = TYP_CYLINDER | (minus ? 0x80 : 0x00);
			v.val.obj = obj;
			return v;

		case TK_UNION:
			obj = ParseObject();
			obj->type = OBJ_UNION;
			v.type = TYP_UNION;
			v.val.obj = obj;
			return v;

		case TK_DIFFERENCE:
			obj = ParseObject();
			obj->type = OBJ_DIFFERENCE;
			v.type = TYP_DIFFERENCE;
			v.val.obj = obj;
			return v;

		case TK_INTERSECTION:
			obj = ParseObject();
			obj->type = OBJ_INTERSECTION;
			v.type = TYP_INTERSECTION;
			v.val.obj = obj;
			return v;

		default:
			p = op;
			throw gcnew Finray::FinrayException(ERR_SYNTAX,0);
		}
	}
}

Value Parser::Multdiv()
{
	Value val = Unary();
	Value v2;
	char *op;

	while (true) {
		op = p;
		switch (NextToken()) {
		case '*':
			switch(val.type) {
			case TYP_INT:
				v2 = Unary();
				if (v2.type==TYP_INT)
					val.i *= v2.i;
				else if (v2.type==TYP_NUM)
					val.i *= (int)v2.d;
				else if (v2.type==TYP_VECTOR) {
					val.type = TYP_VECTOR;
					val.v3 = Vector::Scale(v2.v3,(double)val.i);
				}
				else if (v2.type==TYP_VECTOR2D) {
					val.type = TYP_VECTOR;
					val.v2 = Vector2d::Scale(v2.v2,(double)val.i);
				}
				else if (v2.type==TYP_VECTOR4D) {
					val.type = TYP_VECTOR;
					val.v4 = Vector4d::Scale(v2.v4,(double)val.i);
				}
				else if (v2.type==TYP_VECTOR5D) {
					val.type = TYP_VECTOR;
					val.v5 = Vector5d::Scale(v2.v5,(double)val.i);
				}
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				break;
			case TYP_NUM:
				v2 = Unary();
				if (v2.type==TYP_INT)
					val.d *= (double)v2.i;
				else if (v2.type==TYP_NUM)
					val.d *= (int)v2.d;
				else if (v2.type==TYP_VECTOR) {
					val.type = TYP_VECTOR;
					val.v3 = Vector::Scale(v2.v3,val.d);
				}
				else if (v2.type==TYP_VECTOR2D) {
					val.type = TYP_VECTOR;
					val.v2 = Vector2d::Scale(v2.v2,val.d);
				}
				else if (v2.type==TYP_VECTOR4D) {
					val.type = TYP_VECTOR;
					val.v4 = Vector4d::Scale(v2.v4,val.d);
				}
				else if (v2.type==TYP_VECTOR5D) {
					val.type = TYP_VECTOR;
					val.v5 = Vector5d::Scale(v2.v5,val.d);
				}
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				break;
			case TYP_VECTOR:
				v2 = Unary();
				switch(v2.type) {
				case TYP_INT:	val.v3 = Vector::Scale(val.v3, (double)v2.i); break;
				case TYP_NUM:	val.v3 = Vector::Scale(val.v3, v2.d); break;
				default:
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_VECTOR2D:
				v2 = Unary();
				switch(v2.type) {
				case TYP_INT:	val.v2 = Vector2d::Scale(val.v2, (double)v2.i); break;
				case TYP_NUM:	val.v2 = Vector2d::Scale(val.v2, v2.d); break;
				default:
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_VECTOR4D:
				v2 = Unary();
				switch(v2.type) {
				case TYP_INT:	val.v4 = Vector4d::Scale(val.v4, (double)v2.i); break;
				case TYP_NUM:	val.v4 = Vector4d::Scale(val.v4, v2.d); break;
				default:
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_VECTOR5D:
				v2 = Unary();
				switch(v2.type) {
				case TYP_INT:	val.v5 = Vector5d::Scale(val.v5, (double)v2.i); break;
				case TYP_NUM:	val.v5 = Vector5d::Scale(val.v5, v2.d); break;
				default:
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case '/':
			switch(val.type) {
			case TYP_INT:
				v2 = Unary();
				if (v2.type==TYP_INT)
					val.i /= v2.i;
				else if (v2.type==TYP_NUM)
					val.i /= (int)v2.d;
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				break;
			case TYP_NUM:
				v2 = Unary();
				if (v2.type==TYP_INT)
					val.d /= (double)v2.i;
				else if (v2.type==TYP_NUM)
					val.d /= (int)v2.d;
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				break;
			}
			break;
		default:
			p = op; return val;
		}
	}
}

Value Parser::Addsub()
{
	Value val = Multdiv();
	Value v2;
	char *op;

	while (true) {
		op = p;
		switch (NextToken()) {
		case '+':
			v2 = Multdiv();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i += v2.i; break;
				case TYP_NUM:	val.i += (int)v2.d; break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d += (double)v2.i; break;
				case TYP_NUM:	val.d += v2.d; break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_COLOR:
				switch(v2.type) {
				case TYP_COLOR:	val.c = Color::Add(val.c, v2.c); break;
				case TYP_VECTOR:
								val.c.r += (float)v2.v3.x;
								val.c.g += (float)v2.v3.y;
								val.c.b += (float)v2.v3.z;
								break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_VECTOR:
				if (v2.type != TYP_VECTOR)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v3 = Vector::Add(val.v3,v2.v3);
				break;
			case TYP_VECTOR2D:
				if (v2.type != TYP_VECTOR2D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v2 = Vector2d::Add(val.v2,v2.v2);
				break;
			case TYP_VECTOR4D:
				if (v2.type != TYP_VECTOR4D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v4 = Vector4d::Add(val.v4,v2.v4);
				break;
			case TYP_VECTOR5D:
				if (v2.type != TYP_VECTOR5D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v5 = Vector5d::Add(val.v5,v2.v5);
				break;
			}
			break;
		case '-':
			v2 = Multdiv();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i -= v2.i; break;
				case TYP_NUM:	val.i -= (int)v2.d; break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d -= (double)v2.i; break;
				case TYP_NUM:	val.d -= v2.d; break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_COLOR:
				switch(v2.type) {
				case TYP_COLOR:	val.c = Color::Sub(val.c, v2.c); break;
				case TYP_VECTOR:
								val.c.r -= (float)v2.v3.x;
								val.c.g -= (float)v2.v3.y;
								val.c.b -= (float)v2.v3.z;
								break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
			}
			case TYP_VECTOR:
				if (v2.type != TYP_VECTOR)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v3 = Vector::Sub(val.v3,v2.v3);
				break;
			case TYP_VECTOR2D:
				if (v2.type != TYP_VECTOR2D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v2 = Vector2d::Sub(val.v2,v2.v2);
				break;
			case TYP_VECTOR4D:
				if (v2.type != TYP_VECTOR4D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v4 = Vector4d::Sub(val.v4,v2.v4);
				break;
			case TYP_VECTOR5D:
				if (v2.type != TYP_VECTOR5D)
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				val.v5 = Vector5d::Sub(val.v5,v2.v5);
				break;
			break;
		default:	p = op; return val;
		}
	}
}

Value Parser::Relational()
{
	Value val = Addsub();
	Value v2;
	char *op;

	while (true) {
		op = p;
		switch (NextToken()) {
		case '<':
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i < v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i < (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d < (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d < v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case TK_LE:
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i <= v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i <= (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d <= (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d <= v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case '>':
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i > v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i > (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d > (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d > v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case TK_GE:
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i >= v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i >= (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d >= (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d >= v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case TK_EQ:
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i == v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i == (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d == (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d == v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		case TK_NE:
			v2 = Addsub();
			switch(val.type) {
			case TYP_INT:
				switch(v2.type) {
				case TYP_INT:	val.i = val.i != v2.i ? 1 : 0; return (val);
				case TYP_NUM:	val.i = val.i != (int)v2.d ? 1 : 0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d = val.d != (double)v2.i ? 1.0 : 0.0; return (val);
				case TYP_NUM:	val.d = val.d != v2.d ? 1.0 : 0.0; return (val);
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
				break;
			}
			break;
		default:	p = op; return (val);
		}
	}
}

Value Parser::eval()
{
	return Relational();
}

Value Parser::ParseBuffer(char *buf)
{
	AnObject *obj, *fobj;
	Viewpoint *vp;
	ALight *light;
	Texture *tx;
	Color c;
	Symbol sym, *s;
	int nn;
	char *old_p;
	Value v;
	bool minus = false;

	p = buf;
	while (*p) {
		old_p = p;
		NextToken();
		switch(token) {
		case '-':
			minus = !minus;
			break;
		case TK_RAYTRACER:
			ParseRayTracer();
			v.type = TYP_INT;
			v.i = 0;
			if (level > 0) {
				return v;
			}
			break;
		case TK_CAMERA:
		case TK_VIEW_POINT:
			vp = ParseViewPoint();
			rayTracer.viewPoint = vp;
			v.type = TYP_VIEWPOINT;
			v.val.vp = vp;
			if (level > 0) {
				return v;
			}
			break;
		case TK_LIGHT:
			light = ParseLight();
			v.type = TYP_LIGHT;
			v.val.lt = light;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(light);
			break;
		case TK_SPHERE:
			obj = (AnObject *)ParseSphere();
			v.type = TYP_SPHERE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_TORUS:
			obj = (AnObject *)ParseTorus();
			v.type = TYP_TORUS;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_PLANE:
			obj = (AnObject *)ParsePlane();
			v.type = TYP_PLANE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_TRIANGLE:
			obj = (AnObject *)ParseTriangle();
			v.type = TYP_TRIANGLE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_RECTANGLE:
			obj = (AnObject *)ParseRectangle();
			v.type = TYP_RECTANGLE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_QUADRIC:
			obj = (AnObject *)ParseQuadric();
			v.type = TYP_QUADRIC;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_CONE:
			obj = (AnObject *)ParseCone();
			v.type = TYP_CONE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_BOX:
			obj = (AnObject *)ParseBox();
			v.type = TYP_BOX;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_CUBE:
			obj = (AnObject *)ParseCube();
			v.type = TYP_BOX;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_CYLINDER:
			obj = (AnObject *)ParseCylinder();
			v.type = TYP_CYLINDER;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_OBJECT:
			obj = ParseObject();
			v.type = TYP_OBJECT;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_UNION:
			obj = ParseObject();
			obj->type = OBJ_UNION;
			v.type = TYP_UNION;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_DIFFERENCE:
			obj = ParseObject();
			obj->type = OBJ_DIFFERENCE;
			v.type = TYP_DIFFERENCE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_INTERSECTION:
			obj = ParseObject();
			obj->type = OBJ_INTERSECTION;
			v.type = TYP_INTERSECTION;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			rayTracer.Add(obj->lights);
			break;
		case TK_COLOR:
			c = ParseColor();
			v.type = TYP_COLOR;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			break;

		case TK_BACKGROUND:
			Need('{');
			c = ParseColor();
			pRayTracer->backGround = c;
			Need('}');
			break;
/*
		case TK_VECTOR:
			v = ParseVector();
			if (level > 0) {
				*(Vector *)q = v;
				return TYP_VECTOR;
			}
			break;
*/
		case TK_TEXTURE:
			tx = ParseTexture(nullptr);
			v.type = TYP_TEXTURE;
			v.val.tx = tx;
			if (level > 0) {
				return v;
			}
			break;
		case TK_NUM:
			v.type = TYP_NUM;
			v.d = last_num;
			if (level > 0) {
				return v;
			}
			break;

		case TK_REPEAT:
			Need(TK_NUM);
			nn = (int)last_num;
			old_p = p;

			fobj = ParseObject();
			// The object was already added once so we count down one less
			for (; nn > 0; nn--) {
				p = old_p;
				obj = ParseObject();
				obj->next = fobj->obj;
				fobj->obj = obj;
			}
			v.type = TYP_OBJECT;
			v.val.obj = fobj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(fobj);
			rayTracer.Add(fobj->lights);
			break;

		case TK_FOR:
			rayTracer.Add(obj = ParseFor(nullptr));
			rayTracer.Add(obj->lights);
			break;

		case TK_ID:
			sym.varname = lastid;
			NextToken();
			if (token=='{') {
				s = rayTracer.symbolTable.Find(sym.varname);
				if (!s) {
					throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
				}
				switch(sym.value.type) {
				case TYP_TEXTURE:
					ParseTexture(s->value.val.tx);
					continue;
				case TYP_OBJECT:
					ParseObjectBody(s->value.val.obj);
					continue;
				}
			}
			else if (token == '!') {
				s = rayTracer.symbolTable.Find(sym.varname);
				if (!s) {
					throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
				}
				obj = new AnObject();
				InsertSymValue(s, obj, minus ? ~((s->value.type & 0x80) >> 7) : ((s->value.type & 0x80) >> 7));
				v.type = s->value.type & 0x7f;
				v.val.obj = obj;
				if (level > 0) {
					return v;
				}
				rayTracer.Add(obj);
				rayTracer.Add(obj->lights);
				break;
			}
			else if (token != '=') {
				throw gcnew Finray::FinrayException(ERR_ASSIGNMENT,0);
			}
			level++;
			sym.value = eval();
			level--;
			s = rayTracer.symbolTable.Find(sym.varname);
			if (s) {
				s->value = sym.value;
			}
			else
				rayTracer.symbolTable.Add(&sym);
			break;
		case TK_EOF:
			v.type = TYP_NONE;
			v.d = 0.0;
			return v;
		default:
			p = old_p;
			v = eval();
			return v;
		}
	}
	v.type = TYP_NONE;
	return v;
}

AnObject *Parser::ParseObject()
{
	AnObject *obj;

	obj = new AnObject();
	ParseObjectBody(obj);
	return obj;
}

/*
Vector *Parser::ParseVector()
{
	Symbol *sym;
	Vector *vector, v2, v3;

	switch(NextToken()) {
	case TK_ID:
		sym = rayTracer.symbolTable.Find(std::string(lastid));
		if (!sym)
			throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
		if (sym->type != TYP_VECTOR && sym->type != TYP_COLOR)
			throw gcnew Finray::FinrayException(ERR_MISMATCH_TYP,0);
		vector = new Vector();
		if (sym->type==TYP_COLOR) {
			vector->x = sym->value.c.r;
			vector->y = sym->value.c.g;
			vector->z = sym->value.c.b;
		}
		else
			*vector = *sym->value.v;
		break;

	case TK_RANDV:
		Need('<');
		v2.x = Unary();
		Need(',');
		v2.y = Unary();
		Need(',');
		v2.z = Unary();
		v3.x = (double)RTFClasses::Random::rand(2147483648) / 2147483648;
		v3.y = (double)RTFClasses::Random::rand(2147483648) / 2147483648;
		v3.z = (double)RTFClasses::Random::rand(2147483648) / 2147483648;
		vector = new Vector();
		vector->x = v3.x * v2.x;
		vector->y = v3.y * v2.y;
		vector->z = v3.z * v2.z;
		Need('>');
		break;

	case '<':
		vector = new Vector();
		vector->x = Unary();
		Need(',');
		vector->y = Unary();
		Need(',');
		vector->z = Unary();
		Need('>');
		break;
	default:
		throw gcnew Finray::FinrayException(ERR_SYNTAX,0);
	}
	return vector;
}
*/
void Parser::ParseRayTracer()
{
	Value v;

	Need('{');
	while(true) {
		switch(NextToken()) {
		case TK_FIRSTFRAME:
			v = eval();
			if (v.type != TYP_INT && v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			if (v.type==TYP_INT)
				pRayTracer->first_frame = v.i;
			else
				pRayTracer->first_frame = (int)v.d;
			if (pRayTracer->frameno < pRayTracer->first_frame)
				pRayTracer->frameno = pRayTracer->first_frame;
			break;
		case TK_LASTFRAME:
			v = eval();
			if (v.type != TYP_INT && v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			if (v.type==TYP_INT)
				pRayTracer->last_frame = v.i;
			else
				pRayTracer->last_frame = (int)v.d;
			break;
		case '}':
			return;
		default:
			throw gcnew Finray::FinrayException(ERR_SYNTAX, token);
		}
	}
}

Viewpoint *Parser::ParseViewPoint()
{
	Value v;
	Need('{');
	Viewpoint *viewpoint = new Viewpoint();

	while(true) {
		switch(NextToken()) {
		case TK_LOCATION:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->loc.x = v.v3.x;
			viewpoint->loc.y = v.v3.y;
			viewpoint->loc.z = v.v3.z;
			break;
		case TK_DIRECTION:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->dir.x = v.v3.x;
			viewpoint->dir.y = v.v3.y;
			viewpoint->dir.z = v.v3.z;
			break;
		case TK_UP:		
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->up.x = v.v3.x;
			viewpoint->up.y = v.v3.y;
			viewpoint->up.z = v.v3.z;
			break;
		case TK_RIGHT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->right.x = v.v3.x;
			viewpoint->right.y = v.v3.y;
			viewpoint->right.z = v.v3.z;
			break;
		case TK_LOOK_AT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->dir = Vector::Normalize(Vector::Sub(v.v3, viewpoint->loc));
			break;
		case '}':
			return viewpoint;
		default:
			throw gcnew Finray::FinrayException(ERR_SYNTAX, token);
		}
	}
	return viewpoint;
}

ALight *Parser::ParseLight()
{
	ALight *light;
	Value v;

	v = eval();
	if (v.type != TYP_VECTOR)
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	light = new ALight(v.v3.x,v.v3.y,v.v3.z,0.0,0.0,0.0);
	ParseObjectBody(light);
	return light;
}

AQuadric *Parser::ParseQuadric()
{
	AQuadric *quadric;
	Value v1,v2,v3,v4;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(',');
	v3 = eval();
	Need(',');
	v4 = eval();
	Need(')');
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR 
		|| v3.type != TYP_VECTOR || (v4.type != TYP_NUM && v2.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	quadric = new AQuadric(
		v1.v3.x, v1.v3.y, v1.v3.z,
		v2.v3.x, v2.v3.y, v2.v3.z,
		v3.v3.x, v3.v3.y, v3.v3.z,
		v4.d);
	ParseObjectBody(quadric);
	return quadric;
}

ASphere *Parser::ParseSphere()
{
	ASphere *sphere;
	Value v1,v2;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(')');
	if (v1.type != TYP_VECTOR || (v2.type != TYP_NUM && v2.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	if (v2.type==TYP_INT)
		sphere = new ASphere(v1.v3.x,v1.v3.y,v1.v3.z,(double)v2.i);
	else
		sphere = new ASphere(v1.v3.x,v1.v3.y,v1.v3.z,v2.d);
	ParseObjectBody(sphere);
	return sphere;
}

ATorus *Parser::ParseTorus()
{
	ATorus *torus;
	Value v1,v2;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(')');
	if ((v1.type != TYP_NUM && v1.type != TYP_INT) || (v2.type != TYP_NUM && v2.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	torus = new ATorus(
		(v1.type==TYP_INT ? (DBL)v1.i : v1.d),
		(v2.type==TYP_INT ? (DBL)v2.i : v2.d));
	ParseObjectBody(torus);
	return torus;
}

ACylinder *Parser::ParseCylinder()
{
	ACylinder *obj;
	Value v1,v2,v3;
	bool openA = false;
	bool openB = false;
	char *op;

	Need('(');
	v1 = eval();
	op = p;
	NextToken();
	if (token==TK_OPEN)
		openB = true;
	else
		p = op;
	Need(',');
	v2 = eval();
	op = p;
	NextToken();
	if (token==TK_OPEN)
		openA = true;
	else
		p = op;
	Need(',');
	v3 = eval();
	Need(')');
	op = p;
	NextToken();
	if (token==TK_OPEN) {
		openA = true;
		openB = true;
	}
	else
		p = op;
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR || (v3.type != TYP_NUM && v3.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	if (v3.type==TYP_INT)
		obj = new ACylinder(v1.v3,v2.v3,(double)v3.i);
	else
		obj = new ACylinder(v1.v3,v2.v3,v3.d);
	obj->openBase = openB;
	obj->openApex = openA;
	ParseObjectBody(obj);
	return obj;
}

ACone *Parser::ParseCone()
{
	ACone *obj;
	Value v1,v2,v3,v4;
	double ra, rb;
	bool openA = false;
	bool openB = false;
	char *op;

	Need('(');
	v1 = eval();
	op = p;
	NextToken();
	if (token==TK_OPEN)
		openB = true;
	else
		p = op;
	Need(',');
	v2 = eval();
	op = p;
	NextToken();
	if (token==TK_OPEN)
		openA = true;
	else
		p = op;
	Need(',');
	v3 = eval();
	Need(',');
	v4 = eval();
	Need(')');
	op = p;
	NextToken();
	if (token==TK_OPEN) {
		openA = true;
		openB = true;
	}
	else
		p = op;
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR
		|| (v3.type != TYP_NUM && v3.type != TYP_INT)
		|| (v4.type != TYP_NUM && v4.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	if (v3.type==TYP_INT)
		rb = (double)v3.i;
	else
		rb = v3.d;
	if (v4.type==TYP_INT)
		ra = (double)v4.i;
	else
		ra = v4.d;
	obj = new ACone(v1.v3,v2.v3,rb,ra);
	obj->openBase = openB;
	obj->openApex = openA;
	ParseObjectBody(obj);
	return obj;
}

APlane *Parser::ParsePlane()
{
	APlane *plane;
	Value v1,v2;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(')');
	if (v1.type != TYP_VECTOR || (v2.type != TYP_NUM && v2.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	if (v2.type==TYP_INT)
		plane = new APlane(v1.v3.x,v1.v3.y,v1.v3.z,(double)v2.i);
	else
		plane = new APlane(v1.v3.x,v1.v3.y,v1.v3.z,v2.d);
	ParseObjectBody(plane);
	return plane;
}

ATriangle *Parser::ParseTriangle()
{
	ATriangle *triangle;
	Value v1,v2,v3;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(',');
	v3 = eval();
	Need(')');
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR || v3.type != TYP_VECTOR)
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	triangle = new ATriangle(v1.v3, v2.v3, v3.v3);
	ParseObjectBody(triangle);
	return triangle;
}

ARectangle *Parser::ParseRectangle()
{
	ARectangle *rectangle;
	Value v1,v2,v3,v4;

	Need('(');
	v1 = eval();
	Need(',');
	v2 = eval();
	Need(',');
	v3 = eval();
	Need(',');
	v4 = eval();
	Need(')');
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR || v3.type != TYP_VECTOR || v4.type != TYP_VECTOR)
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	rectangle = new ARectangle(v1.v3, v2.v3, v3.v3, v4.v3);
	ParseObjectBody(rectangle);
	return rectangle;
}

Color Parser::ParseApproximate(AnObject *obj)
{
	Color color;
	Value v;

	switch(NextToken()) {
	case TK_COLOR:
		color = ParseColor();
//		obj->SetColor(color);
		v = eval();
		if (v.type==TYP_VECTOR) {
			color.r = (float)v.v3.x;
			color.g = (float)v.v3.y;
			color.b = (float)v.v3.z;
			obj->SetColorVariance(color);
			return color;
		}
		if (v.type == TYP_NUM) {
			color.r = (float)v.d;
			color.g = (float)v.d;
			color.b = (float)v.d;
			obj->SetColorVariance(color);
			return color;
		}
		break;
	default:
		throw gcnew Finray::FinrayException(ERR_SYNTAX,0);
	}
}

Finray::Pigment *Parser::ParsePigment()
{
	char *op;
	Pigment *pm = new Pigment;
	Value v;

	int token;
	Need('{');
	op = p;
	while((token = NextToken()) != '}') {
		switch(token) {
		case TK_COLOR:
			pm->color = ParseColor();
			break;
		case TK_COLORMAP:
			pm->cm = ParseColorMap();
			break;
		case TK_GRADIENT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			pm->gradient = v.v3;
			break;
		default:
			p = op;
			v = eval();
			switch(v.type) {
			case TYP_COLORMAP:	pm->cm = v.val.cm; break;
			case TYP_COLOR:		pm->color = v.c; break;
			default:
				delete pm;
				throw gcnew Finray::FinrayException(ERR_SYNTAX,0);
			}
		}
		op = p;
	}
	return pm;
}

Finray::Color Parser::ParseColor()
{
	Finray::Color color;
	Value v1;

	v1 = eval();
	switch(v1.type) {
	case TYP_COLOR:	return v1.c;
	case TYP_VECTOR:
		color.r = (float)v1.v3.x;
		color.g = (float)v1.v3.y;
		color.b = (float)v1.v3.z;
		return color;
	case TYP_INT:
		color.r = (float)v1.i;
		color.g = (float)v1.i;
		color.b = (float)v1.i;
		return color;
	case TYP_NUM:
		color.r = (float)v1.d;
		color.g = (float)v1.d;
		color.b = (float)v1.d;
		return color;
	default:
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	}
	return color;
}

Finray::ColorMap *Parser::ParseColorMap()
{
	DBL rng[256];
	Finray::Color clr[256];
	Finray::ColorMap *cm;
	Value v1;
	int nn;

	Need('{');
	for (nn = 0; NextToken()=='[' && nn < 256; nn++) {
		v1 = eval();
		if (v1.type != TYP_INT && v1.type != TYP_NUM)
			throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
		if (v1.type==TYP_INT)
			rng[nn] = (DBL)v1.i;
		else
			rng[nn] = v1.d;
		v1 = eval();
		if (v1.type != TYP_COLOR)
			throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
		clr[nn] = v1.c;
		Need(']');
	}
	Was('}');
	cm = new Finray::ColorMap(nn);
	for (--nn; nn >= 0; --nn) {
		cm->cme[nn].range = rng[nn];
		cm->cme[nn].color = clr[nn];
	}
	return cm;
}

ABox *Parser::ParseBox()
{
	Value v1,v2;
	char *op;
	ABox *box;

	op = p;
	NextToken();
	if (token=='(') {
		v1 = eval();
		Need(',');
		v2 = eval();
		Need(')');
		if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR)
			throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
		box = new ABox(v1.v3,v2.v3);
		ParseObjectBody(box);
		return box;
	}
	p = op;
	box = new ABox();
	ParseObjectBody(box);
	return box;
}

ABox *Parser::ParseCube()
{
	Value v1,v2,v3;
	char *op;
	ABox *cube;

	op = p;
	NextToken();
	if (token=='(') {
		v1 = eval();
		Need(',');
		v2 = eval();
		Need(')');
		if (v1.type != TYP_VECTOR || v2.type != TYP_NUM)
			throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
		cube = new ABox(v1.v3,Vector(v2.d,v2.d,v2.d));
		ParseObjectBody(cube);
		return cube;
	}
	p = op;
	cube = new ABox();
	ParseObjectBody(cube);
	return cube;
}

Color Parser::ParseAmbient()
{
	return ParseColor();
}

Texture *Parser::ParseTexture(Texture *texture)
{
	Value v;
	Transform lt;

	if (texture==nullptr)
		texture = new Texture;
	NextToken();
	if (token==TK_ID) {
		Symbol *sym = rayTracer.symbolTable.Find(lastid);
		if (!sym)
			throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
		texture->Copy(sym->value.val.tx);
		return texture;
	}
	Was('{');
	while (true) {
		switch(NextToken()) {
		case TK_COLOR:
			if (texture->pigment==nullptr)
				texture->pigment = new Pigment();
			texture->pigment->color = ParseColor();
			break;
		case TK_AMBIENT:	texture->ambient = ParseColor(); break;
		case TK_DIFFUSE:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->diffuse = (float)v.d;
			break;
		case TK_BRILLIANCE:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->brilliance = (float)v.d;
			break;
		case TK_ROUGHNESS:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->roughness = (float)v.d;
			break;
		case TK_REFLECTION:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->reflection = (float)v.d;
			break;
		case TK_SPECULAR:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->specular = (float)v.d;
			break;

		case TK_COLORMETHOD:
			v = eval();
			if (v.type != TYP_NUM)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->ColorMethod = (int)v.d;
			break;

		case TK_PIGMENT:
			texture->pigment = ParsePigment();
			break;

		case TK_CHECKER:
			v = eval();
			if (v.type != TYP_COLOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->color1 = v.c;
			v = eval();
			if (v.type != TYP_COLOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->color2 = v.c;
			texture->ColorMethod = TM_CHECKER;
			break;

		case TK_GRADIENT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->gradient = v.v3;
			texture->ColorMethod = TM_GRADIENT;
			break;

		case TK_TURBULENCE:
			v = eval();
			if (v.type != TYP_NUM && v.type != TYP_INT)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->turbulence = v.type==TYP_INT ? (double)v.i : v.d;
			break;

		case TK_SCALE:
			v = eval();
			if (v.type == TYP_VECTOR)
				lt.CalcScaling(v.v3);
			else if (v.type==TYP_NUM)
				lt.CalcScaling(Vector(v.d,v.d,v.d));
			else if (v.type==TYP_INT)
				lt.CalcScaling(Vector((DBL)v.i,(DBL)v.i,(DBL)v.i));
			else
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			texture->trans.Compose(&lt);
			texture->usesTransform = true;
			break;

		case TK_TRANSLATE:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			lt.CalcTranslation(v.v3);
			texture->trans.Compose(&lt);
			texture->usesTransform = true;
			break;

		case TK_ROTATE:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			lt.CalcRotation(v.v3);
			texture->trans.Compose(&lt);
			texture->usesTransform = true;
			break;
		case '}': return texture;
		default:	throw gcnew Finray::FinrayException(ERR_TEXTURE,0);
		}
	}
	return texture;
}

void Parser::ParseNoShadow2(AnObject *obj)
{
	AnObject *o = obj;
	while (o) {
		if (o->obj) {
			ParseNoShadow2(o->obj);
		}
		o->doShadows = false;
		o = o->next;
	}
}

void Parser::ParseNoShadow(AnObject *obj)
{
	ParseNoShadow2(obj->obj);
	obj->doShadows = false;
}

void Parser::ParseNoReflection2(AnObject *obj)
{
	AnObject *o = obj;
	while (o) {
		if (o->obj) {
			ParseNoReflection2(o->obj);
		}
		o->doReflections = false;
		o = o->next;
	}
}

void Parser::ParseNoReflection(AnObject *obj)
{
	ParseNoReflection2(obj->obj);
	obj->doReflections = false;
}

void Parser::InsertSymValue(Symbol *sym, AnObject *obj, bool minus)
{
	AnObject *o;
	Texture *tx;

	switch(sym->value.type) {
	case TYP_SPHERE:
	case TYP_TORUS:
	case TYP_PLANE:
	case TYP_TRIANGLE:
	case TYP_RECTANGLE:
	case TYP_QUADRIC:
	case TYP_CONE:
	case TYP_BOX:
	case TYP_CYLINDER:
	case TYP_UNION:
	case TYP_DIFFERENCE:
	case TYP_INTERSECTION:
		o = sym->value.val.obj;
		if (minus) {
			o->next = obj->negobj;
			obj->negobj = o;
		}
		else {
			o->next = obj->obj;
			obj->obj = o;
		}
		break;
	case TYP_TEXTURE:
		tx = sym->value.val.tx;
		obj->properties = *tx;
		break;
	case TYP_COLOR:
		if (obj->properties.pigment == nullptr)
			obj->properties.pigment = new Pigment;
		obj->properties.pigment->color = sym->value.c;
		break;
	}
}

void Parser::ParseObjectBody(AnObject *obj)
{
	AnObject *o;
	Texture *tx;
	Symbol *sym;
	ALight *light;
	ASphere *sphere;
	Color color;
	int nn;
	char *old_p;
	Value val;
	bool minus = false;

	if (obj==nullptr)
		throw gcnew Finray::FinrayException(ERR_NULLPTR, 0);
	Need('{');
	while(true) {
		switch(NextToken()) {
		case '-':
		case TK_ANTI:
			minus = !minus;
			break;
		case TK_ID:
			sym = rayTracer.symbolTable.Find(lastid);
			old_p = p;
			NextToken();
			if (!sym) {
				if (token=='=') {
					Symbol s;
					s.varname = lastid;
					level++;
					s.value = ParseBuffer(p);
					level--;
					rayTracer.symbolTable.Add(&s);
					break;
				}
				else {
					p = old_p;
					throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
				}
			}
			if (token=='=') {
				level++;
				sym->value = ParseBuffer(p);
				level--;
				break;
			}
			p = old_p;
			InsertSymValue(sym, obj, minus ? ~((sym->value.type & 0x80) >> 7) : ((sym->value.type & 0x80) >> 7));
			break;
		case TK_SPHERE:
			o = (AnObject *)ParseSphere();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
/*
			if (obj->obj) {
				o->next = obj->obj->next;
				obj->obj->next = o;
			}
			else
				obj->obj = o;
*/
			break;
		case TK_TORUS:
			o = (AnObject *)ParseTorus();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_PLANE:
			o = (AnObject *)ParsePlane();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_TRIANGLE:
			o = (AnObject *)ParseTriangle();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_RECTANGLE:
			o = (AnObject *)ParseRectangle();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_QUADRIC:
			o = (AnObject *)ParseQuadric();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_CONE:
			o = (AnObject *)ParseCone();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_BOX:
			o = (AnObject *)ParseBox();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_CUBE:
			o = (AnObject *)ParseCube();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_CYLINDER:
			o = (AnObject *)ParseCylinder();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_OBJECT:
			o = (AnObject *)ParseObject();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_UNION:
			o = (AnObject *)ParseObject();
			if (minus) {
				o->next = obj->negobj;
				obj->negobj = o;
			}
			else {
				o->next = obj->obj;
				obj->obj = o;
			}
			break;
		case TK_TRANSLATE:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			obj->Translate(val.v3.x, val.v3.y, val.v3.z);
			break;
		case TK_ROTATE:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			obj->RotXYZ(val.v3.x, val.v3.y, val.v3.z);
			break;

		case TK_SCALE:
			val = eval();
			if (val.type == TYP_VECTOR)
				obj->Scale(val.v3);
			else if (val.type == TYP_NUM)
				obj->Scale(Vector(val.d,val.d,val.d));
			else if (val.type == TYP_INT)
				obj->Scale(Vector((DBL)val.i,(DBL)val.i,(DBL)val.i));
			else
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			break;

		case TK_TEXTURE:	tx = ParseTexture(nullptr);
//							obj->properties = *tx;
							obj->SetTexture(tx);
							delete tx;
							break;
		case TK_COLOR:
			if (obj->properties.pigment ==nullptr)
				obj->properties.pigment = new Pigment();
			obj->properties.pigment->color = ParseColor();
//			ParseColor();
//			obj->SetColor(color);
//			obj->properties.color = color;
			break;
		case TK_APPROXIMATE:
			color = ParseApproximate(obj);
			obj->SetColorVariance(color);
			break;
		case TK_LOCATION:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			switch(obj->type) {
			case OBJ_SPHERE:
				sphere = (ASphere *)obj;
				sphere->center.x =  val.v3.x;
				sphere->center.y =  val.v3.y;
				sphere->center.z =  val.v3.z;
				break;
			case OBJ_LIGHT:
				light = (ALight *)obj;
				light->center.x = val.v3.x;
				light->center.y = val.v3.y;
				light->center.z = val.v3.z;
				break;
			}
			break;
		case TK_LIGHT_SOURCE:
			switch(obj->type) {
			case OBJ_SPHERE:
				sphere = (ASphere *)obj;
				if (obj->properties.pigment)
					light = new ALight(
						sphere->center.x,
						sphere->center.y,
						sphere->center.z,
						obj->properties.pigment->color.r,
						obj->properties.pigment->color.g,
						obj->properties.pigment->color.b);
				else
					light = new ALight(
						sphere->center.x,
						sphere->center.y,
						sphere->center.z,
						1.0f,
						1.0f,
						1.0f);
				light->next = obj->lights;
				obj->lights = light;
				break;
			}
			break;

		case TK_LIGHT:
			light = ParseLight();
			light->next = obj->lights;
			obj->lights = light;
			break;

		case TK_REPEAT:
			Need(TK_NUM);
			nn = (int)last_num;
			old_p = p;
			for (; nn >= 0; nn--) {
				p = old_p;
				o = ParseObject();
				o->next = obj->obj;
				obj->obj = o;
			}
			break;

		case TK_FOR:	ParseFor(obj);	break;
		case TK_IF:		ParseIf(obj); break;

		case TK_NO_SHADOW:
			ParseNoShadow(obj);
			break;
		case TK_NO_REFLECTION:
			ParseNoReflection(obj);
			break;

		case '}':
			return;
		}
	}
}

AnObject *Parser::ParseIf(AnObject *obj)
{
	Value v;
	int tk;
	bool tf;
	bool throwaway;
	AnObject *eiobj = nullptr;
	AnObject *tobj;	// The one true object
	char *op;

	if (obj == nullptr)
		obj = new AnObject();
	v = eval();
	Need(TK_THEN);
	eiobj = new AnObject();
	ParseObjectBody(eiobj);
	switch(v.type) {
	case TYP_INT:	tf = v.i != 0; break;
	case TYP_NUM:	tf = fabs(v.d) > 1e-10; break;
	default:
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	}
	if (tf) tobj = eiobj;
	if (tf) throwaway = true;
	op = p;
	tk = NextToken();
	while (tk==TK_ELSEIF) {
		v = eval();
		Need(TK_THEN);
		eiobj = new AnObject();
		ParseObjectBody(eiobj);
		// Some previous IF/ELSEIF statement was true, we don't care what this test
		// result was. Discard subsequent objects.
		if (throwaway) {
			delete eiobj;
			eiobj = nullptr;
		}
		else {
			switch(v.type) {
			case TYP_INT:	tf = v.i != 0; break;
			case TYP_NUM:	tf = fabs(v.d) > 1e-10; break;
			default:
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			}
			if (tf) {
				tobj = eiobj;
				eiobj = nullptr;
				throwaway = true;
			}
			// the ELSEIF wasn't true. Get rid of the elseif object
			else {
				delete eiobj;
				eiobj = nullptr;
			}
		}
		op = p;
		tk = NextToken();
	}
	if (tk==TK_ELSE) {
		eiobj = new AnObject();
		ParseObjectBody(eiobj);
		// Some previous IF/ELSEIF statement was true, we don't care what this test
		// result was. Discard subsequent objects.
		if (throwaway) {
			delete eiobj;
			eiobj = nullptr;
		}
		else {
			tobj = eiobj;
		}
	}
	else 
		p = op;
	if (tobj) {
		tobj->next = obj->obj;
		obj->obj = tobj;
	}
	return obj;
}

AnObject *Parser::ParseFor(AnObject *obj)
{
	Symbol sym, *s;
	int lmt;
	char *old_p;
	Value val;

	Need(TK_ID);
	sym.varname = lastid;
	Need('=');
	val = eval();
	if (val.type != TYP_NUM)
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	sym.value.i = (int)val.d;
	sym.value.type = TYP_INT;
	Need(TK_TO);
	val = eval();
	if (val.type != TYP_NUM)
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	lmt = (int)val.d;
	s = rayTracer.symbolTable.Find(sym.varname);
	if (s) {
		s->value.type = sym.value.type;
		s->value.i = sym.value.i;
	}
	else {
		rayTracer.symbolTable.Add(&sym);
		s = rayTracer.symbolTable.Find(sym.varname);
	}
	old_p = p;
	if (obj == nullptr) {
		obj = new AnObject();
	}
	while (sym.value.i <= lmt) {
		p = old_p;
		ParseObjectBody(obj);
		sym.value.i++;
		s->value.i++;
	}
	return obj;
}

void Parser::Parse(String^ fnme)
{
	std::ifstream fs;
	std::string fname;
	AnObject obj;

	char* str = (char*)(void*)Marshal::StringToHGlobalAnsi(fnme);
	fname = str;
	memset(master_filebuf,0,sizeof(master_filebuf));
	fs.open(fname, std::ios::in);
	fs.read(master_filebuf,sizeof(master_filebuf));
	fs.close();
	ParseBuffer(master_filebuf);
//	rayTracer.viewPoint = viewpoint;
	if (rayTracer.viewPoint==nullptr) {
		throw gcnew Finray::FinrayException(ERR_NOVIEWPOINT, 0);
	}
/*
	else {
		char buf [2000];
		Viewpoint *viewPoint = rayTracer.viewPoint;
		sprintf(buf, "loc (%3.3g y=%3.3g z= %3.3g)\n"
					 "dir (%3.3g y=%3.3g z= %3.3g)\n"
					 "up (%3.3g y=%3.3g z= %3.3g)\n"
					 "right (%3.3g y=%3.3g z= %3.3g)\n",
					 viewPoint->loc.x, viewPoint->loc.y, viewPoint->loc.z,
					 viewPoint->dir.x, viewPoint->dir.y, viewPoint->dir.z,
					 viewPoint->up.x, viewPoint->up.y, viewPoint->up.z,
					 viewPoint->right.x, viewPoint->right.y, viewPoint->right.z
					 );
		frmError^ form = gcnew frmError();
		form->msg = buf;
		form->ShowDialog();
	}
*/
}

};

