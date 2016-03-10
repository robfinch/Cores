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
		if (p[0]=='a' && p[1]=='m' && p[2]=='b' && p[3]=='i' && p[4]=='e' && p[5]=='n' && p[6]=='t' && isspace(p[7])) {
			p += 7;
			return token = TK_AMBIENT;
		}
		if (p[0]=='b' && p[1]=='r' && p[2]=='i' && p[3]=='l' && p[4]=='l'
			&& p[5]=='i' && p[6]=='a' && p[7]=='n' && p[8]=='c' && p[9]=='e' && isspace(p[10])) {
			p += 10;
			return token = TK_BRILLIANCE;
		}
		if (p[0]=='b' && p[1]=='a' && p[2]=='c' && p[3]=='k' && p[4]=='g'
			&& p[5]=='r' && p[6]=='o' && p[7]=='u' && p[8]=='n' && p[9]=='d' && isspace(p[10])) {
			p += 10;
			return token = TK_BACKGROUND;
		}
		// camera color colour
		if (p[0]=='c') {
			if (p[1]=='a' && p[2]=='m' && p[3]=='e' && p[4]=='r' && p[5]=='a' && isspace(p[6])) {
				p += 6;
				return token = TK_CAMERA;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='r' && isspace(p[5])) {
				p += 5;
				return token = TK_COLOR;
			}
			if (p[1]=='o' && p[2]=='l' && p[3]=='o' && p[4]=='u' && p[5]=='r' && isspace(p[6])) {
				p += 6;
				return token = TK_COLOR;
			}
		}
		if (p[0]=='d' && p[1]=='i' && p[2]=='f' && p[3]=='f' && p[4]=='u' && p[5]=='s' && p[6]=='e' && isspace(p[7])) {
			p += 7;
			return token = TK_DIFFUSE;
		}
		if (p[0]=='f' && p[1]=='o' && p[2]=='r' && isspace(p[3])) {
			p += 3;
			return token = TK_FOR;
		}
		if (p[0]=='d' && p[1]=='i' && p[2]=='r' && p[3]=='e' && p[4]=='c' && p[5]=='t' && p[6]=='i' && p[7]=='o' && p[8]=='n' && isspace(p[9])) {
			p += 9;
			return token = TK_DIRECTION;
		}
		if (p[0]=='i' && p[1]=='n' && p[2]=='c' && p[3]=='l' && p[4]=='u' && p[5]=='d' && p[6]=='e' && isspace(p[7])) {
			p += 7;
			return token = TK_INCLUDE;
		}
		// light location look_at
		if (p[0]=='l') {
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' && isspace(p[5])) {
				p += 5;
				return token = TK_LIGHT;
			}
			if (p[1]=='o' && p[2]=='c' && p[3]=='a' && p[4]=='t' && p[5]=='i' && p[6]=='o' && p[7]=='n' && isspace(p[8])) {
				p += 8;
				return token = TK_LOCATION;
			}
			if (p[1]=='o' && p[2]=='o' && p[3]=='k' && p[4]=='_' && p[5]=='a' && p[6]=='t' && isspace(p[7])) {
				p += 7;
				return token = TK_LOOK_AT;
			}
		}
		if (p[0]=='o' && p[1]=='b' && p[2]=='j' && p[3]=='e' && p[4]=='c' && p[5]=='t' && isspace(p[6])) {
			p += 6;
			return token = TK_OBJECT;
		}
		if (p[0]=='p' && p[1]=='l' && p[2]=='a' && p[3]=='n' && p[4]=='e' && isspace(p[5])) {
			p += 5;
			return token = TK_PLANE;
		}
		if (p[0]=='q' && p[1]=='u' && p[2]=='a' && p[3]=='d' && p[4]=='r' && p[5]=='i' && p[6]=='c' && isspace(p[7])) {
			p += 7;
			return token = TK_QUADRIC;
		}
		// rectangle reflection right rotate roughness
		if (p[0]=='r') {
			if (p[1]=='e' && p[2]=='c' && p[3]=='t' && p[4]=='a' && p[5]=='n' && p[6]=='g' && p[7]=='l' && p[8]=='e' && isspace(p[9])) {
				p += 9;
				return token = TK_RECTANGLE;
			}
			if (p[1]=='a' && p[2]=='n' && p[3]=='d' && isspace(p[4])) {
				p += 4;
				return TK_RAND;
			}
			if (p[1]=='a' && p[2]=='n' && p[3]=='d' && p[4]=='v' && isspace(p[5])) {
				p += 5;
				return TK_RANDV;
			}
			if (p[1]=='e' && p[2]=='f' && p[3]=='l' && p[4]=='e'
				&& p[5]=='c' && p[6]=='t' && p[7]=='i' && p[8]=='o' && p[9]=='n' && isspace(p[10])) {
				p += 10;
				return token = TK_REFLECTION;
			}
			if (p[1]=='e' && p[2]=='p' && p[3]=='e' && p[4]=='a' && p[5]=='t' && isspace(p[6])) {
				p += 6;
				return token = TK_REPEAT;
			}
			if (p[1]=='i' && p[2]=='g' && p[3]=='h' && p[4]=='t' && isspace(p[5])) {
				p += 5;
				return token = TK_RIGHT;
			}
			if (p[1]=='o' && p[2]=='t' && p[3]=='a' && p[4]=='t' && p[5]=='e' && isspace(p[6])) {
				p += 6;
				return token = TK_ROTATE;
			}
			if (p[1]=='o' && p[2]=='u' && p[3]=='g' && p[4]=='h' && p[5]=='n' && p[6]=='e' && p[7]=='s' && p[8]=='s' && isspace(p[9])) {
				p += 9;
				return token = TK_ROUGHNESS;
			}
		}
		if (p[0]=='s' && p[1]=='p' && p[2]=='e' && p[3]=='c' && p[4]=='u' && p[5]=='l' && p[6]=='a' && p[7]=='r' && isspace(p[8])) {
			p += 8;
			return token = TK_SPECULAR;
		}
		if (p[0]=='s' && p[1]=='p' && p[2]=='h' && p[3]=='e' && p[4]=='r' && p[5]=='e' && isspace(p[6])) {
			p += 6;
			return token = TK_SPHERE;
		}
		// texture to translate triangle
		if (p[0]=='t') {
			if (p[1]=='e' && p[2]=='x' && p[3]=='t' && p[4]=='u' && p[5]=='r' && p[6]=='e' && isspace(p[7])) {
				p += 7;
				return token = TK_TEXTURE;
			}
			if (p[1]=='o' && isspace(p[2])) {
				p += 2;
				return token = TK_TO;
			}
			if (p[1]=='r' && p[2]=='a' && p[3]=='n' && p[4]=='s' && p[5]=='l' && p[6]=='a' && p[7]=='t' && p[8]=='e' && isspace(p[9])) {
				p += 9;
				return token = TK_TRANSLATE;
			}
			if (p[1]=='r' && p[2]=='i' && p[3]=='a' && p[4]=='n' && p[5]=='g' && p[6]=='l' && p[7]=='e' && isspace(p[8])) {
				p += 8;
				return token = TK_TRIANGLE;
			}
		}
		if (p[0]=='v' && p[1]=='i' && p[2]=='e' && p[3]=='w' && p[4]=='_'
			&& p[5]=='p' && p[6]=='o' && p[7]=='i' && p[8]=='n' && p[9]=='t' && isspace(p[10])) {
			p += 10;
			return token = TK_VIEW_POINT;
		}
		if (p[0]=='u' && p[1]=='p' && isspace(p[2])) {
			p += 2;
			return token = TK_UP;
		}
        if(isidch(p[0])) {
			getid();
			return token = TK_ID;
		}
	}
}

