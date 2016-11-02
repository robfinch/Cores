// This project was started based on 'C' code found in the book:
// Practical RAY TRACING in C by Craig A. Lindley
// 
namespace Finray {

#ifndef __BYTE
#define __BYTE
typedef unsigned __int8 BYTE;
#endif

#define BIG		1e10
#define EPSILON	1e-03
#define MAXRECURSELEVEL	7

#define MIN(a,b)	(((a) > (b)) ? (b) : (a))
#define MAX(a,b)	(((a) > (b)) ? (a) : (b))
#define SQUARE(x)	((x) * (x))

class AnObject;
class ALight;

enum {
	MRT_UNION = 0,
	MRT_DIFFERENCE = 1,
	MRT_INTERSECTION = 2,
};

// This class used to track intersections with shapes.

class Intersection
{
public:
	DBL T;			// The transit distance from the ray's origin
	Vector3d P;		// The point of intersection in global space
	AnObject *obj;	// The intersected object
	int part;		// part of the object intersected
public:
	Intersection() {
		/* slows things down
		T = 0.0;
		P = Vector(0,0,0);
		obj = nullptr;
		part = 0;
		*/
	};
	Intersection(DBL t, Vector3d p, AnObject *o, int prt) {
		T = t;
		P = p;
		obj = o;
		part = prt;
	};
	void Assign(DBL t, Vector3d p, AnObject *o, int prt) {
		T = t;
		P = p;
		obj = o;
		part = prt;
	};
};

// Intersection tests with shapes return an IntersectResult object. The
// IntersectResult object contains a number of intersection points.

// Most objects will have four or fewer intersections. So we setup the default
// to handle up to four intersections without having the overhead of calling
// new and delete. This is good for plane,sphere,box,cylinder,triangle, and
// torus.

class IntersectResult
{
public:
	int n;					// number of stored intersections
	Intersection *pI;
	Intersection I[4];
	IntersectResult() { n = 0; pI = &I[0]; };
	IntersectResult(int nn) {
		n = 0;
		pI = new Intersection[nn];
	};
	~IntersectResult() {
		if (pI && pI != I)
			delete[] pI;
	}
};

class Ray
{
public:
	Vector origin;
	Vector dir;
	void Trace(Color *clr);
	IntersectResult *Test(AnObject *);
	IntersectResult *TestList(AnObject *, int TestType);
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

enum {
	TM_FLAT = 0,
	TM_NOISY = 1,
	TM_GRADIENT = 4,
	TM_GRANITE = 5,
	TM_MARBLE = 6,
	TM_WOOD = 7,
	TM_BOZO = 8,
	TM_CHECKER = 9,
	TM_RANDOM = 255,
};

class Texture
{
public:
	Color color1;	// base color
	Color color2;	// for checkered colors
	Color variance;
	Color acolor;	// color with ambience pre-calculated
	Color ambient;
	Transform trans;
	bool usesTransform;
	int ColorMethod;
	float diffuse;
	float brilliance;
	float specular;	// phong
	float roughness;
	float reflection;
	bool transparent;
	Pigment *pigment;
	Vector gradient;
	DBL turbulence;
	Texture();
	Texture(Texture *);
	void Copy(Texture *);
	~Texture();
//	void SetAttrib(float rd, float gr, float bl, Color a, float d, float b, float s, float ro, float r);
	void SetColorVariance(Color v) { variance = v; };
	Color GetColor(Vector point);
	Color Gradient(Vector point, Color c);
	Color Granite(Vector point, Color c);
	Color Marble(Vector point, Color c);
	Color Wood(Vector point, Color c);
	Color Bozo(Vector point, Color c);
	Color Checker(Vector point, Color c);
};

enum {
	OBJ_OBJECT = 1,
	OBJ_UNION,
	OBJ_INTERSECTION,
	OBJ_DIFFERENCE,
	OBJ_SPHERE,
	OBJ_TORUS,
	OBJ_PLANE,
	OBJ_TRIANGLE,
	OBJ_RECTANGLE,
	OBJ_CONE,
	OBJ_CYLINDER,
	OBJ_QUADRIC,
	OBJ_CUBE,
	OBJ_BOX,
	OBJ_LIGHT
};

class AnObject {
public:
	unsigned int type;
	Vector center;			// for bounding volumes
	Transform trans;
	double radius;			// for bounding object
	double radius2;			// square of radius
	bool doReflections;
	bool doShadows;
	bool doImage;
	bool usesTransform;
	bool inverted;
	AnObject *next;
	AnObject *obj;
	AnObject *posobj;
	AnObject *negobj;
	AnObject *boundingObject;
	ALight *lights;
	Texture properties;
	AnObject();
	int Print(AnObject *);
//	void SetAttrib(float rd, float gr, float bl, Color a, float d, float b, float s, float ro, float r);
	Color Shade(Ray *ray, Vector normal, Vector point, Color *color);
	virtual void SetColorVariance(Color v) { properties.SetColorVariance(v); };
	IntersectResult *Intersect(Ray *);
	virtual bool BoundingIntersect(Ray *ray);
	bool AntiIntersects(Ray *);
	virtual bool IsInside(Vector point) { return (false); };
	virtual void SetTexture(Texture *tx);
//	virtual void SetColor(Color c) { properties.color = c; };
	virtual Color GetColor(Vector point) { return (properties.GetColor(point)); };
	virtual Vector Normal(Vector) { return (Vector()); };
	virtual void Translate(double x, double y, double z) { Translate(Vector(x,y,z)); };
	virtual void Translate(Vector v);
	virtual void Scale(Vector v);
	virtual void Rotate(Vector rv) {};
	virtual void RotXYZ(double, double, double);
	virtual void RotX(double a) {};
	virtual void RotY(double a) {};
	virtual void RotZ(double a) {};
	virtual void Invert() { inverted = !inverted; };
	virtual void Print() {} ;
	bool IsContainer();
	void TransformX(Transform *tr) { trans.Compose(tr); };
};


class AQuadric : public AnObject
{
public:
	double A,B,C,D,E,F,G,H,I,J;
	AQuadric();
	AQuadric(double a, double b, double c, double d, double e,
			double f, double g, double h, double i, double j);
	void CalcBoundingObject();
	IntersectResult *Intersect(Ray *);
	Vector Normal(Vector);
	void Print();
	void Translate(Vector t);
	void RotXYZ(double, double, double);
	void RotX(double a) { RotXYZ(a, 0.0, 0.0); };
	void RotY(double a) { RotXYZ(0.0, a, 0.0); };
	void RotZ(double a) { RotXYZ(0.0, 0.0, a); };
	void Scale(Vector v);
	void Scale(double x, double y, double z) { Scale(Vector(x,y,z)); };
	void ToMatrix(Matrix *) const;
	void FromMatrix(Matrix *);
	void TransformX(Transform *tr);
};


class ASphere : public AnObject
{
public:
	ASphere();
	ASphere(Vector P, double R);
	ASphere(double x,double y ,double z,double rad);
	IntersectResult *Intersect(Ray *);
	bool IsInside(Vector point);
	Vector Normal(Vector);
	void Translate(Vector p);
	void Scale(Vector s);
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
	APlane(DBL,DBL,DBL,DBL);
	IntersectResult *Intersect(Ray *);
	bool IsInside(Vector point);
	Vector Normal(Vector);
	void Print() {};
	void Translate(Vector point);
	void Rotate(Vector rv);
	void Scale(Vector sc);
	void RotX(DBL);
	void RotY(DBL);
	void RotZ(DBL);
	void Invert();
};

class ACone : public AnObject
{
public:
	enum {
		BODY,
		BASE,
		APEX
	};
	Vector base, apex;
	Vector baseNormal, apexNormal, bodyNormal;
	double baseRadius, apexRadius;
	double length;
	static const double tolerance;
	unsigned int intersectedPart : 2;
	unsigned int openBase : 1;
	unsigned int openApex : 1;
	ACone(Vector b, Vector a, double rb, double ra);
	void CalcCylinderTransform();
	void CalcTransform();
	void CalcCenter();
	void CalcRadius();
	void CalcBoundingObject();
	Vector Normal(Vector);
	IntersectResult *Intersect(Ray *);
	void Translate(Vector pt);
	void Scale(double x, double y, double z);
	void Scale(Vector v);
	void Print() {};
	void RotX(double a) { ACone::RotXYZ(a, 0.0, 0.0); };
	void RotY(double a) { ACone::RotXYZ(0.0, a, 0.0); };
	void RotZ(double a) { ACone::RotXYZ(0.0, 0.0, a); };
	void RotXYZ(double,double,double);
};

class ACylinder : public ACone
{
public:
	ACylinder(Vector b, Vector a, double r);
	void CalcTransform();
	IntersectResult *Intersect(Ray *);
	void RotX(double a) { ACone::RotXYZ(a, 0.0, 0.0); };
	void RotY(double a) { ACone::RotXYZ(0.0, a, 0.0); };
	void RotZ(double a) { ACone::RotXYZ(0.0, 0.0, a); };
	void RotXYZ(double a,double b,double c) { ACone::RotXYZ(a,b,c); };
};

class ATriangle;

class ABox : public AnObject
{
public:
	double maxLength;
	Vector lowerLeft;
	Vector upperRight;
	Vector corner[8];
	ATriangle *tri[12];
	ABox();
	ABox(Vector pt, Vector dist);
	ABox(double x, double y, double z);
	void CalcBoundingObject();
	bool BoundingIntersect(Ray *ray);
	Vector CalcCenter();
	double CalcRadius();
	Vector Normal(Vector v);
	void SetVariance(Color v);
	IntersectResult *Intersect(Ray *);
	bool IsInside(Vector point);
	void Print() {};
	void Translate(Vector p);
	void Scale(Vector s);
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
	ATriangle();
	ATriangle(Vector a, Vector b, Vector c);
	void Init();
	void CalcNormal();
	void CalcBoundingObject();
	bool InternalSide(Vector pt1, Vector pt2, Vector a, Vector b);
	bool PointInTriangle(Vector p);
	bool IsInside(Vector P);
	IntersectResult *Intersect(Ray *);
	Vector Normal(Vector);
	void Print() {};
	void Translate(Vector p);
	void Scale(Vector s);
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
	IntersectResult *Intersect(Ray *);
	void CalcNormal();
	Vector Normal(Vector);
	void Translate(Vector pt) {};
	void Print() {};
	void RotX(double);
	void RotY(double);
	void RotZ(double);
};

class ATorus : public AnObject
{
public:
	DBL MajorRadius, MinorRadius;
private:
	bool TestThickCylinder(const Vector P, const Vector D, DBL h1, DBL h2, DBL r1, DBL r2) const;
public:
	ATorus(DBL, DBL);
	void CalcBoundingObject();
	IntersectResult *Intersect(Ray *);
	bool IsInside(Vector P);
	Vector Normal(Vector v);
	void Translate(Vector pt);
	void Rotate(Vector rv);
	void Scale(Vector sc);
	void Print() {};
	void RotX(double a) { ATorus::RotXYZ(a, 0.0, 0.0); };
	void RotY(double a) { ATorus::RotXYZ(0.0, a, 0.0); };
	void RotZ(double a) { ATorus::RotXYZ(0.0, 0.0, a); };
	void RotXYZ(double,double,double);
};

class ALight : public AnObject
{
public:
	Vector center;
	double Intersect(Ray *) { return 0.0; };
	Vector Normal(Vector) { return Vector(); };
	ALight(double, double, double, float, float, float);
	void Print() {};
	Finray::Color GetColor(AnObject *so, AnObject *objPtr, Ray *ray, DBL distance);
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
	TK_ANTI,
	TK_APPROXIMATE,
	TK_BACKGROUND,
	TK_BOX,
	TK_BRILLIANCE,
	TK_CAMERA,
	TK_CHECKER,
	TK_COLOR,
	TK_COLORMAP,
	TK_COLORMETHOD,
	TK_CONE,
	TK_COS,
	TK_CUBE,
	TK_CYLINDER,
	TK_DIFFERENCE,
	TK_DIFFUSE,
	TK_DIRECTION,
	TK_ELSE,
	TK_ELSEIF,
	TK_EQ,
	TK_FIRSTFRAME,
	TK_FOR,
	TK_FRAMENO,
	TK_FRAMES,
	TK_GE,
	TK_GRADIENT,
	TK_GT,
	TK_ICONST,
	TK_ID,
	TK_IF,
	TK_INCLUDE,
	TK_INTERSECTION,
	TK_LASTFRAME,
	TK_LE,
	TK_LIGHT,
	TK_LIGHT_SOURCE,
	TK_LOCATION,
	TK_LOOK_AT,
	TK_LT,
	TK_NE,
	TK_NO_REFLECTION,
	TK_NO_SHADOW,
	TK_NUM,
	TK_OBJECT,
	TK_OPEN,
	TK_PHONG,
	TK_PHONGSIZE,
	TK_PIGMENT,
	TK_PLANE,
	TK_QUADRIC,
	TK_RAND,
	TK_RANDV,
	TK_RAYTRACER,
	TK_RCONST,
	TK_RECTANGLE,
	TK_REFLECTION,
	TK_REPEAT,
	TK_RGB,
	TK_RGBF,
	TK_RGBFT,
	TK_RGBT,
	TK_RIGHT,
	TK_ROTATE,
	TK_ROUGHNESS,
	TK_SCALE,
	TK_SIN,
	TK_SPECULAR,
	TK_SPHERE,
	TK_SRAND,
	TK_TEXTURE,
	TK_THEN,
	TK_TO,
	TK_TORUS,
	TK_TRANSLATE,
	TK_TRIANGLE,
	TK_TURBULENCE,
	TK_UNION,
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
	ERR_ASSIGNMENT,
	ERR_ILLEGALOP,
	ERR_BADTYPE,
	ERR_SINGULAR_MATRIX,
	ERR_DEGENERATE,
	ERR_NULLPTR,
};

enum {
	TYP_NONE = 0,
	TYP_DIFFERENCE,
	TYP_INT,
	TYP_INTERSECTION,
	TYP_NUM,
	TYP_VECTOR,
	TYP_VECTOR2D,
	TYP_VECTOR4D,
	TYP_VECTOR5D,
	TYP_RGB,
	TYP_RGBF,
	TYP_RGBT,
	TYP_RGBFT,
	TYP_COLOR,
	TYP_COLORMAP,
	TYP_TEXT,
	TYP_SPHERE,
	TYP_TORUS,
	TYP_PLANE,
	TYP_TRIANGLE,
	TYP_RECTANGLE,
	TYP_QUADRIC,
	TYP_CONE,
	TYP_CYLINDER,
	TYP_CUBE,
	TYP_BOX,
	TYP_OBJECT,
	TYP_TEXTURE,
	TYP_VIEWPOINT,
	TYP_LIGHT,
	TYP_RAND,
	TYP_UNION,
};

class Value
{
public:
	int type;
	int i;
	double d;
	Finray::Color c;
	Vector2d v2;
	Vector3d v3;
	Vector4d v4;
	Vector5d v5;
	union {
		ACone *cn;
		ACylinder *cy;
		ASphere *sp;
		ATorus *tr;
		APlane *pl;
		Viewpoint *vp;
		Texture *tx;
		ColorMap *cm;
		AQuadric *qd;
		AnObject *obj;
		ALight *lt;
	} val;
};

class Symbol
{
public:
	std::string varname;
	Value value;
};

class SymbolTable
{
	Symbol symbols[1000];
public:
	int count;
	SymbolTable();
	void AddDefaultSymbols();
	Symbol *Find(std::string nm);
	void Add(Symbol *sym);
};

class RayTracer;

class Parser
{
public:
	RayTracer *pRayTracer;
	std::string path;
private:
	int mfp;
	int token;
	double rval;
	double last_num;
	Color last_color;
	Vector last_vector;
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
	Value Unary();
	Value Multdiv();
	Value Addsub();
	Value Relational();
	Value eval();
	void getid();
	bool Test(int);
	Color ParseAmbient();
	ACone *ParseCone();
	ACylinder *ParseCylinder();
	Color ParseApproximate(AnObject *obj);
	void ParseNoReflection2(AnObject *obj);
	void ParseNoReflection(AnObject *obj);
	void ParseNoShadow2(AnObject *obj);
	void ParseNoShadow(AnObject *obj);
	Color ParseColor();
	ColorMap *ParseColorMap();
	Pigment *ParsePigment();
	Texture *ParseTexture(Texture *texture);
	void ParseObjectBody(AnObject *obj);
	ALight *ParseLight();
	ASphere *ParseSphere();
	ATorus *ParseTorus();
	ABox *ParseBox();
	ABox *ParseCube();
	APlane *ParsePlane();
	ATriangle *ParseTriangle();
	ARectangle *ParseRectangle();
	AQuadric *ParseQuadric();
	AnObject *ParseObject();
	Viewpoint *ParseViewPoint();
	AnObject *ParseIf(AnObject *);
	AnObject *ParseFor(AnObject *);
	void InsertSymValue(Symbol *sym, AnObject *obj, bool minus);
	void ParseRayTracer();
	void Need(int);
	void Was(int);
	int NextToken();
public:
	char *p;
	Parser();
	Value ParseBuffer(char *buf);
	void Parse(System::String^ path);
};

class RayTracer
{
public:
	int first_frame;
	int last_frame;
	int frameno;
	int maxRecurseLevel;
	int recurseLevel;
	Finray::Color backGround;
	Viewpoint *viewPoint;
	AnObject *objectList;
	ALight *lightList;
	SymbolTable symbolTable;
	Parser parser;
	std::ofstream ofs;
	int indent;
	RayTracer() {
		Init();
	}
	void Init();
	bool HitRecurseLimit();
	void Add(AnObject *);
	void Add(ALight *);
	void DeleteList(AnObject *);
	void DeleteList();
	void DumpObject(AnObject *);
	void DumpObjects();
};

};
