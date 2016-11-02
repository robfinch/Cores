#pragma once

namespace Finray {

class Color
{
public:
	float r;
	float g;
	float b;
	float f;	// filter
	float t;	// transmit
	Color(float R, float G, float B) { r = R; g = G; b = B; };
	Color() { r = 0.0f; g = 0.0f; b = 0.0f; f = 0.0f; t = 0.0f; };
	static Color Add(Color a, Color b) {
		Color c;
		c.r = a.r + b.r;
		c.g = a.g + b.g;
		c.b = a.b + b.b;
		return c;
	};
	static Color Sub(Color a, Color b) {
		Color c;
		c.r = a.r - b.r;
		c.g = a.g - b.g;
		c.b = a.b - b.b;
		return c;
	};
	static Color Neg(Color a) {
		Color c;
		c.r = -a.r;
		c.g = -a.g;
		c.b = -a.b;
		return c;
	};
	static Color Scale(Color a, float k) {
		Color c;
		c.r = a.r * k;
		c.g = a.g * k;
		c.b = a.b * k;
		return c;
	};
	static float Dot(Color a, Color b) {
		float d;
		d = a.r * b.r + a.g * b.g + a.b * b.b;
		return d;
	};
	static Color Cross(Color a, Color b) {
		Color c;

		c.r = a.g * b.b - a.b * b.g;
		c.g = a.b * b.r - a.r * b.b;
		c.b = a.r * b.g - a.g * b.r;
		return c;
	};
	static float Length(Color a) {
		return sqrt(a.r*a.r + a.g*a.g + a.b*a.b);
	};
	static Color Normalize(Color a) {
		Color b;
		float l = sqrt(a.r*a.r + a.g*a.g + a.b*a.b);
		b.r = a.r/l;
		b.g = a.g/l;
		b.b = a.b/l;
		return b;
	};
	static Color Project(Color A, Color B) {
		return Color::Scale(B,(Color::Dot(A,A) / Color::Dot(B,B)));
	};
	static Color RotX(Color pt, float angle)
	{
		angle = angle * (float)PI / 180.0f;
		float y = pt.g * cos(angle) - pt.b * sin(angle);
		float z = pt.g * sin(angle) + pt.b * cos(angle);
		pt.g = y;
		pt.b = z;
		return pt;
	}
	static Color RotY(Color pt, float angle)
	{
		angle = angle * (float)PI / 180.0f;
		float x = pt.r * cos(angle) - pt.b * sin(angle);
		float z = pt.r * sin(angle) + pt.b * cos(angle);
		pt.r = x;
		pt.b = z;
		return pt;
	}
	static Color RotZ(Color pt, float angle)
	{
		angle = angle * (float)PI / 180.0f;
		float x = pt.r * cos(angle) - pt.g * sin(angle);
		float y = pt.r * sin(angle) + pt.g * cos(angle);
		pt.r = x;
		pt.g = y;
		return pt;
	}
	bool IsBlack() {
		return r==0.0 && g==0.0 && b==0.0;
	}
};

class ColorMapEntry
{
public:
	double range;
	Color color;
};

class ColorMap
{
public:
	__int16 num;
	ColorMapEntry *cme;
public:
	ColorMap() { num = 0; cme = nullptr; };
	ColorMap(int nn) {
		num = nn;
		cme = new ColorMapEntry[num];
	}
	~ColorMap() {
		if (cme)
			delete[] cme;
	}
	Color GetColor(double value);
	void Copy(ColorMap *cmap);
};

};
