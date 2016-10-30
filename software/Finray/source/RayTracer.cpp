#include "stdafx.h"

Finray::RayTracer rayTracer;

using namespace Finray;

namespace Finray {

void RayTracer::Init()
{
	objectList = nullptr;
	lightList = nullptr;
	viewPoint = nullptr;
	symbolTable.count = 0;
	symbolTable.AddDefaultSymbols();
	recurseLevel = 0;
	maxRecurseLevel = 5;
	parser.pRayTracer = this;
	first_frame = 0;
	last_frame = 0;
	frameno = 0;
}

void RayTracer::Add(AnObject *obj) {
	if (obj==nullptr)
		throw gcnew Finray::FinrayException(ERR_NULLPTR, 0);
	if (objectList==nullptr) {
		objectList = obj;
		obj->next = nullptr;
	}
	else {
		obj->next = objectList;
		objectList = obj;
	}
}

void RayTracer::DeleteList(AnObject *list)
{
	AnObject *obj;

	while (list) {
		obj = list->next;
		delete list;
		list = obj;
	}
}

void RayTracer::DeleteList() {
	AnObject *obj;
	ALight *lobj;

	while (objectList) {
		DeleteList(objectList->obj);
		DeleteList(objectList->negobj);
		obj = objectList->next;
		delete objectList;
		objectList = obj;
	}
	while (lightList) {
		lobj = (ALight *)lightList->next;
		delete lightList;
		lightList = lobj;
	}
}

void RayTracer::Add(ALight *L)
{
	ALight *p, *q = nullptr;

	p = lightList;
	while (p) {
		q = p;
		p = (ALight *)p->next;
	}
	if (q)
		q->next = L;
	else
		lightList = L;
}

bool RayTracer::HitRecurseLimit()
{
	return recurseLevel > maxRecurseLevel;
}


void RayTracer::DumpObject(AnObject *obj)
{
	int nn;

	if (obj==nullptr)
		return;
	do {
		for (nn = 0; nn < indent; nn++)
			ofs.write(" ",1);
		switch(obj->type) {
		case OBJ_OBJECT:
			ofs.write("OBJECT\n",7);
			indent += 4;
			DumpObject(obj->obj);
			indent -= 4;
			break;
		case OBJ_SPHERE:
			ofs.write("SPHERE\n",7);
			break;
		case OBJ_CONE:
			ofs.write("CONE\n",5);
			break;
		case OBJ_CUBE:
			ofs.write("CUBE\n",5);
			indent += 4;
			DumpObject(obj->obj);
			indent -= 4;
			break;
		case OBJ_BOX:
			ofs.write("BOX\n",4);
			indent += 4;
			DumpObject(obj->obj);
			indent -= 4;
			break;
		case OBJ_CYLINDER:
			ofs.write("CYLINDER\n",9);
			break;
		case OBJ_TRIANGLE:
			ofs.write("TRIANGLE\n",9);
			break;
		}
	} while (obj = obj->next);
}

void RayTracer::DumpObjects()
{
	ofs.open("FinrayObjects.log", std::ios::out);
	indent = 0;
	DumpObject(objectList);
	ofs.close();
}

};