double Parser::Unary()
{
	bool minus = false;
	double val = 0;
	double minval,maxval;
	Symbol *sym;
	char *op;

	while (true) {
		op = p;
		switch(NextToken()) {
		case TK_ID:
			sym = rayTracer.symbolTable.Find(std::string(lastid));
			if (!sym)
				throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
			if (sym->type == TYP_NUM)
				return sym->value.d;
			if (sym->type == TYP_INT)
				return (double)sym->value.i;
			return 0.0;
/*
		case '<':
			vector.x = eval();
			vector.y = eval();
			vector.z = eval();
			Was('>');
			return 0.0;
*/

		case '(':
			val = eval();
			Need(')');
			if (minus)
				return -val;
			else
				return val;

		case '-':
			minus = !minus;
			break;
		case TK_NUM:
			val = last_num;
			if (minus)
				return -val;
			else
				return val;
		case TK_RAND:
			Need('(');
			minval = eval();
			Need(',');
			maxval = eval();
			Need(')');
			val = (maxval-minval) * (double)RTFClasses::Random::rand(2147483648) / 2147483648 + minval;
			if (minus)
				return -val;
			else
				return val;
		default:
			p = op;
			return val;
		}
	}
}

double Parser::Multdiv()
{
	double val = Unary();
	char *op;

	while (true) {
		op = p;
		switch (NextToken()) {
		case '*':
			val *= Unary(); break;
		case '/':
			val /= Unary(); break;
		default:
			p = op; return val;
		}
	}
}

