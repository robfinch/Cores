#include "stdafx.h"

extern Finray::RayTracer rayTracer;

using namespace Finray;

#define PTS_MAX	1000

namespace Finray
{

int compar(const void *p1, const void *p2)
{
	Intersection *q1 = (Intersection *)p1;
	Intersection *q2 = (Intersection *)p2;
	DBL d1, d2;
	d1 = q1->T;
	d2 = q2->T;
	return d1 < d2 ? -1 : d1==d2 ? 0 : 1;
}

IntersectResult *Ray::TestList(AnObject *obj, int TestType)
{
	int nn, mm;
	AnObject *o, *p, *lo;		//
	AnObject *slo, *sloNext;	// second last object
	IntersectResult *m, *q, *r;
	Intersection pts[PTS_MAX];
	int np;
	static int level = 0;
	bool isInside = false;

	if (obj==nullptr)
		return (nullptr);
	level++;
	np = 0;
	r = new IntersectResult;
	r->I[0].T = BIG;
	for (o = obj; o; o = o->next) {
		switch (o->type) {
		// In order to obtain the difference we need to temporarily remove the
		// last item in the object list, which is the object we want the difference
		// from. Otherwise the object would end up taking the difference of itself
		// and nothing displays then.
		case OBJ_DIFFERENCE:
			// Find the object at the end of the list, which will be the
			// object we want the difference from.
			p = o->obj;
			lo = p;
			slo = nullptr;
			while (p) {
				slo = lo;
				lo = p;
				p = p->next;
			}
			if (slo) {
				sloNext = slo->next;
				slo->next = nullptr;
			}

			switch(lo->type) {
			case OBJ_DIFFERENCE:	m = TestList(lo,MRT_UNION); break;
			case OBJ_INTERSECTION:	m = TestList(lo,MRT_INTERSECTION); break;
			default:				m = TestList(lo,MRT_UNION); break;
			}
			if (m==nullptr) {
				if (slo)
					slo->next = sloNext;
				break;
			}
			if (m->n==0) {
				if (slo)
					slo->next = sloNext;
				break;
			}
			// Now get the union of all the objects remaining in the difference clause
			q = TestList(o->obj,MRT_UNION);
			if (q) {
				if (q->n) {
					for (nn = 0; nn < m->n; nn++) {
						isInside = false;
						for (mm = 0; mm < q->n; mm++) {
							if (q->pI[mm].obj->IsInside(m->pI[nn].P))
								isInside = true;
						}
						// If the point is not inside any objects then keep it.
						if (!isInside) {
							pts[np] = m->pI[nn];
							np++;
						}
					}
				}
				else {
					for (nn = 0; nn < m->n && np < PTS_MAX; nn++) {
						pts[np] = m->pI[nn];
						np++;
					}
				}
				delete q;
			}
			// If there was nothing to remove for the difference, just return
			// the object points.
			else {
				for (nn = 0; nn < m->n && np < PTS_MAX; nn++) {
					pts[np] = m->pI[nn];
					np++;
				}
			}
			m->n = 0;
			if (slo) slo->next = sloNext;
			break;
		case OBJ_UNION:
		case OBJ_OBJECT:
			m = TestList(o->obj, MRT_UNION);
			break;
		case OBJ_INTERSECTION:
			m = TestList(o->obj, MRT_INTERSECTION);
			// Choose the innermost intersection ( the point in the middle )
			if (m) {
				if (m->n > 1) {
					m->I[0] = m->pI[(m->n>>1)-1];
					m->I[1] = m->I[0];
					m->n = 2;
				}
			}
			break;
		default:
			m = o->Intersect(this);
		}
		switch (TestType) {
		// A difference and a union have the same list processing.
		case MRT_DIFFERENCE:
			//break;
		// For a union keep track of any intersection point with any object.
		// Process the entire list.
		case MRT_UNION:
			if (m == nullptr)
				break;
			for (nn = 0; nn < m->n && np < PTS_MAX; nn++) {
				pts[np] = m->pI[nn];
				np++;
			}
			break;
		// For an intersection the ray must intersect all objects. On the first
		// object that isn't intersected, return a no-intersection status.
		// Otherwise keep processing until the end of the list is reached.
		case MRT_INTERSECTION:
			if (m == nullptr) {
				r->n = 0;
				level--;
				return (r);
			}
			if (m->n==0) {
				delete m;
				r->n = 0;
				level--;
				return (r);
			}
			for (nn = 0; nn < m->n && np < PTS_MAX; nn++) {
				pts[np] = m->pI[nn];
				np++;
			}
			break;
		}
		if (m)
			delete m;
	}
	if (np > 1)
		qsort((void *)pts, np, sizeof(Intersection), compar);
	if (np > 4)
		r->pI = new Intersection[min(35,np)];
	for (nn = 0; nn < 35 && nn < np; nn++)
		r->pI[nn] = pts[nn];
	r->n = nn;
	level--;
	return (r);
}

void Ray::Trace(Color *c)
{
	DBL normalDir;
	Vector point;
	Vector normal;
	IntersectResult *r;

	c->r = c->g = c->b = 0.0;
	if (rayTracer.HitRecurseLimit())
		return;
	// The objects listed in the script are implicitly a union at the outermost
	// level.
	r = TestList(rayTracer.objectList,(int)MRT_UNION);
	// If nothing intersected
	if (r == nullptr) {
		*c = rayTracer.backGround;
		return;
	}
	if (r->n == 0 || r->pI[0].T>=BIG) {
		delete r;
		*c = rayTracer.backGround;
		return;
	}
	point = r->pI[0].P;//Vector::Scale(dir, r->pI[0].T);
//	point = Vector::Add(point, origin);
	normal = r->pI[0].obj->Normal(point);
	normalDir = Vector::Dot(normal,dir);
	if (normalDir > 0.0)
		normal = Vector::Neg(normal);
	r->pI[0].obj->Shade(this, normal, point, c);
	delete r;
}

IntersectResult *Ray::Test(AnObject *o)
{
	IntersectResult *ir = nullptr;
	bool ai;

	if (o==nullptr)
		return (nullptr);
//	ai = o->AntiIntersects(this);
	ai = false;
	if (!ai) {
		ir = o->Intersect(this);
		return (ir);
	}
	return (ir);
}

};
