namespace Finray {

#ifndef __BYTE
#define __BYTE
typedef unsigned __int8 BYTE;
#endif

#define BIG		1e10
#define EPSILON	1e-03
#define MAXRECURSELEVEL	5

#define MIN(a,b)	(((a) > (b)) ? (b) : (a))
#define MAX(a,b)	(((a) > (b)) ? (a) : (b))
#define SQUARE(x)	((x) * (x))

class Color
{
public:
	float r;
	float g;
	float b;
};

class Ray
{
public:
	Vector origin;
	Vector dir;
	void Trace(Color *clr);
};

class Viewpoint
{
public:
	Vector loc;
	Vector dir;
	Vector up;
	Vector right;
	Viewpoint() {
		loc.x = 0.0;
		loc.y = 0.0;
		loc.z = 0.0;
		dir.x = 0.0;
		dir.y = 0.0;
		dir.z = 0.0;
		up.x = 0.0;
		up.y = 0.0;
		up.z = 0.0;
		right.x = 0.0;
		right.y = 0.0;
		right.z = 0.0;
	};
};

class Surface
{
public:
	Color color;
	float ambient;
	float diffuse;
	float brilliance;
	float specular;
	float roughness;
	float reflection;
	Surface();
	Surface(Surface *);
	void SetAttrib(float rd, float gr, float bl, float a, float d, float b, float s, float ro, float r);
};

enum {
	OBJ_OBJECT = 1,
	OBJ_SPHERE,
	OBJ_PLANE,
	OBJ_TRIANGLE,
	OBJ_QUADRIC,
	OBJ_LIGHT
};

class AnObject {
public:
	unsigned int type;
	AnObject *next;
	AnObject *obj;
	Surface properties;
	AnObject();
	int Print(AnObject *);
	void SetAttrib(float rd, float gr, float bl, float a, float d, float b, float s, float ro, float r);
	Color Shade(Ray *ray, Vector normal, Vector point, Color *color);
	virtual int Intersect(Ray *, double *) { return 0.0; } ;
	virtual Vector Normal(Vector) { return Vector(); };
	virtual void Translate(double x, double y, double z);
	virtual void RotXYZ(double, double, double);
	virtual void RotX(double a) {};
	virtual void RotY(double a) {};
	virtual void RotZ(double a) {};
	virtual void Print() {} ;
};


class AQuadric : public AnObject
{
public:
	double A,B,C,D,E,F,G,H,I,J;
	AQuadric();
	AQuadric(double a, double b, double c, double d, double e,
			double f, double g, double h, double i, double j);
	int Intersect(Ray *, double *);
	Vector Normal(Vector);
	void Print();
	void Translate(double x, double y, double z);
	void RotXYZ(double, double, double);
	void RotX(double a) { RotXYZ(a, 0.0, 0.0); };
	void RotY(double a) { RotXYZ(0.0, a, 0.0); };
	void RotZ(double a) { RotXYZ(0.0, 0.0, a); };
	void ToMatrix(Matrix *) const;
	void FromMatrix(Matrix *);
	void TransformX(Transform *tr);
};


class ASphere : public AnObject
{
public:
	Vector center;
	double radius;
	double radius2;	// radius squared
	ASphere();
	ASphere(double x,double y ,double z,double rad);
	int Intersect(Ray *, double *);
	Vector Normal(Vector);
	void Translate(double x, double y, double z) {
		center.x = x; center.y = y; center.z = z;
	};
	void Print();
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

/*
class ACylinder : public AnObject
{
public:
	Vector axis;
	Vector center;
	double radius;
	double radius2;	// radius squared
	double height;
	ACylinder();
	double Intersect(Ray *);
	Vector Normal(Vector);
	void Print();
};
*/

class APlane : public AnObject
{
public:
	Vector normal;
	double distance;
	APlane();
	APlane(double,double,double,double);
	int Intersect(Ray *, double *);
	Vector Normal(Vector);
	void Print() {};
	void Translate(double x, double y, double z) {};
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

class ATriangle : public AnObject
{
	void CalcCentroid();
public:
	Vector normal, unnormal;
	Vector u, v;
	double uu, vv, uv;	// vars for intersection testing
	double D;			// denominator
	Vector p1, p2, p3;
	Vector pc;			// centroid for translations
	ATriangle(Vector a, Vector b, Vector c);
	void Init();
	void CalcNormal();
	bool InternalSide(Vector pt1, Vector pt2, Vector a, Vector b);
	bool PointInTriangle(Vector p);
	int Intersect(Ray *, double *);
	Vector Normal(Vector);
	void Print() {};
	void Translate(double x, double y, double z);
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

class ARectangle : public AnObject
{
public:
	Vector normal;
	Vector p1, p2, p3, p4;
	ARectangle(Vector a, Vector b, Vector c, Vector d);
	int Intersect(Ray *, double *);
	void CalcNormal();
	Vector Normal(Vector);
	void Translate(double x, double y, double z) {};
	void Print() {};
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

class ALight : public AnObject
{
public:
	Vector center;
	double Intersect(Ray *) { return 0.0; };
	Vector Normal(Vector) { return Vector(); };
	ALight(double, double, double, float, float, float);
	void Print() {};
	Finray::Color GetColor(AnObject *objPtr, Ray *ray, double distance);
	double MakeRay(Vector point, Ray *ray);
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

ref class FinrayException : public System::Exception
{
public:
	int data;
	int errnum;
	FinrayException(int e, int d) { data = d; errnum = e; };
};

enum {
	TK_EOF = 0,
	TK_AMBIENT = 256,
	TK_BACKGROUND,
	TK_BRILLIANCE,
	TK_CAMERA,
	TK_COLOR,
	TK_DIFFUSE,
	TK_DIRECTION,
	TK_FOR,
	TK_ICONST,
	TK_INCLUDE,
	TK_ID,
	TK_LIGHT,
	TK_LIGHT_SOURCE,
	TK_LOCATION,
	TK_LOOK_AT,
	TK_NUM,
	TK_OBJECT,
	TK_PHONG,
	TK_PHONGSIZE,
	TK_PLANE,
	TK_QUADRIC,
	TK_RAND,
	TK_RANDV,
	TK_RCONST,
	TK_RECTANGLE,
	TK_REFLECTION,
	TK_REPEAT,
	TK_RIGHT,
	TK_ROTATE,
	TK_ROUGHNESS,
	TK_SPECULAR,
	TK_SPHERE,
	TK_TEXTURE,
	TK_TO,
	TK_TRANSLATE,
	TK_TRIANGLE,
	TK_UP,
	TK_VIEW_POINT
};

enum {
	ERR_SYNTAX = 1,
	ERR_EXPECT_TOKEN,
	ERR_FPCON,
	ERR_TEXTURE,
	ERR_TOOMANY_SYMBOLS,
	ERR_UNDEFINED,
	ERR_MISMATCH_TYP,
	ERR_FILEDEPTH,
	ERR_NOVIEWPOINT,
	ERR_TOOMANY_OBJECTS,
	ERR_NONPLANER,
	ERR_ASSIGNMENT
};

enum {
	TYP_NONE = 0,
	TYP_INT,
	TYP_NUM,
	TYP_VECTOR,
	TYP_COLOR,
	TYP_TEXT,
	TYP_SPHERE,
	TYP_PLANE,
	TYP_TRIANGLE,
	TYP_RECTANGLE,
	TYP_QUADRIC,
	TYP_OBJECT,
	TYP_TEXTURE,
	TYP_VIEWPOINT,
	TYP_LIGHT
};

class Symbol
{
public:
	std::string varname;
	int type;
	union symval {
		int i;
		double d;
		Color c;
		Vector *v;
		ASphere *sp;
		APlane *pl;
		Viewpoint *vp;
		Surface *tx;
		AQuadric *qd;
		AnObject *obj;
		ALight *lt;
	} value;
};

class SymbolTable
{
	Symbol symbols[1000];
public:
	int count;
	SymbolTable();
	Symbol *Find(std::string nm);
	void Add(Symbol *sym);
};

class Parser
{
	int mfp;
	int token;
	double rval;
	double last_num;
	int level;				// Parse level
	int lastch;
	char fbuf[2000000];
	char lastid[64];
	char lastkw[64];
	Symbol *symbol;
	__int64 ival;
	__int64 radix36(char c);
	void getbase(__int64 b);
	void getfrac();
	void getexp();
	void getnum();
	void SkipSpaces();
	void ScanToEOL();
	int isalnum(char c);
	int isidch(char c);
	int isspace(char c);
	int isdigit(char c);
	double Unary();
	double Multdiv();
	double Addsub();
	double eval();
	void getid();
public:
	char *p;
	Parser();
	void Need(int);
	void Was(int);
	int NextToken();
	Vector *ParseVector();
	int ParseBuffer(char *buf, void *q);
	Color ParseColor();
	Surface *ParseTexture(Surface *texture);
	void ParseObjectBody(AnObject *obj);
	ALight *ParseLight();
	ASphere *ParseSphere();
	APlane *ParsePlane();
	ATriangle *ParseTriangle();
	ARectangle *ParseRectangle();
	AQuadric *ParseQuadric();
	AnObject *ParseObject();
	Viewpoint *ParseViewPoint();
	AnObject *ParseFor(AnObject *);
	void Parse(std::string path);
};

class RayTracer
{
public:
	int recurseLevel;
	AnObject *objectList;
	ALight *lightList;
	Viewpoint *viewPoint;
	Parser parser;
	SymbolTable symbolTable;
	RayTracer() {
		Init();
	}
	void Init();
	void Add(AnObject *);
	void Add(ALight *);
	void DeleteList(AnObject *);
	void DeleteList();
};

};