double Parser::Addsub()
{
	double val = Multdiv();
	char *op;

	while (true) {
		op = p;
		switch (NextToken()) {
		case '+':
			val += Unary(); break;
		case '-':
			val -= Unary(); break;
		default:	p = op; return val;
		}
	}
}

double Parser::eval()
{
	return Addsub();
}

int Parser::ParseBuffer(char *buf, void *q)
{
	AnObject *obj, *fobj;
	Viewpoint *vp;
	ALight *light;
	Surface *tx;
	Color c;
	Symbol sym, *s;
	double d;
	int nn;
	char *old_p;

	p = buf;
	while (*p) {
		old_p = p;
		NextToken();
		switch(token) {
		case TK_CAMERA:
		case TK_VIEW_POINT:
			vp = ParseViewPoint();
			rayTracer.viewPoint = vp;
			if (level > 0) {
				*(Viewpoint **)q = vp;
				return TYP_VIEWPOINT;
			}
			break;
		case TK_LIGHT:
			light = ParseLight();
			if (level > 0) {
				*(ALight **)q = light;
				return TYP_LIGHT;
			}
			rayTracer.Add(light);
			break;
		case TK_SPHERE:
			obj = (AnObject *)ParseSphere();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_SPHERE;
			}
			rayTracer.Add(obj);
			break;
		case TK_PLANE:
			obj = (AnObject *)ParsePlane();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_PLANE;
			}
			rayTracer.Add(obj);
			break;
		case TK_TRIANGLE:
			obj = (AnObject *)ParseTriangle();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_PLANE;
			}
			rayTracer.Add(obj);
			break;
		case TK_RECTANGLE:
			obj = (AnObject *)ParseRectangle();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_PLANE;
			}
			rayTracer.Add(obj);
			break;
		case TK_QUADRIC:
			obj = (AnObject *)ParseQuadric();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_QUADRIC;
			}
			rayTracer.Add(obj);
			break;
		case TK_OBJECT:
			obj = ParseObject();
			if (level > 0) {
				*(AnObject **)q = obj;
				return TYP_OBJECT;
			}
			rayTracer.Add(obj);
			break;
		case TK_COLOR:
			c = ParseColor();
			if (level > 0) {
				*(Color *)q = c;
				return TYP_COLOR;
			}
			break;

		case TK_RANDV:
		case '<':
			if (level > 0) {
				p = old_p;
				*(Vector **)q = ParseVector();
				return TYP_VECTOR;
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
			if (level > 0) {
				*(Surface **)q = tx;
				return TYP_TEXTURE;
			}
			break;
		case TK_NUM:
			if (level > 0) {
				*(double *)q = last_num;
				return TYP_NUM;
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
			if (level > 0) {
				*(AnObject **)q = fobj;
				return TYP_OBJECT;
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
				switch(sym.type) {
				case TYP_TEXTURE:
					ParseTexture(s->value.tx);
					continue;
				case TYP_OBJECT:
					ParseObjectBody(s->value.obj);
					continue;
				}
			}
			else if (token != '=') {
				throw gcnew Finray::FinrayException(ERR_ASSIGNMENT,0);
			}
			level++;
			sym.type = ParseBuffer(p,&sym.value);
			level--;
			s = rayTracer.symbolTable.Find(sym.varname);
			if (s) {
				s->type = sym.type;
				s->value = sym.value;
			}
			else
				rayTracer.symbolTable.Add(&sym);
			break;
		case TK_EOF:
			return TYP_NONE;
		default:
			p = old_p;
			d = eval();
			*(double *)q = d;
			return TYP_NUM;
		}
	}
	return TYP_NONE;
}

