#include "stdafx.h"
#include "frmError.h"

extern Finray::RayTracer rayTracer;
static char numstr[100];
static char *numstrptr;
static char backup_token = 0;
extern Finray::Color backGround;
extern char master_filebuf[10000000];

namespace Finray {

Parser::Parser()
{
	mfp = 0;
	level = 0;
	RTFClasses::Random::srand((RANDOM_TYPE)time(NULL));
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
                if (p[0]=='.')
                     goto j1;
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
					p++;
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
			return token = '=';
		}
		if (p[0]=='-') {
			p++;
			return token = '-';
		}
		if (p[0]=='<') {
			p++;
			return token = '<';
		}
		if (p[0]=='>') {
			p++;
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

		// ambient anti
		if (p[0]=='a') {
			if (p[1]=='m' && p[2]=='b' && p[3]=='i' && p[4]=='e' && p[5]=='n' && p[6]=='t' && !isidch(p[7])) {
				p += 7;
				return token = TK_AMBIENT;
			}
			if (p[1]=='n' && p[2]=='t' && p[3]=='i' && !isidch(p[4])) {
				p += 4;
				return token = TK_ANTI;
			}
		}
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
		// camera color colour cone cylinder
		if (p[0]=='c') {
			if (p[1]=='a' && p[2]=='m' && p[3]=='e' && p[4]=='r' && p[5]=='a' && !isidch(p[6])) {
				p += 6;
				return token = TK_CAMERA;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='r' && !isidch(p[5])) {
				p += 5;
				return token = TK_COLOR;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='u' && p[5]=='r' && !isidch(p[6])) {
				p += 6;
				return token = TK_COLOR;
			}
			if (p[1]=='o' && p[2]=='n' && p[3]=='e' && !isidch(p[4])) {
				p += 4;
				return token = TK_CONE;
			}
			if (p[1]=='y' && p[2]=='l' && p[3]=='i' && p[4]=='n' && p[5]=='d' && p[6]=='e' && p[7]=='r' && !isidch(p[8])) {
				p += 8;
				return token = TK_CYLINDER;
			}
		}
		if (p[0]=='d' && p[1]=='i' && p[2]=='f' && p[3]=='f' && p[4]=='u' && p[5]=='s' && p[6]=='e' && !isidch(p[7])) {
			p += 7;
			return token = TK_DIFFUSE;
		}
		if (p[0]=='f' && p[1]=='o' && p[2]=='r' && !isidch(p[3])) {
			p += 3;
			return token = TK_FOR;
		}
		if (p[0]=='d' && p[1]=='i' && p[2]=='r' && p[3]=='e' && p[4]=='c' && p[5]=='t' && p[6]=='i' && p[7]=='o' && p[8]=='n' && !isidch(p[9])) {
			p += 9;
			return token = TK_DIRECTION;
		}
		if (p[0]=='i' && p[1]=='n' && p[2]=='c' && p[3]=='l' && p[4]=='u' && p[5]=='d' && p[6]=='e' && !isidch(p[7])) {
			p += 7;
			return token = TK_INCLUDE;
		}
		// light location look_at
		if (p[0]=='l') {
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' && !isidch(p[5])) {
				p += 5;
				return token = TK_LIGHT;
			}
			if (p[1]=='o' && p[2]=='c' && p[3]=='a' && p[4]=='t' && p[5]=='i' && p[6]=='o' && p[7]=='n' && !isidch(p[8])) {
				p += 8;
				return token = TK_LOCATION;
			}
			if (p[1]=='o' && p[2]=='o' && p[3]=='k' && p[4]=='_' && p[5]=='a' && p[6]=='t' && !isidch(p[7])) {
				p += 7;
				return token = TK_LOOK_AT;
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
		if (p[0]=='p' && p[1]=='l' && p[2]=='a' && p[3]=='n' && p[4]=='e' && !isidch(p[5])) {
			p += 5;
			return token = TK_PLANE;
		}
		if (p[0]=='q' && p[1]=='u' && p[2]=='a' && p[3]=='d' && p[4]=='r' && p[5]=='i' && p[6]=='c' && !isidch(p[7])) {
			p += 7;
			return token = TK_QUADRIC;
		}
		// rectangle reflection right rotate roughness
		if (p[0]=='r') {
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
		if (p[0]=='s' && p[1]=='p' && p[2]=='e' && p[3]=='c' && p[4]=='u' && p[5]=='l' && p[6]=='a' && p[7]=='r' && !isidch(p[8])) {
			p += 8;
			return token = TK_SPECULAR;
		}
		if (p[0]=='s' && p[1]=='p' && p[2]=='h' && p[3]=='e' && p[4]=='r' && p[5]=='e' && !isidch(p[6])) {
			p += 6;
			return token = TK_SPHERE;
		}
		// texture to translate triangle
		if (p[0]=='t') {
			if (p[1]=='e' && p[2]=='x' && p[3]=='t' && p[4]=='u' && p[5]=='r' && p[6]=='e' && !isidch(p[7])) {
				p += 7;
				return token = TK_TEXTURE;
			}
			if (p[1]=='o' && !isidch(p[2])) {
				p += 2;
				return token = TK_TO;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='n' && p[4]=='s' && p[5]=='l' && p[6]=='a' && p[7]=='t' && p[8]=='e' && !isidch(p[9])) {
				p += 9;
				return token = TK_TRANSLATE;
			}
			if (p[1]=='r' && p[2]=='i' && p[3]=='a' && p[4]=='n' && p[5]=='g' && p[6]=='l' && p[7]=='e' && !isidch(p[8])) {
				p += 8;
				return token = TK_TRIANGLE;
			}
		}
		if (p[0]=='v' && p[1]=='i' && p[2]=='e' && p[3]=='w' && p[4]=='_'
			&& p[5]=='p' && p[6]=='o' && p[7]=='i' && p[8]=='n' && p[9]=='t' && !isidch(p[10])) {
			p += 10;
			return token = TK_VIEW_POINT;
		}
		if (p[0]=='u' && p[1]=='p' && !isidch(p[2])) {
			p += 2;
			return token = TK_UP;
		}
        if(isidch(p[0])) {
			getid();
			return token = TK_ID;
		}
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
	Surface *tx;

	while (true) {
		op = p;
		switch(NextToken()) {

		case TK_ID:
			sym = rayTracer.symbolTable.Find(std::string(lastid));
			if (!sym)
				throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
			return sym->value;

		case TK_RANDV:
			Need('(');
			v2 = eval();
			minvalv = v2.v;
			Need(',');
			v2 = eval();
			maxvalv = v2.v;
			Need(')');
			v2.v.x = (maxvalv.x-minvalv.x) * (double)RTFClasses::Random::rand(2147483648) / 2147483648 + minvalv.x;
			v2.v.y = (maxvalv.y-minvalv.y) * (double)RTFClasses::Random::rand(2147483648) / 2147483648 + minvalv.y;
			v2.v.z = (maxvalv.x-minvalv.z) * (double)RTFClasses::Random::rand(2147483648) / 2147483648 + minvalv.z;
			v2.type = TYP_VECTOR;
			return v2;

			// Fall through
		case '<':
			v2 = eval();
			v.v.x = v2.d;
			Need(',');
			v2 = eval();
			v.v.y = v2.d;
			Need(',');
			v2 = eval();
			v.v.z = v2.d;
			Need('>');
			v.type = TYP_VECTOR;
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
					v2.v = Vector::Neg(v2.v);
				break;
			}
			return v2;

		case '-':
			minus = !minus;
			break;

		case TK_RAND:
			Need('(');
			v2 = eval();
			minval = v2.d;
			Need(',');
			v2 = eval();
			maxval = v2.d;
			Need(')');
			last_num = (maxval-minval) * (double)RTFClasses::Random::rand(2147483648) / 2147483648 + minval;
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
			v = eval();
			if (v.type==TYP_VECTOR) {
				v2.c.r = (float)v.v.x;
				v2.c.g = (float)v.v.y;
				v2.c.b = (float)v.v.z;
			}
			else if (v.type==TYP_COLOR) {
				v2.c = v.c;
			}
			else if (v.type==TYP_NUM) {
				v2.c.r = (float)v.d;
				v2.c.g = (float)v.d;
				v2.c.b = (float)v.d;
			}
			else if (v.type==TYP_INT) {
				v2.c.r = (float)v.i;
				v2.c.g = (float)v.i;
				v2.c.b = (float)v.i;
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
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				break;
			case TYP_NUM:
				v2 = Unary();
				if (v2.type==TYP_INT)
					val.d *= (double)v2.i;
				else if (v2.type==TYP_NUM)
					val.d *= (int)v2.d;
				else
					throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
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
			case TYP_NUM:
				switch(v2.type) {
				case TYP_INT:	val.d += (double)v2.i; break;
				case TYP_NUM:	val.d += v2.d; break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
			case TYP_COLOR:
				switch(v2.type) {
				case TYP_COLOR:	val.c = Color::Add(val.c, v2.c); break;
				case TYP_VECTOR:
								val.c.r += (float)v2.v.x;
								val.c.g += (float)v2.v.y;
								val.c.b += (float)v2.v.z;
								break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
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
								val.c.r -= (float)v2.v.x;
								val.c.g -= (float)v2.v.y;
								val.c.b -= (float)v2.v.z;
								break;
				default:	throw gcnew Finray::FinrayException(ERR_ILLEGALOP,0);
				}
			}
			break;
		default:	p = op; return val;
		}
	}
}

Value Parser::eval()
{
	return Addsub();
}

Value Parser::ParseBuffer(char *buf)
{
	AnObject *obj, *fobj;
	Viewpoint *vp;
	ALight *light;
	Surface *tx;
	Color c;
	Symbol sym, *s;
	int nn;
	char *old_p;
	Value v;

	p = buf;
	while (*p) {
		old_p = p;
		NextToken();
		switch(token) {
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
			break;
		case TK_PLANE:
			obj = (AnObject *)ParsePlane();
			v.type = TYP_PLANE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_TRIANGLE:
			obj = (AnObject *)ParseTriangle();
			v.type = TYP_TRIANGLE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_RECTANGLE:
			obj = (AnObject *)ParseRectangle();
			v.type = TYP_RECTANGLE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_QUADRIC:
			obj = (AnObject *)ParseQuadric();
			v.type = TYP_QUADRIC;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_CONE:
			obj = (AnObject *)ParseCone();
			v.type = TYP_CONE;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_CYLINDER:
			obj = (AnObject *)ParseCylinder();
			v.type = TYP_CYLINDER;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
			break;
		case TK_OBJECT:
			obj = ParseObject();
			v.type = TYP_OBJECT;
			v.val.obj = obj;
			if (level > 0) {
				return v;
			}
			rayTracer.Add(obj);
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
			backGround = ParseColor();
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
			break;

		case TK_FOR:
			rayTracer.Add(ParseFor(nullptr));
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
			viewpoint->loc.x = v.v.x;
			viewpoint->loc.y = v.v.y;
			viewpoint->loc.z = v.v.z;
			break;
		case TK_DIRECTION:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->dir.x = v.v.x;
			viewpoint->dir.y = v.v.y;
			viewpoint->dir.z = v.v.z;
			break;
		case TK_UP:		
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->up.x = v.v.x;
			viewpoint->up.y = v.v.y;
			viewpoint->up.z = v.v.z;
			break;
		case TK_RIGHT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->right.x = v.v.x;
			viewpoint->right.y = v.v.y;
			viewpoint->right.z = v.v.z;
			break;
		case TK_LOOK_AT:
			v = eval();
			if (v.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			viewpoint->dir = Vector::Normalize(Vector::Sub(v.v, viewpoint->loc));
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
	light = new ALight(v.v.x,v.v.y,v.v.z,0.0,0.0,0.0);
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
		v1.v.x, v1.v.y, v1.v.z,
		v2.v.x, v2.v.y, v2.v.z,
		v3.v.x, v3.v.y, v3.v.z,
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
		sphere = new ASphere(v1.v.x,v1.v.y,v1.v.z,(double)v2.i);
	else
		sphere = new ASphere(v1.v.x,v1.v.y,v1.v.z,v2.d);
	ParseObjectBody(sphere);
	return sphere;
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
	if (v1.type != TYP_VECTOR || v2.type != TYP_VECTOR || (v3.type != TYP_NUM && v3.type != TYP_INT))
		throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
	if (v3.type==TYP_INT)
		obj = new ACylinder(v1.v,v2.v,(double)v3.i);
	else
		obj = new ACylinder(v1.v,v2.v,v3.d);
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
	obj = new ACone(v1.v,v2.v,rb,ra);
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
		plane = new APlane(v1.v.x,v1.v.y,v1.v.z,(double)v2.i);
	else
		plane = new APlane(v1.v.x,v1.v.y,v1.v.z,v2.d);
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
	triangle = new ATriangle(v1.v, v2.v, v3.v);
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
	rectangle = new ARectangle(v1.v, v2.v, v3.v, v4.v);
	ParseObjectBody(rectangle);
	return rectangle;
}

Color Parser::ParseColor()
{
	Color color;
	Value v1;

	v1 = eval();
	switch(v1.type) {
	case TYP_COLOR:	return v1.c;
	case TYP_VECTOR:
		color.r = (float)v1.v.x;
		color.g = (float)v1.v.y;
		color.b = (float)v1.v.z;
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
}

Color Parser::ParseAmbient()
{
	return ParseColor();
}

Surface *Parser::ParseTexture(Surface *texture)
{
	Value v;

	if (texture==nullptr)
		texture = new Surface;
	NextToken();
	if (token==TK_ID) {
		Symbol *sym = rayTracer.symbolTable.Find(lastid);
		if (!sym)
			throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
		texture->color = sym->value.val.tx->color;
		texture->ambient = sym->value.val.tx->ambient;
		texture->diffuse = sym->value.val.tx->diffuse;
		texture->brilliance = sym->value.val.tx->brilliance;
		texture->roughness = sym->value.val.tx->roughness;
		texture->reflection = sym->value.val.tx->reflection;
		texture->specular = sym->value.val.tx->specular;
		return texture;
	}
	Was('{');
	while (true) {
		switch(NextToken()) {
		case TK_COLOR:		texture->color = ParseColor(); break;
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
		case '}': return texture;
		default:	throw gcnew Finray::FinrayException(ERR_TEXTURE,0);
		}
	}
	return texture;
}

void Parser::ParseObjectBody(AnObject *obj)
{
	AnObject *o;
	Surface *tx;
	Symbol *sym;
	ALight *light;
	ASphere *sphere;
	Color color;
	int nn;
	char *old_p;
	Value val;
	bool minus = false;

	Need('{');
	while(true) {
		switch(NextToken()) {
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
			switch(sym->value.type) {
			case TYP_SPHERE:
			case TYP_PLANE:
			case TYP_TRIANGLE:
			case TYP_RECTANGLE:
			case TYP_QUADRIC:
			case TYP_CONE:
			case TYP_CYLINDER:
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
				obj->properties.color = sym->value.c;
				break;
			}
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
		case TK_TRANSLATE:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			obj->Translate(val.v.x, val.v.y, val.v.z);
			break;
		case TK_ROTATE:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			obj->RotXYZ(val.v.x, val.v.y, val.v.z);
			break;
		case TK_TEXTURE:	tx = ParseTexture(nullptr);
							obj->properties = *tx;
							delete tx;
							break;
		case TK_COLOR:	
			color = ParseColor();
			obj->properties.color = color;
			break;
		case TK_LOCATION:
			val = eval();
			if (val.type != TYP_VECTOR)
				throw gcnew Finray::FinrayException(ERR_BADTYPE,0);
			switch(obj->type) {
			case OBJ_SPHERE:
				sphere = (ASphere *)obj;
				sphere->center.x =  val.v.x;
				sphere->center.y =  val.v.y;
				sphere->center.z =  val.v.z;
				break;
			case OBJ_LIGHT:
				light = (ALight *)obj;
				light->center.x = val.v.x;
				light->center.y = val.v.y;
				light->center.z = val.v.z;
				break;
			}
			break;
		case TK_LIGHT_SOURCE:
			switch(obj->type) {
			case OBJ_SPHERE:
				sphere = (ASphere *)obj;
				new ALight(
					sphere->center.x,
					sphere->center.y,
					sphere->center.z,
					obj->properties.color.r,
					obj->properties.color.g,
					obj->properties.color.b);
				break;
			}
			break;

		case TK_REPEAT:
			Need(TK_NUM);
			nn = last_num;
			old_p = p;
			for (; nn >= 0; nn--) {
				p = old_p;
				o = ParseObject();
				o->next = obj->obj;
				obj->obj = o;
			}
			break;

		case TK_FOR:
			ParseFor(obj);
			break;

		case '}': return;
		}
	}
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
	while (sym.value.i < lmt) {
		p = old_p;
		ParseObjectBody(obj);
		sym.value.i++;
		s->value.i++;
	}
	return obj;
}

void Parser::Parse(std::string fname)
{
	std::ifstream fs;
	AnObject obj;

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
