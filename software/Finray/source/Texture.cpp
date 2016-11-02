#include "stdafx.h"

extern FinitronClasses::NoiseGen noiseGen;

#define FLOOR(x) ((x) >= 0.0 ? floor(x) : (0.0 - floor(0.0 - (x)) - 1.0))

using namespace Finray;

namespace Finray {

Texture::Texture()
{
	color1 = Color();
	color2 = Color();
	ambient.r = 0.0;
	ambient.g = 0.0;
	ambient.b = 0.0;
	diffuse = 0.0;
	brilliance = 0.0;
	specular = 0.0;
	roughness = 0.0;
	reflection = 0.0;
	ColorMethod = 0;
	gradient = Vector(0,0,0);
	pigment = nullptr;
	usesTransform = false;
}

Texture::Texture(Texture *s)
{
	Copy(s);
}

Texture::~Texture()
{
	if (pigment)
		delete pigment;
}

void Texture::Copy(Texture *t)
{
	color1 = t->color1;
	color2 = t->color2;
	if (pigment)
		delete pigment;
	if (t->pigment) {
		pigment = new Pigment;
		pigment->color.r = t->pigment->color.r;
		pigment->color.g = t->pigment->color.g;
		pigment->color.b = t->pigment->color.b;
		if (t->pigment->cm) {
			pigment->cm = new ColorMap;
			pigment->cm->Copy(t->pigment->cm);
		}
	}
	ambient = t->ambient;
	diffuse = t->diffuse;
	brilliance = t->brilliance;
	specular = t->specular;
	roughness = t->roughness;
	reflection = t->reflection;
	ColorMethod = t->ColorMethod;
	gradient = t->gradient;
	turbulence = t->turbulence;
	usesTransform = t->usesTransform;
	trans.Copy(&t->trans);
}

/*
void Texture::SetAttrib(float rd, float gn, float bl, Color a, float d, float b, float s, float ro, float r)
{
	color.r = rd;
	color.g = gn;
	color.b = bl;
	ambient = a;
	diffuse = d;
	brilliance = b;
	specular = s;
	roughness = ro;
	reflection = r;
}
*/

DBL TriangleWave (DBL value)
{
   DBL offset;

   if (value >= 0.0) offset = value - FLOOR(value);
   else offset = value - (-1.0 - FLOOR(fabs(value)));

   if (offset >= 0.5) return (2.0 * (1.0 - offset));
   else return (2.0 * offset);
}


Color Texture::Granite(Vector point, Color clr)
{
	int ii;
	DBL temp;
	DBL noise = 0.0;
	DBL freq = 1.0;

	for (ii = 0; ii < 6; ii++) {
		temp = noiseGen.Noise3(Vector::Scale(point,4*freq));
		temp = 0.5 - temp;
		temp = fabs(temp);
		noise += temp / freq;
		freq *= 2.0;
	}
	if (pigment->cm != nullptr) {
		return (Color::Add(clr,pigment->cm->GetColor(noise)));
	}
	return (Color::Add(clr,Color((float)noise,(float)noise,(float)noise)));
}


Color Texture::Marble(Vector point, Color clr)
{
   DBL noise, hue;
   Color New_Color;

   noise = TriangleWave(point.x + noiseGen.Turbulence(point) * turbulence);

   if (pigment) {
	   if (pigment->cm != nullptr)
	   {
		  New_Color = pigment->cm->GetColor(noise);
		  clr.r += New_Color.r;
		  clr.g += New_Color.g;
		  clr.b += New_Color.b;
	//      colour -> Alpha += New_Colour.Alpha;
		  return (clr);
	   }
   }

   if (noise < 0.0)
   {
      clr.r += 0.9f;
      clr.g += 0.8f;
      clr.b += 0.8f;
   }
   else if (noise < 0.9)
   {
      clr.r += 0.9f;
      hue = 0.8 - noise * 0.8;
      clr.g += (float)hue;
      clr.b += (float)hue;
   }
   return (clr);
}


Color Texture::Wood (Vector pt, Color colour)
{
   DBL noise, length;
   Vector WoodTurbulence;
   Vector point;
   Color NewColour;

   WoodTurbulence = noiseGen.DTurbulence(pt);

   point.x = noiseGen.Cycloidal((pt.x + WoodTurbulence.x) * turbulence);
   point.y = noiseGen.Cycloidal((pt.y + WoodTurbulence.y) * turbulence);
   point.z = 0.0;

   point.x += pt.x;
   point.y += pt.y;
   point.z += pt.z;

   length = Vector::Length(point);
   noise = TriangleWave(length);

	if (pigment != nullptr) {
	   if (pigment->cm != nullptr) {
		  NewColour = pigment->cm->GetColor(noise);
		  colour.r += NewColour.r;
		  colour.g += NewColour.g;
		  colour.b += NewColour.b;
	//      colour -> Alpha += NewColour.Alpha;
		  return (colour);
		}
	}

   if (noise > 0.6) {
      colour.r += 0.4f;
      colour.g += 0.133f;
      colour.b += 0.066f;
      }
  else {
      colour.r += 0.666f;
      colour.g += 0.312f;
      colour.b += 0.2f;
  }
  return (colour);
}

Color Texture::Gradient(Vector point, Color clr)
{
	Color c;
	DBL value = 0.0;
	DBL x,y,z;

	if (pigment->cm==nullptr)
		return (c);
	if (gradient.x != 0.0) {
		x = fabs(point.x);
		value += x - FLOOR(x);
	}
	if (gradient.y != 0.0) {
		y = fabs(point.y);
		value += y - FLOOR(y);
	}
	if (gradient.z != 0.0) {
		z = fabs(point.z);
		value += z - FLOOR(z);
	}
	value = (value > 1.0) ? fmod(value,1.0) : value;
	return (Color::Add(clr,pigment->cm->GetColor(value)));
}

Color Texture::Bozo(Vector point, Color clr)
{
   DBL noise, turb;
   Color NewColour;
   Vector BozoTurbulence;

   if ((turb = turbulence) != 0.0)
   {
      BozoTurbulence = noiseGen.DTurbulence (point);
	  point = Vector::Add(point, Vector::Scale(BozoTurbulence, turb));
   }

   noise = noiseGen.Noise3(point);

   if (pigment != nullptr) {
	   if (pigment->cm != nullptr) {
		  NewColour = pigment->cm->GetColor(noise);
		  clr = Color::Add(clr,NewColour);
		  //clr.Alpha += New_Colour.Alpha;
		  return (clr);
      }
   }

	if (noise < 0.4) {
		clr = Color::Add(clr,Color(1.0,1.0,1.0));
		return (clr);
    }

   if (noise < 0.6) {
      clr.g += 1.0;
      return (clr);
      }

   if (noise < 0.8) {
      clr.b += 1.0;
      return (clr);
      }

   clr.r += 1.0;
   return (clr);
}

Color Texture::Checker(Vector point, Color clr)
{
   int brkindx;

   brkindx = (int) FLOOR(point.x) + (int) FLOOR(point.z);

   if (brkindx & 1)
      clr = color1;
   else
      clr = color2;
   return (clr);
}



Color Texture::GetColor(Vector point)
{
	Color c;
	double n;
	double r,g,b;
	int rb,gb,bb,ndx;
	static RTFClasses::Random *prand = nullptr;

	if (prand==nullptr)
		prand = RTFClasses::Random::srand(21);

	if (usesTransform)
		point = trans.InvTransPoint(point);

	switch(ColorMethod) {
	case TM_FLAT:
		if (pigment)
			return (pigment->color);
		return (c);
	case TM_NOISY:
		n = noiseGen.Noise(point, 2.0, 2.0, 4);
		if (pigment)
			c = pigment->color;
		c.r += (float)n;
		c.g += (float)n;
		c.b += (float)n;
		if (c.r > 1.0) c.r = 1.0;
		if (c.g > 1.0) c.g = 1.0;
		if (c.b > 1.0) c.b = 1.0;
		if (c.r < 0.0) c.r = 0.0;
		if (c.g < 0.0) c.g = 0.0;
		if (c.b < 0.0) c.b = 0.0;
		return (c);
	case 2:
		r = fmod(point.x,1.0);
		if (fabs(r) > 0.5) rb = 4; else rb = 0;
		g = fmod(point.y,1.0);
		if (fabs(g) > 0.5) gb = 2; else gb = 0;
		b = fmod(point.z,1.0);
		if (fabs(b) > 0.5) bb = 1; else bb = 0;
		ndx = rb|gb|bb;
		switch(ndx) {
		case 0:	c.r = 0.0; c.g = 0.0; c.b = 0.0; break;
		case 1:	c.r = 0.0; c.g = 0.0; c.b = 1.0; break;
		case 2:	c.r = 0.0; c.g = 1.0; c.b = 0.0; break;
		case 3:	c.r = 0.0; c.g = 1.0; c.b = 1.0; break;
		case 4:	c.r = 1.0; c.g = 0.0; c.b = 0.0; break;
		case 5:	c.r = 1.0; c.g = 0.0; c.b = 1.0; break;
		case 6:	c.r = 1.0; c.g = 1.0; c.b = 0.0; break;
		case 7:	c.r = 1.0; c.g = 1.0; c.b = 1.0; break;
		}
		return (c);
	case 3:	// approximate color
		if (pigment)
			c = pigment->color;
		c.r = c.r + ((float)prand->rand((int)(variance.r * 256))-variance.r * 128) / 256.0f;
		c.g = c.g + ((float)prand->rand((int)(variance.g * 256))-variance.g * 128) / 256.0f;
		c.b = c.b + ((float)prand->rand((int)(variance.b * 256))-variance.b * 128) / 256.0f;
		return (c);
	case TM_GRADIENT:	return (Gradient(point, pigment ? pigment->color : c));
	case TM_GRANITE:	return (Granite(point, pigment ? pigment->color : c));
	case TM_MARBLE:		return (Marble(point, pigment ? pigment->color : c));
	case TM_WOOD:		return (Wood(point, pigment ? pigment->color : c));
	case TM_BOZO:		return (Bozo(point, pigment ? pigment->color : c));
	case TM_CHECKER:	return (Checker(point, c));
	case TM_RANDOM:
		c.r = (float)prand->rand(256) / 256.0f;
		c.g = (float)prand->rand(256) / 256.0f;
		c.b = (float)prand->rand(256) / 256.0f;
		return (c);
	}
	// Return black for unknown coloring method.
	return (c);
}

};