AnObject *Parser::ParseObject()
{
	AnObject *obj;

	obj = new AnObject();
	ParseObjectBody(obj);
	return obj;
}

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

Viewpoint *Parser::ParseViewPoint()
{
	Vector *vector;
	Need('{');
	Viewpoint *viewpoint = new Viewpoint();

	while(true) {
		switch(NextToken()) {
		case TK_LOCATION:
			vector = ParseVector();
			viewpoint->loc.x = vector->x;
			viewpoint->loc.y = vector->y;
			viewpoint->loc.z = vector->z;
			delete vector;
			break;
		case TK_DIRECTION:
			vector = ParseVector();
			viewpoint->dir = *vector;
			delete vector;
			break;
		case TK_UP:		
			vector = ParseVector();
			viewpoint->up = *vector;
			delete vector;
			break;
		case TK_RIGHT:
			vector = ParseVector();
			viewpoint->right = *vector;
			delete vector;
			break;
		case TK_LOOK_AT:
			vector = ParseVector();
			viewpoint->dir = Vector::Normalize(Vector::Sub(*vector, viewpoint->loc));
			delete vector;
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
	Vector *l;

	Need('(');
	l = ParseVector();
	NextToken();
	Was(')');
	light = new ALight(l->x,l->y,l->z,0.0,0.0,0.0);
	delete l;
	ParseObjectBody(light);
	return light;
}

AQuadric *Parser::ParseQuadric()
{
	AQuadric *quadric;
	Vector *vector1,*vector2,*vector3;
	double r;

	Need('(');
	vector1 = ParseVector();
	vector2 = ParseVector();
	vector3 = ParseVector();
	r = eval();
	Need(')');
	quadric = new AQuadric(
		vector1->x, vector1->y, vector1->z,
		vector2->x, vector2->y, vector2->z,
		vector3->x, vector3->y, vector3->z,
		r);
	delete vector1;
	delete vector2;
	delete vector3;
	ParseObjectBody(quadric);
	return quadric;
}

ASphere *Parser::ParseSphere()
{
	ASphere *sphere;
	double r;
	Vector *vector;

	Need('(');
	vector = ParseVector();
	r = eval();
	NextToken();
	Was(')');
	sphere = new ASphere(vector->x,vector->y,vector->z,r);
	delete vector;
	ParseObjectBody(sphere);
	return sphere;
}

APlane *Parser::ParsePlane()
{
	APlane *plane;
	Vector *vector;
	double d;

	Need('(');
	vector = ParseVector();
	d = eval();
	NextToken();
	Was(')');
	plane = new APlane(vector->x,vector->y,vector->z,d);
	delete vector;
	ParseObjectBody(plane);
	return plane;
}

ATriangle *Parser::ParseTriangle()
{
	ATriangle *triangle;
	Vector *pt1, *pt2, *pt3;

	Need('(');
	pt1 = ParseVector();
	pt2 = ParseVector();
	pt3 = ParseVector();
	Need(')');
	triangle = new ATriangle(*pt1, *pt2, *pt3);
	delete pt1;
	delete pt2;
	delete pt3;
	ParseObjectBody(triangle);
	return triangle;
}

ARectangle *Parser::ParseRectangle()
{
	ARectangle *rectangle;
	Vector *pt1, *pt2, *pt3, *pt4;

	Need('(');
	pt1 = ParseVector();
	pt2 = ParseVector();
	pt3 = ParseVector();
	pt4 = ParseVector();
	Need(')');
	rectangle = new ARectangle(*pt1, *pt2, *pt3, *pt4);
	delete pt1;
	delete pt2;
	delete pt3;
	delete pt4;
	ParseObjectBody(rectangle);
	return rectangle;
}

Color Parser::ParseColor()
{
	Color color;
	Vector *vector;

	vector = ParseVector();
	color.r = (float)vector->x;
	color.g = (float)vector->y;
	color.b = (float)vector->z;
	delete vector;
	return color;
}

Surface *Parser::ParseTexture(Surface *texture)
{
	if (texture==nullptr)
		texture = new Surface;
	NextToken();
	if (token==TK_ID) {
		Symbol *sym = rayTracer.symbolTable.Find(lastid);
		if (!sym)
			throw gcnew Finray::FinrayException(ERR_UNDEFINED,0);
		texture->color = sym->value.tx->color;
		texture->ambient = sym->value.tx->ambient;
		texture->diffuse = sym->value.tx->diffuse;
		texture->brilliance = sym->value.tx->brilliance;
		texture->roughness = sym->value.tx->roughness;
		texture->reflection = sym->value.tx->reflection;
		texture->specular = sym->value.tx->specular;
		return texture;
	}
	Was('{');
	while (true) {
		switch(NextToken()) {
		case TK_COLOR:		texture->color = ParseColor(); break;
		case TK_AMBIENT:	texture->ambient = eval(); break;
		case TK_DIFFUSE:	texture->diffuse = eval(); break;
		case TK_BRILLIANCE:	texture->brilliance = eval(); break;
		case TK_ROUGHNESS:	texture->roughness = eval(); break;
		case TK_REFLECTION:	texture->reflection = eval(); break;
		case TK_SPECULAR:	texture->specular = eval(); break;
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
	Vector *vector;
	ALight *light;
	ASphere *sphere;
	Color color;
	int nn;
	char *old_p;

	Need('{');
	while(true) {
		switch(NextToken()) {
		case TK_ID:
			sym = rayTracer.symbolTable.Find(lastid);
			old_p = p;
			NextToken();
			if (!sym) {
				if (token=='=') {
					Symbol s;
					s.varname = lastid;
					level++;
					s.type = ParseBuffer(p,&s.value);
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
				sym->type = ParseBuffer(p,&sym->value);
				level--;
				break;
			}
			p = old_p;
			switch(sym->type) {
			case TYP_SPHERE:
			case TYP_PLANE:
			case TYP_TRIANGLE:
			case TYP_RECTANGLE:
			case TYP_QUADRIC:
				o = sym->value.obj;
				o->next = obj->obj;
				obj->obj = o;
				break;
			case TYP_TEXTURE:
				tx = sym->value.tx;
				obj->properties = *tx;
				break;
			case TYP_COLOR:
				obj->properties.color = sym->value.c;
				break;
			}
			break;
		case TK_SPHERE:
			o = (AnObject *)ParseSphere();
			o->next = obj->obj;
			obj->obj = o;
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
			o->next = obj->obj;
			obj->obj = o;
			break;
		case TK_TRIANGLE:
			o = (AnObject *)ParseTriangle();
			o->next = obj->obj;
			obj->obj = o;
			break;
		case TK_RECTANGLE:
			o = (AnObject *)ParseRectangle();
			o->next = obj->obj;
			obj->obj = o;
			break;
		case TK_QUADRIC:
			o = (AnObject *)ParseQuadric();
			o->next = obj->obj;
			obj->obj = o;
			break;
		case TK_TRANSLATE:
			vector = ParseVector();
			obj->Translate(vector->x, vector->y, vector->z);
			delete vector;
			break;
		case TK_ROTATE:
			vector = ParseVector();
			obj->RotXYZ(vector->x, vector->y, vector->z);
			delete vector;
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
			vector = ParseVector();
			switch(obj->type) {
			case OBJ_SPHERE:
				sphere = (ASphere *)obj;
				sphere->center.x =  vector->x;
				sphere->center.y =  vector->y;
				sphere->center.z =  vector->z;
				delete vector;
				break;
			case OBJ_LIGHT:
				light = (ALight *)obj;
				light->center.x = vector->x;
				light->center.y = vector->y;
				light->center.z = vector->z;
				delete vector;
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
	AnObject *o;

	Need(TK_ID);
	sym.varname = lastid;
	Need('=');
	sym.value.i = (int)eval();
	sym.type = TYP_INT;
	Need(TK_TO);
	lmt = eval();
	s = rayTracer.symbolTable.Find(sym.varname);
	if (s) {
		s->type = sym.type;
		s->value.i = sym.value.i;
	}
	else {
		rayTracer.symbolTable.Add(&sym);
		s = rayTracer.symbolTable.Find(sym.varname);
	}
	old_p = p;
	while (sym.value.i < lmt) {
		p = old_p;
		o = ParseObject();
		if (obj) {
			o->next = obj->obj;
			obj->obj = o;
		}
		else
			obj = o;
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
	ParseBuffer(master_filebuf,&obj);
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

