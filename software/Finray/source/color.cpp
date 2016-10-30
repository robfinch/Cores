#include "stdafx.h"

Finray::Color backGround;
/*
Color Color::Approximate(Vector v)
{

}
*/

namespace Finray
{
Finray::Color ColorMap::GetColor(double value) {
	int nn;
	Finray::Color clr, clr1, clr2;
	double fraction, r1, r2;

	if (value > 1.0) value = 1.0;
	if (value < 0.0) value = 0.0;
	for (nn = 0; nn < num; nn++) {
		if (value <= cme[nn].range) {
			clr2 = cme[nn].color;
			r2 = cme[nn].range;
			if (nn > 0) {
				clr1 = cme[nn-1].color;
				r1 = cme[nn-1].range;
			}
			else {
				clr1 = cme[num-1].color;
				r1 = -(1.0 - cme[num-1].range);
			}
			fraction = (value - r1) / (r2 - r1);
			clr.r = clr1.r + (float)(fraction * (clr2.r-clr1.r));
			clr.g = clr1.g + (float)(fraction * (clr2.g-clr1.g));
			clr.b = clr1.b + (float)(fraction * (clr2.b-clr1.b));
			return clr;
		}
	}
	clr1 = cme[num-1].color;
	r1 = cme[num-1].range;
	clr2 = cme[0].color;
	r2 = cme[0].range + 1.0;
	fraction = (value - r1) / (r2 - r1);
	clr.r = clr1.r + (float)(fraction * (clr2.r-clr1.r));
	clr.g = clr1.g + (float)(fraction * (clr2.g-clr1.g));
	clr.b = clr1.b + (float)(fraction * (clr2.b-clr1.b));
	return clr;
}

void ColorMap::Copy(ColorMap *cmap)
{
	num = cmap->num;
	if (cme)
		delete[] cme;
	cme = new ColorMapEntry[num];
	memcpy(cme, cmap->cme, sizeof(ColorMapEntry) * num);
}

}
