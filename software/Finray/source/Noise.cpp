#include "stdafx.h"

// A straight-forward port of Ken Perlin's noise code (perlin.h and perlin.c) to C++

extern FinitronClasses::NoiseGen noiseGen;

namespace FinitronClasses {

//unsigned __int16 NoiseGen::p[B + B + 2];
//Vector NoiseGen::g3[B + B + 2];
//Vector2d NoiseGen::g2[B + B + 2];
//double NoiseGen::g1[B + B + 2];

//float Gradient[IZMAX][IYMAX][IXMAX][3];
NoiseGen::NoiseGen()
{
	hashTable = nullptr;
	Init();
}

NoiseGen::~NoiseGen()
{
	if (hashTable)
		delete[] hashTable;
}

void NoiseGen::InitHashTable()
{
	int next_rand;
	int i, j;
	unsigned __int16 temp;

	next_rand = 0;
	hashTable = new unsigned __int16[8192];
	for (i = 0; i < 4096; i++)
		hashTable[i] = i;

	for(i = 4095; i >= 0; i--)
	{
		next_rand = next_rand * 1812433253L + 12345L;
		j = ((int)(next_rand >> 16) & 0x7FFF) % 4096;
		temp = hashTable[i];
		hashTable[i] = hashTable[j];
		hashTable[j] = temp;
	}

	for(i = 0; i < 4096; i++)
		hashTable[4096 + i] = hashTable[i];
}

void NoiseGen::Init(void)
{
   int i, j, k;
   double r;

   for (i = 0 ; i < SINTABSIZE ; i++)
      sintab[i] = sin(i/(DBL)SINTABSIZE * (3.14159265359 * 2.0));

   next_rand = 0;
   for (i = 0 ; i < B ; i++) {
      p[i] = i;
	  r = (double)(random() % (B + B));
      g1[i] = (double)(r - (double)B) / (double)B;

      g2[i].u = (double)((random() % (B + B)) - B) / B;
      g2[i].v = (double)((random() % (B + B)) - B) / B;
	  g2[i] = Vector2d::Normalize(g2[i]);

      g3[i].x = (double)((random() % (B + B)) - B) / B;
      g3[i].y = (double)((random() % (B + B)) - B) / B;
      g3[i].z = (double)((random() % (B + B)) - B) / B;
	  g3[i] = Vector::Normalize(g3[i]);
   }

   while (--i) {
      k = p[i];
	  j = random() % B;
      p[i] = p[j];
      p[j] = k;
   }

   for (i = 0 ; i < B + 2 ; i++) {
      p[B + i] = p[i];
      g1[B + i] = g1[i];
      g2[B + i] = g2[i];
      g3[B + i] = g3[i];
   }
}

double NoiseGen::Noise3(Vector vec)
{
   int bx0, bx1, by0, by1, bz0, bz1, b00, b10, b01, b11;
   double rx0, rx1, ry0, ry1, rz0, rz1, sy, sz, sx, a, b, c, d, u, v;
   int i, j;

   setupX(bx0,bx1, rx0,rx1);
   setupY(by0,by1, ry0,ry1);
   setupZ(bz0,bz1, rz0,rz1);

   i = p[ bx0 ];
   j = p[ bx1 ];

   b00 = p[ i + by0 ];
   b10 = p[ j + by0 ];
   b01 = p[ i + by1 ];
   b11 = p[ j + by1 ];

   sx  = s_curve(rx0);
   sy = s_curve(ry0);
   sz = s_curve(rz0);

   q = g3[ b00 + bz0 ] ; u = at3(rx0,ry0,rz0);
   q = g3[ b10 + bz0 ] ; v = at3(rx1,ry0,rz0);
   a = lerp(sx, u, v);

   q = g3[ b01 + bz0 ] ; u = at3(rx0,ry1,rz0);
   q = g3[ b11 + bz0 ] ; v = at3(rx1,ry1,rz0);
   b = lerp(sx, u, v);

   c = lerp(sy, a, b);

   q = g3[ b00 + bz1 ] ; u = at3(rx0,ry0,rz1);
   q = g3[ b10 + bz1 ] ; v = at3(rx1,ry0,rz1);
   a = lerp(sx, u, v);

   q = g3[ b01 + bz1 ] ; u = at3(rx0,ry1,rz1);
   q = g3[ b11 + bz1 ] ; v = at3(rx1,ry1,rz1);
   b = lerp(sx, u, v);

   d = lerp(sy, a, b);

   return lerp(sz, c, d);
}


Vector NoiseGen::Noise(Vector vec)
{
   int bx0, bx1, by0, by1, bz0, bz1, b00, b10, b01, b11;
   double rx0, rx1, ry0, ry1, rz0, rz1, sy, sz, sx;
   Vector a, b, c, d, u, v;
   int i, j;

   setupX(bx0,bx1, rx0,rx1);
   setupY(by0,by1, ry0,ry1);
   setupZ(bz0,bz1, rz0,rz1);

   i = p[ bx0 ];
   j = p[ bx1 ];

   b00 = p[ i + by0 ];
   b10 = p[ j + by0 ];
   b01 = p[ i + by1 ];
   b11 = p[ j + by1 ];

   sx = s_curve(rx0);
   sy = s_curve(ry0);
   sz = s_curve(rz0);

   u = g3[ b00 + bz0 ];
   v = g3[ b10 + bz0 ];
   a = Vector::Lerp(u, v, sx);

   u = g3[ b01 + bz0 ] ;
   v = g3[ b11 + bz0 ] ;
   b = Vector::Lerp(u, v, sx);

   c = Vector::Lerp(a, b, sy);

   u = g3[ b00 + bz1 ];
   v = g3[ b10 + bz1 ];
   a = Vector::Lerp(u, v, sx);

   u = g3[ b01 + bz1 ];
   v = g3[ b11 + bz1 ];
   b = Vector::Lerp(u, v, sx);

   d = Vector::Lerp(a, b, sy);

   return Vector::Lerp(c, d, sz);
}


double NoiseGen::Noise(Vector p, double alpha, double beta, int n)
{
   int i;
   double val,sum = 0;
   double scale = 1;

   for (i=0;i<n;i++) {
      val = Noise3(p);
      sum += val / scale;
      scale *= alpha;
	  p = Vector::Scale(p,beta);
   }
   return(sum);
}

DBL NoiseGen::Cycloidal(DBL value)
{
   if (value >= 0.0)
      return (sintab [(int)((value - floor (value)) * SINTABSIZE)]);
   else
      return (0.0 - sintab [(int)((0.0 - (value + floor (0.0 - value)))
                                    * SINTABSIZE)]);
}


DBL NoiseGen::Turbulence (Vector v)
{
	DBL pixelSize = 0.1;
	DBL t = 0.0;
	DBL scale, value;

	for (scale = 1.0 ; scale > pixelSize ; scale *= 0.5) {
	    value = noiseGen.Noise3(Vector::Scale(v,1.0/scale));
		t += fabs (value) * scale;
	}
	return (t);
}

Vector NoiseGen::DTurbulence (Vector v)
{
   Vector result;
   DBL pixelSize = 0.01;
   DBL scale;
   Vector value;

   for (scale = 1.0 ; scale > pixelSize ; scale *= 0.5) {
      value = noiseGen.Noise(Vector::Scale(v,1.0/scale));
      result.x += value.x * scale;
      result.y += value.y * scale;
      result.z += value.z * scale;
   }
   return result;
}



/*
float lerp(float a0, float a1, float w)
{
	return (a0 + w *(a1-a0));
}

float dotGridGradient(Vector a, Vector b)
{
	int ix = (int)fabs(a.x) % 4096;
	int iy = (int)fabs(a.y) % 4096;
	int iz = (int)fabs(a.z) % 4096;
	Vector d = Vector::Sub(b,a);
	return Vector::Dot(d,Gradient[iz][iy][ix]);
}

float dotGridGradient(int ix, int iy, int iz, float x, float y, float z)
{
	float dx = x - (float)ix;
	float dy = y - (float)iy;
	float dz = z - (float)iz;
	return (dx * Gradient[iz][iy][ix][0] + dy * Gradient[iz][iy][ix][1] + dz * Gradient[iz][iy][ix][2]);
}

float perlin(Vector v)
{
	int x0 = v.x > 0.0f ? (int)v.x : (int)v.x-1;
	int x1 = x0 + 1;
	int y0 = v.y > 0.0f ? (int)v.y : (int)v.y-1;
	int y1 = y0 + 1;
	int z0 = v.z > 0.0f ? (int)v.z : (int)v.z-1;
	int z1 = z0 + 1;

	float sx = v.x - (float)x0;
	float sy = v.y - (float)y0;
	float sz = v.z - (float)z0;

	float n0, n1;
	n0 = dotGridGradient(x0, y0, z0, v.x, v.y, v.z);
	n1 = dotGridGradient(x1, y0, z0, v.x, v.y, v.z);
}
*/
}
