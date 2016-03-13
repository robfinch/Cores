#include "stdafx.h"

namespace Finray {


ACube::ACube(double s)
{
	int nn;
	Vector pt1,pt2,pt3,pt4,pt5,pt6,pt7,pt8;
	ATriangle *o;

	type = OBJ_CUBE;
	obj = nullptr;
	next = nullptr;
	negobj = nullptr;

	for (nn = 0; nn < 12; nn++) {
		o = new ATriangle();
		tri[nn] = o;
		o->next = obj;
		obj = o;
	}

	pt1 = Vector(s,0,0);
	pt2 = Vector(s,0,s);
	pt3 = Vector(s,s,s);
	pt4 = Vector(s,s,0);
	pt5 = Vector(0,0,0);
	pt6 = Vector(0,0,s);
	pt7 = Vector(0,s,s);
	pt8 = Vector(0,s,0);

	// right
	tri[0]->p1 = pt1;
	tri[0]->p2 = pt2;
	tri[0]->p3 = pt3;
	tri[1]->p1 = pt1;
	tri[1]->p2 = pt3;
	tri[1]->p3 = pt4;
	// front
	tri[2]->p1 = pt1;
	tri[2]->p2 = pt4;
	tri[2]->p3 = pt5;
	tri[3]->p1 = pt5;
	tri[3]->p2 = pt4;
	tri[3]->p3 = pt8;
	//left
	tri[4]->p1 = pt5;
	tri[4]->p2 = pt6;
	tri[4]->p3 = pt7;
	tri[5]->p1 = pt7;
	tri[5]->p2 = pt8;
	tri[5]->p3 = pt5;
	// back face
	tri[6]->p1 = pt2;
	tri[6]->p2 = pt6;
	tri[6]->p3 = pt3;
	tri[7]->p1 = pt3;
	tri[7]->p2 = pt6;
	tri[7]->p3 = pt7;
	// bottom
	tri[8]->p1 = pt5;
	tri[8]->p2 = pt1;
	tri[8]->p3 = pt2;
	tri[9]->p1 = pt5;
	tri[9]->p2 = pt2;
	tri[9]->p3 = pt6;
	// top
	tri[10]->p1 = pt8;
	tri[10]->p2 = pt4;
	tri[10]->p3 = pt3;
	tri[11]->p1 = pt3;
	tri[11]->p2 = pt7;
	tri[11]->p3 = pt8;

	o = (ATriangle *)obj;
	while (o) {
		o->Init();
		o = (ATriangle *)o->next;
	}
}

ACube::ACube(Vector pt, double s) : ABox(pt, Vector(s,s,s))
{
}

};
