namespace FinitronClasses
{

#define setupX(b0,b1,r0,r1)\
        sx = vec.x + N;\
        b0 = ((int)sx) & BM;\
        b1 = (b0+1) & BM;\
        r0 = sx - (int)sx;\
        r1 = r0 - 1.;
#define setupY(b0,b1,r0,r1)\
        sx = vec.y + N;\
        b0 = ((int)sx) & BM;\
        b1 = (b0+1) & BM;\
        r0 = sx - (int)sx;\
        r1 = r0 - 1.;
#define setupZ(b0,b1,r0,r1)\
        sx = vec.z + N;\
        b0 = ((int)sx) & BM;\
        b1 = (b0+1) & BM;\
        r0 = sx - (int)sx;\
        r1 = r0 - 1.;

#define SINTABSIZE 1000

class NoiseGen
{
	static const int B = 0x100;
	static const int BM = 0xff;
	static const int N = 0x1000;
	static const int NP = 12;
	static const int NM = 0xfff;
	unsigned __int16 p[B + B + 2];
	Vector g3[B + B + 2];
	Vector2d g2[B + B + 2];
	double g1[B + B + 2];
	DBL sintab [SINTABSIZE];
	int start;
	unsigned __int16 *hashTable;
	int next_rand;
	Vector q;
//	double at2(double rx, double ry) { return ( rx * q[0] + ry * q[1] ); };
	double at3(double rx, double ry, double rz) { return ( rx * q.x + ry * q.y + rz * q.z ); };
	double s_curve(double t) { return ( t * t * (3. - 2. * t) ); };
	double lerp(double t, double a, double b) { return ( a + t * (b - a) ); };
public:
	NoiseGen();
	~NoiseGen();
	// Always return a positive number from random(). The result is used as an array index.
	int random() { next_rand = next_rand * 1812433253L + 12345L; return next_rand & 0x7FFFFFFF; };
	void Init(void);
	void InitHashTable();
	double Noise3(Vector vec);
	Vector Noise(Vector vec);
	double Noise(Vector p, double alpha, double beta, int n);
	DBL Cycloidal(DBL value);
	DBL Turbulence(Vector);
	Vector DTurbulence(Vector);
};

}
